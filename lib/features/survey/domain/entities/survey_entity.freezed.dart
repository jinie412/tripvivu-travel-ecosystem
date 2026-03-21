// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'survey_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SurveyEntity {
  int? get age => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  List<String> get interests => throw _privateConstructorUsedError;

  /// Create a copy of SurveyEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SurveyEntityCopyWith<SurveyEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurveyEntityCopyWith<$Res> {
  factory $SurveyEntityCopyWith(
    SurveyEntity value,
    $Res Function(SurveyEntity) then,
  ) = _$SurveyEntityCopyWithImpl<$Res, SurveyEntity>;
  @useResult
  $Res call({int? age, String? gender, List<String> interests});
}

/// @nodoc
class _$SurveyEntityCopyWithImpl<$Res, $Val extends SurveyEntity>
    implements $SurveyEntityCopyWith<$Res> {
  _$SurveyEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SurveyEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? age = freezed,
    Object? gender = freezed,
    Object? interests = null,
  }) {
    return _then(
      _value.copyWith(
            age: freezed == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String?,
            interests: null == interests
                ? _value.interests
                : interests // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SurveyEntityImplCopyWith<$Res>
    implements $SurveyEntityCopyWith<$Res> {
  factory _$$SurveyEntityImplCopyWith(
    _$SurveyEntityImpl value,
    $Res Function(_$SurveyEntityImpl) then,
  ) = __$$SurveyEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? age, String? gender, List<String> interests});
}

/// @nodoc
class __$$SurveyEntityImplCopyWithImpl<$Res>
    extends _$SurveyEntityCopyWithImpl<$Res, _$SurveyEntityImpl>
    implements _$$SurveyEntityImplCopyWith<$Res> {
  __$$SurveyEntityImplCopyWithImpl(
    _$SurveyEntityImpl _value,
    $Res Function(_$SurveyEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurveyEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? age = freezed,
    Object? gender = freezed,
    Object? interests = null,
  }) {
    return _then(
      _$SurveyEntityImpl(
        age: freezed == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String?,
        interests: null == interests
            ? _value._interests
            : interests // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$SurveyEntityImpl implements _SurveyEntity {
  const _$SurveyEntityImpl({
    this.age,
    this.gender,
    final List<String> interests = const [],
  }) : _interests = interests;

  @override
  final int? age;
  @override
  final String? gender;
  final List<String> _interests;
  @override
  @JsonKey()
  List<String> get interests {
    if (_interests is EqualUnmodifiableListView) return _interests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_interests);
  }

  @override
  String toString() {
    return 'SurveyEntity(age: $age, gender: $gender, interests: $interests)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurveyEntityImpl &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            const DeepCollectionEquality().equals(
              other._interests,
              _interests,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    age,
    gender,
    const DeepCollectionEquality().hash(_interests),
  );

  /// Create a copy of SurveyEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SurveyEntityImplCopyWith<_$SurveyEntityImpl> get copyWith =>
      __$$SurveyEntityImplCopyWithImpl<_$SurveyEntityImpl>(this, _$identity);
}

abstract class _SurveyEntity implements SurveyEntity {
  const factory _SurveyEntity({
    final int? age,
    final String? gender,
    final List<String> interests,
  }) = _$SurveyEntityImpl;

  @override
  int? get age;
  @override
  String? get gender;
  @override
  List<String> get interests;

  /// Create a copy of SurveyEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SurveyEntityImplCopyWith<_$SurveyEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
