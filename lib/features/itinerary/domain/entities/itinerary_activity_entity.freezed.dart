// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_activity_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ItineraryActivityEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get startTime => throw _privateConstructorUsedError;
  String get endTime => throw _privateConstructorUsedError;
  String get locationName => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get transportInfo => throw _privateConstructorUsedError;
  bool get isFree => throw _privateConstructorUsedError;
  String? get category =>
      throw _privateConstructorUsedError; // e.g. "Cà phê", "Tham quan"
  // Geographical coordinates
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError; // Status
  ActivityStatus get status => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryActivityEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryActivityEntityCopyWith<ItineraryActivityEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryActivityEntityCopyWith<$Res> {
  factory $ItineraryActivityEntityCopyWith(
    ItineraryActivityEntity value,
    $Res Function(ItineraryActivityEntity) then,
  ) = _$ItineraryActivityEntityCopyWithImpl<$Res, ItineraryActivityEntity>;
  @useResult
  $Res call({
    String id,
    String title,
    String startTime,
    String endTime,
    String locationName,
    String address,
    String imageUrl,
    double price,
    String currency,
    String? transportInfo,
    bool isFree,
    String? category,
    double? latitude,
    double? longitude,
    ActivityStatus status,
  });
}

/// @nodoc
class _$ItineraryActivityEntityCopyWithImpl<
  $Res,
  $Val extends ItineraryActivityEntity
>
    implements $ItineraryActivityEntityCopyWith<$Res> {
  _$ItineraryActivityEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryActivityEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? locationName = null,
    Object? address = null,
    Object? imageUrl = null,
    Object? price = null,
    Object? currency = null,
    Object? transportInfo = freezed,
    Object? isFree = null,
    Object? category = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? status = null,
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
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as String,
            endTime: null == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as String,
            locationName: null == locationName
                ? _value.locationName
                : locationName // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            transportInfo: freezed == transportInfo
                ? _value.transportInfo
                : transportInfo // ignore: cast_nullable_to_non_nullable
                      as String?,
            isFree: null == isFree
                ? _value.isFree
                : isFree // ignore: cast_nullable_to_non_nullable
                      as bool,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ActivityStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItineraryActivityEntityImplCopyWith<$Res>
    implements $ItineraryActivityEntityCopyWith<$Res> {
  factory _$$ItineraryActivityEntityImplCopyWith(
    _$ItineraryActivityEntityImpl value,
    $Res Function(_$ItineraryActivityEntityImpl) then,
  ) = __$$ItineraryActivityEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String startTime,
    String endTime,
    String locationName,
    String address,
    String imageUrl,
    double price,
    String currency,
    String? transportInfo,
    bool isFree,
    String? category,
    double? latitude,
    double? longitude,
    ActivityStatus status,
  });
}

/// @nodoc
class __$$ItineraryActivityEntityImplCopyWithImpl<$Res>
    extends
        _$ItineraryActivityEntityCopyWithImpl<
          $Res,
          _$ItineraryActivityEntityImpl
        >
    implements _$$ItineraryActivityEntityImplCopyWith<$Res> {
  __$$ItineraryActivityEntityImplCopyWithImpl(
    _$ItineraryActivityEntityImpl _value,
    $Res Function(_$ItineraryActivityEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItineraryActivityEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? locationName = null,
    Object? address = null,
    Object? imageUrl = null,
    Object? price = null,
    Object? currency = null,
    Object? transportInfo = freezed,
    Object? isFree = null,
    Object? category = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? status = null,
  }) {
    return _then(
      _$ItineraryActivityEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as String,
        endTime: null == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as String,
        locationName: null == locationName
            ? _value.locationName
            : locationName // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        transportInfo: freezed == transportInfo
            ? _value.transportInfo
            : transportInfo // ignore: cast_nullable_to_non_nullable
                  as String?,
        isFree: null == isFree
            ? _value.isFree
            : isFree // ignore: cast_nullable_to_non_nullable
                  as bool,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ActivityStatus,
      ),
    );
  }
}

/// @nodoc

class _$ItineraryActivityEntityImpl implements _ItineraryActivityEntity {
  const _$ItineraryActivityEntityImpl({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.address,
    required this.imageUrl,
    this.price = 0,
    this.currency = 'VNĐ',
    this.transportInfo,
    this.isFree = false,
    this.category,
    this.latitude,
    this.longitude,
    this.status = ActivityStatus.chuaDi,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  final String locationName;
  @override
  final String address;
  @override
  final String imageUrl;
  @override
  @JsonKey()
  final double price;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? transportInfo;
  @override
  @JsonKey()
  final bool isFree;
  @override
  final String? category;
  // e.g. "Cà phê", "Tham quan"
  // Geographical coordinates
  @override
  final double? latitude;
  @override
  final double? longitude;
  // Status
  @override
  @JsonKey()
  final ActivityStatus status;

  @override
  String toString() {
    return 'ItineraryActivityEntity(id: $id, title: $title, startTime: $startTime, endTime: $endTime, locationName: $locationName, address: $address, imageUrl: $imageUrl, price: $price, currency: $currency, transportInfo: $transportInfo, isFree: $isFree, category: $category, latitude: $latitude, longitude: $longitude, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryActivityEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.transportInfo, transportInfo) ||
                other.transportInfo == transportInfo) &&
            (identical(other.isFree, isFree) || other.isFree == isFree) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    startTime,
    endTime,
    locationName,
    address,
    imageUrl,
    price,
    currency,
    transportInfo,
    isFree,
    category,
    latitude,
    longitude,
    status,
  );

  /// Create a copy of ItineraryActivityEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryActivityEntityImplCopyWith<_$ItineraryActivityEntityImpl>
  get copyWith =>
      __$$ItineraryActivityEntityImplCopyWithImpl<
        _$ItineraryActivityEntityImpl
      >(this, _$identity);
}

abstract class _ItineraryActivityEntity implements ItineraryActivityEntity {
  const factory _ItineraryActivityEntity({
    required final String id,
    required final String title,
    required final String startTime,
    required final String endTime,
    required final String locationName,
    required final String address,
    required final String imageUrl,
    final double price,
    final String currency,
    final String? transportInfo,
    final bool isFree,
    final String? category,
    final double? latitude,
    final double? longitude,
    final ActivityStatus status,
  }) = _$ItineraryActivityEntityImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get startTime;
  @override
  String get endTime;
  @override
  String get locationName;
  @override
  String get address;
  @override
  String get imageUrl;
  @override
  double get price;
  @override
  String get currency;
  @override
  String? get transportInfo;
  @override
  bool get isFree;
  @override
  String? get category; // e.g. "Cà phê", "Tham quan"
  // Geographical coordinates
  @override
  double? get latitude;
  @override
  double? get longitude; // Status
  @override
  ActivityStatus get status;

  /// Create a copy of ItineraryActivityEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryActivityEntityImplCopyWith<_$ItineraryActivityEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
