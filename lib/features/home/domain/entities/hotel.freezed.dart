// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hotel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Hotel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  String get price => throw _privateConstructorUsedError;
  String get priceUnit => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  int get placeholderColor => throw _privateConstructorUsedError;

  /// Create a copy of Hotel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HotelCopyWith<Hotel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HotelCopyWith<$Res> {
  factory $HotelCopyWith(Hotel value, $Res Function(Hotel) then) =
      _$HotelCopyWithImpl<$Res, Hotel>;
  @useResult
  $Res call({
    String id,
    String name,
    double rating,
    String price,
    String priceUnit,
    String? imageUrl,
    int placeholderColor,
  });
}

/// @nodoc
class _$HotelCopyWithImpl<$Res, $Val extends Hotel>
    implements $HotelCopyWith<$Res> {
  _$HotelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hotel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? rating = null,
    Object? price = null,
    Object? priceUnit = null,
    Object? imageUrl = freezed,
    Object? placeholderColor = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as String,
            priceUnit: null == priceUnit
                ? _value.priceUnit
                : priceUnit // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            placeholderColor: null == placeholderColor
                ? _value.placeholderColor
                : placeholderColor // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HotelImplCopyWith<$Res> implements $HotelCopyWith<$Res> {
  factory _$$HotelImplCopyWith(
    _$HotelImpl value,
    $Res Function(_$HotelImpl) then,
  ) = __$$HotelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double rating,
    String price,
    String priceUnit,
    String? imageUrl,
    int placeholderColor,
  });
}

/// @nodoc
class __$$HotelImplCopyWithImpl<$Res>
    extends _$HotelCopyWithImpl<$Res, _$HotelImpl>
    implements _$$HotelImplCopyWith<$Res> {
  __$$HotelImplCopyWithImpl(
    _$HotelImpl _value,
    $Res Function(_$HotelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Hotel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? rating = null,
    Object? price = null,
    Object? priceUnit = null,
    Object? imageUrl = freezed,
    Object? placeholderColor = null,
  }) {
    return _then(
      _$HotelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as String,
        priceUnit: null == priceUnit
            ? _value.priceUnit
            : priceUnit // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        placeholderColor: null == placeholderColor
            ? _value.placeholderColor
            : placeholderColor // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$HotelImpl implements _Hotel {
  const _$HotelImpl({
    required this.id,
    required this.name,
    required this.rating,
    required this.price,
    this.priceUnit = '1 đêm',
    this.imageUrl,
    this.placeholderColor = 0xFFD4C5B0,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final double rating;
  @override
  final String price;
  @override
  @JsonKey()
  final String priceUnit;
  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final int placeholderColor;

  @override
  String toString() {
    return 'Hotel(id: $id, name: $name, rating: $rating, price: $price, priceUnit: $priceUnit, imageUrl: $imageUrl, placeholderColor: $placeholderColor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HotelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.priceUnit, priceUnit) ||
                other.priceUnit == priceUnit) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.placeholderColor, placeholderColor) ||
                other.placeholderColor == placeholderColor));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    rating,
    price,
    priceUnit,
    imageUrl,
    placeholderColor,
  );

  /// Create a copy of Hotel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HotelImplCopyWith<_$HotelImpl> get copyWith =>
      __$$HotelImplCopyWithImpl<_$HotelImpl>(this, _$identity);
}

abstract class _Hotel implements Hotel {
  const factory _Hotel({
    required final String id,
    required final String name,
    required final double rating,
    required final String price,
    final String priceUnit,
    final String? imageUrl,
    final int placeholderColor,
  }) = _$HotelImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  double get rating;
  @override
  String get price;
  @override
  String get priceUnit;
  @override
  String? get imageUrl;
  @override
  int get placeholderColor;

  /// Create a copy of Hotel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HotelImplCopyWith<_$HotelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
