import 'package:flutter/material.dart';

import 'reset_password_screen.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/widgets/auth_shared_widgets.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String destination; // Email or Phone

  const VerifyOTPScreen({super.key, required this.destination});

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handleVerify();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handleVerify() {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6) {
      // Simulate success
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
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
                          Icons.mark_email_read_rounded,
                          size: AppSizes.s48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s32),

                  // 2. Title Section
                  Text(
                    'Xác minh mã',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Text(
                    'Mã xác minh đã được gửi đến\n${widget.destination}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.s48),

                  // 3. OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: AppSizes.s48,
                        height: AppSizes.appBarHeight,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.inputFill,
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.r12),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          onChanged: (value) => _onOTPChanged(value, index),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSizes.s48),

                  // 4. Verify Button
                  SizedBox(
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.r12),
                        ),
                      ),
                      child: Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s32),

                  // 5. Resend Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Không nhận được mã? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Resend logic
                        },
                        child: Text(
                          'Gửi lại mã',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s48),

                  // 6. Footer (Back)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: AppSizes.iconMd, color: AppColors.primary),
                    label: Text(
                      'Quay lại',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}