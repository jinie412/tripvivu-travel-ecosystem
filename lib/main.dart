import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_navigation_service.dart';
import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/survey/presentation/screens/survey_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';

/// 🔧 DEV FLAG — true = bỏ qua AuthGate, vào thẳng MainShell (chỉ dùng khi dev)
const bool kSkipLogin = AppConfig.kSkipLogin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Giới hạn cache ảnh giải mã trong RAM (mặc định Flutter là 100MB/1000 ảnh).
  // App nhiều ảnh + Mapbox → RAM cao khiến Android ưu tiên kill khi chạy nền;
  // hạ trần xuống 48MB để process nhẹ hơn khi người dùng đa nhiệm.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20; // 48MB
  PaintingBinding.instance.imageCache.maximumSize = 300;

  await dotenv.load(fileName: ".env");
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await FcmService.init();
  } else {
    debugPrint('[FCM] Firebase initialization skipped on web.');
  }
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  await initializeDateFormatting('vi_VN', null);
  // AlarmManager chỉ hỗ trợ Android — guard để không crash trên iOS/web.
  if (!kIsWeb && Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }
  await initDependencies();

  // ✅ KHỞI TẠO MAPBOX SDK
  // Lưu ý: Mapbox v2 bắt buộc dùng Mapbox Public Token (pk...) để khởi động engine.
  // Goong Key sẽ được dùng riêng trong Style URL ở các Widget.
  if (!kIsWeb) {
    String mapboxPublicToken =
        dotenv.env['MAPBOX_PUBLIC_TOKEN'] ??
        'pk.eyJ1IjoibWFwdHJhdmVsNjgiLCJhIjoiY21vbmpkdXh4MDF0YTJxczlhMzQ3ZzF1cSJ9.gC1J7jzlMnFD_yHe-4JgqQ';
    MapboxOptions.setAccessToken(mapboxPublicToken);
  }

  runApp(const TravelAdvisorApp());
}

class TravelAdvisorApp extends StatefulWidget {
  const TravelAdvisorApp({super.key});

  @override
  State<TravelAdvisorApp> createState() => _TravelAdvisorAppState();
}

class _TravelAdvisorAppState extends State<TravelAdvisorApp>
    with WidgetsBindingObserver {
  final _navigatorKey = NotificationNavigationService.navigatorKey;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi app vào nền: xả cache ảnh đã giải mã để giảm RAM chiếm giữ →
    // Android ít kill process hơn khi người dùng đa nhiệm. Ảnh đang hiển thị
    // không bị ảnh hưởng (widget còn giữ tham chiếu); khi quay lại app các
    // ảnh khác được nạp lại từ disk cache nên rất nhanh.
    if (state == AppLifecycleState.paused) {
      PaintingBinding.instance.imageCache.clear();
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Lắng nghe deeplink khi app đang chạy
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Kiểm tra deeplink khi app khởi động cold (vừa bị tắt)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  /// Xử lý deeplink từ email Supabase reset-password.
  /// URL sẽ có dạng: gptraveladvisor://reset-password?access_token=xxx&...
  void _handleDeepLink(Uri uri) {
    if (uri.host == 'itinerary-share') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationNavigationService.handleItineraryShareLink(uri);
      });
      return;
    }

    if (uri.host == 'reset-password') {
      // Lấy access_token từ query params hoặc fragment (#access_token=...)
      String? accessToken = uri.queryParameters['access_token'];

      // Supabase đôi khi đặt token trong fragment (#)
      if (accessToken == null && uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        accessToken = fragmentParams['access_token'];
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(accessToken: accessToken!),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'GP Travel Advisor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      home: kSkipLogin ? const MainShell() : const AuthGateScreen(),
      routes: {
        '/home': (context) => const MainShell(),
        '/survey': (context) => const SurveyScreen(),
      },
    );
  }
}
