import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

/// 🔧 DEV FLAG — false = login screen, true = skip to home
const bool kSkipLogin = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const TravelAdvisorApp());
}

class TravelAdvisorApp extends StatelessWidget {
  const TravelAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GP Travel Advisor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: kSkipLogin ? const MainShell() : const LoginScreen(),
    );
  }
}
