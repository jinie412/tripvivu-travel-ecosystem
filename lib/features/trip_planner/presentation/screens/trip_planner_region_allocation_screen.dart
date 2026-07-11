import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';

/// Wizard phân bổ vùng: sau khi backend phân cụm địa lý xong, người dùng
/// xem trước từng vùng (kèm vài địa điểm mẫu) và tự chọn số ngày muốn dành
/// cho vùng đó bằng stepper (-0+), giới hạn 0..maxDays. Nút "Tạo lịch trình"
/// chỉ bật khi tổng số ngày đã phân bổ khớp đúng tổng số ngày chuyến đi.
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
  late final Map<RegionInfo, int> _days;

  @override
  void initState() {
    super.initState();
    // Backend đã tự tính sẵn phân bổ gợi ý (vùng trung tâm trước, mượn từ
    // vùng kế tiếp gần nhất nếu thiếu — xem geo_clustering.py:detect_regions)
    // nên điền sẵn TOÀN BỘ vùng, không chỉ vùng trung tâm như trước. Người
    // dùng chỉ cần bấm "Tạo lịch trình" ngay; ai muốn chỉnh tay mới cần đụng
    // tới stepper.
    _days = {
      for (final r in widget.regions) r: r.suggestedDays.clamp(0, widget.numDays),
    };
  }

  int get _totalAllocated => _days.values.fold(0, (a, b) => a + b);

  bool get _canSubmit => _totalAllocated == widget.numDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Phân bổ vùng tham quan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (_remoteRegionWarning() != null) ...[
                  _buildWarningBanner(_remoteRegionWarning()!),
                  const SizedBox(height: 16),
                ],
                ...widget.regions.map(_buildRegionCard),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRegionCard(RegionInfo region) {
    final days = _days[region] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                region.regionName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (region.isRemote)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ở xa',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('${region.placeIds.length} địa điểm'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            // Đã bỏ giới hạn 6 chip đầu tiên (thứ tự trước đây tuỳ thuộc thứ
            // tự cụm HDBSCAN, có cảm giác "hỏng"/random) — backend giờ trả
            // place_names đã sort alphabet, hiển thị đủ toàn bộ.
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: region.placeNames
                  .map(
                    (name) => Chip(
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Địa điểm này có thể đi nhiều nhất trong ${region.maxDays} ngày',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Dựa trên thời gian tham quan + di chuyển, không chỉ theo số lượng địa điểm',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số ngày dành cho vùng này',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              _buildStepper(region, days),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(RegionInfo region, int days) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove,
          enabled: days > 0,
          onTap: () => _updateDays(region, days - 1),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$days',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add,
          enabled: days < region.maxDays,
          onTap: () => _updateDays(region, days + 1),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  void _updateDays(RegionInfo region, int newDays) {
    setState(() => _days[region] = newDays);
  }

  /// Cảnh báo hợp nhất — hiển thị như 1 banner tĩnh phản ánh trạng thái hiện
  /// tại, KHÔNG phải dialog chặn thao tác từng lần tăng/giảm stepper (trước
  /// đây mỗi lần bấm "+" ở vùng xa lại hiện 1 AlertDialog riêng, rất phiền
  /// khi người dùng tăng dần từng ngày một).
  String? _remoteRegionWarning() {
    final selectedRemote = widget.regions
        .where((r) => r.isRemote && (_days[r] ?? 0) > 0)
        .toList();
    if (selectedRemote.isEmpty) return null;

    if (selectedRemote.length == 1) {
      final region = selectedRemote.first;
      if ((_days[region] ?? 0) <= 1) return null;
      final roundTripHours =
          (region.travelMinutesFromCentral * 2 / 60).toStringAsFixed(1);
      return '${region.regionName} cách khu vực trung tâm khá xa. Hệ thống chỉ '
          'hỗ trợ 1 khách sạn duy nhất, nên với ${_days[region]} ngày ở đây, '
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (context) {
                final delta = _totalAllocated - widget.numDays;
                final label = delta == 0
                    ? 'Đã phân bổ đủ ${widget.numDays} ngày'
                    : delta < 0
                    ? 'Còn thiếu ${-delta} ngày (đã chọn $_totalAllocated/${widget.numDays})'
                    : 'Đang vượt $delta ngày (đã chọn $_totalAllocated/${widget.numDays})';
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: delta == 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _canSubmit
                ? () => context.read<TripPlannerCubit>().submitRegionAllocations(
                      widget.regions
                          .where((r) => (_days[r] ?? 0) > 0)
                          .map(
                            (r) => RegionAllocationInput(
                              placeIds: r.placeIds,
                              days: _days[r] ?? 0,
                            ),
                          )
                          .toList(),
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
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
