import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import 'package:travel_advisor_mobile/core/services/auth_storage.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/widgets/auth_shared_widgets.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/widgets/auth_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmPassword = true;

  Future<void> _logoutAndRedirect() async {
    await supabase_flutter.Supabase.instance.client.auth.signOut();

    await AuthStorage.delete('access_token');
    await AuthStorage.delete('refresh_token');
    await AuthStorage.delete('cached_user');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthCubit>().changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';
    if (confirmPassword.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }

    if (confirmPassword != _newPasswordController.text.trim()) {
      return 'Mật khẩu xác nhận không khớp';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is ChangePasswordSuccess) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thành công!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _logoutAndRedirect();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is AuthError) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Không thể đổi mật khẩu'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.premiumBackground,
          appBar: AppBar(
            backgroundColor: AppColors.premiumBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.premiumNavy,
                size: 20,
              ),
              onPressed: isLoading ? null : () => Navigator.pop(context),
            ),
            title: Text(
              'Đổi mật khẩu',
              style: TextStyle(
                color: AppColors.premiumNavy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              const AuthBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FF),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_person_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Bảo mật tài khoản',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới để thay đổi',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        AuthTextField(
                          controller: _currentPasswordController,
                          label: 'Mật khẩu hiện tại',
                          hintText: 'Nhập mật khẩu hiện tại',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureCurrent,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: isLoading
                                ? null
                                : () => setState(
                                    () => _obscureCurrent = !_obscureCurrent,
                                  ),
                          ),
                          validator: (v) => (v?.isEmpty ?? true)
                              ? 'Vui lòng nhập mật khẩu hiện tại'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          controller: _newPasswordController,
                          label: 'Mật khẩu mới',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: isLoading
                                ? null
                                : () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Vui lòng nhập mật khẩu mới';
                            if (v.length < 8)
                              return 'Mật khẩu phải có ít nhất 8 ký tự';
                            if (!RegExp(r'[A-Z]').hasMatch(v))
                              return 'Mật khẩu phải chứa ít nhất 1 chữ hoa';
                            if (!RegExp(r'[a-z]').hasMatch(v))
                              return 'Mật khẩu phải chứa ít nhất 1 chữ thường';
                            if (!RegExp(r'[0-9]').hasMatch(v))
                              return 'Mật khẩu phải chứa ít nhất 1 chữ số';
                            if (!RegExp(r'[@$!%*?&.#]').hasMatch(v)) {
                              return r'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (@$!%*?&.#)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Xác nhận mật khẩu mới',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: isLoading
                                ? null
                                : () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                          ),
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleChangePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Cập nhật mật khẩu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
