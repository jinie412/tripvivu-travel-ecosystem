import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/region_allocation_card.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/region_allocation_map_view.dart';

/// Wizard phân bổ vùng: sau khi backend phân cụm địa lý xong, người dùng
/// xem trước từng vùng (kèm vài địa điểm mẫu) và tự chọn số ngày muốn dành
/// cho vùng đó bằng stepper (-0+), giới hạn 0..maxDays. Nút "Tạo lịch trình"
/// chỉ bật khi tổng số ngày đã phân bổ khớp đúng tổng số ngày chuyến đi.
///
/// Mỗi vùng có 1 `ValueNotifier<int>` riêng (thay vì 1 `Map<RegionInfo,int>`
/// dùng setState ở State cha) để bấm +/- ở 1 thẻ chỉ rebuild đúng thẻ đó —
/// không kéo theo rebuild toàn bộ ListView + tất cả chip của mọi vùng khác.
class TripPlannerRegionAllocationScreen extends StatefulWidget {
  final String message;
  final List<RegionInfo> regions;
  final int numDays;

  const TripPlannerRegionAllocationScreen({
    super.key,
    required this.message,
    required this.regions,
    required this.numDays,
  });

  @override
  State<TripPlannerRegionAllocationScreen> createState() =>
      _TripPlannerRegionAllocationScreenState();
}

class _TripPlannerRegionAllocationScreenState
    extends State<TripPlannerRegionAllocationScreen> {
  late final List<ValueNotifier<int>> _dayNotifiers;
  late final Listenable _totalListenable;

  @override
  void initState() {
    super.initState();
    // Backend đã tự tính sẵn phân bổ gợi ý (vùng trung tâm trước, mượn từ
    // vùng kế tiếp gần nhất nếu thiếu — xem geo_clustering.py:detect_regions)
    // nên điền sẵn TOÀN BỘ vùng, không chỉ vùng trung tâm như trước. Người
    // dùng chỉ cần bấm "Tạo lịch trình" ngay; ai muốn chỉnh tay mới cần đụng
    // tới stepper.
    _dayNotifiers = [
      for (final r in widget.regions)
        ValueNotifier<int>(r.suggestedDays.clamp(0, widget.numDays)),
    ];
    _totalListenable = Listenable.merge(_dayNotifiers);
  }

  @override
  void dispose() {
    for (final n in _dayNotifiers) {
      n.dispose();
    }
    super.dispose();
  }

  int get _totalAllocated =>
      _dayNotifiers.fold(0, (sum, n) => sum + n.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.premiumBackground,
        elevation: 0,
        title: const Text(
          'Tùy chỉnh khu vực tham quan',
          style: TextStyle(
            color: AppColors.premiumNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Bản đồ nhúng cố định phía trên, KHÔNG toggle full-screen list/map
          // nữa — trước đây bấm map rồi quay lại list làm dispose/recreate
          // native MapWidget giữa chừng lúc annotation manager còn đang vẽ
          // dở (await), gây lỗi bất đồng bộ hiện ra ngay bước kế tiếp. Nhúng
          // cố định 1 khung nhỏ ở đây thì map chỉ mount 1 lần, sống suốt màn
          // hình — hết nguồn lỗi đó. Bấm nút mở rộng để xem to/rõ hơn.
          if (widget.regions.any((r) => r.hasCentroid)) _buildMapPreview(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              // +1 cho phần header (thông báo + banner cảnh báo động)
              itemCount: widget.regions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHeaderSection(),
                  );
                }
                final region = widget.regions[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RegionAllocationCard(
                    key: ValueKey(region.regionName),
                    region: region,
                    daysNotifier: _dayNotifiers[index - 1],
                  ),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: _totalListenable,
            builder: (context, _) => _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RegionAllocationMapView(
                regions: widget.regions,
                onRegionTap: _openRegionSheet,
              ),
              // Khung nhỏ để pinch-zoom chật tay — nút này mở bản đồ to hơn
              // hẳn 1 màn hình riêng để xem chi tiết thoải mái.
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _openFullscreenMap,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.fullscreen_rounded,
                        size: 20,
                        color: AppColors.premiumNavy,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullscreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.premiumBackground,
            elevation: 0,
            title: const Text(
              'Bản đồ các vùng',
              style: TextStyle(
                color: AppColors.premiumNavy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: RegionAllocationMapView(
            regions: widget.regions,
            onRegionTap: _openRegionSheet,
          ),
        ),
      ),
    );
  }

  /// Bấm pin/vùng trên Map View mở thẻ chi tiết + stepper của đúng vùng đó
  /// trong 1 bottom sheet — tái dùng nguyên `RegionAllocationCard` thay vì
  /// vẽ lại UI stepper một lần nữa trên bản đồ.
  void _openRegionSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: RegionAllocationCard(
          region: widget.regions[index],
          daysNotifier: _dayNotifiers[index],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.premiumSoftBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.route_rounded,
                size: 18,
                color: AppColors.premiumBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.premiumNavy,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _totalListenable,
          builder: (context, _) {
            final warning = _remoteRegionWarning();
            if (warning == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildWarningBanner(warning),
            );
          },
        ),
      ],
    );
  }

  /// Cảnh báo hợp nhất — hiển thị như 1 banner tĩnh phản ánh trạng thái hiện
  /// tại, KHÔNG phải dialog chặn thao tác từng lần tăng/giảm stepper (trước
  /// đây mỗi lần bấm "+" ở vùng xa lại hiện 1 AlertDialog riêng, rất phiền
  /// khi người dùng tăng dần từng ngày một).
  String? _remoteRegionWarning() {
    final selectedRemote = <RegionInfo>[];
    for (var i = 0; i < widget.regions.length; i++) {
      if (widget.regions[i].isRemote && _dayNotifiers[i].value > 0) {
        selectedRemote.add(widget.regions[i]);
      }
    }
    if (selectedRemote.isEmpty) return null;

    if (selectedRemote.length == 1) {
      final region = selectedRemote.first;
      final index = widget.regions.indexOf(region);
      final days = _dayNotifiers[index].value;
      if (days <= 1) return null;
      final roundTripHours = (region.travelMinutesFromCentral * 2 / 60)
          .toStringAsFixed(1);
      return '${region.regionName} cách khu vực trung tâm khá xa. Hệ thống chỉ '
          'hỗ trợ 1 khách sạn duy nhất, nên với $days ngày ở đây, '
          'mỗi ngày bạn sẽ phải di chuyển khứ hồi khoảng $roundTripHours giờ.';
    }

    final names = selectedRemote.map((r) => r.regionName).join(', ');
    return 'Bạn đang chọn nhiều vùng ở xa nhau ($names) — vì hệ thống chỉ hỗ '
        'trợ 1 khách sạn duy nhất, việc di chuyển giữa khách sạn và các vùng '
        'này có thể khá bất tiện.';
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _totalAllocated;
    final delta = total - widget.numDays;
    final canSubmit = delta == 0;
    final progress = widget.numDays == 0
        ? 0.0
        : (total / widget.numDays).clamp(0.0, 1.0);

    late final String label;
    late final Color statusColor;
    if (delta == 0) {
      label = 'Đã phân bổ đủ ${widget.numDays} ngày';
      statusColor = const Color(0xFF16A34A); // xanh lá — đủ
    } else if (delta > 0) {
      label = 'Đang vượt $delta ngày (đã chọn $total/${widget.numDays})';
      statusColor = const Color(0xFFDC2626); // đỏ — vượt
    } else {
      label = 'Đã phân bổ: $total/${widget.numDays} ngày';
      statusColor = AppColors.premiumMuted; // trung tính — chưa đủ
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                delta > 0 ? statusColor : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: canSubmit
                ? () =>
                      context.read<TripPlannerCubit>().submitRegionAllocations(
                        [
                          for (var i = 0; i < widget.regions.length; i++)
                            if (_dayNotifiers[i].value > 0)
                              RegionAllocationInput(
                                placeIds: widget.regions[i].placeIds,
                                days: _dayNotifiers[i].value,
                              ),
                        ],
                      )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: canSubmit ? 4 : 0,
              shadowColor: AppColors.primary.withValues(alpha: .35),
            ),
            child: const Text(
              'Tạo lịch trình',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
