// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_review_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlaceReviewEntity {
  String get id => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String get userAvatar => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  String get timeAgo => throw _privateConstructorUsedError;
  String get reviewText => throw _privateConstructorUsedError;
  List<String> get reviewImages => throw _privateConstructorUsedError;

  /// Create a copy of PlaceReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaceReviewEntityCopyWith<PlaceReviewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaceReviewEntityCopyWith<$Res> {
  factory $PlaceReviewEntityCopyWith(
    PlaceReviewEntity value,
    $Res Function(PlaceReviewEntity) then,
  ) = _$PlaceReviewEntityCopyWithImpl<$Res, PlaceReviewEntity>;
  @useResult
  $Res call({
    String id,
    String userName,
    String userAvatar,
    double rating,
    String timeAgo,
    String reviewText,
    List<String> reviewImages,
  });
}

/// @nodoc
class _$PlaceReviewEntityCopyWithImpl<$Res, $Val extends PlaceReviewEntity>
    implements $PlaceReviewEntityCopyWith<$Res> {
  _$PlaceReviewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaceReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userName = null,
    Object? userAvatar = null,
    Object? rating = null,
    Object? timeAgo = null,
    Object? reviewText = null,
    Object? reviewImages = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            userAvatar: null == userAvatar
                ? _value.userAvatar
                : userAvatar // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            timeAgo: null == timeAgo
                ? _value.timeAgo
                : timeAgo // ignore: cast_nullable_to_non_nullable
                      as String,
            reviewText: null == reviewText
                ? _value.reviewText
                : reviewText // ignore: cast_nullable_to_non_nullable
                      as String,
            reviewImages: null == reviewImages
                ? _value.reviewImages
                : reviewImages // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaceReviewEntityImplCopyWith<$Res>
    implements $PlaceReviewEntityCopyWith<$Res> {
  factory _$$PlaceReviewEntityImplCopyWith(
    _$PlaceReviewEntityImpl value,
    $Res Function(_$PlaceReviewEntityImpl) then,
  ) = __$$PlaceReviewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userName,
    String userAvatar,
    double rating,
    String timeAgo,
    String reviewText,
    List<String> reviewImages,
  });
}

/// @nodoc
class __$$PlaceReviewEntityImplCopyWithImpl<$Res>
    extends _$PlaceReviewEntityCopyWithImpl<$Res, _$PlaceReviewEntityImpl>
    implements _$$PlaceReviewEntityImplCopyWith<$Res> {
  __$$PlaceReviewEntityImplCopyWithImpl(
    _$PlaceReviewEntityImpl _value,
    $Res Function(_$PlaceReviewEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaceReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userName = null,
    Object? userAvatar = null,
    Object? rating = null,
    Object? timeAgo = null,
    Object? reviewText = null,
    Object? reviewImages = null,
  }) {
    return _then(
      _$PlaceReviewEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        userAvatar: null == userAvatar
            ? _value.userAvatar
            : userAvatar // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        timeAgo: null == timeAgo
            ? _value.timeAgo
            : timeAgo // ignore: cast_nullable_to_non_nullable
                  as String,
        reviewText: null == reviewText
            ? _value.reviewText
            : reviewText // ignore: cast_nullable_to_non_nullable
                  as String,
        reviewImages: null == reviewImages
            ? _value._reviewImages
            : reviewImages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$PlaceReviewEntityImpl implements _PlaceReviewEntity {
  const _$PlaceReviewEntityImpl({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.timeAgo,
    required this.reviewText,
    final List<String> reviewImages = const [],
  }) : _reviewImages = reviewImages;

  @override
  final String id;
  @override
  final String userName;
  @override
  final String userAvatar;
  @override
  final double rating;
  @override
  final String timeAgo;
  @override
  final String reviewText;
  final List<String> _reviewImages;
  @override
  @JsonKey()
  List<String> get reviewImages {
    if (_reviewImages is EqualUnmodifiableListView) return _reviewImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reviewImages);
  }

  @override
  String toString() {
    return 'PlaceReviewEntity(id: $id, userName: $userName, userAvatar: $userAvatar, rating: $rating, timeAgo: $timeAgo, reviewText: $reviewText, reviewImages: $reviewImages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceReviewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.timeAgo, timeAgo) || other.timeAgo == timeAgo) &&
            (identical(other.reviewText, reviewText) ||
                other.reviewText == reviewText) &&
            const DeepCollectionEquality().equals(
              other._reviewImages,
              _reviewImages,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userName,
    userAvatar,
    rating,
    timeAgo,
    reviewText,
    const DeepCollectionEquality().hash(_reviewImages),
  );

  /// Create a copy of PlaceReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceReviewEntityImplCopyWith<_$PlaceReviewEntityImpl> get copyWith =>
      __$$PlaceReviewEntityImplCopyWithImpl<_$PlaceReviewEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _PlaceReviewEntity implements PlaceReviewEntity {
  const factory _PlaceReviewEntity({
    required final String id,
    required final String userName,
    required final String userAvatar,
    required final double rating,
    required final String timeAgo,
    required final String reviewText,
    final List<String> reviewImages,
  }) = _$PlaceReviewEntityImpl;

  @override
  String get id;
  @override
  String get userName;
  @override
  String get userAvatar;
  @override
  double get rating;
  @override
  String get timeAgo;
  @override
  String get reviewText;
  @override
  List<String> get reviewImages;

  /// Create a copy of PlaceReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaceReviewEntityImplCopyWith<_$PlaceReviewEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
