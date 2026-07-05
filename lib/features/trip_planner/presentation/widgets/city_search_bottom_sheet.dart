import 'dart:async';

import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city/domain/entities/city_entity.dart';
import 'package:travel_advisor_mobile/features/city/domain/usecases/search_cities_usecase.dart';

/// Bottom sheet cho phép user tìm kiếm thành phố với debounce.
/// Trả về [CityEntity] được chọn qua [Navigator.pop].
class CitySearchBottomSheet extends StatefulWidget {
  final SearchCitiesUseCase searchCitiesUseCase;
  final String title;

  /// Khi true: chỉ cho chọn trong danh sách tỉnh/thành app đang hỗ trợ lên
  /// lịch trình (dùng cho ô "điểm đến"). Khi false: tìm kiếm tự do trên toàn
  /// bộ tỉnh/thành (dùng cho ô "điểm khởi hành").
  final bool destinationOnly;

  const CitySearchBottomSheet({
    super.key,
    required this.searchCitiesUseCase,
    required this.title,
    this.destinationOnly = false,
  });

  static Future<CityEntity?> show(
    BuildContext context, {
    required SearchCitiesUseCase searchCitiesUseCase,
    required String title,
    bool destinationOnly = false,
  }) {
    return showModalBottomSheet<CityEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CitySearchBottomSheet(
        searchCitiesUseCase: searchCitiesUseCase,
        title: title,
        destinationOnly: destinationOnly,
      ),
    );
  }

  @override
  State<CitySearchBottomSheet> createState() => _CitySearchBottomSheetState();
}

class _CitySearchBottomSheetState extends State<CitySearchBottomSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<CityEntity> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search(''); // load toàn bộ thành phố khi mở
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.searchCitiesUseCase(
        query,
        destinationOnly: widget.destinationOnly,
      );
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể tải danh sách thành phố');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (widget.destinationOnly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'App hiện chỉ hỗ trợ lên lịch trình cho các tỉnh/thành phổ biến dưới đây. '
                        'Các điểm đến khác sẽ sớm được bổ sung.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: widget.destinationOnly ? 'Tìm trong các tỉnh/thành hỗ trợ...' : 'Tìm thành phố...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Results
          Expanded(
            child: _buildBody(),
          ),

          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.destinationOnly
                ? 'Không tìm thấy tỉnh/thành phù hợp trong danh sách app đang hỗ trợ'
                : 'Không tìm thấy thành phố',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final city = _results[index];
        return ListTile(
          leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
          title: Text(
            city.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          onTap: () => Navigator.of(context).pop(city),
        );
      },
    );
  }
}
