import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/incurred_cost_sheet.dart';

/// Màn "Quản lý chi phí" tổng hợp (mục 1.9) — danh sách toàn bộ chi phí phát
/// sinh của lịch trình + bảng "mỗi người phải trả tổng bao nhiêu" (mục 1.7).
class IncurredCostsScreen extends StatefulWidget {
  final String itineraryId;
  final List<ItineraryMemberEntity> members;
  final bool isCompleted;

  const IncurredCostsScreen({
    super.key,
    required this.itineraryId,
    required this.members,
    this.isCompleted = false,
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
  String? _currentUserId;
  bool _isOwner = false;

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
        _repository.getIncurredCosts(widget.itineraryId),
        _repository.getCostBreakdown(widget.itineraryId),
      ]);
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _isOwner = widget.members.any(
          (m) => m.id == userId && m.isOwner,
        );
        _costs = results[0] as List<IncurredCostEntity>;
        _breakdown = results[1] as CostBreakdownEntity;
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
    if (cost.type == CostType.priceAdjustment) return _isOwner;
    return cost.createdBy == _currentUserId;
  }

  String _memberName(String userId) {
    final match = widget.members.where((m) => m.id == userId);
    if (match.isEmpty) return 'Thành viên';
    final name = match.first.fullName;
    return name.isNotEmpty ? name : 'Thành viên';
  }

  Future<void> _openSheet({IncurredCostEntity? editing}) async {
    await IncurredCostSheet.show(
      context,
      itineraryId: widget.itineraryId,
      members: widget.members,
      isOwner: _isOwner,
      editingCost: editing,
      onSaved: _load,
    );
  }

  Future<void> _delete(IncurredCostEntity cost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá khoản chi phí?'),
        content: Text('Xoá "${cost.note}" (${_formatter.format(cost.amount)}đ)?'),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý chi phí'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      floatingActionButton: widget.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openSheet(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm chi phí'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.isCompleted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_rounded, size: 18, color: Color(0xFFB45309)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lịch trình đã hoàn thành — không thể thêm/sửa/xoá chi phí nữa.',
                              style: TextStyle(fontSize: 13, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_breakdown != null) ...[
                    _buildEstimateCard(_breakdown!),
                    const SizedBox(height: 12),
                    _buildMemberBreakdownCard(_breakdown!),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Danh sách chi phí phát sinh',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_costs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Chưa có khoản chi phí phát sinh nào',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    )
                  else
                    ..._costs.map(_buildCostTile),
                ],
              ),
            ),
    );
  }

  /// Card 1: chi phí ước tính + mức có thể chi trả. Mỗi mục người lớn/trẻ em
  /// hiển thị công thức nhân rõ ràng ("2 × 1.500.000đ = 3.000.000đ"); riêng
  /// phần ước tính có thể bấm xổ ra breakdown Địa điểm/Lưu trú/Xăng xe.
  Widget _buildEstimateCard(CostBreakdownEntity breakdown) {
    String formula(int count, double unitPrice) =>
        '$count × ${_formatter.format(unitPrice)}đ = '
        '${_formatter.format(count * unitPrice)}đ';

    Widget breakdownRow(String label, double value, {String? caption}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
        title: Text(
          '$label: ${formula(count, unitPrice)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
      );
    }

    Widget formulaLine(String label, int count, double unitPrice) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '$label: ${formula(count, unitPrice)}',
        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mức có thể chi trả',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Text(
            '${_formatter.format(breakdown.payableLimitForGroup)}đ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Tổng ước tính (đã gồm 10% dự trù)',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Text(
            '${_formatter.format(breakdown.roundedGroupTotal)}đ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            'cho cả nhóm — chưa dự trù: '
            '${_formatter.format(breakdown.estimatedCostForGroup)}đ',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
              contingency: breakdown.roundedCostPerChild -
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mỗi người phải trả',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          // Số này là CHI PHÍ THỰC TẾ (chỉ địa điểm đã ghé + chi phí phát
          // sinh gắn địa điểm đã ghé) — khác với "Chi phí ước tính" ở card
          // trên (tính cho cả kế hoạch), nên cần ghi rõ mốc thời gian để
          // tránh hiểu nhầm 2 số không khớp nhau là do sai sót.
          const Text(
            'Tính đến hiện tại',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostTile(IncurredCostEntity cost) {
    final canModify = _canModify(cost);
    final chargedLabel = cost.chargedTo.isEmpty
        ? 'Chia đều cả nhóm'
        : cost.chargedTo.map(_memberName).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cost.note, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (cost.placeName != null && cost.placeName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      cost.placeName!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chargedLabel,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
                style: const TextStyle(fontWeight: FontWeight.w700),
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
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _delete(cost),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
