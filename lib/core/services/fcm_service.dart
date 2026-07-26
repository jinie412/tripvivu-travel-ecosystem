import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/services/notification_navigation_service.dart';
import 'package:travel_advisor_mobile/core/services/notification_service.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized. Android shows notifications automatically.
}

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'default',
    'Thông báo',
    description: 'Thông báo từ GP Travel Advisor',
    importance: Importance.high,
  );

  /// Call once after Firebase.initializeApp() in main.dart.
  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('[FCM] Init skipped on web.');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // v21: initialize uses named parameter `settings`
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        NotificationNavigationService.handlePayload(response.payload);
      },
    );

    if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Show local notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      if (!NotificationService.claimRemoteNotification(
        message.data['notification_id']?.toString(),
      )) {
        return;
      }

      // v21: show uses named parameters
      _localNotif.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationNavigationService.handleData(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationNavigationService.handleData(initialMessage.data);
      });
    }
  }

  /// Request permission and register FCM token for the given user.
  /// Call this after successful login / session restore.
  static Future<void> registerToken(String userId, DioClient dioClient) async {
    if (kIsWeb) {
      debugPrint('[FCM] Token registration skipped on web.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      if (Platform.isIOS) {
        await messaging.getAPNSToken();
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await dioClient.dio.post(
        '/notifications/fcm-token',
        data: {'tourist_id': userId, 'fcm_token': fcmToken},
        options: Options(extra: {'_retried': false}),
      );

      debugPrint('[FCM] Token registered for user $userId');

      messaging.onTokenRefresh.listen((newToken) {
        dioClient.dio.post(
          '/notifications/fcm-token',
          data: {'tourist_id': userId, 'fcm_token': newToken},
        ).catchError((_) => Response(requestOptions: RequestOptions()));
      });
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}
