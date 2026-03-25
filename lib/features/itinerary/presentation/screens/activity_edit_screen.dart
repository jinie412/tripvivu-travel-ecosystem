import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/itinerary_activity_entity.dart';
import '../cubit/activity_edit_cubit.dart';
import '../cubit/activity_edit_state.dart';
import '../widgets/edit_activity_header.dart';
import '../widgets/activity_quick_info.dart';
import '../widgets/visiting_time_slider.dart';
import '../widgets/replace_location_section.dart';
import '../widgets/conflict_resolution_sheet.dart';
import '../../../../core/theme/app_colors.dart';

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
          title: const Text(
            'Chi tiết địa điểm',
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          ),
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
              );
            }

            if (state is ActivityEditConflictDetected) {
              return _buildEditForm(
                context,
                state.activity,
                state.startTime,
                state.endTime,
                state.notes,
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
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. Header (Status + Image + Title)
            EditActivityHeader(
              title: activityData.title,
              imageUrl: activityData.imageUrl,
            ),
            const SizedBox(height: 24),

            // 2. Visiting Time Slider
            VisitingTimeSlider(
              start: startTime,
              end: endTime,
              onChanged: (s, e) => context.read<ActivityEditCubit>().updateTime(s, e),
            ),
            const SizedBox(height: 32),

            // 3. Quick Info Box (Opening, Price, Rating)
            const ActivityQuickInfo(
              opening: '07:00 - 19:00',
              price: 'Miễn phí',
              rating: 4.5,
              reviews: 2300,
            ),
            const SizedBox(height: 32),

            // 4. Personal Notes Field
            _ActivityNotesField(initialNotes: notes),
            const SizedBox(height: 32),

            // 5. Replace Location Section
            const ReplaceLocationSection(),
            const SizedBox(height: 48),

            // 6. Apply Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.read<ActivityEditCubit>().applyChanges(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Áp dụng thay đổi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
}

class _ActivityNotesField extends StatelessWidget {
  final String initialNotes;
  const _ActivityNotesField({required this.initialNotes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_outlined, size: 22, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Ghi chú cá nhân',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                maxLines: 4,
                key: ValueKey(initialNotes), // Ensure updates if notes changed
                initialValue: initialNotes,
                onChanged: (val) => context.read<ActivityEditCubit>().updateNotes(val),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Thêm ghi chú của bạn...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đã lưu tự động',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

