// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ItinerarySummary {
  /// Tổng số lịch trình.
  int get total => throw _privateConstructorUsedError;

  /// Số lịch trình đã hoàn thành.
  int get completed => throw _privateConstructorUsedError;

  /// Số lịch trình sắp đi.
  int get upcoming => throw _privateConstructorUsedError;

  /// Số lịch trình đang tạo (nháp).
  int get draft => throw _privateConstructorUsedError;

  /// Create a copy of ItinerarySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItinerarySummaryCopyWith<ItinerarySummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItinerarySummaryCopyWith<$Res> {
  factory $ItinerarySummaryCopyWith(
    ItinerarySummary value,
    $Res Function(ItinerarySummary) then,
  ) = _$ItinerarySummaryCopyWithImpl<$Res, ItinerarySummary>;
  @useResult
  $Res call({int total, int completed, int upcoming, int draft});
}

/// @nodoc
class _$ItinerarySummaryCopyWithImpl<$Res, $Val extends ItinerarySummary>
    implements $ItinerarySummaryCopyWith<$Res> {
  _$ItinerarySummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItinerarySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? completed = null,
    Object? upcoming = null,
    Object? draft = null,
  }) {
    return _then(
      _value.copyWith(
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            completed: null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as int,
            upcoming: null == upcoming
                ? _value.upcoming
                : upcoming // ignore: cast_nullable_to_non_nullable
                      as int,
            draft: null == draft
                ? _value.draft
                : draft // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItinerarySummaryImplCopyWith<$Res>
    implements $ItinerarySummaryCopyWith<$Res> {
  factory _$$ItinerarySummaryImplCopyWith(
    _$ItinerarySummaryImpl value,
    $Res Function(_$ItinerarySummaryImpl) then,
  ) = __$$ItinerarySummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, int completed, int upcoming, int draft});
}

/// @nodoc
class __$$ItinerarySummaryImplCopyWithImpl<$Res>
    extends _$ItinerarySummaryCopyWithImpl<$Res, _$ItinerarySummaryImpl>
    implements _$$ItinerarySummaryImplCopyWith<$Res> {
  __$$ItinerarySummaryImplCopyWithImpl(
    _$ItinerarySummaryImpl _value,
    $Res Function(_$ItinerarySummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItinerarySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? completed = null,
    Object? upcoming = null,
    Object? draft = null,
  }) {
    return _then(
      _$ItinerarySummaryImpl(
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        completed: null == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as int,
        upcoming: null == upcoming
            ? _value.upcoming
            : upcoming // ignore: cast_nullable_to_non_nullable
                  as int,
        draft: null == draft
            ? _value.draft
            : draft // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ItinerarySummaryImpl implements _ItinerarySummary {
  const _$ItinerarySummaryImpl({
    this.total = 0,
    this.completed = 0,
    this.upcoming = 0,
    this.draft = 0,
  });

  /// Tổng số lịch trình.
  @override
  @JsonKey()
  final int total;

  /// Số lịch trình đã hoàn thành.
  @override
  @JsonKey()
  final int completed;

  /// Số lịch trình sắp đi.
  @override
  @JsonKey()
  final int upcoming;

  /// Số lịch trình đang tạo (nháp).
  @override
  @JsonKey()
  final int draft;

  @override
  String toString() {
    return 'ItinerarySummary(total: $total, completed: $completed, upcoming: $upcoming, draft: $draft)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItinerarySummaryImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.upcoming, upcoming) ||
                other.upcoming == upcoming) &&
            (identical(other.draft, draft) || other.draft == draft));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, total, completed, upcoming, draft);

  /// Create a copy of ItinerarySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItinerarySummaryImplCopyWith<_$ItinerarySummaryImpl> get copyWith =>
      __$$ItinerarySummaryImplCopyWithImpl<_$ItinerarySummaryImpl>(
        this,
        _$identity,
      );
}

abstract class _ItinerarySummary implements ItinerarySummary {
  const factory _ItinerarySummary({
    final int total,
    final int completed,
    final int upcoming,
    final int draft,
  }) = _$ItinerarySummaryImpl;

  /// Tổng số lịch trình.
  @override
  int get total;

  /// Số lịch trình đã hoàn thành.
  @override
  int get completed;

  /// Số lịch trình sắp đi.
  @override
  int get upcoming;

  /// Số lịch trình đang tạo (nháp).
  @override
  int get draft;

  /// Create a copy of ItinerarySummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItinerarySummaryImplCopyWith<_$ItinerarySummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
