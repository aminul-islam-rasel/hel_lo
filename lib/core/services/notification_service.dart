import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  try {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    
    // Create channel for Android background messages
    final androidPlugin = localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        ),
      );
    }

    await localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Hel Lo Message',
      message.notification?.body ?? message.data['body'] ?? 'New message received',
      details,
    );
  } catch (e) {
    debugPrint('Background message handler notification error: $e');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create Android Notification Channels
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'incoming_call_channel',
          'Incoming Calls',
          description: 'This channel is used for incoming voice and video calls.',
          importance: Importance.max,
        ),
      );
    }

    await _localNotifications.initialize(initSettings);

    // Request FCM permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Automatically update token when refreshed
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        savePushToken(currentUserId);
      }
    });
  }

  static Future<void> savePushToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'pushToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FCM Token save note: $e');
    }
  }

  static Future<void> sendNotificationToUser({
    required String recipientUid,
    required String senderName,
    required String messageText,
  }) async {
    if (recipientUid.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(recipientUid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data();
      final pushToken = data?['pushToken'] as String?;
      final notificationSettings = data?['notificationSettings'] as Map<String, dynamic>? ?? {};
      final isPreviewEnabled = notificationSettings['preview'] as bool? ?? true;

      if (pushToken == null || pushToken.isEmpty) return;

      final bodyText = isPreviewEnabled ? messageText : 'New message received';

      await _localNotifications.show(
        DateTime.now().millisecond,
        senderName,
        bodyText,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Send notification error: $e');
    }
  }

  static Future<void> sendCallNotification({
    required String recipientUid,
    required String callerName,
    required String callId,
    required String callType,
  }) async {
    if (recipientUid.isEmpty) return;
    try {
      await _localNotifications.show(
        9999,
        'Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
        '$callerName is calling you...',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'incoming_call_channel',
            'Incoming Calls',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Send call notification error: $e');
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      details,
    );
  }
}
