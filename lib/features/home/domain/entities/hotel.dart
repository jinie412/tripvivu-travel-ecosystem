import 'package:freezed_annotation/freezed_annotation.dart';

part 'hotel.freezed.dart';

@freezed
class Hotel with _$Hotel {
  const factory Hotel({
    required String id,
    required String name,
    required double rating,
    required String price,
    @Default('1 đêm') String priceUnit,
    String? imageUrl,
    @Default(0xFFD4C5B0) int placeholderColor,
  }) = _Hotel;
}