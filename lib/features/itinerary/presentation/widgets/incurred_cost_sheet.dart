import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
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
    final effectiveInput =
        (!_needsSharedGroupAmount && _amountIsPerPerson)
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: widget.isPriceEdit ? 0.4 : 0.62,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: widget.isPriceEdit
                  ? _buildPriceEditContent()
                  : _buildFullFormContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }

  List<Widget> _buildPriceEditContent() {
    return [
      _buildDragHandle(),
      const Text(
        'Sửa giá địa điểm',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        widget.initialPlaceName ?? '',
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Giá mới (VNĐ)',
          helperText: 'Tối thiểu 1.000đ, làm tròn đến đơn vị nghìn',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Cập nhật thẳng vào "Chi phí kế hoạch" của địa điểm này — áp dụng cho cả nhóm, không gán riêng cho ai.',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
      const SizedBox(height: 20),
      _buildSubmitButton(label: 'Lưu giá mới'),
    ];
  }

  List<Widget> _buildFullFormContent() {
    return [
      _buildDragHandle(),
      Text(
        _isEditing ? 'Sửa chi phí phát sinh' : 'Thêm chi phí phát sinh',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      const Text('Loại chi phí', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        // "Chi phí kế hoạch" hệ thống tự ghi, "Điều chỉnh giá" giờ sửa qua
        // showPriceEdit() — cả 2 không xuất hiện trong form thêm chung này.
        children: CostType.values
            .where(
              (t) =>
                  t != CostType.baselinePlan && t != CostType.priceAdjustment,
            )
            .where((t) => t != CostType.transportAdjustment || widget.isOwner)
            .map(
              (t) => ChoiceChip(
                label: Text(t.label),
                selected: _type == t,
                // Không cho đổi type khi đang sửa — tránh phải xử lý lại
                // logic charged_to/place giữa chừng.
                onSelected: _isEditing
                    ? null
                    : (value) {
                        if (!value) return;
                        setState(() {
                          _type = t;
                          if (t == CostType.transportAdjustment) {
                            _chargedTo.clear();
                            _selectedPlaceId = null;
                            _selectedDayNumber = null;
                          }
                        });
                      },
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          labelText: 'Nội dung/ghi chú',
          hintText: 'VD: Gửi xe máy, ăn vặt dọc đường...',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 12),
      if (_isTransportAdjustment)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Áp dụng cho cả chuyến đi (không phải riêng ngày hay địa điểm nào).',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        )
      else ...[
        if (_loadingPlaces)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else
          DropdownButtonFormField<String?>(
            initialValue: _selectedPlaceId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Địa điểm (tuỳ chọn)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Không gắn địa điểm cụ thể'),
              ),
              ..._places.map(
                (p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _selectedPlaceId = value;
              // Chỉ gắn theo địa điểm HOẶC theo ngày, không cả hai.
              if (value != null) _selectedDayNumber = null;
            }),
          ),
        if (widget.days.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _selectedDayNumber,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Ngày (tuỳ chọn, nếu không gắn địa điểm)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Không gắn ngày cụ thể'),
              ),
              ...widget.days.map(
                (d) => DropdownMenuItem<int?>(
                  value: d.dayNumber,
                  child: Text('Ngày ${d.dayNumber}'),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _selectedDayNumber = value;
              if (value != null) _selectedPlaceId = null;
            }),
          ),
        ],
      ],
      const SizedBox(height: 12),
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: _isTransportAdjustment
              ? 'Chi phí xăng xe đã chi (VNĐ, cả nhóm)'
              : _amountIsPerPerson
                  ? 'Số tiền / người (VNĐ)'
                  : 'Tổng số tiền phát sinh (VNĐ)',
          helperText: _isTransportAdjustment
              ? 'Nhập tổng cộng cho cả nhóm. Có thể nhập số âm nếu cần đính chính lại số đã ghi trước đó.'
              : 'Tối thiểu 1.000đ, làm tròn đến đơn vị nghìn',
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (_needsSharedGroupAmount) ...[
        Text(
          _isEditingPriceAdjustment
              ? 'Điều chỉnh giá áp dụng cho cả nhóm, không gán riêng cho ai.'
              : 'Số tiền trên là TỔNG cho cả nhóm, sẽ được chia đều cho mọi người (kể cả trẻ em).',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        if (_isTransportAdjustment && _perPersonPreviewText() != null) ...[
          const SizedBox(height: 4),
          Text(
            _perPersonPreviewText()!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ] else ...[
        // Số tiền nhập là TỔNG đã chi thật hay giá TÍNH TRÊN MỖI NGƯỜI (hệ
        // thống tự nhân ra tổng lúc lưu) — làm rõ để khỏi phải đoán ý nghĩa
        // con số, đúng góp ý đã nhận: nhập "5.000" có thể là tổng 1 chai nước
        // hoặc 5.000/người nếu mỗi người 1 chai.
        const Text('Số tiền nhập là', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tổng cộng'),
              selected: !_amountIsPerPerson,
              onSelected: (_) => setState(() => _amountIsPerPerson = false),
            ),
            ChoiceChip(
              label: const Text('Mỗi người'),
              selected: _amountIsPerPerson,
              onSelected: (_) => setState(() => _amountIsPerPerson = true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Người chi trả',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "Cả nhóm" loại trừ với chọn thành viên cụ thể — chọn cái này sẽ
            // bỏ hết lựa chọn thành viên, và ngược lại. Rõ ràng hơn hẳn so
            // với "để trống = cả nhóm" trước đây (dễ hiểu nhầm).
            ChoiceChip(
              label: const Text('Cả nhóm'),
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
              return FilterChip(
                label: Text(
                  member.fullName.isNotEmpty ? member.fullName : 'Thành viên',
                ),
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
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
      const SizedBox(height: 20),
      _buildSubmitButton(label: _isEditing ? 'Lưu thay đổi' : 'Thêm chi phí'),
    ];
  }
}
