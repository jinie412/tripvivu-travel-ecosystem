import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/constants/cost_ui_labels.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/incurred_cost_sheet.dart';

/// Màn "Quản lý chi phí" tổng hợp (mục 1.9) — danh sách toàn bộ chi phí phát
/// sinh của lịch trình + bảng "mỗi người phải trả tổng bao nhiêu" (mục 1.7).
class IncurredCostsScreen extends StatefulWidget {
  final String itineraryId;
  final List<ItineraryMemberEntity> members;
  final bool isCompleted;
  // Mở màn này đã lọc sẵn theo 1 địa điểm (từ badge "chi phí phát sinh" ở
  // Chi tiết lịch trình) — người dùng vẫn bấm "Xem tất cả" để bỏ lọc được.
  final String? initialPlaceId;
  final String? initialPlaceName;
  // Mở màn này đã xem sẵn "chi tiết ngày N" (từ icon sổ ở "Tổng quan ngày")
  // — mỗi người phải trả bao nhiêu CHỈ TÍNH CHO NGÀY NÀY, khác Card 3 tính
  // cho cả chuyến. Không dùng cùng lúc với initialPlaceId.
  final int? initialDayNumber;
  // Dùng để gom "Chi phí đã chi" theo ngày (mỗi khoản chi gắn 1 địa điểm →
  // suy ra ngày qua địa điểm đó nằm ở ngày nào trong lịch trình). Rỗng =
  // không gom, hiển thị danh sách phẳng như cũ.
  final List<ItineraryDayEntity> days;

  const IncurredCostsScreen({
    super.key,
    required this.itineraryId,
    required this.members,
    this.isCompleted = false,
    this.initialPlaceId,
    this.initialPlaceName,
    this.initialDayNumber,
    this.days = const [],
  });

  @override
  State<IncurredCostsScreen> createState() => _IncurredCostsScreenState();
}

class _IncurredCostsScreenState extends State<IncurredCostsScreen> {
  final _repository = sl<ItineraryRepository>();
  final _formatter = NumberFormat('#,###', 'vi_VN');

  bool _isLoading = true;
  String? _error;
  List<IncurredCostEntity> _costs = const [];
  CostBreakdownEntity? _breakdown;
  DayCostBreakdownEntity? _dayBreakdown;
  String? _currentUserId;
  bool _isOwner = false;
  // Bảng "mỗi người phải trả"/"chi phí ước tính" luôn tính cho CẢ lịch
  // trình (không lọc theo địa điểm) — chỉ "Danh sách chi phí phát sinh" bị
  // lọc, nên bộ lọc là state riêng, không đụng tới _breakdown.
  late String? _placeFilterId = widget.initialPlaceId;
  late String? _placeFilterName = widget.initialPlaceName;
  late int? _dayFilterNumber = widget.initialDayNumber;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await AuthUtils.requireCurrentUserId();
      final results = await Future.wait([
        _repository.getIncurredCosts(
          widget.itineraryId,
          placeId: _placeFilterId,
          dayNumber: _dayFilterNumber,
        ),
        _repository.getCostBreakdown(widget.itineraryId),
        if (_dayFilterNumber != null)
          _repository.getDayCostBreakdown(
            widget.itineraryId,
            _dayFilterNumber!,
          ),
      ]);
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _isOwner = widget.members.any((m) => m.id == userId && m.isOwner);
        _costs = results[0] as List<IncurredCostEntity>;
        _breakdown = results[1] as CostBreakdownEntity;
        _dayBreakdown = _dayFilterNumber != null
            ? results[2] as DayCostBreakdownEntity
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // price_adjustment: chỉ chủ lịch trình được sửa/xoá (không có ngoại lệ
  // creator vì chỉ owner mới tạo được type này). Các type khác: chỉ đúng
  // người tạo, kể cả chủ lịch trình cũng không được sửa khoản của người khác
  // — khớp assertCanModify() ở backend.
  bool _canModify(IncurredCostEntity cost) {
    if (widget.isCompleted) return false;
    // "Chi phí kế hoạch" do hệ thống tự ghi khi check-in — không ai sửa/xoá
    // tay được, kể cả chủ lịch trình. Sửa giá đi qua "Sửa giá" riêng.
    if (cost.type == CostType.baselinePlan) return false;
    // "Điều chỉnh giá": không tạo mới được nữa, chỉ còn là dữ liệu lịch sử —
    // vẫn cho ĐÍNH CHÍNH nếu nhập sai lúc trước, theo đúng quy tắc như các
    // chi phí ad-hoc khác (chỉ người TẠO mới sửa/xoá). Mọi dòng loại này từ
    // trước đều do owner tạo (chỉ owner mới tạo được type này) nên vẫn chỉ
    // owner sửa được trên thực tế — chỉ đổi thành "người tạo" cho dễ hiểu.
    if (cost.type == CostType.transportAdjustment) {
      return _isOwner;
    }
    return cost.createdBy == _currentUserId;
  }

  String _memberName(String userId) {
    final match = widget.members.where((m) => m.id == userId);
    if (match.isEmpty) return 'Thành viên';
    final name = match.first.fullName;
    return name.isNotEmpty ? name : 'Thành viên';
  }

  // Chỉ gom theo ngày khi có đủ dữ liệu ngày VÀ đang xem toàn bộ (không lọc
  // theo 1 địa điểm/1 ngày cụ thể — lúc đó chỉ có tối đa 1 ngày, gom vào sẽ
  // thừa 1 header).
  bool get _shouldGroupByDay =>
      _placeFilterId == null &&
      _dayFilterNumber == null &&
      widget.days.length > 1;

  /// place_id -> "Ngày N" (suy ra ngày qua địa điểm nằm ở ngày nào trong
  /// lịch trình — incurred_costs không lưu ngày trực tiếp).
  Map<String, int> _dayNumberByPlaceId() {
    final map = <String, int>{};
    for (final day in widget.days) {
      for (final activity in day.activities) {
        final placeId = activity.placeId;
        if (placeId != null) map[placeId] = day.dayNumber;
      }
    }
    return map;
  }

  /// Nhóm [_costs] theo ngày, sắp theo dayNumber tăng dần. Ngày suy ra từ
  /// place_id trước (qua địa điểm nằm ở ngày nào), rồi mới tới field
  /// dayNumber lưu thẳng trên chính khoản chi (ad-hoc gắn ngày, không gắn địa
  /// điểm cụ thể — trước đây bị bỏ qua field này, luôn rơi vào "Không gắn địa
  /// điểm" dù đã chọn ngày). Chỉ khoản KHÔNG có cả 2 mới dồn vào nhóm cuối
  /// (vd "Điều chỉnh xăng xe" — áp dụng cả chuyến, không thuộc ngày nào).
  List<({String label, List<IncurredCostEntity> items})> _groupedCosts() {
    final dayNumberByPlaceId = _dayNumberByPlaceId();
    final byDay = <int, List<IncurredCostEntity>>{};
    final unassigned = <IncurredCostEntity>[];
    for (final cost in _costs) {
      final dayNumber = cost.placeId != null
          ? dayNumberByPlaceId[cost.placeId]
          : cost.dayNumber;
      if (dayNumber != null) {
        byDay.putIfAbsent(dayNumber, () => []).add(cost);
      } else {
        unassigned.add(cost);
      }
    }
    final sortedDays = byDay.keys.toList()..sort();
    return [
      for (final dayNumber in sortedDays)
        (label: 'Ngày $dayNumber', items: byDay[dayNumber]!),
      if (unassigned.isNotEmpty)
        (label: 'Không gắn ngày/địa điểm cụ thể', items: unassigned),
    ];
  }

  void _clearPlaceFilter() {
    setState(() {
      _placeFilterId = null;
      _placeFilterName = null;
    });
    _load();
  }

  void _clearDayFilter() {
    setState(() {
      _dayFilterNumber = null;
      _dayBreakdown = null;
    });
    _load();
  }

  Future<void> _openSheet({IncurredCostEntity? editing}) async {
    await IncurredCostSheet.show(
      context,
      itineraryId: widget.itineraryId,
      members: widget.members,
      isOwner: _isOwner,
      days: widget.days,
      editingCost: editing,
      onSaved: _load,
      adultCount: _breakdown?.adultCount ?? 1,
      childCount: _breakdown?.childCount ?? 0,
    );
  }

  Future<void> _delete(IncurredCostEntity cost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá khoản chi phí?'),
        content: Text(
          'Xoá "${cost.note}" (${_formatter.format(cost.amount)}đ)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteIncurredCost(widget.itineraryId, cost.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      appBar: AppBar(
        title: const Text(
          CostUiLabels.managementTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.premiumNavy,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.premiumBackground,
        foregroundColor: AppColors.premiumNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: widget.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openSheet(),
              backgroundColor: AppColors.premiumNavy,
              foregroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Thêm chi phí',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.premiumBlue),
            )
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.premiumBlue,
              child: ListView(
                // Bottom padding đủ lớn để FAB "Thêm chi phí" (nổi góc dưới
                // phải) không che icon sửa/xóa của item cuối cùng trong danh
                // sách.
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                children: [
                  if (widget.isCompleted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.costSoftAmber,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.costAmber.withValues(alpha: .28),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: AppColors.costAmber,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lịch trình đã hoàn thành — không thể thêm/sửa/xoá chi phí nữa.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.costAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_dayFilterNumber != null && _dayBreakdown != null) ...[
                    _buildDayBreakdownCard(_dayBreakdown!, _dayFilterNumber!),
                  ] else if (_breakdown != null) ...[
                    _buildOverviewHero(_breakdown!),
                    const SizedBox(height: 20),
                    _buildSectionHeading(
                      CostUiLabels.estimateDetails,
                      CostUiLabels.estimateDetailsSubtitle,
                    ),
                    const SizedBox(height: 10),
                    _buildEstimateCard(_breakdown!),
                    const SizedBox(height: 20),
                    _buildSectionHeading(
                      CostUiLabels.memberAllocation,
                      CostUiLabels.memberAllocationSubtitle,
                    ),
                    const SizedBox(height: 10),
                    _buildMemberBreakdownCard(_breakdown!),
                  ],
                  const SizedBox(height: 24),
                  if (_placeFilterId != null) ...[
                    _buildPlaceFilterBanner(),
                    const SizedBox(height: 8),
                  ],
                  if (_dayFilterNumber != null) ...[
                    _buildDayFilterBanner(),
                    const SizedBox(height: 8),
                  ],
                  _buildSectionHeading(
                    _placeFilterId != null
                        ? 'Chi phí tại ${_placeFilterName ?? "địa điểm này"}'
                        : _dayFilterNumber != null
                        ? 'Chi phí ngày $_dayFilterNumber'
                        : CostUiLabels.expenseHistory,
                    _costs.isEmpty
                        ? 'Chưa ghi nhận khoản chi nào'
                        : '${_costs.length} khoản chi đã ghi nhận',
                  ),
                  const SizedBox(height: 10),
                  if (_costs.isEmpty)
                    _buildEmptyState()
                  else if (_shouldGroupByDay)
                    ..._groupedCosts().expand(
                      (group) => [
                        _buildDayGroupHeader(group.label, group.items),
                        ...group.items.map(_buildCostTile),
                      ],
                    )
                  else
                    ..._costs.map(_buildCostTile),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewHero(CostBreakdownEntity breakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.costHeroStart, AppColors.costHeroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumBlue.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  CostUiLabels.overviewEyebrow,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFFCFE8FF),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.costMint.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  CostUiLabels.reserveIncluded,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB8FFF3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            CostUiLabels.estimatedTotal,
            style: TextStyle(fontSize: 13, color: Color(0xFFCFE0F2)),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatter.format(breakdown.roundedGroupTotal)}đ',
            style: const TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeroMetric(
                    CostUiLabels.spent,
                    '${_formatter.format(breakdown.spentSoFar)}đ',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: .16),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildHeroMetric(
                      CostUiLabels.spendingLimit,
                      '${_formatter.format(breakdown.payableLimitForGroup)}đ',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFFCFE0F2)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.costText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.costTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.costSoftDanger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.costDanger,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.costText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.costTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.premiumSoftBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.premiumBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _placeFilterId != null
                ? 'Chưa có chi phí tại địa điểm này'
                : _dayFilterNumber != null
                ? 'Chưa có chi phí trong ngày này'
                : 'Chưa có khoản chi nào',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.costText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Các khoản phát sinh sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.costTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDayFilterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.premiumSoftBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.premiumBlue.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            size: 16,
            color: AppColors.premiumBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang xem: Ngày $_dayFilterNumber',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.premiumBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _clearDayFilter,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.premiumBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Chi tiết ngày N" — thay Card 1+3 (tính cả chuyến) khi đang xem 1 ngày
  /// cụ thể. Xăng xe KHÔNG chia theo ngày (điều chỉnh 1 lần/cả chuyến) nên
  /// hiển thị riêng, ghi rõ "cả chuyến" để không hiểu nhầm là của ngày này.
  // "Điều chỉnh xăng xe" trong categoryBreakdown khi CHƯA hoàn tất chuyến và
  // CHƯA ai ghi thực tế chỉ là số ƯỚC TÍNH chia đều — ẩn khỏi danh sách chi
  // tiết theo mục để tránh hiểu nhầm là khoản đã tiêu thật (xem
  // transportIsActual ở CostBreakdownEntity).
  List<MapEntry<CostType, double>> _visibleCategoryEntries(
    Map<CostType, double> categoryBreakdown,
  ) {
    final showEstimatedTransport =
        widget.isCompleted || (_breakdown?.transportIsActual ?? false);
    return categoryBreakdown.entries
        .where(
          (e) =>
              e.key != CostType.transportAdjustment || showEstimatedTransport,
        )
        .toList();
  }

  Widget _buildDayBreakdownCard(
    DayCostBreakdownEntity breakdown,
    int dayNumber,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.premiumBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mỗi người phải trả — Ngày $dayNumber',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.costText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Chỉ tính chi phí của riêng ngày này',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          ...breakdown.memberTotals.map(
            (m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.fullName.isNotEmpty
                              ? '${m.fullName}${m.isOwner ? ' (Chủ lịch trình)' : ''}'
                              : 'Thành viên',
                        ),
                      ),
                      Text(
                        '${_formatter.format(m.total)}đ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (m.childrenShare > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '+ Phần trẻ em',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Text(
                            '${_formatter.format(m.childrenShare)}đ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_visibleCategoryEntries(m.categoryBreakdown).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _visibleCategoryEntries(m.categoryBreakdown)
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.key.label,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_formatter.format(e.value)}đ',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          // Số xăng xe khi CHƯA hoàn tất chuyến và chưa ai ghi thực tế chỉ là
          // ƯỚC TÍNH — hiển thị ngay từ đầu dễ khiến người dùng tưởng nhầm là
          // đã tiêu, không rõ để làm gì. Chỉ hiện con số thật khi chuyến đã
          // hoàn tất, hoặc chủ lịch trình đã tự ghi "Điều chỉnh xăng xe".
          if (widget.isCompleted || (_breakdown?.transportIsActual ?? false))
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Xăng xe (áp dụng cả chuyến, không riêng ngày này)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ),
                Text(
                  '${_formatter.format(breakdown.transportPerAdultWholeTrip)}đ/người',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            )
          else
            const Text(
              'Xăng xe: số ước tính sẽ hiện khi chuyến đi hoàn tất (hoặc khi có ghi chi phí thực tế).',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceFilterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.premiumSoftBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.premiumBlue.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            size: 16,
            color: AppColors.premiumBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang lọc theo: ${_placeFilterName ?? "địa điểm này"}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.premiumBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _clearPlaceFilter,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.premiumBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 1: chi phí ước tính + mức có thể chi trả. Mỗi mục người lớn/trẻ em
  /// hiển thị công thức nhân rõ ràng ("2 × 1.500.000đ = 3.000.000đ"); riêng
  /// phần ước tính có thể bấm xổ ra breakdown Địa điểm/Lưu trú/Xăng xe.
  Widget _buildEstimateCard(CostBreakdownEntity breakdown) {
    Widget breakdownRow(
      String label,
      double value, {
      String? caption,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Text(
                '${_formatter.format(value)}đ',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (caption != null)
            Text(
              caption,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFB0B8C1)),
            ),
        ],
      ),
    );

    // Minh bạch căn cứ tính "Xăng xe/tự túc" — đáp ứng phản hồi "chi phí xăng
    // xe đang hơi thấp" bằng cách cho thấy mức giá/km đang dùng thay vì chỉ
    // hiện 1 con số không rõ nguồn gốc.
    final rateCaption =
        'Ước tính theo ${_formatter.format(breakdown.transportRatePerKmMotorbike)}đ/km '
        '(xe máy) hoặc ${_formatter.format(breakdown.transportRatePerKmCar)}đ/km (ô tô)';

    // Với trẻ em, Địa điểm & ăn uống / Lưu trú = giá người lớn × tỉ lệ trẻ em
    // — ghi rõ công thức này thay vì chỉ hiện số, để tránh hiểu nhầm số trẻ
    // em không rõ căn cứ từ đâu ra.
    final childRatioPercent = (breakdown.childPriceRatio * 100).round();
    String childRatioCaption(double adultValue) =>
        'Người lớn ${_formatter.format(adultValue)}đ × $childRatioPercent%';

    Widget travelerTile({
      required String label,
      required int count,
      required double unitPrice,
      required double placeCost,
      required double hotelCost,
      required double transportCost,
      required double contingency,
      double? adultPlaceCost,
      double? adultHotelCost,
    }) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.premiumBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.premiumBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: AppColors.premiumBlue,
          collapsedIconColor: AppColors.costTextMuted,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '$label ($count)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.costText,
                  ),
                ),
              ),
              Text(
                '${_formatter.format(count * unitPrice)}đ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.costText,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${_formatter.format(unitPrice)}đ/người · Chạm để xem chi tiết',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.costTextMuted,
            ),
          ),
          children: [
            breakdownRow(
              'Địa điểm & ăn uống',
              placeCost,
              caption: adultPlaceCost != null
                  ? childRatioCaption(adultPlaceCost)
                  : null,
            ),
            breakdownRow(
              'Lưu trú',
              hotelCost,
              caption: adultHotelCost != null
                  ? childRatioCaption(adultHotelCost)
                  : null,
            ),
            breakdownRow('Xăng xe/tự túc', transportCost, caption: rateCaption),
            breakdownRow('Phí dự trù (10%, đã làm tròn)', contingency),
          ],
        ),
      );
    }

    Widget formulaLine(String label, int count, double unitPrice) => Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.costSoftMint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ($count)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.costText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatter.format(unitPrice)}đ/người',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.costTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatter.format(count * unitPrice)}đ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.premiumTeal,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.premiumBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.costMint),
              SizedBox(width: 8),
              Text(
                CostUiLabels.spendingLimit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.costTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatter.format(breakdown.payableLimitForGroup)}đ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.costText,
            ),
          ),
          const Text(
            'cho cả nhóm',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          formulaLine(
            'Người lớn',
            breakdown.adultCount,
            breakdown.payableLimitPerAdult,
          ),
          if (breakdown.childCount > 0)
            formulaLine(
              'Trẻ em',
              breakdown.childCount,
              breakdown.payableLimitPerChild,
            ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.premiumBorder),
          const SizedBox(height: 14),
          const Text(
            CostUiLabels.estimateByTraveler,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.costText,
            ),
          ),
          Text(
            '${CostUiLabels.beforeReserve}: '
            '${_formatter.format(breakdown.estimatedCostForGroup)}đ',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.costTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          travelerTile(
            label: 'Người lớn',
            count: breakdown.adultCount,
            unitPrice: breakdown.roundedCostPerAdult,
            placeCost: breakdown.placeCostPerAdult,
            hotelCost: breakdown.hotelCostPerAdult,
            transportCost: breakdown.transportPerAdult,
            contingency:
                breakdown.roundedCostPerAdult - breakdown.estimatedCostPerAdult,
          ),
          if (breakdown.childCount > 0)
            travelerTile(
              label: 'Trẻ em',
              count: breakdown.childCount,
              unitPrice: breakdown.roundedCostPerChild,
              placeCost: breakdown.placeCostPerChild,
              hotelCost: breakdown.hotelCostPerChild,
              transportCost: breakdown.transportPerAdult,
              contingency:
                  breakdown.roundedCostPerChild -
                  breakdown.estimatedCostPerChild,
              adultPlaceCost: breakdown.placeCostPerAdult,
              adultHotelCost: breakdown.hotelCostPerAdult,
            ),
        ],
      ),
    );
  }

  /// Card 3: "mỗi người phải trả tổng bao nhiêu" (mục 1.7), không đổi so với
  /// bản cũ ngoài việc tách khỏi headline tổng chi phí (đã chuyển sang Card 2).
  Widget _buildMemberBreakdownCard(CostBreakdownEntity breakdown) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.premiumBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 17, color: AppColors.costMint),
              SizedBox(width: 8),
              Text(
                'Tính đến hiện tại',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.costTextMuted,
                ),
              ),
            ],
          ),
          // Số này là CHI PHÍ THỰC TẾ (chỉ địa điểm đã ghé + chi phí phát
          // sinh gắn địa điểm đã ghé) — khác với "Chi phí ước tính" ở card
          // trên (tính cho cả kế hoạch), nên cần ghi rõ mốc thời gian để
          // tránh hiểu nhầm 2 số không khớp nhau là do sai sót.
          const SizedBox(height: 10),
          for (int i = 0; i < breakdown.memberTotals.length; i++) ...[
            // Phân cách rõ giữa từng người — trước đây chỉ cách nhau 4px,
            // dễ nhìn lộn phần category breakdown của người này sang người kế
            // tiếp khi không có ranh giới nào.
            if (i > 0) const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildMemberRow(breakdown.memberTotals[i], breakdown),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    MemberCostTotalEntity m,
    CostBreakdownEntity breakdown,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.fullName.isNotEmpty
                      ? '${m.fullName}${m.isOwner ? ' (Chủ lịch trình)' : ''}'
                      : 'Thành viên',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${_formatter.format(m.total)}đ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          // Chi phí trẻ em không cộng gộp vào total ở trên — hiển thị
          // thành dòng riêng cho người đang chịu trách nhiệm phần này.
          if (m.childrenShare > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      breakdown.childCount > 1
                          ? '+ Phần trẻ em (phụ trách ${breakdown.childCount} trẻ)'
                          : '+ Phần trẻ em (phụ trách 1 trẻ)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Text(
                    '${_formatter.format(m.childrenShare)}đ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Chi tiết theo từng mục (Nước uống/Quà tặng/Mua sắm/Phí
          // gửi xe/Khác) cộng vào phần của người này — không gồm
          // basePlanCost (đã nằm sẵn trong [total] ở trên).
          if (_visibleCategoryEntries(m.categoryBreakdown).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _visibleCategoryEntries(m.categoryBreakdown)
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key.label,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            Text(
                              '${_formatter.format(e.value)}đ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayGroupHeader(String label, List<IncurredCostEntity> items) {
    final subtotal = items.fold<double>(0, (sum, c) => sum + c.amount);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.costMint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.costText,
              ),
            ),
          ),
          Text(
            '${_formatter.format(subtotal)}đ',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.costText,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPriceEditSheet(IncurredCostEntity cost) async {
    if (cost.placeId == null) return;
    await IncurredCostSheet.showPriceEdit(
      context,
      itineraryId: widget.itineraryId,
      placeId: cost.placeId!,
      placeName: cost.placeName ?? '',
      currentPrice: cost.amount,
      onSaved: _load,
    );
  }

  Widget _buildCostTile(IncurredCostEntity cost) {
    final canModify = _canModify(cost);
    final canEditPrice =
        cost.type == CostType.baselinePlan &&
        _isOwner &&
        !widget.isCompleted &&
        cost.placeId != null;
    final chargedLabel = cost.chargedTo.isEmpty
        ? 'Chia đều cả nhóm'
        : cost.chargedTo.map(_memberName).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _costTypeBackground(cost.type),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _costTypeIcon(cost.type),
              size: 19,
              color: _costTypeColor(cost.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cost.note,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.costText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cost.type.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _costTypeColor(cost.type),
                  ),
                ),
                if (cost.placeName != null && cost.placeName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      cost.placeName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.costTextMuted,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chargedLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.costTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatter.format(cost.amount)}đ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.costText,
                ),
              ),
              if (canModify)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _openSheet(editing: cost),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.costDanger,
                      ),
                      onPressed: () => _delete(cost),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                )
              else if (canEditPrice)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => _openPriceEditSheet(cost),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.price_change_outlined,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Sửa giá',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _costTypeColor(CostType type) {
    switch (type) {
      case CostType.water:
        return AppColors.premiumBlue;
      case CostType.gift:
      case CostType.shopping:
        return AppColors.costAmber;
      case CostType.baselinePlan:
        return AppColors.premiumTeal;
      case CostType.priceAdjustment:
      case CostType.transportAdjustment:
        return AppColors.costDanger;
      case CostType.parkingFee:
      case CostType.other:
        return AppColors.costTextMuted;
    }
  }

  Color _costTypeBackground(CostType type) {
    switch (type) {
      case CostType.water:
        return AppColors.premiumSoftBlue;
      case CostType.gift:
      case CostType.shopping:
        return AppColors.costSoftAmber;
      case CostType.baselinePlan:
        return AppColors.costSoftMint;
      case CostType.priceAdjustment:
      case CostType.transportAdjustment:
        return AppColors.costSoftDanger;
      case CostType.parkingFee:
      case CostType.other:
        return AppColors.premiumBackground;
    }
  }

  IconData _costTypeIcon(CostType type) {
    switch (type) {
      case CostType.water:
        return Icons.local_drink_outlined;
      case CostType.gift:
        return Icons.card_giftcard_rounded;
      case CostType.shopping:
        return Icons.shopping_bag_outlined;
      case CostType.parkingFee:
        return Icons.local_parking_rounded;
      case CostType.baselinePlan:
        return Icons.route_outlined;
      case CostType.priceAdjustment:
        return Icons.price_change_outlined;
      case CostType.transportAdjustment:
        return Icons.local_gas_station_outlined;
      case CostType.other:
        return Icons.receipt_long_outlined;
    }
  }
}
