// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_review_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ItineraryReviewEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get dateRange => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<LocationReviewEntity> get locations =>
      throw _privateConstructorUsedError;

  /// Create a copy of ItineraryReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryReviewEntityCopyWith<ItineraryReviewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryReviewEntityCopyWith<$Res> {
  factory $ItineraryReviewEntityCopyWith(
    ItineraryReviewEntity value,
    $Res Function(ItineraryReviewEntity) then,
  ) = _$ItineraryReviewEntityCopyWithImpl<$Res, ItineraryReviewEntity>;
  @useResult
  $Res call({
    String id,
    String title,
    String imageUrl,
    String dateRange,
    String status,
    List<LocationReviewEntity> locations,
  });
}

/// @nodoc
class _$ItineraryReviewEntityCopyWithImpl<
  $Res,
  $Val extends ItineraryReviewEntity
>
    implements $ItineraryReviewEntityCopyWith<$Res> {
  _$ItineraryReviewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? imageUrl = null,
    Object? dateRange = null,
    Object? status = null,
    Object? locations = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            dateRange: null == dateRange
                ? _value.dateRange
                : dateRange // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            locations: null == locations
                ? _value.locations
                : locations // ignore: cast_nullable_to_non_nullable
                      as List<LocationReviewEntity>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItineraryReviewEntityImplCopyWith<$Res>
    implements $ItineraryReviewEntityCopyWith<$Res> {
  factory _$$ItineraryReviewEntityImplCopyWith(
    _$ItineraryReviewEntityImpl value,
    $Res Function(_$ItineraryReviewEntityImpl) then,
  ) = __$$ItineraryReviewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String imageUrl,
    String dateRange,
    String status,
    List<LocationReviewEntity> locations,
  });
}

/// @nodoc
class __$$ItineraryReviewEntityImplCopyWithImpl<$Res>
    extends
        _$ItineraryReviewEntityCopyWithImpl<$Res, _$ItineraryReviewEntityImpl>
    implements _$$ItineraryReviewEntityImplCopyWith<$Res> {
  __$$ItineraryReviewEntityImplCopyWithImpl(
    _$ItineraryReviewEntityImpl _value,
    $Res Function(_$ItineraryReviewEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItineraryReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? imageUrl = null,
    Object? dateRange = null,
    Object? status = null,
    Object? locations = null,
  }) {
    return _then(
      _$ItineraryReviewEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        dateRange: null == dateRange
            ? _value.dateRange
            : dateRange // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        locations: null == locations
            ? _value._locations
            : locations // ignore: cast_nullable_to_non_nullable
                  as List<LocationReviewEntity>,
      ),
    );
  }
}

/// @nodoc

class _$ItineraryReviewEntityImpl implements _ItineraryReviewEntity {
  const _$ItineraryReviewEntityImpl({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.dateRange,
    required this.status,
    required final List<LocationReviewEntity> locations,
  }) : _locations = locations;

  @override
  final String id;
  @override
  final String title;
  @override
  final String imageUrl;
  @override
  final String dateRange;
  @override
  final String status;
  final List<LocationReviewEntity> _locations;
  @override
  List<LocationReviewEntity> get locations {
    if (_locations is EqualUnmodifiableListView) return _locations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_locations);
  }

  @override
  String toString() {
    return 'ItineraryReviewEntity(id: $id, title: $title, imageUrl: $imageUrl, dateRange: $dateRange, status: $status, locations: $locations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryReviewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._locations,
              _locations,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    imageUrl,
    dateRange,
    status,
    const DeepCollectionEquality().hash(_locations),
  );

  /// Create a copy of ItineraryReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryReviewEntityImplCopyWith<_$ItineraryReviewEntityImpl>
  get copyWith =>
      __$$ItineraryReviewEntityImplCopyWithImpl<_$ItineraryReviewEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _ItineraryReviewEntity implements ItineraryReviewEntity {
  const factory _ItineraryReviewEntity({
    required final String id,
    required final String title,
    required final String imageUrl,
    required final String dateRange,
    required final String status,
    required final List<LocationReviewEntity> locations,
  }) = _$ItineraryReviewEntityImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get imageUrl;
  @override
  String get dateRange;
  @override
  String get status;
  @override
  List<LocationReviewEntity> get locations;

  /// Create a copy of ItineraryReviewEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryReviewEntityImplCopyWith<_$ItineraryReviewEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
