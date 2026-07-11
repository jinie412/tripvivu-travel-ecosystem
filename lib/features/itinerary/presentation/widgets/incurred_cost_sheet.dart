import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

/// Bottom sheet dùng chung để thêm/sửa 1 khoản chi phí phát sinh (mục 1.6),
/// dùng ở màn "Quản lý chi phí" tổng hợp.
///
/// 2 loại chi phí khác nhau (xem [CostType]): [CostType.priceAdjustment]
/// (chỉ chủ lịch trình, bắt buộc gắn 1 địa điểm, nhập giá MỚI thay vì số
/// tiền — sheet tự tính chênh lệch so với giá hiện tại) và các type còn lại
/// (chi phí phát sinh cá nhân, ai cũng tạo được, nhập thẳng số tiền).
class IncurredCostSheet extends StatefulWidget {
  final String itineraryId;
  final List<ItineraryMemberEntity> members;
  final bool isOwner;
  final String? initialPlaceId;
  final String? initialPlaceName;
  final IncurredCostEntity? editingCost;
  final VoidCallback? onSaved;

  const IncurredCostSheet({
    super.key,
    required this.itineraryId,
    required this.members,
    required this.isOwner,
    this.initialPlaceId,
    this.initialPlaceName,
    this.editingCost,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String itineraryId,
    required List<ItineraryMemberEntity> members,
    required bool isOwner,
    String? initialPlaceId,
    String? initialPlaceName,
    IncurredCostEntity? editingCost,
    VoidCallback? onSaved,
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
        editingCost: editingCost,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<IncurredCostSheet> createState() => _IncurredCostSheetState();
}

class _IncurredCostSheetState extends State<IncurredCostSheet> {
  final _repository = sl<ItineraryRepository>();
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;

  List<EligiblePlaceEntity> _places = [];
  bool _loadingPlaces = true;
  String? _selectedPlaceId;
  final Set<String> _chargedTo = {};
  late CostType _type;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.editingCost != null;
  bool get _isPriceAdjustment => _type == CostType.priceAdjustment;

  EligiblePlaceEntity? get _selectedPlace => _selectedPlaceId == null
      ? null
      : _places.where((p) => p.id == _selectedPlaceId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingCost;
    _type = editing?.type ?? CostType.other;
    _noteController = TextEditingController(text: editing?.note ?? '');
    _amountController = TextEditingController(
      text: editing != null && !_isPriceAdjustment
          ? editing.amount.toStringAsFixed(0)
          : '',
    );
    _selectedPlaceId = editing?.placeId ?? widget.initialPlaceId;
    _chargedTo.addAll(editing?.chargedTo ?? const []);
    _loadPlaces();
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
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    final rawInput = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    if (note.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung/ghi chú');
      return;
    }
    if (_isPriceAdjustment && _selectedPlaceId == null) {
      setState(() => _error = 'Điều chỉnh giá phải gắn với 1 địa điểm');
      return;
    }
    if (rawInput == null) {
      setState(
        () => _error = _isPriceAdjustment && !_isEditing
            ? 'Vui lòng nhập giá mới hợp lệ'
            : 'Vui lòng nhập số tiền hợp lệ',
      );
      return;
    }
    if (!_isPriceAdjustment && rawInput <= 0) {
      setState(() => _error = 'Vui lòng nhập số tiền hợp lệ');
      return;
    }
    // Khi tạo mới điều chỉnh giá, người dùng nhập GIÁ MỚI (không phải chênh
    // lệch) — sheet tự trừ giá hiện tại để ra amount (delta) gửi lên API.
    // Khi sửa 1 điều chỉnh giá đã có, giữ nguyên số đang nhập là delta trực
    // tiếp (tránh phải cộng/trừ ngược qua các lần sửa trước đó).
    final rawAmount =
        _isPriceAdjustment && !_isEditing
            ? rawInput - (_selectedPlace?.currentEffectivePrice ?? 0)
            : rawInput;
    // Server làm tròn đến nghìn và bắt buộc tối thiểu 1.000đ — validate sớm
    // ở đây để báo lỗi ngay, tránh round-trip lên server mới biết.
    final amount = (rawAmount / 1000).round() * 1000.0;
    if (amount.abs() < 1000) {
      setState(() => _error = 'Số tiền phải từ 1.000đ trở lên');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await _repository.updateIncurredCost(
          widget.itineraryId,
          widget.editingCost!.id,
          type: _type,
          note: note,
          amount: amount,
          placeId: _selectedPlaceId,
          chargedTo: _isPriceAdjustment ? const [] : _chargedTo.toList(),
        );
      } else {
        await _repository.createIncurredCost(
          widget.itineraryId,
          type: _type,
          note: note,
          amount: amount,
          placeId: _selectedPlaceId,
          chargedTo: _isPriceAdjustment ? const [] : _chargedTo.toList(),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
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
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _isEditing
                      ? 'Sửa chi phí phát sinh'
                      : 'Thêm chi phí phát sinh',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loại chi phí',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CostType.values
                      .where(
                        (t) =>
                            t != CostType.priceAdjustment || widget.isOwner,
                      )
                      .map(
                        (t) => ChoiceChip(
                          label: Text(t.label),
                          selected: _type == t,
                          // Không cho đổi type khi đang sửa — tránh phải xử
                          // lý lại logic chênh lệch giá giữa chừng.
                          onSelected: _isEditing
                              ? null
                              : (value) {
                                  if (!value) return;
                                  setState(() {
                                    _type = t;
                                    if (t == CostType.priceAdjustment) {
                                      _chargedTo.clear();
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
                if (_loadingPlaces)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedPlaceId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _isPriceAdjustment
                          ? 'Địa điểm (bắt buộc)'
                          : 'Địa điểm (tuỳ chọn)',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      if (!_isPriceAdjustment)
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
                    onChanged: (value) => setState(() => _selectedPlaceId = value),
                  ),
                const SizedBox(height: 12),
                if (_isPriceAdjustment && !_isEditing && _selectedPlace != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Giá hiện tại: ${_selectedPlace!.currentEffectivePrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(
                    labelText: _isPriceAdjustment
                        ? (_isEditing
                              ? 'Số tiền chênh lệch (VNĐ, có thể âm)'
                              : 'Giá mới (VNĐ)')
                        : 'Số tiền phát sinh (VNĐ)',
                    helperText: 'Tối thiểu 1.000đ, làm tròn đến đơn vị nghìn',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isPriceAdjustment) ...[
                  const Text(
                    'Điều chỉnh giá áp dụng cho cả nhóm, không gán riêng cho ai.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ] else ...[
                const SizedBox(height: 4),
                const Text(
                  'Người chi trả (bỏ trống = chia đều cả nhóm)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((member) {
                    final selected = _chargedTo.contains(member.id);
                    return FilterChip(
                      label: Text(
                        member.fullName.isNotEmpty
                            ? member.fullName
                            : 'Thành viên',
                      ),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _chargedTo.add(member.id);
                          } else {
                            _chargedTo.remove(member.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
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
                        : Text(_isEditing ? 'Lưu thay đổi' : 'Thêm chi phí'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
