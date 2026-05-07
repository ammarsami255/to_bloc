import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_moza3/core/constants/app_constants.dart';
import 'package:el_moza3/core/theme/app_theme.dart';
import 'package:el_moza3/firebase_options.dart';
import 'package:el_moza3/screens/splash_screen.dart';
import 'package:el_moza3/screens/otp_verification_screen.dart';
import 'package:el_moza3/services/error_handler.dart';
import 'package:el_moza3/services/notification_service.dart';
import 'package:el_moza3/services/chat_service.dart';
import 'package:el_moza3/features/auth/presentation/cubit/auth_cubit.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.initialize();

  runApp(const ElMoza3App());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.processPendingNavigation();
  });

  // Set online when app starts
  ChatService.setOnline();

  // Listen for app lifecycle to update online/offline
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
}

/// Observer to set online/offline status when app pauses/resumes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App going to background - set offline
      ChatService.setOffline();
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - set online
      ChatService.setOnline();
    }
  }
}

class ElMoza3App extends StatelessWidget {
  const ElMoza3App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'الموزّع',
        theme: AppTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
        locale: const Locale('ar', 'SA'),
        home: const SplashScreen(),
        routes: <String, WidgetBuilder>{
          OtpVerificationScreen.id: (context) {
            final email =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return OtpVerificationScreen(email: email);
          },
        },
      ),
    );
  }
}