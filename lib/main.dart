import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/firebase_options.dart';
import 'package:el_moza3/screens/splash_screen.dart';
import 'package:el_moza3/screens/otp_verification_screen.dart';
import 'package:el_moza3/services/error_handler.dart';
import 'package:el_moza3/services/notification_service.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'package:el_moza3/services/chat_service.dart';

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
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'الموزّع',
      theme: _buildTheme(),
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
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background2,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.radiusMedium,
          side: AppBorders.defaultBorderSide,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.inputPadding,
          vertical: AppSizes.inputPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: AppBorders.defaultBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: AppBorders.defaultBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: AppBorders.focusBorderSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: AppSizes.fieldFontSize,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusMedium),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusMedium),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      fontFamily: AppTypography.fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
