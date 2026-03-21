// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'survey_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SurveyState {
  int get currentStep => throw _privateConstructorUsedError;
  SurveyEntity get data => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int currentStep, SurveyEntity data) initial,
    required TResult Function(int currentStep, SurveyEntity data) loading,
    required TResult Function(int currentStep, SurveyEntity data) success,
    required TResult Function(
      int currentStep,
      SurveyEntity data,
      String message,
    )
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int currentStep, SurveyEntity data)? initial,
    TResult? Function(int currentStep, SurveyEntity data)? loading,
    TResult? Function(int currentStep, SurveyEntity data)? success,
    TResult? Function(int currentStep, SurveyEntity data, String message)?
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int currentStep, SurveyEntity data)? initial,
    TResult Function(int currentStep, SurveyEntity data)? loading,
    TResult Function(int currentStep, SurveyEntity data)? success,
    TResult Function(int currentStep, SurveyEntity data, String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SurveyStateCopyWith<SurveyState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurveyStateCopyWith<$Res> {
  factory $SurveyStateCopyWith(
    SurveyState value,
    $Res Function(SurveyState) then,
  ) = _$SurveyStateCopyWithImpl<$Res, SurveyState>;
  @useResult
  $Res call({int currentStep, SurveyEntity data});

  $SurveyEntityCopyWith<$Res> get data;
}

/// @nodoc
class _$SurveyStateCopyWithImpl<$Res, $Val extends SurveyState>
    implements $SurveyStateCopyWith<$Res> {
  _$SurveyStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentStep = null, Object? data = null}) {
    return _then(
      _value.copyWith(
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as int,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as SurveyEntity,
          )
          as $Val,
    );
  }

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurveyEntityCopyWith<$Res> get data {
    return $SurveyEntityCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res>
    implements $SurveyStateCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int currentStep, SurveyEntity data});

  @override
  $SurveyEntityCopyWith<$Res> get data;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$SurveyStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentStep = null, Object? data = null}) {
    return _then(
      _$InitialImpl(
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as SurveyEntity,
      ),
    );
  }
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl({this.currentStep = 0, this.data = const SurveyEntity()});

  @override
  @JsonKey()
  final int currentStep;
  @override
  @JsonKey()
  final SurveyEntity data;

  @override
  String toString() {
    return 'SurveyState.initial(currentStep: $currentStep, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InitialImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentStep, data);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InitialImplCopyWith<_$InitialImpl> get copyWith =>
      __$$InitialImplCopyWithImpl<_$InitialImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int currentStep, SurveyEntity data) initial,
    required TResult Function(int currentStep, SurveyEntity data) loading,
    required TResult Function(int currentStep, SurveyEntity data) success,
    required TResult Function(
      int currentStep,
      SurveyEntity data,
      String message,
    )
    error,
  }) {
    return initial(currentStep, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int currentStep, SurveyEntity data)? initial,
    TResult? Function(int currentStep, SurveyEntity data)? loading,
    TResult? Function(int currentStep, SurveyEntity data)? success,
    TResult? Function(int currentStep, SurveyEntity data, String message)?
    error,
  }) {
    return initial?.call(currentStep, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int currentStep, SurveyEntity data)? initial,
    TResult Function(int currentStep, SurveyEntity data)? loading,
    TResult Function(int currentStep, SurveyEntity data)? success,
    TResult Function(int currentStep, SurveyEntity data, String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(currentStep, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements SurveyState {
  const factory _Initial({final int currentStep, final SurveyEntity data}) =
      _$InitialImpl;

  @override
  int get currentStep;
  @override
  SurveyEntity get data;

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InitialImplCopyWith<_$InitialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res>
    implements $SurveyStateCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
    _$LoadingImpl value,
    $Res Function(_$LoadingImpl) then,
  ) = __$$LoadingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int currentStep, SurveyEntity data});

  @override
  $SurveyEntityCopyWith<$Res> get data;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$SurveyStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentStep = null, Object? data = null}) {
    return _then(
      _$LoadingImpl(
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as SurveyEntity,
      ),
    );
  }
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl({required this.currentStep, required this.data});

  @override
  final int currentStep;
  @override
  final SurveyEntity data;

  @override
  String toString() {
    return 'SurveyState.loading(currentStep: $currentStep, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadingImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentStep, data);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadingImplCopyWith<_$LoadingImpl> get copyWith =>
      __$$LoadingImplCopyWithImpl<_$LoadingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int currentStep, SurveyEntity data) initial,
    required TResult Function(int currentStep, SurveyEntity data) loading,
    required TResult Function(int currentStep, SurveyEntity data) success,
    required TResult Function(
      int currentStep,
      SurveyEntity data,
      String message,
    )
    error,
  }) {
    return loading(currentStep, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int currentStep, SurveyEntity data)? initial,
    TResult? Function(int currentStep, SurveyEntity data)? loading,
    TResult? Function(int currentStep, SurveyEntity data)? success,
    TResult? Function(int currentStep, SurveyEntity data, String message)?
    error,
  }) {
    return loading?.call(currentStep, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int currentStep, SurveyEntity data)? initial,
    TResult Function(int currentStep, SurveyEntity data)? loading,
    TResult Function(int currentStep, SurveyEntity data)? success,
    TResult Function(int currentStep, SurveyEntity data, String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(currentStep, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements SurveyState {
  const factory _Loading({
    required final int currentStep,
    required final SurveyEntity data,
  }) = _$LoadingImpl;

  @override
  int get currentStep;
  @override
  SurveyEntity get data;

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadingImplCopyWith<_$LoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SuccessImplCopyWith<$Res>
    implements $SurveyStateCopyWith<$Res> {
  factory _$$SuccessImplCopyWith(
    _$SuccessImpl value,
    $Res Function(_$SuccessImpl) then,
  ) = __$$SuccessImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int currentStep, SurveyEntity data});

  @override
  $SurveyEntityCopyWith<$Res> get data;
}

/// @nodoc
class __$$SuccessImplCopyWithImpl<$Res>
    extends _$SurveyStateCopyWithImpl<$Res, _$SuccessImpl>
    implements _$$SuccessImplCopyWith<$Res> {
  __$$SuccessImplCopyWithImpl(
    _$SuccessImpl _value,
    $Res Function(_$SuccessImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentStep = null, Object? data = null}) {
    return _then(
      _$SuccessImpl(
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as SurveyEntity,
      ),
    );
  }
}

/// @nodoc

class _$SuccessImpl implements _Success {
  const _$SuccessImpl({required this.currentStep, required this.data});

  @override
  final int currentStep;
  @override
  final SurveyEntity data;

  @override
  String toString() {
    return 'SurveyState.success(currentStep: $currentStep, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuccessImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentStep, data);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      __$$SuccessImplCopyWithImpl<_$SuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int currentStep, SurveyEntity data) initial,
    required TResult Function(int currentStep, SurveyEntity data) loading,
    required TResult Function(int currentStep, SurveyEntity data) success,
    required TResult Function(
      int currentStep,
      SurveyEntity data,
      String message,
    )
    error,
  }) {
    return success(currentStep, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int currentStep, SurveyEntity data)? initial,
    TResult? Function(int currentStep, SurveyEntity data)? loading,
    TResult? Function(int currentStep, SurveyEntity data)? success,
    TResult? Function(int currentStep, SurveyEntity data, String message)?
    error,
  }) {
    return success?.call(currentStep, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int currentStep, SurveyEntity data)? initial,
    TResult Function(int currentStep, SurveyEntity data)? loading,
    TResult Function(int currentStep, SurveyEntity data)? success,
    TResult Function(int currentStep, SurveyEntity data, String message)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(currentStep, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _Success implements SurveyState {
  const factory _Success({
    required final int currentStep,
    required final SurveyEntity data,
  }) = _$SuccessImpl;

  @override
  int get currentStep;
  @override
  SurveyEntity get data;

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res>
    implements $SurveyStateCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int currentStep, SurveyEntity data, String message});

  @override
  $SurveyEntityCopyWith<$Res> get data;
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$SurveyStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? data = null,
    Object? message = null,
  }) {
    return _then(
      _$ErrorImpl(
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as SurveyEntity,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl({
    required this.currentStep,
    required this.data,
    required this.message,
  });

  @override
  final int currentStep;
  @override
  final SurveyEntity data;
  @override
  final String message;

  @override
  String toString() {
    return 'SurveyState.error(currentStep: $currentStep, data: $data, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentStep, data, message);

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int currentStep, SurveyEntity data) initial,
    required TResult Function(int currentStep, SurveyEntity data) loading,
    required TResult Function(int currentStep, SurveyEntity data) success,
    required TResult Function(
      int currentStep,
      SurveyEntity data,
      String message,
    )
    error,
  }) {
    return error(currentStep, data, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int currentStep, SurveyEntity data)? initial,
    TResult? Function(int currentStep, SurveyEntity data)? loading,
    TResult? Function(int currentStep, SurveyEntity data)? success,
    TResult? Function(int currentStep, SurveyEntity data, String message)?
    error,
  }) {
    return error?.call(currentStep, data, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int currentStep, SurveyEntity data)? initial,
    TResult Function(int currentStep, SurveyEntity data)? loading,
    TResult Function(int currentStep, SurveyEntity data)? success,
    TResult Function(int currentStep, SurveyEntity data, String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(currentStep, data, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements SurveyState {
  const factory _Error({
    required final int currentStep,
    required final SurveyEntity data,
    required final String message,
  }) = _$ErrorImpl;

  @override
  int get currentStep;
  @override
  SurveyEntity get data;
  String get message;

  /// Create a copy of SurveyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
