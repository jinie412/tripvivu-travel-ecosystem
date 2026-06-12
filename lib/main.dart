import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/survey/presentation/screens/survey_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';

/// 🔧 DEV FLAG — false = login screen, true = skip to home
const bool kSkipLogin = AppConfig.kSkipLogin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  await initializeDateFormatting('vi_VN', null);
  // AlarmManager cho theo dõi lịch trình (đăng ký lại geofence sáng hôm sau).
  if (!kIsWeb) {
    await AndroidAlarmManager.initialize();
  }
  await initDependencies();
  
  // ✅ KHỞI TẠO MAPBOX SDK
  // Lưu ý: Mapbox v2 bắt buộc dùng Mapbox Public Token (pk...) để khởi động engine.
  // Goong Key sẽ được dùng riêng trong Style URL ở các Widget.
  if (!kIsWeb) {
    String mapboxPublicToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? 'pk.eyJ1IjoibWFwdHJhdmVsNjgiLCJhIjoiY21vbmpkdXh4MDF0YTJxczlhMzQ3ZzF1cSJ9.gC1J7jzlMnFD_yHe-4JgqQ';
    MapboxOptions.setAccessToken(mapboxPublicToken);
  }

  runApp(const TravelAdvisorApp());
}

class TravelAdvisorApp extends StatefulWidget {
  const TravelAdvisorApp({super.key});

  @override
  State<TravelAdvisorApp> createState() => _TravelAdvisorAppState();
}

class _TravelAdvisorAppState extends State<TravelAdvisorApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
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
      home: kSkipLogin ? const MainShell() : const LoginScreen(),
      routes: {
        '/home': (context) => const MainShell(),
        '/survey': (context) => const SurveyScreen(),
      },
    );
  }
}
