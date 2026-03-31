import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/widgets/auth_shared_widgets.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tạo tài khoản...')),
      );
      // Navigate to survey after a small delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/survey');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24, vertical: AppSizes.s32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Logo Section
                    Center(
                      child: Container(
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
                    ),
                    const SizedBox(height: AppSizes.s32),
                    
                    // 2. Title Section
                    Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.s12),
                    Text(
                      'Tạo tài khoản để bắt đầu chuyến đi của bạn',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.s32),

                    // 3. Name Field
                    AuthTextField(
                      controller: _nameController,
                      label: 'Họ và tên',
                      hintText: 'Nhập họ và tên của bạn',
                      prefixIcon: null, // No icon for name as per image
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: AppSizes.s20),

                    // 4. Gender Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giới tính',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(AppSizes.r12),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              hint: Text(
                                'Chọn giới tính',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                              items: ['Nam', 'Nữ'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. Email Field
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Nhập email của bạn',
                      prefixIcon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập email' : null,
                    ),
                    const SizedBox(height: 20),

                    // 6. Phone Field
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại của bạn',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập SĐT' : null,
                    ),
                    const SizedBox(height: 20),

                    // 7. Password Field
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: AppSizes.iconMd,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu' : null,
                    ),
                    const SizedBox(height: 20),

                    // 8. Confirm Password
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_rounded,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: AppSizes.iconMd,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) return 'Mật khẩu không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.s32),

                    // 9. Register Button
                    SizedBox(
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.r12),
                          ),
                        ),
                        child: Text(
                          'Đăng ký',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s32),
                    
                    const OrDivider(),
                    const SizedBox(height: AppSizes.s24),

                    // 10. Social Buttons
                    Row(
                      children: [
                        Expanded(child: GoogleSignInButton(onPressed: () {})),
                        const SizedBox(width: AppSizes.s16),
                        Expanded(child: FacebookSignInButton(onPressed: () {})),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s32),

                    // 11. Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Đăng nhập',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}