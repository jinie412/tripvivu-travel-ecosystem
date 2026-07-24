import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_state.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/screens/trip_planner_region_allocation_screen.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/budget_slider_section.dart';
import 'package:travel_advisor_mobile/core/navigation/main_shell.dart';
import '../widgets/step_progress_bar.dart';

// ════════════════════════════════════════════════════════════════
// [TRIP_NAME_INPUT] Đổi sang StatefulWidget để quản lý TextEditingController
// cho phần nhập tên chuyến đi được thêm vào Bước 3.
// ════════════════════════════════════════════════════════════════
class TripPlannerStep3Screen extends StatefulWidget {
  const TripPlannerStep3Screen({super.key});

  @override
  State<TripPlannerStep3Screen> createState() => _TripPlannerStep3ScreenState();
}

class _TripPlannerStep3ScreenState extends State<TripPlannerStep3Screen> {
  // [TRIP_NAME_INPUT] Controller cho TextField tên chuyến đi
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // [TRIP_NAME_INPUT] Lấy tên hiện tại hoặc tự sinh từ điểm đến + ngày
    final generatedName = context
        .read<TripPlannerCubit>()
        .resolveOrGenerateTripName();
    _nameController = TextEditingController(text: generatedName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripPlannerCubit, TripPlannerState>(
      listener: (context, state) {
        state.whenOrNull(
          generating: () => _showLoadingDialog(context),
          success: (itineraryId) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            MainShellTabController.refreshItineraries();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) {
                        final cubit = sl<ItineraryCubit>();
                        cubit.loadData().then(
                          (_) => cubit.selectItinerary(itineraryId),
                        );
                        return cubit;
                      },
                    ),
                    BlocProvider(create: (_) => sl<TrackingCubit>()),
                  ],
                  child: ItinerarySummaryScreen(itineraryId: itineraryId),
                ),
              ),
              (route) => route.isFirst,
            );
          },
          error: (msg) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: $msg'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          budgetConfirmationRequired:
              (
                message,
                userBudget,
                calculatedCost,
                recommendedBudget,
                participantCount,
                confirmToken,
              ) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                _showBudgetConfirmationDialog(
                  context,
                  message: message,
                  recommendedBudget: recommendedBudget,
                );
              },
          budgetTooLow: (message, minimumBudget) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            _showBudgetTooLowDialog(
              context,
              message: message,
              minimumBudget: minimumBudget,
            );
          },
          infeasible: (message, suggestions) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            _showInfeasibleDialog(
              context,
              message: message,
              suggestions: suggestions,
            );
          },
          regionAllocationRequired:
              (message, regions, numDays, estimatedTotalDays) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<TripPlannerCubit>(),
                      child: TripPlannerRegionAllocationScreen(
                        message: message,
                        regions: regions,
                        numDays: numDays,
                      ),
                    ),
                  ),
                );
              },
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.premiumBackground,
          appBar: AppBar(
            backgroundColor: AppColors.premiumSurface,
            elevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.premiumSoftBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    context.read<TripPlannerCubit>().goPrevStep();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            title: Column(
              children: [
                const Text(
                  'Tạo lịch trình mới',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'BƯỚC 3/3',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: state.maybeWhen(
            loaded: (tripForm) => Column(
              children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: StepProgressBar(
                    currentStep: tripForm.currentStep,
                    totalSteps: 3,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ════════════════════════════════════════
                        // [TRIP_NAME_INPUT] Phần nhập tên chuyến đi
                        // ════════════════════════════════════════
                        const Text(
                          'Tên chuyến đi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đặt tên để dễ nhận ra chuyến đi của bạn.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          onChanged: (v) => context
                              .read<TripPlannerCubit>()
                              .updateTripName(v),
                          decoration: InputDecoration(
                            hintText: 'Nhập tên chuyến đi...',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLength: 100,
                          buildCounter:
                              (
                                _, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bạn có thể đổi tên sau khi tạo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        // ════════════════════════════════════════
                        const SizedBox(height: 36),
                        // Phần ngân sách (giữ nguyên như cũ)
                        const Text(
                          'Ngân sách chuyến đi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nhập số tiền có thể chi trả cho mỗi người lớn.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BudgetSliderSection(
                          currentBudget: tripForm.budget,
                          onChanged: (v) =>
                              context.read<TripPlannerCubit>().updateBudget(v),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.background,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.read<TripPlannerCubit>().submitTripPlan(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hoàn thành',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Tạo lịch trình...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Vui lòng chờ trong giây lát',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chỉ còn 1 lựa chọn: dùng mức đề xuất. Trước đây có thêm nút "Tiếp tục
  // với ngân sách hiện tại" — bỏ vì mức đề xuất chỉ tính được SAU KHI đã
  // chạy 1 lượt lập lịch trình đầy đủ (không phải ước tính trước), nên
  // không có cách nào cho người dùng tự nhập 1 ngân sách "chắc chắn đủ"
  // ngay từ đầu — cho phép "cứ tiếp tục" ở đây đồng nghĩa cố tình tạo ra
  // lịch trình mà chính hệ thống vừa xác nhận là vượt ngân sách họ khai.
  void _showBudgetConfirmationDialog(
    BuildContext context, {
    required String message,
    required double recommendedBudget,
  }) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final cubit = context.read<TripPlannerCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chưa tạo được lịch trình'),
        content: Text(
          '$message Bạn có muốn thử lịch trình với mức chi phí '
          '${formatter.format(recommendedBudget)}đ này không?',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.retryWithRecommendedBudget();
            },
            child: const Text('Dùng lịch trình gợi ý'),
          ),
        ],
      ),
    );
  }

  // Backend chặn TRƯỚC KHI chạy thuật toán vì ngân sách rõ ràng quá thấp
  // (dưới cả mức sàn tối thiểu) — không có plan nào để gợi ý, chỉ có thể
  // hướng dẫn tăng ngân sách rồi thử lại.
  void _showBudgetTooLowDialog(
    BuildContext context, {
    required String message,
    required double minimumBudget,
  }) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final cubit = context.read<TripPlannerCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ngân sách quá thấp'),
        content: Text(
          '$message\n\nNgân sách tối thiểu: ${formatter.format(minimumBudget)} VNĐ.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.dismissBudgetTooLow();
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  // Không tìm được BẤT KỲ lịch trình nào thỏa ngân sách/thời gian/giờ mở
  // cửa — khác dialog ngân sách ở trên (đó là "tìm được nhưng đắt hơn"),
  // đây không có gì để tự động retry, chỉ có thể hướng dẫn người dùng tự
  // điều chỉnh form theo suggestions rồi thử lại.
  void _showInfeasibleDialog(
    BuildContext context, {
    required String message,
    required List<String> suggestions,
  }) {
    final cubit = context.read<TripPlannerCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Không tạo được lịch trình'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Bạn có thể thử:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(s)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.dismissInfeasible();
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
