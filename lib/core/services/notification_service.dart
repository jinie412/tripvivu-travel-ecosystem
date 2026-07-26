import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'notification_navigation_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static final Set<String> _claimedRemoteNotificationIds = <String>{};

  /// FCM foreground và Supabase Realtime có thể cùng báo một notification.
  /// Nguồn đến trước được quyền hiển thị; nguồn đến sau bỏ qua theo ID.
  static bool claimRemoteNotification(String? notificationId) {
    final id = notificationId?.trim() ?? '';
    if (id.isEmpty) return true;
    if (!_claimedRemoteNotificationIds.add(id)) return false;
    if (_claimedRemoteNotificationIds.length > 200) {
      _claimedRemoteNotificationIds.remove(
        _claimedRemoteNotificationIds.first,
      );
    }
    return true;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    // Cấu hình Android (cần có icon ic_launcher trong android/app/src/main/res/drawable hoặc mipmap)
    // Flutter mặc định dùng @mipmap/ic_launcher
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình iOS (nếu có build iOS)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        NotificationNavigationService.handlePayload(response.payload);
      },
    );

    _isInitialized = true;
  }

  /// Xin quyền gửi thông báo từ người dùng
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Hiển thị một Push Notification (popup ở trên cùng màn hình)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'travel_advisor_channel', // id kênh
      'Travel Advisor Notifications', // tên kênh
      channelDescription: 'Thông báo từ hệ thống GP Travel Advisor',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: Random().nextInt(100000), // ID tự tạo
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
