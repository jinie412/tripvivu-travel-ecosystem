// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_item_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ActivityItemEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  ActivityType get type => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  DateTime? get date => throw _privateConstructorUsedError;
  ActivityStatus get status => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;

  /// Create a copy of ActivityItemEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivityItemEntityCopyWith<ActivityItemEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityItemEntityCopyWith<$Res> {
  factory $ActivityItemEntityCopyWith(
    ActivityItemEntity value,
    $Res Function(ActivityItemEntity) then,
  ) = _$ActivityItemEntityCopyWithImpl<$Res, ActivityItemEntity>;
  @useResult
  $Res call({
    String id,
    String title,
    ActivityType type,
    double? rating,
    DateTime? date,
    ActivityStatus status,
    String? code,
  });
}

/// @nodoc
class _$ActivityItemEntityCopyWithImpl<$Res, $Val extends ActivityItemEntity>
    implements $ActivityItemEntityCopyWith<$Res> {
  _$ActivityItemEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivityItemEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? rating = freezed,
    Object? date = freezed,
    Object? status = null,
    Object? code = freezed,
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ActivityType,
            rating: freezed == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double?,
            date: freezed == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ActivityStatus,
            code: freezed == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActivityItemEntityImplCopyWith<$Res>
    implements $ActivityItemEntityCopyWith<$Res> {
  factory _$$ActivityItemEntityImplCopyWith(
    _$ActivityItemEntityImpl value,
    $Res Function(_$ActivityItemEntityImpl) then,
  ) = __$$ActivityItemEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    ActivityType type,
    double? rating,
    DateTime? date,
    ActivityStatus status,
    String? code,
  });
}

/// @nodoc
class __$$ActivityItemEntityImplCopyWithImpl<$Res>
    extends _$ActivityItemEntityCopyWithImpl<$Res, _$ActivityItemEntityImpl>
    implements _$$ActivityItemEntityImplCopyWith<$Res> {
  __$$ActivityItemEntityImplCopyWithImpl(
    _$ActivityItemEntityImpl _value,
    $Res Function(_$ActivityItemEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActivityItemEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? rating = freezed,
    Object? date = freezed,
    Object? status = null,
    Object? code = freezed,
  }) {
    return _then(
      _$ActivityItemEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ActivityType,
        rating: freezed == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double?,
        date: freezed == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ActivityStatus,
        code: freezed == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ActivityItemEntityImpl implements _ActivityItemEntity {
  const _$ActivityItemEntityImpl({
    required this.id,
    required this.title,
    required this.type,
    this.rating,
    this.date,
    this.status = ActivityStatus.none,
    this.code,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final ActivityType type;
  @override
  final double? rating;
  @override
  final DateTime? date;
  @override
  @JsonKey()
  final ActivityStatus status;
  @override
  final String? code;

  @override
  String toString() {
    return 'ActivityItemEntity(id: $id, title: $title, type: $type, rating: $rating, date: $date, status: $status, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityItemEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.code, code) || other.code == code));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, type, rating, date, status, code);

  /// Create a copy of ActivityItemEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityItemEntityImplCopyWith<_$ActivityItemEntityImpl> get copyWith =>
      __$$ActivityItemEntityImplCopyWithImpl<_$ActivityItemEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _ActivityItemEntity implements ActivityItemEntity {
  const factory _ActivityItemEntity({
    required final String id,
    required final String title,
    required final ActivityType type,
    final double? rating,
    final DateTime? date,
    final ActivityStatus status,
    final String? code,
  }) = _$ActivityItemEntityImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  ActivityType get type;
  @override
  double? get rating;
  @override
  DateTime? get date;
  @override
  ActivityStatus get status;
  @override
  String? get code;

  /// Create a copy of ActivityItemEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivityItemEntityImplCopyWith<_$ActivityItemEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
