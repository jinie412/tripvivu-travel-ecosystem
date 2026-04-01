import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/survey/presentation/cubit/survey_cubit.dart';
import 'package:travel_advisor_mobile/features/survey/presentation/widgets/basic_info_step.dart';
import 'package:travel_advisor_mobile/features/survey/presentation/widgets/interests_step.dart';
import 'package:travel_advisor_mobile/features/survey/presentation/widgets/survey_background.dart';
import 'package:travel_advisor_mobile/features/survey/presentation/widgets/welcome_step.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(BuildContext context, int currentStep) {
    final cubit = context.read<SurveyCubit>();
    if (!cubit.checkCurrentStepValid()) {
      String message = 'Vui lòng điền đầy đủ thông tin';
      if (currentStep == 1) {
        message = 'Vui lòng nhập tuổi hợp lệ và chọn giới tính';
      } else if (currentStep == 2) {
        message = 'Vui lòng chọn ít nhất 1 sở thích';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (currentStep < 2) {
      cubit.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      cubit.submitSurvey();
    }
  }

  void _onSkip(BuildContext context) {
    // Navigate to Home or handle skip logic
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SurveyCubit(),
      child: BlocConsumer<SurveyCubit, SurveyState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (_, __) {
              Navigator.of(context).pushReplacementNamed('/home');
            },
            error: (_, __, message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final currentStep = state.currentStep;

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                const SurveyBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar: Back, Progress, Skip
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // Back Button (only from step 1)
                            SizedBox(
                              width: 48,
                              child: currentStep > 0
                                  ? IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                      onPressed: () {
                                        context.read<SurveyCubit>().prevStep();
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            
                            // Horizontal Progress Bar
                            Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedFractionallySizedBox(
                                      duration: const Duration(milliseconds: 400),
                                      widthFactor: (currentStep + 1) / 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Skip Button
                            TextButton(
                              onPressed: () => _onSkip(context),
                              child: Text(
                                'Bỏ qua',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content: PageView
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            WelcomeStep(),
                            BasicInfoStep(),
                            InterestsStep(),
                          ],
                        ),
                      ),

                      // Bottom Bar: Action Button
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: state.maybeWhen(
                              loading: (_, __) => null,
                              orElse: () => () => _onNext(context, currentStep),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: state.maybeMap(
                              loading: (_) => const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              orElse: () => Text(
                                currentStep == 2 ? 'Bắt đầu ngay' : 'Tiếp tục',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}