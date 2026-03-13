// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_review_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LocationReviewModel _$LocationReviewModelFromJson(Map<String, dynamic> json) {
  return _LocationReviewModel.fromJson(json);
}

/// @nodoc
mixin _$LocationReviewModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  int get day => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  String? get reviewText => throw _privateConstructorUsedError;

  /// Serializes this LocationReviewModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocationReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocationReviewModelCopyWith<LocationReviewModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationReviewModelCopyWith<$Res> {
  factory $LocationReviewModelCopyWith(
    LocationReviewModel value,
    $Res Function(LocationReviewModel) then,
  ) = _$LocationReviewModelCopyWithImpl<$Res, LocationReviewModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String imageUrl,
    int day,
    double? rating,
    String? reviewText,
  });
}

/// @nodoc
class _$LocationReviewModelCopyWithImpl<$Res, $Val extends LocationReviewModel>
    implements $LocationReviewModelCopyWith<$Res> {
  _$LocationReviewModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocationReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageUrl = null,
    Object? day = null,
    Object? rating = freezed,
    Object? reviewText = freezed,
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
            day: null == day
                ? _value.day
                : day // ignore: cast_nullable_to_non_nullable
                      as int,
            rating: freezed == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double?,
            reviewText: freezed == reviewText
                ? _value.reviewText
                : reviewText // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocationReviewModelImplCopyWith<$Res>
    implements $LocationReviewModelCopyWith<$Res> {
  factory _$$LocationReviewModelImplCopyWith(
    _$LocationReviewModelImpl value,
    $Res Function(_$LocationReviewModelImpl) then,
  ) = __$$LocationReviewModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String imageUrl,
    int day,
    double? rating,
    String? reviewText,
  });
}

/// @nodoc
class __$$LocationReviewModelImplCopyWithImpl<$Res>
    extends _$LocationReviewModelCopyWithImpl<$Res, _$LocationReviewModelImpl>
    implements _$$LocationReviewModelImplCopyWith<$Res> {
  __$$LocationReviewModelImplCopyWithImpl(
    _$LocationReviewModelImpl _value,
    $Res Function(_$LocationReviewModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageUrl = null,
    Object? day = null,
    Object? rating = freezed,
    Object? reviewText = freezed,
  }) {
    return _then(
      _$LocationReviewModelImpl(
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
        day: null == day
            ? _value.day
            : day // ignore: cast_nullable_to_non_nullable
                  as int,
        rating: freezed == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double?,
        reviewText: freezed == reviewText
            ? _value.reviewText
            : reviewText // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationReviewModelImpl extends _LocationReviewModel {
  const _$LocationReviewModelImpl({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.day,
    this.rating,
    this.reviewText,
  }) : super._();

  factory _$LocationReviewModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationReviewModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String imageUrl;
  @override
  final int day;
  @override
  final double? rating;
  @override
  final String? reviewText;

  @override
  String toString() {
    return 'LocationReviewModel(id: $id, name: $name, imageUrl: $imageUrl, day: $day, rating: $rating, reviewText: $reviewText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationReviewModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewText, reviewText) ||
                other.reviewText == reviewText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, imageUrl, day, rating, reviewText);

  /// Create a copy of LocationReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationReviewModelImplCopyWith<_$LocationReviewModelImpl> get copyWith =>
      __$$LocationReviewModelImplCopyWithImpl<_$LocationReviewModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationReviewModelImplToJson(this);
  }
}

abstract class _LocationReviewModel extends LocationReviewModel {
  const factory _LocationReviewModel({
    required final String id,
    required final String name,
    required final String imageUrl,
    required final int day,
    final double? rating,
    final String? reviewText,
  }) = _$LocationReviewModelImpl;
  const _LocationReviewModel._() : super._();

  factory _LocationReviewModel.fromJson(Map<String, dynamic> json) =
      _$LocationReviewModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get imageUrl;
  @override
  int get day;
  @override
  double? get rating;
  @override
  String? get reviewText;

  /// Create a copy of LocationReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationReviewModelImplCopyWith<_$LocationReviewModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
