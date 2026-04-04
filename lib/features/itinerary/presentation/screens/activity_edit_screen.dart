import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/utils/input_formatter.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/activity_edit_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/activity_edit_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/conflict_resolution_sheet.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/edit_activity_header.dart';

class ActivityEditScreen extends StatelessWidget {
  final ItineraryActivityEntity activity;

  const ActivityEditScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityEditCubit()..initEdit(activity),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Chi tiết địa điểm',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          actions: [
            BlocBuilder<ActivityEditCubit, ActivityEditState>(
              builder: (context, state) {
                if (state is ActivityEditInitial) {
                  return IconButton(
                    onPressed: () =>
                        context.read<ActivityEditCubit>().toggleEditMode(),
                    icon: Icon(
                      state.isEditing
                          ? Icons.close_rounded
                          : Icons.edit_outlined,
                      color: state.isEditing
                          ? AppColorsExt.error
                          : AppColors.primary,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<ActivityEditCubit, ActivityEditState>(
          listener: (context, state) {
            if (state is ActivityEditConflictDetected) {
              _showConflictResolutionSheet(context);
            }
            if (state is ActivityEditSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật thay đổi thành công!')),
              );
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            if (state is ActivityEditLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ActivityEditInitial) {
              return _buildEditForm(
                context,
                state.activity,
                state.startTime,
                state.endTime,
                state.notes,
                state.actualCost,
                state.isEditing,
              );
            }

            if (state is ActivityEditConflictDetected) {
              return _buildEditForm(
                context,
                state.activity,
                state.startTime,
                state.endTime,
                state.notes,
                state.actualCost,
                state.isEditing,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    ItineraryActivityEntity activityData,
    String startTime,
    String endTime,
    String notes,
    double actualCost,
    bool isEditing,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. Header (Status + Image + Title) - Disabled when editing
            Opacity(
              opacity: isEditing ? 0.6 : 1.0,
              child: EditActivityHeader(
                title: activityData.title,
                imageUrl: activityData.imageUrl,
              ),
            ),
            const SizedBox(height: 24),
            // 2. Thời gian thực hiện - Editable
            _buildTimeSection(context, startTime, endTime, isEditing),
            const SizedBox(height: AppSizes.s24),

            // 3. Chi phí dự kiến & Thực tế
            _buildCostSection(context, activityData, actualCost, isEditing),
            const SizedBox(height: AppSizes.s24),

            // 4. Ghi chú cá nhân - Editable
            _ActivityNotesField(initialNotes: notes, isEditing: isEditing),
            const SizedBox(height: AppSizes.s32),

            // 6. Apply Button (Only shown in edit mode)
            if (isEditing)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () =>
                      context.read<ActivityEditCubit>().applyChanges(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showConflictResolutionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConflictResolutionSheet(
        onSelect: () => context.read<ActivityEditCubit>().resolveConflict(2),
      ),
    );
  }

  Widget _buildTimeSection(
    BuildContext context,
    String startTime,
    String endTime,
    bool isEditing,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s20,
        AppSizes.s12,
        AppSizes.s20,
        AppSizes.s20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: AppColorsExt.divider.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khung thời gian',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          InkWell(
            onTap: isEditing
                ? () async {
                    final s = startTime.split(':');
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(s[0]),
                        minute: int.parse(s[1]),
                      ),
                    );
                    if (time != null) {
                      final newStart =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      context.read<ActivityEditCubit>().updateTime(
                        newStart,
                        endTime,
                      );
                    }
                  }
                : null,
            child: _buildInfoRow(
              Icons.event_note_rounded,
              'Thời gian đến',
              startTime,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: AppSizes.s32, color: AppColorsExt.divider),
          InkWell(
            onTap: isEditing
                ? () async {
                    final e = endTime.split(':');
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(e[0]),
                        minute: int.parse(e[1]),
                      ),
                    );
                    if (time != null) {
                      final newEnd =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      context.read<ActivityEditCubit>().updateTime(
                        startTime,
                        newEnd,
                      );
                    }
                  }
                : null,
            child: _buildInfoRow(
              Icons.timelapse_rounded,
              'Thời gian đi',
              endTime,
              color: AppColorsExt.profileBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSection(
    BuildContext context,
    ItineraryActivityEntity activity,
    double actualCost,
    bool isEditing,
  ) {
    final ticketPrice = activity.isFree
        ? 'Miễn phí'
        : (activity.price > 0
              ? '${activity.price.toStringAsFixed(0)} ${activity.currency}'
              : 'Miễn phí');
    final transportCost = '100.000 VNĐ';

    final formatter = NumberFormat.decimalPattern('vi');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s20,
        AppSizes.s12,
        AppSizes.s20,
        AppSizes.s20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: AppColorsExt.divider.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi phí',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.s12),

          // Chi phí dự kiến (Disabled/Dimmable)
          Opacity(
            opacity: isEditing ? 0.6 : 1.0,
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.local_activity_outlined,
                  'Giá vé tham quan',
                  ticketPrice,
                  color: AppColorsExt.success,
                ),
                const Divider(
                  height: AppSizes.s24,
                  color: AppColorsExt.divider,
                ),
                _buildInfoRow(
                  Icons.directions_car_outlined,
                  'Chi phí di chuyển',
                  transportCost,
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ),

          const Divider(
            height: AppSizes.s32,
            color: AppColorsExt.divider,
            thickness: 1.5,
          ),

          // CHI PHÍ THỰC TẾ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Text(
                  'Chi phí thực tế',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing)
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('actual_cost_field_$isEditing'),
                          initialValue: actualCost > 0
                              ? formatter.format(actualCost)
                              : '',
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          onChanged: (val) {
                            final numStr = val.replaceAll('.', '');
                            final cost = double.tryParse(numStr) ?? 0.0;
                            context.read<ActivityEditCubit>().updateActualCost(
                                  cost,
                                );
                          },
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (isEditing)
                      Text(
                        ' ${activity.currency}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      )
                    else
                      Text(
                        actualCost > 0
                            ? '${formatter.format(actualCost)} ${activity.currency}'
                            : 'Chưa nhập',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.s8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppSizes.iconSm, color: color),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}


class _ActivityNotesField extends StatelessWidget {
  final String initialNotes;
  final bool isEditing;
  const _ActivityNotesField({
    required this.initialNotes,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s20,
        AppSizes.s12,
        AppSizes.s20,
        AppSizes.s20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: AppColorsExt.divider.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú cá nhân',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          TextFormField(
            maxLines: 4,
            key: ValueKey(
              '${initialNotes}_$isEditing',
            ), // Rebuild when mode changes
            initialValue: initialNotes,
            enabled: isEditing,
            onChanged: (val) =>
                context.read<ActivityEditCubit>().updateNotes(val),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: isEditing
                  ? 'Thêm ghi chú của bạn...'
                  : 'Không có ghi chú',
              hintStyle: const TextStyle(color: AppColorsExt.textHint),
              contentPadding: EdgeInsets.zero,
            ),
            style: AppTextStyles.body.copyWith(
              height: 1.5,
              color: isEditing
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}