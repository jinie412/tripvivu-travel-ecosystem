import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../cubit/survey_cubit.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    final currentAge = context.read<SurveyCubit>().state.data.age;
    _ageController = TextEditingController(text: currentAge?.toString() ?? '');
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Một chút về bạn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF113D3C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Thông tin này giúp chúng tôi đưa ra các gợi ý phù hợp với độ tuổi và giới tính của bạn.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Age Section
          Text(
            'Độ tuổi của bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF113D3C),
            ),
          ),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _ageController,
            label: '',
            hintText: 'Nhập tuổi của bạn',
            prefixIcon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final age = int.tryParse(value);
              context.read<SurveyCubit>().updateAge(age ?? 0);
            },
          ),
          
          const SizedBox(height: 32),

          // Gender Section
          Text(
            'Giới tính',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF113D3C),
            ),
          ),
          const SizedBox(height: 8),
          BlocBuilder<SurveyCubit, SurveyState>(
            builder: (context, state) {
              final selectedGender = state.data.gender;
              return Row(
                children: [
                  Expanded(child: _buildGenderChip(context, 'Nam', selectedGender == 'Nam')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGenderChip(context, 'Nữ', selectedGender == 'Nữ')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<SurveyCubit>().updateGender(label),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
