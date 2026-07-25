import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

/// Bottom sheet dùng chung để thêm/sửa 1 khoản chi phí phát sinh (mục 1.6),
/// dùng ở màn "Quản lý chi phí" tổng hợp.
///
/// 2 nhóm type khác nhau (xem [CostType]):
/// - [CostType.transportAdjustment]: chỉ chủ lịch trình, áp dụng CẢ CHUYẾN
///   (không gắn địa điểm/ngày), nhập tổng chi phí xăng xe THẬT đã chi cho cả
///   nhóm (thay thế số ước tính, chia đều cho mọi người); có thể âm để đính
///   chính lại số đã ghi trước đó.
/// - Còn lại: chi phí phát sinh cá nhân, ai cũng tạo được, nhập thẳng số
///   tiền, có thể gắn 1 địa điểm HOẶC 1 ngày (không cả hai).
///
/// [CostType.baselinePlan] ("Chi phí kế hoạch") không xuất hiện ở đây — hệ
/// thống tự ghi khi check-in. [CostType.priceAdjustment] cũng không tạo tay
/// được nữa — sửa giá 1 địa điểm giờ dùng [IncurredCostSheet.showPriceEdit]
/// (cập nhật thẳng lên dòng "Chi phí kế hoạch", không phải chênh lệch).
class IncurredCostSheet extends StatefulWidget {
  final String itineraryId;
  final List<ItineraryMemberEntity> members;
  final bool isOwner;
  final String? initialPlaceId;
  final String? initialPlaceName;
  final List<ItineraryDayEntity> days;
  final IncurredCostEntity? editingCost;
  final VoidCallback? onSaved;
  // Khi true: sheet chỉ làm đúng 1 việc — sửa giá HIỆU LỰC của
  // initialPlaceId (đã visited), gọi updatePlaceEffectivePrice() thay vì
  // tạo/sửa 1 dòng incurred_costs thường. Dùng qua showPriceEdit().
  final bool isPriceEdit;
  final double? initialPrice;
  // Dùng để nhân ra tổng khi user chọn nhập "Mỗi người" thay vì "Tổng cộng"
  // (xem _amountIsPerPerson) — cả nhóm = adultCount + childCount, KHÔNG nhân
  // childPriceRatio (chi phí ad-hoc thực tế, trẻ em dùng/ăn y hệt người lớn).
  final int adultCount;
  final int childCount;

  const IncurredCostSheet({
    super.key,
    required this.itineraryId,
    required this.members,
    required this.isOwner,
    this.initialPlaceId,
    this.initialPlaceName,
    this.days = const [],
    this.editingCost,
    this.onSaved,
    this.isPriceEdit = false,
    this.initialPrice,
    this.adultCount = 1,
    this.childCount = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required String itineraryId,
    required List<ItineraryMemberEntity> members,
    required bool isOwner,
    String? initialPlaceId,
    String? initialPlaceName,
    List<ItineraryDayEntity> days = const [],
    IncurredCostEntity? editingCost,
    VoidCallback? onSaved,
    int adultCount = 1,
    int childCount = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncurredCostSheet(
        itineraryId: itineraryId,
        members: members,
        isOwner: isOwner,
        initialPlaceId: initialPlaceId,
        initialPlaceName: initialPlaceName,
        days: days,
        editingCost: editingCost,
        onSaved: onSaved,
        adultCount: adultCount,
        childCount: childCount,
      ),
    );
  }

  /// Sửa giá HIỆU LỰC của 1 địa điểm đã visited — xem [isPriceEdit].
  static Future<void> showPriceEdit(
    BuildContext context, {
    required String itineraryId,
    required String placeId,
    required String placeName,
    required double currentPrice,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncurredCostSheet(
        itineraryId: itineraryId,
        members: const [],
        isOwner: true,
        initialPlaceId: placeId,
        initialPlaceName: placeName,
        isPriceEdit: true,
        initialPrice: currentPrice,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<IncurredCostSheet> createState() => _IncurredCostSheetState();
}

class _IncurredCostSheetState extends State<IncurredCostSheet> {
  final _repository = sl<ItineraryRepository>();
  final _amountFormatter = NumberFormat('#,###', 'vi_VN');
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;

  List<EligiblePlaceEntity> _places = [];
  bool _loadingPlaces = true;
  String? _selectedPlaceId;
  int? _selectedDayNumber;
  final Set<String> _chargedTo = {};
  // true = chip "Cả nhóm" đang chọn (loại trừ với chọn thành viên cụ thể).
  // Mặc định true vì trước đây "bỏ trống" == cả nhóm — giữ hành vi cũ.
  bool _wholeGroup = true;
  // Số tiền nhập vào là TỔNG hay MỖI NGƯỜI (nhân đều theo adultCount+childCount
  // khi lưu, không nhân theo childPriceRatio — xem _submit()).
  bool _amountIsPerPerson = false;
  late CostType _type;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.editingCost != null;
  bool get _isTransportAdjustment => _type == CostType.transportAdjustment;
  // Đính chính 1 dòng "Điều chỉnh giá" cũ (lịch sử) — vẫn là chi phí CHUNG,
  // không gán riêng cho ai, và amount vẫn có thể âm (giữ nguyên bản chất
  // delta của nó). Không tạo mới được (đã chặn ở chip chọn loại).
  bool get _isEditingPriceAdjustment =>
      _isEditing && widget.editingCost!.type == CostType.priceAdjustment;
  bool get _needsSharedGroupAmount =>
      _isTransportAdjustment || _isEditingPriceAdjustment;

  @override
  void initState() {
    super.initState();
    _type = CostType.other;
    _noteController = TextEditingController();
    if (widget.isPriceEdit) {
      _amountController = TextEditingController(
        text: widget.initialPrice?.toStringAsFixed(0) ?? '',
      );
      _loadingPlaces = false;
      return;
    }
    final editing = widget.editingCost;
    _type = editing?.type ?? CostType.other;
    _noteController.text = editing?.note ?? '';
    _amountController = TextEditingController(
      text: editing != null ? editing.amount.toStringAsFixed(0) : '',
    );
    // Rebuild khi gõ số tiền để cập nhật preview "≈ Xđ/người" theo thời gian
    // thực (xem _perPersonPreviewText).
    _amountController.addListener(_onAmountChanged);
    _selectedPlaceId = editing?.placeId ?? widget.initialPlaceId;
    _selectedDayNumber = editing?.dayNumber;
    _chargedTo.addAll(editing?.chargedTo ?? const []);
    // Sửa 1 khoản đã có người trả cụ thể -> giữ đúng lựa chọn đó, không mặc
    // định về "Cả nhóm" nữa.
    _wholeGroup = _chargedTo.isEmpty;
    _loadPlaces();
  }

  void _onAmountChanged() => setState(() {});

  // Số tiền nhập vào (Điều chỉnh xăng xe / Điều chỉnh giá) luôn là TỔNG cho
  // cả nhóm, chia đều cho mọi người (không theo childPriceRatio) — hiển thị
  // con số cụ thể để không phải đoán, đúng góp ý người dùng.
  String? _perPersonPreviewText() {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9\-]'), '');
    final amount = double.tryParse(raw);
    if (amount == null || amount == 0) return null;
    final headcount = widget.adultCount + widget.childCount;
    if (headcount <= 0) return null;
    final perPerson = amount / headcount;
    final sign = perPerson < 0 ? '-' : '';
    return '≈ $sign${_amountFormatter.format(perPerson.abs())}đ/người ($headcount người)';
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await _repository.getEligiblePlaces(widget.itineraryId);
      if (!mounted) return;
      setState(() {
        _places = places;
        _loadingPlaces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlaces = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.isPriceEdit) return _submitPriceEdit();

    final note = _noteController.text.trim();
    final rawInput = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    if (note.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung/ghi chú');
      return;
    }
    if (rawInput == null) {
      setState(() => _error = 'Vui lòng nhập số tiền hợp lệ');
      return;
    }
    if (!_needsSharedGroupAmount && rawInput <= 0) {
      setState(() => _error = 'Vui lòng nhập số tiền hợp lệ');
      return;
    }
    if (!_needsSharedGroupAmount && !_wholeGroup && _chargedTo.isEmpty) {
      setState(() => _error = 'Vui lòng chọn ít nhất 1 người chi trả');
      return;
    }
    // "Mỗi người" -> nhân đều theo số người áp dụng để ra TỔNG thật gửi lên
    // server (server/distributeCosts() luôn làm việc với tổng, không biết khái
    // niệm "mỗi người" nhập tay này). Cả nhóm = adultCount+childCount, chọn
    // riêng vài người = đúng số người đã chọn. Không áp dụng cho điều chỉnh
    // xăng xe/giá (delta/giá tuyệt đối, không có khái niệm "mỗi người").
    final effectiveInput = (!_needsSharedGroupAmount && _amountIsPerPerson)
        ? rawInput *
              (_wholeGroup
                  ? (widget.adultCount + widget.childCount)
                  : _chargedTo.length)
        : rawInput;
    // Server làm tròn đến nghìn và bắt buộc tối thiểu 1.000đ — validate sớm
    // ở đây để báo lỗi ngay, tránh round-trip lên server mới biết.
    final amount = (effectiveInput / 1000).round() * 1000.0;
    if (amount.abs() < 1000) {
      setState(() => _error = 'Số tiền phải từ 1.000đ trở lên');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      // Điều chỉnh xăng xe áp dụng cả chuyến — không gắn địa điểm/ngày.
      final placeId = _isTransportAdjustment ? null : _selectedPlaceId;
      final dayNumber = _isTransportAdjustment ? null : _selectedDayNumber;
      final chargedTo = _needsSharedGroupAmount
          ? const <String>[]
          : _chargedTo.toList();
      if (_isEditing) {
        await _repository.updateIncurredCost(
          widget.itineraryId,
          widget.editingCost!.id,
          type: _type,
          note: note,
          amount: amount,
          placeId: placeId,
          dayNumber: dayNumber,
          chargedTo: chargedTo,
        );
      } else {
        await _repository.createIncurredCost(
          widget.itineraryId,
          type: _type,
          note: note,
          amount: amount,
          placeId: placeId,
          dayNumber: dayNumber,
          chargedTo: chargedTo,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitPriceEdit() async {
    final rawInput = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (rawInput == null || rawInput <= 0) {
      setState(() => _error = 'Vui lòng nhập giá mới hợp lệ');
      return;
    }
    final amount = (rawInput / 1000).round() * 1000.0;
    if (amount < 1000) {
      setState(() => _error = 'Giá phải từ 1.000đ trở lên');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _repository.updatePlaceEffectivePrice(
        widget.itineraryId,
        widget.initialPlaceId!,
        amount,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: widget.isPriceEdit ? 0.52 : 0.82,
        minChildSize: widget.isPriceEdit ? 0.4 : 0.58,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.premiumBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumNavy.withValues(alpha: .18),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildDragHandle(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: widget.isPriceEdit
                        ? _buildPriceEditContent()
                        : _buildFullFormContent(),
                  ),
                ),
                _buildStickyFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.premiumBorder,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildStickyFooter() {
    final label = widget.isPriceEdit
        ? 'Lưu giá mới'
        : _isEditing
        ? 'Lưu thay đổi'
        : 'Thêm chi phí';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.premiumBorder)),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(top: false, child: _buildSubmitButton(label: label)),
    );
  }

  Widget _buildSubmitButton({required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.premiumNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.premiumMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing || widget.isPriceEdit
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.costHeroStart, AppColors.costHeroEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.costText,
                ),
              ),
              const SizedBox(height: 3),
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
        IconButton(
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 20),
          color: AppColors.costTextMuted,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.premiumBorder),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.premiumSoftBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.premiumBlue),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.costText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.premiumSoftBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.premiumBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.costTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPriceEditContent() {
    return [
      _buildSheetHeader(
        icon: Icons.price_change_outlined,
        title: 'Sửa giá địa điểm',
        subtitle: widget.initialPlaceName ?? 'Cập nhật chi phí kế hoạch',
      ),
      const SizedBox(height: 18),
      _buildFormCard(
        title: 'Giá áp dụng cho cả nhóm',
        icon: Icons.payments_outlined,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.costText,
            ),
            decoration: const InputDecoration(
              labelText: 'Giá mới',
              hintText: '0',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              suffixText: 'đ',
              helperText: 'Tối thiểu 1.000đ · Làm tròn đến đơn vị nghìn',
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoBox(
            'Giá mới được cập nhật vào Chi phí kế hoạch của địa điểm và áp dụng cho cả nhóm.',
          ),
        ],
      ),
      if (_error != null) ...[const SizedBox(height: 12), _buildErrorBox()],
    ];
  }

  List<Widget> _buildFullFormContent() {
    return [
      _buildSheetHeader(
        icon: _isEditing ? Icons.edit_note_rounded : Icons.receipt_long_rounded,
        title: _isEditing ? 'Sửa chi phí' : 'Thêm chi phí',
        subtitle: 'Ghi nhận khoản chi thực tế của chuyến đi',
      ),
      const SizedBox(height: 18),
      _buildExpenseInfoCard(),
      const SizedBox(height: 12),
      _buildContextCard(),
      const SizedBox(height: 12),
      _buildAmountCard(),
      if (!_needsSharedGroupAmount) ...[
        const SizedBox(height: 12),
        _buildPayerCard(),
      ],
      if (_error != null) ...[const SizedBox(height: 12), _buildErrorBox()],
    ];
  }

  Widget _buildExpenseInfoCard() {
    return _buildFormCard(
      title: 'Thông tin khoản chi',
      icon: Icons.category_outlined,
      children: [
        const Text(
          'Loại chi phí',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.costTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CostType.values
              .where(
                (t) =>
                    t != CostType.baselinePlan && t != CostType.priceAdjustment,
              )
              .where((t) => t != CostType.transportAdjustment || widget.isOwner)
              .map(_buildCostTypeChip)
              .toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Nội dung khoản chi',
            hintText: 'VD: Gửi xe máy, ăn vặt dọc đường...',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCostTypeChip(CostType type) {
    final selected = _type == type;
    return ChoiceChip(
      avatar: Icon(
        _costTypeIcon(type),
        size: 16,
        color: selected ? AppColors.premiumNavy : AppColors.costTextMuted,
      ),
      label: Text(type.label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.costSoftMint,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.costMint : AppColors.premiumBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.premiumNavy : AppColors.costTextMuted,
      ),
      onSelected: _isEditing
          ? null
          : (value) {
              if (!value) return;
              setState(() {
                _type = type;
                if (type == CostType.transportAdjustment) {
                  _chargedTo.clear();
                  _selectedPlaceId = null;
                  _selectedDayNumber = null;
                }
              });
            },
    );
  }

  Widget _buildContextCard() {
    return _buildFormCard(
      title: _isTransportAdjustment
          ? 'Phạm vi áp dụng'
          : 'Thời gian và địa điểm',
      icon: _isTransportAdjustment
          ? Icons.route_outlined
          : Icons.location_on_outlined,
      children: _isTransportAdjustment
          ? [
              _buildInfoBox(
                'Khoản xăng xe này áp dụng cho toàn bộ chuyến đi, không gắn với ngày hoặc địa điểm riêng.',
                icon: Icons.directions_car_outlined,
              ),
            ]
          : [
              if (_loadingPlaces)
                const LinearProgressIndicator(color: AppColors.premiumBlue)
              else
                DropdownButtonFormField<String?>(
                  initialValue: _selectedPlaceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Địa điểm',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Không gắn địa điểm cụ thể'),
                    ),
                    ..._places.map(
                      (place) => DropdownMenuItem<String?>(
                        value: place.id,
                        child: Text(
                          place.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedPlaceId = value;
                    if (value != null) _selectedDayNumber = null;
                  }),
                ),
              if (widget.days.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedDayNumber,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ngày trong lịch trình',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Không gắn ngày cụ thể'),
                    ),
                    ...widget.days.map(
                      (day) => DropdownMenuItem<int?>(
                        value: day.dayNumber,
                        child: Text('Ngày ${day.dayNumber}'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedDayNumber = value;
                    if (value != null) _selectedPlaceId = null;
                  }),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Chỉ chọn địa điểm hoặc ngày; hệ thống sẽ tự bỏ lựa chọn còn lại.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.costTextMuted,
                ),
              ),
            ],
    );
  }

  Widget _buildAmountCard() {
    return _buildFormCard(
      title: 'Số tiền',
      icon: Icons.payments_outlined,
      children: [
        if (!_needsSharedGroupAmount) ...[
          const Text(
            'Cách nhập',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.costTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  label: 'Tổng cộng',
                  icon: Icons.groups_2_outlined,
                  selected: !_amountIsPerPerson,
                  onTap: () => setState(() => _amountIsPerPerson = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeOption(
                  label: 'Mỗi người',
                  icon: Icons.person_outline_rounded,
                  selected: _amountIsPerPerson,
                  onTap: () => setState(() => _amountIsPerPerson = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.costText,
          ),
          decoration: InputDecoration(
            labelText: _isTransportAdjustment
                ? 'Tổng chi phí xăng xe'
                : _amountIsPerPerson
                ? 'Số tiền mỗi người'
                : 'Tổng số tiền',
            hintText: '0',
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            suffixText: 'đ',
            helperText: _isTransportAdjustment
                ? 'Có thể nhập số âm để đính chính'
                : 'Tối thiểu 1.000đ · Làm tròn đến đơn vị nghìn',
          ),
        ),
        if (_needsSharedGroupAmount) ...[
          const SizedBox(height: 10),
          _buildInfoBox(
            _isEditingPriceAdjustment
                ? 'Điều chỉnh này áp dụng cho cả nhóm và không gán riêng cho thành viên.'
                : 'Đây là tổng chi phí của cả nhóm và sẽ được chia đều cho mọi người.',
          ),
          if (_isTransportAdjustment && _perPersonPreviewText() != null) ...[
            const SizedBox(height: 8),
            Text(
              _perPersonPreviewText()!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.premiumTeal,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.costSoftMint
              : AppColors.premiumBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.costMint : AppColors.premiumBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : icon,
              size: 17,
              color: selected ? AppColors.premiumTeal : AppColors.costTextMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.premiumNavy
                      : AppColors.costTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerCard() {
    return _buildFormCard(
      title: 'Người chi trả',
      icon: Icons.groups_2_outlined,
      children: [
        const Text(
          'Khoản chi được phân bổ cho',
          style: TextStyle(fontSize: 11.5, color: AppColors.costTextMuted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPayerChip(
              label: 'Cả nhóm',
              selected: _wholeGroup,
              onSelected: (value) {
                if (!value) return;
                setState(() {
                  _wholeGroup = true;
                  _chargedTo.clear();
                });
              },
            ),
            ...widget.members.map((member) {
              final selected = !_wholeGroup && _chargedTo.contains(member.id);
              return _buildPayerChip(
                label: member.fullName.isNotEmpty
                    ? member.fullName
                    : 'Thành viên',
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    _wholeGroup = false;
                    if (value) {
                      _chargedTo.add(member.id);
                    } else {
                      _chargedTo.remove(member.id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPayerChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      avatar: Icon(
        selected ? Icons.check_rounded : Icons.person_outline_rounded,
        size: 15,
        color: selected ? AppColors.premiumNavy : AppColors.costTextMuted,
      ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.costSoftMint,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.costMint : AppColors.premiumBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.premiumNavy : AppColors.costTextMuted,
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.costSoftDanger,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.costDanger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.costDanger,
              ),
            ),
          ),
        ],
      ),
    );
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
      case CostType.transportAdjustment:
        return Icons.local_gas_station_outlined;
      case CostType.priceAdjustment:
        return Icons.price_change_outlined;
      case CostType.baselinePlan:
        return Icons.route_outlined;
      case CostType.other:
        return Icons.receipt_long_outlined;
    }
  }
}
