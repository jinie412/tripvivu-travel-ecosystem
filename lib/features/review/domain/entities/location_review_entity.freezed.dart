// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_review_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LocationReviewEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  int get day => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  String? get reviewText => throw _privateConstructorUsedError;
  List<String>? get reviewTags => throw _privateConstructorUsedError;
  List<String>? get mediaPaths => throw _privateConstructorUsedError;

  /// Create a copy of LocationReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocationReviewEntityCopyWith<LocationReviewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationReviewEntityCopyWith<$Res> {
  factory $LocationReviewEntityCopyWith(
    LocationReviewEntity value,
    $Res Function(LocationReviewEntity) then,
  ) = _$LocationReviewEntityCopyWithImpl<$Res, LocationReviewEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String imageUrl,
    int day,
    double? rating,
    String? reviewText,
    List<String>? reviewTags,
    List<String>? mediaPaths,
  });
}

/// @nodoc
class _$LocationReviewEntityCopyWithImpl<
  $Res,
  $Val extends LocationReviewEntity
>
    implements $LocationReviewEntityCopyWith<$Res> {
  _$LocationReviewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocationReviewEntity
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
    Object? reviewTags = freezed,
    Object? mediaPaths = freezed,
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
            reviewTags: freezed == reviewTags
                ? _value.reviewTags
                : reviewTags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            mediaPaths: freezed == mediaPaths
                ? _value.mediaPaths
                : mediaPaths // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocationReviewEntityImplCopyWith<$Res>
    implements $LocationReviewEntityCopyWith<$Res> {
  factory _$$LocationReviewEntityImplCopyWith(
    _$LocationReviewEntityImpl value,
    $Res Function(_$LocationReviewEntityImpl) then,
  ) = __$$LocationReviewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String imageUrl,
    int day,
    double? rating,
    String? reviewText,
    List<String>? reviewTags,
    List<String>? mediaPaths,
  });
}

/// @nodoc
class __$$LocationReviewEntityImplCopyWithImpl<$Res>
    extends _$LocationReviewEntityCopyWithImpl<$Res, _$LocationReviewEntityImpl>
    implements _$$LocationReviewEntityImplCopyWith<$Res> {
  __$$LocationReviewEntityImplCopyWithImpl(
    _$LocationReviewEntityImpl _value,
    $Res Function(_$LocationReviewEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationReviewEntity
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
    Object? reviewTags = freezed,
    Object? mediaPaths = freezed,
  }) {
    return _then(
      _$LocationReviewEntityImpl(
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
        reviewTags: freezed == reviewTags
            ? _value._reviewTags
            : reviewTags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        mediaPaths: freezed == mediaPaths
            ? _value._mediaPaths
            : mediaPaths // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc

class _$LocationReviewEntityImpl implements _LocationReviewEntity {
  const _$LocationReviewEntityImpl({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.day,
    this.rating,
    this.reviewText,
    final List<String>? reviewTags,
    final List<String>? mediaPaths,
  }) : _reviewTags = reviewTags,
       _mediaPaths = mediaPaths;

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
  final List<String>? _reviewTags;
  @override
  List<String>? get reviewTags {
    final value = _reviewTags;
    if (value == null) return null;
    if (_reviewTags is EqualUnmodifiableListView) return _reviewTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _mediaPaths;
  @override
  List<String>? get mediaPaths {
    final value = _mediaPaths;
    if (value == null) return null;
    if (_mediaPaths is EqualUnmodifiableListView) return _mediaPaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'LocationReviewEntity(id: $id, name: $name, imageUrl: $imageUrl, day: $day, rating: $rating, reviewText: $reviewText, reviewTags: $reviewTags, mediaPaths: $mediaPaths)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationReviewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewText, reviewText) ||
                other.reviewText == reviewText) &&
            const DeepCollectionEquality().equals(
              other._reviewTags,
              _reviewTags,
            ) &&
            const DeepCollectionEquality().equals(
              other._mediaPaths,
              _mediaPaths,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    imageUrl,
    day,
    rating,
    reviewText,
    const DeepCollectionEquality().hash(_reviewTags),
    const DeepCollectionEquality().hash(_mediaPaths),
  );

  /// Create a copy of LocationReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationReviewEntityImplCopyWith<_$LocationReviewEntityImpl>
  get copyWith =>
      __$$LocationReviewEntityImplCopyWithImpl<_$LocationReviewEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _LocationReviewEntity implements LocationReviewEntity {
  const factory _LocationReviewEntity({
    required final String id,
    required final String name,
    required final String imageUrl,
    required final int day,
    final double? rating,
    final String? reviewText,
    final List<String>? reviewTags,
    final List<String>? mediaPaths,
  }) = _$LocationReviewEntityImpl;

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
  @override
  List<String>? get reviewTags;
  @override
  List<String>? get mediaPaths;

  /// Create a copy of LocationReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationReviewEntityImplCopyWith<_$LocationReviewEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
