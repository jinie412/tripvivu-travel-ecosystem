// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlaceEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;

  /// Create a copy of PlaceEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaceEntityCopyWith<PlaceEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaceEntityCopyWith<$Res> {
  factory $PlaceEntityCopyWith(
    PlaceEntity value,
    $Res Function(PlaceEntity) then,
  ) = _$PlaceEntityCopyWithImpl<$Res, PlaceEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String imageUrl,
    double rating,
    String district,
    String city,
  });
}

/// @nodoc
class _$PlaceEntityCopyWithImpl<$Res, $Val extends PlaceEntity>
    implements $PlaceEntityCopyWith<$Res> {
  _$PlaceEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaceEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageUrl = null,
    Object? rating = null,
    Object? district = null,
    Object? city = null,
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
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            district: null == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaceEntityImplCopyWith<$Res>
    implements $PlaceEntityCopyWith<$Res> {
  factory _$$PlaceEntityImplCopyWith(
    _$PlaceEntityImpl value,
    $Res Function(_$PlaceEntityImpl) then,
  ) = __$$PlaceEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String imageUrl,
    double rating,
    String district,
    String city,
  });
}

/// @nodoc
class __$$PlaceEntityImplCopyWithImpl<$Res>
    extends _$PlaceEntityCopyWithImpl<$Res, _$PlaceEntityImpl>
    implements _$$PlaceEntityImplCopyWith<$Res> {
  __$$PlaceEntityImplCopyWithImpl(
    _$PlaceEntityImpl _value,
    $Res Function(_$PlaceEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaceEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageUrl = null,
    Object? rating = null,
    Object? district = null,
    Object? city = null,
  }) {
    return _then(
      _$PlaceEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        district: null == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PlaceEntityImpl implements _PlaceEntity {
  const _$PlaceEntityImpl({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.district,
    required this.city,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String imageUrl;
  @override
  final double rating;
  @override
  final String district;
  @override
  final String city;

  @override
  String toString() {
    return 'PlaceEntity(id: $id, name: $name, imageUrl: $imageUrl, rating: $rating, district: $district, city: $city)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.city, city) || other.city == city));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, imageUrl, rating, district, city);

  /// Create a copy of PlaceEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceEntityImplCopyWith<_$PlaceEntityImpl> get copyWith =>
      __$$PlaceEntityImplCopyWithImpl<_$PlaceEntityImpl>(this, _$identity);
}

abstract class _PlaceEntity implements PlaceEntity {
  const factory _PlaceEntity({
    required final String id,
    required final String name,
    required final String imageUrl,
    required final double rating,
    required final String district,
    required final String city,
  }) = _$PlaceEntityImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get imageUrl;
  @override
  double get rating;
  @override
  String get district;
  @override
  String get city;

  /// Create a copy of PlaceEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaceEntityImplCopyWith<_$PlaceEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
