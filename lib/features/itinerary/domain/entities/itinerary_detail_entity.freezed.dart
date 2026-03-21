// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_detail_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ItineraryDetailEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // e.g. "DANG DIEN RA"
  bool get isPublic => throw _privateConstructorUsedError; // Stats for 2x2 grid
  int get durationDays => throw _privateConstructorUsedError;
  int get activitiesCount => throw _privateConstructorUsedError;
  int get hotelsCount => throw _privateConstructorUsedError;
  int get transportTurns => throw _privateConstructorUsedError; // Budget
  double get estimatedBudget => throw _privateConstructorUsedError;
  double get spentBudget => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError; // Content
  List<ItineraryDayEntity> get days => throw _privateConstructorUsedError;
  List<String> get notes =>
      throw _privateConstructorUsedError; // Coordinates for map context (simplified)
  List<double> get centerCoordinate => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryDetailEntityCopyWith<ItineraryDetailEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryDetailEntityCopyWith<$Res> {
  factory $ItineraryDetailEntityCopyWith(
    ItineraryDetailEntity value,
    $Res Function(ItineraryDetailEntity) then,
  ) = _$ItineraryDetailEntityCopyWithImpl<$Res, ItineraryDetailEntity>;
  @useResult
  $Res call({
    String id,
    String title,
    String destination,
    DateTime startDate,
    DateTime endDate,
    String status,
    bool isPublic,
    int durationDays,
    int activitiesCount,
    int hotelsCount,
    int transportTurns,
    double estimatedBudget,
    double spentBudget,
    String currency,
    List<ItineraryDayEntity> days,
    List<String> notes,
    List<double> centerCoordinate,
  });
}

/// @nodoc
class _$ItineraryDetailEntityCopyWithImpl<
  $Res,
  $Val extends ItineraryDetailEntity
>
    implements $ItineraryDetailEntityCopyWith<$Res> {
  _$ItineraryDetailEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? destination = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? status = null,
    Object? isPublic = null,
    Object? durationDays = null,
    Object? activitiesCount = null,
    Object? hotelsCount = null,
    Object? transportTurns = null,
    Object? estimatedBudget = null,
    Object? spentBudget = null,
    Object? currency = null,
    Object? days = null,
    Object? notes = null,
    Object? centerCoordinate = null,
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
            destination: null == destination
                ? _value.destination
                : destination // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            isPublic: null == isPublic
                ? _value.isPublic
                : isPublic // ignore: cast_nullable_to_non_nullable
                      as bool,
            durationDays: null == durationDays
                ? _value.durationDays
                : durationDays // ignore: cast_nullable_to_non_nullable
                      as int,
            activitiesCount: null == activitiesCount
                ? _value.activitiesCount
                : activitiesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            hotelsCount: null == hotelsCount
                ? _value.hotelsCount
                : hotelsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            transportTurns: null == transportTurns
                ? _value.transportTurns
                : transportTurns // ignore: cast_nullable_to_non_nullable
                      as int,
            estimatedBudget: null == estimatedBudget
                ? _value.estimatedBudget
                : estimatedBudget // ignore: cast_nullable_to_non_nullable
                      as double,
            spentBudget: null == spentBudget
                ? _value.spentBudget
                : spentBudget // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            days: null == days
                ? _value.days
                : days // ignore: cast_nullable_to_non_nullable
                      as List<ItineraryDayEntity>,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            centerCoordinate: null == centerCoordinate
                ? _value.centerCoordinate
                : centerCoordinate // ignore: cast_nullable_to_non_nullable
                      as List<double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItineraryDetailEntityImplCopyWith<$Res>
    implements $ItineraryDetailEntityCopyWith<$Res> {
  factory _$$ItineraryDetailEntityImplCopyWith(
    _$ItineraryDetailEntityImpl value,
    $Res Function(_$ItineraryDetailEntityImpl) then,
  ) = __$$ItineraryDetailEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String destination,
    DateTime startDate,
    DateTime endDate,
    String status,
    bool isPublic,
    int durationDays,
    int activitiesCount,
    int hotelsCount,
    int transportTurns,
    double estimatedBudget,
    double spentBudget,
    String currency,
    List<ItineraryDayEntity> days,
    List<String> notes,
    List<double> centerCoordinate,
  });
}

/// @nodoc
class __$$ItineraryDetailEntityImplCopyWithImpl<$Res>
    extends
        _$ItineraryDetailEntityCopyWithImpl<$Res, _$ItineraryDetailEntityImpl>
    implements _$$ItineraryDetailEntityImplCopyWith<$Res> {
  __$$ItineraryDetailEntityImplCopyWithImpl(
    _$ItineraryDetailEntityImpl _value,
    $Res Function(_$ItineraryDetailEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItineraryDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? destination = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? status = null,
    Object? isPublic = null,
    Object? durationDays = null,
    Object? activitiesCount = null,
    Object? hotelsCount = null,
    Object? transportTurns = null,
    Object? estimatedBudget = null,
    Object? spentBudget = null,
    Object? currency = null,
    Object? days = null,
    Object? notes = null,
    Object? centerCoordinate = null,
  }) {
    return _then(
      _$ItineraryDetailEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        destination: null == destination
            ? _value.destination
            : destination // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        isPublic: null == isPublic
            ? _value.isPublic
            : isPublic // ignore: cast_nullable_to_non_nullable
                  as bool,
        durationDays: null == durationDays
            ? _value.durationDays
            : durationDays // ignore: cast_nullable_to_non_nullable
                  as int,
        activitiesCount: null == activitiesCount
            ? _value.activitiesCount
            : activitiesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        hotelsCount: null == hotelsCount
            ? _value.hotelsCount
            : hotelsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        transportTurns: null == transportTurns
            ? _value.transportTurns
            : transportTurns // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedBudget: null == estimatedBudget
            ? _value.estimatedBudget
            : estimatedBudget // ignore: cast_nullable_to_non_nullable
                  as double,
        spentBudget: null == spentBudget
            ? _value.spentBudget
            : spentBudget // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        days: null == days
            ? _value._days
            : days // ignore: cast_nullable_to_non_nullable
                  as List<ItineraryDayEntity>,
        notes: null == notes
            ? _value._notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        centerCoordinate: null == centerCoordinate
            ? _value._centerCoordinate
            : centerCoordinate // ignore: cast_nullable_to_non_nullable
                  as List<double>,
      ),
    );
  }
}

/// @nodoc

class _$ItineraryDetailEntityImpl implements _ItineraryDetailEntity {
  const _$ItineraryDetailEntityImpl({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isPublic = true,
    required this.durationDays,
    required this.activitiesCount,
    required this.hotelsCount,
    required this.transportTurns,
    required this.estimatedBudget,
    required this.spentBudget,
    this.currency = 'VNĐ',
    final List<ItineraryDayEntity> days = const [],
    final List<String> notes = const [],
    final List<double> centerCoordinate = const [],
  }) : _days = days,
       _notes = notes,
       _centerCoordinate = centerCoordinate;

  @override
  final String id;
  @override
  final String title;
  @override
  final String destination;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final String status;
  // e.g. "DANG DIEN RA"
  @override
  @JsonKey()
  final bool isPublic;
  // Stats for 2x2 grid
  @override
  final int durationDays;
  @override
  final int activitiesCount;
  @override
  final int hotelsCount;
  @override
  final int transportTurns;
  // Budget
  @override
  final double estimatedBudget;
  @override
  final double spentBudget;
  @override
  @JsonKey()
  final String currency;
  // Content
  final List<ItineraryDayEntity> _days;
  // Content
  @override
  @JsonKey()
  List<ItineraryDayEntity> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  final List<String> _notes;
  @override
  @JsonKey()
  List<String> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  // Coordinates for map context (simplified)
  final List<double> _centerCoordinate;
  // Coordinates for map context (simplified)
  @override
  @JsonKey()
  List<double> get centerCoordinate {
    if (_centerCoordinate is EqualUnmodifiableListView)
      return _centerCoordinate;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_centerCoordinate);
  }

  @override
  String toString() {
    return 'ItineraryDetailEntity(id: $id, title: $title, destination: $destination, startDate: $startDate, endDate: $endDate, status: $status, isPublic: $isPublic, durationDays: $durationDays, activitiesCount: $activitiesCount, hotelsCount: $hotelsCount, transportTurns: $transportTurns, estimatedBudget: $estimatedBudget, spentBudget: $spentBudget, currency: $currency, days: $days, notes: $notes, centerCoordinate: $centerCoordinate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryDetailEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.activitiesCount, activitiesCount) ||
                other.activitiesCount == activitiesCount) &&
            (identical(other.hotelsCount, hotelsCount) ||
                other.hotelsCount == hotelsCount) &&
            (identical(other.transportTurns, transportTurns) ||
                other.transportTurns == transportTurns) &&
            (identical(other.estimatedBudget, estimatedBudget) ||
                other.estimatedBudget == estimatedBudget) &&
            (identical(other.spentBudget, spentBudget) ||
                other.spentBudget == spentBudget) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            const DeepCollectionEquality().equals(other._days, _days) &&
            const DeepCollectionEquality().equals(other._notes, _notes) &&
            const DeepCollectionEquality().equals(
              other._centerCoordinate,
              _centerCoordinate,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    destination,
    startDate,
    endDate,
    status,
    isPublic,
    durationDays,
    activitiesCount,
    hotelsCount,
    transportTurns,
    estimatedBudget,
    spentBudget,
    currency,
    const DeepCollectionEquality().hash(_days),
    const DeepCollectionEquality().hash(_notes),
    const DeepCollectionEquality().hash(_centerCoordinate),
  );

  /// Create a copy of ItineraryDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryDetailEntityImplCopyWith<_$ItineraryDetailEntityImpl>
  get copyWith =>
      __$$ItineraryDetailEntityImplCopyWithImpl<_$ItineraryDetailEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _ItineraryDetailEntity implements ItineraryDetailEntity {
  const factory _ItineraryDetailEntity({
    required final String id,
    required final String title,
    required final String destination,
    required final DateTime startDate,
    required final DateTime endDate,
    required final String status,
    final bool isPublic,
    required final int durationDays,
    required final int activitiesCount,
    required final int hotelsCount,
    required final int transportTurns,
    required final double estimatedBudget,
    required final double spentBudget,
    final String currency,
    final List<ItineraryDayEntity> days,
    final List<String> notes,
    final List<double> centerCoordinate,
  }) = _$ItineraryDetailEntityImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get destination;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  String get status; // e.g. "DANG DIEN RA"
  @override
  bool get isPublic; // Stats for 2x2 grid
  @override
  int get durationDays;
  @override
  int get activitiesCount;
  @override
  int get hotelsCount;
  @override
  int get transportTurns; // Budget
  @override
  double get estimatedBudget;
  @override
  double get spentBudget;
  @override
  String get currency; // Content
  @override
  List<ItineraryDayEntity> get days;
  @override
  List<String> get notes; // Coordinates for map context (simplified)
  @override
  List<double> get centerCoordinate;

  /// Create a copy of ItineraryDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryDetailEntityImplCopyWith<_$ItineraryDetailEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
