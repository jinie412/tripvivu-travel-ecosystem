import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/survey/presentation/cubit/survey_cubit.dart';

class InterestsStep extends StatelessWidget {
  const InterestsStep({super.key});

  final List<Map<String, String>> _interests = const [
    {'label': 'Biển', 'icon': '🌴'},
    {'label': 'Núi', 'icon': '🏔️'},
    {'label': 'Thành phố', 'icon': '🏙️'},
    {'label': 'Văn hóa', 'icon': '🏛️'},
    {'label': 'Ẩm thực', 'icon': '🥣'},
    {'label': 'Mua sắm', 'icon': '🛍️'},
    {'label': 'Nghỉ dưỡng', 'icon': '💆'},
    {'label': 'Thể thao mạo hiểm', 'icon': '🧗'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sở thích của bạn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF113D3C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chọn những loại hình du lịch mà bạn yêu thích nhất để chúng tôi chuẩn bị gợi ý.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          BlocBuilder<SurveyCubit, SurveyState>(
            builder: (context, state) {
              final selectedInterests = state.data.interests;
              
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: _interests.map((interest) {
                  final label = interest['label']!;
                  final icon = interest['icon']!;
                  final isSelected = selectedInterests.contains(label);
                  
                  return _buildInterestChip(
                    context: context,
                    label: label,
                    icon: icon,
                    isSelected: isSelected,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip({
    required BuildContext context,
    required String label,
    required String icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => context.read<SurveyCubit>().toggleInterest(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F7F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF14DFBC) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF14DFBC).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF113D3C) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}