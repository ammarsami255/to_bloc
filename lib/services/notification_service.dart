import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_service.dart';
import 'error_handler.dart';
import '../screens/chat_screen.dart';
import '../screens/service_detail_screen.dart';

/// Handles FCM registration, foreground fallback display, and notification taps.
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const MethodChannel _platformNotifications = MethodChannel(
    'el_moza3/notifications',
  );

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static Map<String, dynamic>? _pendingNavigationData;

  static Future<bool> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _createAndroidNotificationChannel();

      if (kDebugMode) {
        debugPrint('Notification permission: ${settings.authorizationStatus}');
        debugPrint('FCM Token: ${await _messaging.getToken()}');
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleInitialMessage(initialMessage);
      }

      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Notification init error: $error');
      }
      return false;
    }
  }

  static Future<void> saveToken(String userId) async {
    try {
      if (userId.isEmpty) return;
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final fn = _functions.httpsCallable('saveToken');
      await fn.call({'token': token, 'platform': _platformLabel()});

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
        newToken,
      ) async {
        final refreshFn = _functions.httpsCallable('saveToken');
        await refreshFn.call({'token': newToken, 'platform': _platformLabel()});
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Save token error: $error');
      }
    }
  }

  static Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      final fn = _functions.httpsCallable('deleteToken');
      await fn.call({'token': token});
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Delete token error: $error');
      }
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Subscribe error: $error');
      }
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unsubscribe error: $error');
      }
    }
  }

  @Deprecated('Use server-side notifications via triggers instead')
  static Future<void> createNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? actionData,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'Client notification creation blocked - use server-side triggers',
      );
    }
  }

  static Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'read': true});
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Mark as read error: $error');
      }
    }
  }

  static Future<void> clearAll(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Clear notifications error: $error');
      }
    }
  }

  static Future<void> processPendingNavigation() async {
    final data = _pendingNavigationData;
    if (data == null) return;
    _pendingNavigationData = null;
    await _navigateFromData(data);
  }

  static Future<void> handleLocalNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        await _navigateFromData(decoded);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Notification payload error: $error');
      }
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Foreground message: ${message.notification?.title}');
    }
    await _showForegroundNotification(message);
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    await _navigateFromMessage(message);
  }

  static Future<void> _handleInitialMessage(RemoteMessage message) async {
    await _navigateFromMessage(message);
  }

  static Future<void> _navigateFromMessage(RemoteMessage message) async {
    await _navigateFromData(Map<String, dynamic>.from(message.data));
  }

  static Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNavigationData = data;
      return;
    }

    final type = data['type']?.toString();
    if (type == 'chat') {
      final chatId = data['chatId']?.toString();
      if (chatId == null || chatId.isEmpty) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _pendingNavigationData = data;
        return;
      }

      final participants = await ChatService.getParticipants(chatId);
      if (!participants.contains(currentUserId)) return;

      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ChatDetailScreen(chatId: chatId, otherUserId: otherUserId),
        ),
      );
      return;
    }

    if (type == 'listing') {
      final listingId = data['listingId']?.toString();
      if (listingId == null || listingId.isEmpty) return;

      final doc = await _firestore.collection('listings').doc(listingId).get();
      final item = doc.data();
      if (!doc.exists || item == null) return;

      item['id'] = doc.id;
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ServiceDetailScreen(item: item, onRequireLogin: () async {}),
        ),
      );
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) return;

    try {
      await _platformNotifications.invokeMethod('showNotification', {
        'title': title.isEmpty ? 'Notification' : title,
        'body': body,
        'payload': jsonEncode(message.data),
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Foreground notification error: $error');
      }
    }
  }

  static Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _platformNotifications.invokeMethod('createChannel');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Create Android notification channel error: $error');
      }
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
