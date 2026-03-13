// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_review_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ItineraryReviewModel _$ItineraryReviewModelFromJson(Map<String, dynamic> json) {
  return _ItineraryReviewModel.fromJson(json);
}

/// @nodoc
mixin _$ItineraryReviewModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get dateRange => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<LocationReviewModel> get locations => throw _privateConstructorUsedError;

  /// Serializes this ItineraryReviewModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryReviewModelCopyWith<ItineraryReviewModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryReviewModelCopyWith<$Res> {
  factory $ItineraryReviewModelCopyWith(
    ItineraryReviewModel value,
    $Res Function(ItineraryReviewModel) then,
  ) = _$ItineraryReviewModelCopyWithImpl<$Res, ItineraryReviewModel>;
  @useResult
  $Res call({
    String id,
    String title,
    String imageUrl,
    String dateRange,
    String status,
    List<LocationReviewModel> locations,
  });
}

/// @nodoc
class _$ItineraryReviewModelCopyWithImpl<
  $Res,
  $Val extends ItineraryReviewModel
>
    implements $ItineraryReviewModelCopyWith<$Res> {
  _$ItineraryReviewModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryReviewModel
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
                      as List<LocationReviewModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItineraryReviewModelImplCopyWith<$Res>
    implements $ItineraryReviewModelCopyWith<$Res> {
  factory _$$ItineraryReviewModelImplCopyWith(
    _$ItineraryReviewModelImpl value,
    $Res Function(_$ItineraryReviewModelImpl) then,
  ) = __$$ItineraryReviewModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String imageUrl,
    String dateRange,
    String status,
    List<LocationReviewModel> locations,
  });
}

/// @nodoc
class __$$ItineraryReviewModelImplCopyWithImpl<$Res>
    extends _$ItineraryReviewModelCopyWithImpl<$Res, _$ItineraryReviewModelImpl>
    implements _$$ItineraryReviewModelImplCopyWith<$Res> {
  __$$ItineraryReviewModelImplCopyWithImpl(
    _$ItineraryReviewModelImpl _value,
    $Res Function(_$ItineraryReviewModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItineraryReviewModel
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
      _$ItineraryReviewModelImpl(
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
                  as List<LocationReviewModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryReviewModelImpl extends _ItineraryReviewModel {
  const _$ItineraryReviewModelImpl({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.dateRange,
    required this.status,
    required final List<LocationReviewModel> locations,
  }) : _locations = locations,
       super._();

  factory _$ItineraryReviewModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryReviewModelImplFromJson(json);

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
  final List<LocationReviewModel> _locations;
  @override
  List<LocationReviewModel> get locations {
    if (_locations is EqualUnmodifiableListView) return _locations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_locations);
  }

  @override
  String toString() {
    return 'ItineraryReviewModel(id: $id, title: $title, imageUrl: $imageUrl, dateRange: $dateRange, status: $status, locations: $locations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryReviewModelImpl &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of ItineraryReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryReviewModelImplCopyWith<_$ItineraryReviewModelImpl>
  get copyWith =>
      __$$ItineraryReviewModelImplCopyWithImpl<_$ItineraryReviewModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryReviewModelImplToJson(this);
  }
}

abstract class _ItineraryReviewModel extends ItineraryReviewModel {
  const factory _ItineraryReviewModel({
    required final String id,
    required final String title,
    required final String imageUrl,
    required final String dateRange,
    required final String status,
    required final List<LocationReviewModel> locations,
  }) = _$ItineraryReviewModelImpl;
  const _ItineraryReviewModel._() : super._();

  factory _ItineraryReviewModel.fromJson(Map<String, dynamic> json) =
      _$ItineraryReviewModelImpl.fromJson;

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
  List<LocationReviewModel> get locations;

  /// Create a copy of ItineraryReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryReviewModelImplCopyWith<_$ItineraryReviewModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
