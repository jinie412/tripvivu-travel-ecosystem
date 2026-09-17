import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

/// Thẻ 1 vùng tham quan trong màn phân bổ ngày. Sở hữu state expand/collapse
/// của riêng nó và lắng nghe [daysNotifier] bằng ValueListenableBuilder, nên
/// khi người dùng bấm +/- chỉ THẺ NÀY rebuild — các thẻ vùng khác trong
/// ListView.builder không bị kéo theo (khác với bản cũ dùng setState ở
/// State cha, rebuild lại toàn bộ danh sách mỗi lần bấm stepper).
class RegionAllocationCard extends StatefulWidget {
  final RegionInfo region;
  final ValueNotifier<int> daysNotifier;

  const RegionAllocationCard({
    super.key,
    required this.region,
    required this.daysNotifier,
  });

  @override
  State<RegionAllocationCard> createState() => _RegionAllocationCardState();
}

class _RegionAllocationCardState extends State<RegionAllocationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final region = widget.region;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.premiumSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.premiumBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(region),
          const SizedBox(height: 4),
          Text(
            '${region.placeIds.length} địa điểm • Gợi ý: 1 - ${region.maxDays} ngày',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildStepperRow(region),
          const SizedBox(height: 8),
          _buildExpandToggle(region),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
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
                      .toList(growable: false),
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RegionInfo region) {
    // Tên vùng giờ nội suy từ district_old, có thể dài (vd "Khu vực: Thành
    // phố Thủ Đức, Quận 1, Quận 2") — trước đây ép chung 1 hàng với badge
    // "Ở xa" + maxLines:1 nên bị ellipsis cắt mất phần lớn. Xếp theo cột,
    // tên được wrap tối đa 2 dòng, badge xuống hàng riêng bên dưới.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          region.regionName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        if (region.isRemote) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_filled_rounded,
                    size: 12, color: Color(0xFFB45309)),
                SizedBox(width: 3),
                Text(
                  'Ở xa',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepperRow(RegionInfo region) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Số ngày phân bổ (Tối đa: ${region.maxDays} ngày)',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'Địa điểm này có thể đi nhiều nhất trong ${region.maxDays} '
                    'ngày. Dựa trên thời gian tham quan + di chuyển, không chỉ '
                    'theo số lượng địa điểm.',
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.premiumMuted,
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: widget.daysNotifier,
          builder: (context, days, _) => _buildStepper(region, days),
        ),
      ],
    );
  }

  Widget _buildStepper(RegionInfo region, int days) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove,
          enabled: days > 0,
          onTap: () => widget.daysNotifier.value = days - 1,
        ),
        SizedBox(
          width: 30,
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
          onTap: () => widget.daysNotifier.value = days + 1,
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }

  Widget _buildExpandToggle(RegionInfo region) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _expanded ? 'Ẩn danh sách địa điểm' : 'Xem ${region.placeIds.length} địa điểm',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
