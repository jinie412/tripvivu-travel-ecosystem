// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ItineraryEntity {
  /// Mã định danh duy nhất.
  String get id => throw _privateConstructorUsedError;

  /// Tên lịch trình. VD: "Sài Gòn 3N2Đ"
  String get title => throw _privateConstructorUsedError;

  /// URL ảnh đại diện.
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Ngày bắt đầu chuyến đi.
  DateTime? get startDate => throw _privateConstructorUsedError;

  /// Ngày kết thúc chuyến đi.
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// Tổng chi phí dự kiến (VNĐ). VD: 5200000
  double get estimatedCost => throw _privateConstructorUsedError;

  /// Đơn vị tiền tệ. VD: "VNĐ"
  String get currency => throw _privateConstructorUsedError;

  /// Số ngày. VD: 3
  int get durationDays => throw _privateConstructorUsedError;

  /// Tiến độ hoàn thành (0.0 → 1.0). Dùng cho card "Sắp đi".
  double get progress => throw _privateConstructorUsedError;

  /// Trạng thái: upcoming, completed, draft.
  ItineraryStatus get status => throw _privateConstructorUsedError;

  /// Đánh giá sau chuyến đi (chỉ khi status == completed). VD: 4.8
  double? get rating => throw _privateConstructorUsedError;

  /// Màu placeholder khi ảnh chưa tải xong.
  int get placeholderColor => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryEntityCopyWith<ItineraryEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryEntityCopyWith<$Res> {
  factory $ItineraryEntityCopyWith(
    ItineraryEntity value,
    $Res Function(ItineraryEntity) then,
  ) = _$ItineraryEntityCopyWithImpl<$Res, ItineraryEntity>;
  @useResult
  $Res call({
    String id,
    String title,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    double estimatedCost,
    String currency,
    int durationDays,
    double progress,
    ItineraryStatus status,
    double? rating,
    int placeholderColor,
  });
}

/// @nodoc
class _$ItineraryEntityCopyWithImpl<$Res, $Val extends ItineraryEntity>
    implements $ItineraryEntityCopyWith<$Res> {
  _$ItineraryEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? imageUrl = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? estimatedCost = null,
    Object? currency = null,
    Object? durationDays = null,
    Object? progress = null,
    Object? status = null,
    Object? rating = freezed,
    Object? placeholderColor = null,
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
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            estimatedCost: null == estimatedCost
                ? _value.estimatedCost
                : estimatedCost // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            durationDays: null == durationDays
                ? _value.durationDays
                : durationDays // ignore: cast_nullable_to_non_nullable
                      as int,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ItineraryStatus,
            rating: freezed == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double?,
            placeholderColor: null == placeholderColor
                ? _value.placeholderColor
                : placeholderColor // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItineraryEntityImplCopyWith<$Res>
    implements $ItineraryEntityCopyWith<$Res> {
  factory _$$ItineraryEntityImplCopyWith(
    _$ItineraryEntityImpl value,
    $Res Function(_$ItineraryEntityImpl) then,
  ) = __$$ItineraryEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    double estimatedCost,
    String currency,
    int durationDays,
    double progress,
    ItineraryStatus status,
    double? rating,
    int placeholderColor,
  });
}

/// @nodoc
class __$$ItineraryEntityImplCopyWithImpl<$Res>
    extends _$ItineraryEntityCopyWithImpl<$Res, _$ItineraryEntityImpl>
    implements _$$ItineraryEntityImplCopyWith<$Res> {
  __$$ItineraryEntityImplCopyWithImpl(
    _$ItineraryEntityImpl _value,
    $Res Function(_$ItineraryEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItineraryEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? imageUrl = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? estimatedCost = null,
    Object? currency = null,
    Object? durationDays = null,
    Object? progress = null,
    Object? status = null,
    Object? rating = freezed,
    Object? placeholderColor = null,
  }) {
    return _then(
      _$ItineraryEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        estimatedCost: null == estimatedCost
            ? _value.estimatedCost
            : estimatedCost // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        durationDays: null == durationDays
            ? _value.durationDays
            : durationDays // ignore: cast_nullable_to_non_nullable
                  as int,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ItineraryStatus,
        rating: freezed == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double?,
        placeholderColor: null == placeholderColor
            ? _value.placeholderColor
            : placeholderColor // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ItineraryEntityImpl implements _ItineraryEntity {
  const _$ItineraryEntityImpl({
    required this.id,
    required this.title,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.estimatedCost = 0,
    this.currency = 'VNĐ',
    this.durationDays = 1,
    this.progress = 0.0,
    this.status = ItineraryStatus.draft,
    this.rating,
    this.placeholderColor = 0xFF90CAF9,
  });

  /// Mã định danh duy nhất.
  @override
  final String id;

  /// Tên lịch trình. VD: "Sài Gòn 3N2Đ"
  @override
  final String title;

  /// URL ảnh đại diện.
  @override
  final String? imageUrl;

  /// Ngày bắt đầu chuyến đi.
  @override
  final DateTime? startDate;

  /// Ngày kết thúc chuyến đi.
  @override
  final DateTime? endDate;

  /// Tổng chi phí dự kiến (VNĐ). VD: 5200000
  @override
  @JsonKey()
  final double estimatedCost;

  /// Đơn vị tiền tệ. VD: "VNĐ"
  @override
  @JsonKey()
  final String currency;

  /// Số ngày. VD: 3
  @override
  @JsonKey()
  final int durationDays;

  /// Tiến độ hoàn thành (0.0 → 1.0). Dùng cho card "Sắp đi".
  @override
  @JsonKey()
  final double progress;

  /// Trạng thái: upcoming, completed, draft.
  @override
  @JsonKey()
  final ItineraryStatus status;

  /// Đánh giá sau chuyến đi (chỉ khi status == completed). VD: 4.8
  @override
  final double? rating;

  /// Màu placeholder khi ảnh chưa tải xong.
  @override
  @JsonKey()
  final int placeholderColor;

  @override
  String toString() {
    return 'ItineraryEntity(id: $id, title: $title, imageUrl: $imageUrl, startDate: $startDate, endDate: $endDate, estimatedCost: $estimatedCost, currency: $currency, durationDays: $durationDays, progress: $progress, status: $status, rating: $rating, placeholderColor: $placeholderColor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.placeholderColor, placeholderColor) ||
                other.placeholderColor == placeholderColor));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    imageUrl,
    startDate,
    endDate,
    estimatedCost,
    currency,
    durationDays,
    progress,
    status,
    rating,
    placeholderColor,
  );

  /// Create a copy of ItineraryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryEntityImplCopyWith<_$ItineraryEntityImpl> get copyWith =>
      __$$ItineraryEntityImplCopyWithImpl<_$ItineraryEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _ItineraryEntity implements ItineraryEntity {
  const factory _ItineraryEntity({
    required final String id,
    required final String title,
    final String? imageUrl,
    final DateTime? startDate,
    final DateTime? endDate,
    final double estimatedCost,
    final String currency,
    final int durationDays,
    final double progress,
    final ItineraryStatus status,
    final double? rating,
    final int placeholderColor,
  }) = _$ItineraryEntityImpl;

  /// Mã định danh duy nhất.
  @override
  String get id;

  /// Tên lịch trình. VD: "Sài Gòn 3N2Đ"
  @override
  String get title;

  /// URL ảnh đại diện.
  @override
  String? get imageUrl;

  /// Ngày bắt đầu chuyến đi.
  @override
  DateTime? get startDate;

  /// Ngày kết thúc chuyến đi.
  @override
  DateTime? get endDate;

  /// Tổng chi phí dự kiến (VNĐ). VD: 5200000
  @override
  double get estimatedCost;

  /// Đơn vị tiền tệ. VD: "VNĐ"
  @override
  String get currency;

  /// Số ngày. VD: 3
  @override
  int get durationDays;

  /// Tiến độ hoàn thành (0.0 → 1.0). Dùng cho card "Sắp đi".
  @override
  double get progress;

  /// Trạng thái: upcoming, completed, draft.
  @override
  ItineraryStatus get status;

  /// Đánh giá sau chuyến đi (chỉ khi status == completed). VD: 4.8
  @override
  double? get rating;

  /// Màu placeholder khi ảnh chưa tải xong.
  @override
  int get placeholderColor;

  /// Create a copy of ItineraryEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryEntityImplCopyWith<_$ItineraryEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
