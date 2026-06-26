import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/navigation/main_shell.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/services/fcm_service.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/screens/login_screen.dart';

/// Màn hình đầu tiên khi app khởi động.
/// Kiểm tra session trong storage và điều hướng tự động:
///   - Có session hợp lệ → MainShell (không cần đăng nhập lại)
///   - Không có / hết hạn → LoginScreen
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Tạo cubit và gọi checkSession() ngay khi widget được mount.
      create: (_) => sl<AuthCubit>()..checkSession(),
      child: const _AuthGateView(),
    );
  }
}

class _AuthGateView extends StatelessWidget {
  const _AuthGateView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          FcmService.registerToken(state.user.id, sl<DioClient>());
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: _SplashBody(),
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo — đồng nhất với LoginScreen
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColorsExt.authBgLight,
              borderRadius: BorderRadius.circular(AppSizes.r32),
            ),
            child: const Center(
              child: Icon(
                Icons.flight_takeoff_rounded,
                size: AppSizes.s48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s24),
          Text(
            'GP Travel Advisor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3C6E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            'Đang khởi động...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s40),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}
