import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'support_screen.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/cubit/auth_cubit.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<bool> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    return shouldLogout ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await _confirmLogout(context);
    if (!shouldLogout || !context.mounted) return;

    await Supabase.instance.client.auth.signOut();

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24,
            vertical: AppSizes.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tài khoản',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 22,
                      color: AppColorsExt.textDark,
                    ),
                  ),
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      final avatarUrl = state is ProfileLoaded
                          ? state.profile.avatarUrl
                          : '';

                      return CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 30,
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s32),

              // Menu Items
              _buildMenuItem(
                icon: Icons.account_circle,
                title: 'Hồ sơ',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (_) => sl<ProfileCubit>()..loadProfile(),
                        child: const EditProfileScreen(),
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  context.read<ProfileCubit>().loadProfile();
                },
              ),
              const Divider(height: 1),
              _buildMenuItem(
                icon: Icons.notifications,
                title: 'Thông báo',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildMenuItem(
                icon: Icons.language,
                title: 'Ngôn ngữ',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Chọn ngôn ngữ'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.check,
                              color: AppColors.primary,
                            ),
                            title: Text('Tiếng Việt'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Đổi mật khẩu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (_) => sl<AuthCubit>(),
                        child: const ChangePasswordScreen(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Hỗ trợ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              const SizedBox(height: AppSizes.s48),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Đăng xuất',
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.s40),

              // Footer Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Phiên bản: v66.5 bản dựng 260119007',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s40,
                      ),
                      child: Text(
                        'ID thiết bị: 19d532bc-7d43-4941-900b-a18233ea8644',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Icon(icon, color: AppColorsExt.textDark, size: AppSizes.iconLg),
      title: Text(
        title,
        style: AppTextStyles.heading2.copyWith(
          fontSize: 18,
          color: AppColorsExt.textDark,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
