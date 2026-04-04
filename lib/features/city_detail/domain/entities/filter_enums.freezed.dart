// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter_enums.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ActivityFilter {
  /// Các loại hình đã chọn (chọn nhiều). Rỗng = tất cả.
  Set<ActivityCategory> get categories => throw _privateConstructorUsedError;

  /// Khoảng giá đã chọn (chọn 1)
  ActivityPriceType get priceType => throw _privateConstructorUsedError;

  /// Quận/Huyện đã chọn. null = tất cả.
  String? get district => throw _privateConstructorUsedError;

  /// Tùy chọn sắp xếp
  SortOption get sortOption => throw _privateConstructorUsedError;

  /// Create a copy of ActivityFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivityFilterCopyWith<ActivityFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityFilterCopyWith<$Res> {
  factory $ActivityFilterCopyWith(
    ActivityFilter value,
    $Res Function(ActivityFilter) then,
  ) = _$ActivityFilterCopyWithImpl<$Res, ActivityFilter>;
  @useResult
  $Res call({
    Set<ActivityCategory> categories,
    ActivityPriceType priceType,
    String? district,
    SortOption sortOption,
  });
}

/// @nodoc
class _$ActivityFilterCopyWithImpl<$Res, $Val extends ActivityFilter>
    implements $ActivityFilterCopyWith<$Res> {
  _$ActivityFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivityFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? priceType = null,
    Object? district = freezed,
    Object? sortOption = null,
  }) {
    return _then(
      _value.copyWith(
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as Set<ActivityCategory>,
            priceType: null == priceType
                ? _value.priceType
                : priceType // ignore: cast_nullable_to_non_nullable
                      as ActivityPriceType,
            district: freezed == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOption: null == sortOption
                ? _value.sortOption
                : sortOption // ignore: cast_nullable_to_non_nullable
                      as SortOption,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActivityFilterImplCopyWith<$Res>
    implements $ActivityFilterCopyWith<$Res> {
  factory _$$ActivityFilterImplCopyWith(
    _$ActivityFilterImpl value,
    $Res Function(_$ActivityFilterImpl) then,
  ) = __$$ActivityFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Set<ActivityCategory> categories,
    ActivityPriceType priceType,
    String? district,
    SortOption sortOption,
  });
}

/// @nodoc
class __$$ActivityFilterImplCopyWithImpl<$Res>
    extends _$ActivityFilterCopyWithImpl<$Res, _$ActivityFilterImpl>
    implements _$$ActivityFilterImplCopyWith<$Res> {
  __$$ActivityFilterImplCopyWithImpl(
    _$ActivityFilterImpl _value,
    $Res Function(_$ActivityFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActivityFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? priceType = null,
    Object? district = freezed,
    Object? sortOption = null,
  }) {
    return _then(
      _$ActivityFilterImpl(
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as Set<ActivityCategory>,
        priceType: null == priceType
            ? _value.priceType
            : priceType // ignore: cast_nullable_to_non_nullable
                  as ActivityPriceType,
        district: freezed == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOption: null == sortOption
            ? _value.sortOption
            : sortOption // ignore: cast_nullable_to_non_nullable
                  as SortOption,
      ),
    );
  }
}

/// @nodoc

class _$ActivityFilterImpl implements _ActivityFilter {
  const _$ActivityFilterImpl({
    final Set<ActivityCategory> categories = const {},
    this.priceType = ActivityPriceType.all,
    this.district = null,
    this.sortOption = SortOption.none,
  }) : _categories = categories;

  /// Các loại hình đã chọn (chọn nhiều). Rỗng = tất cả.
  final Set<ActivityCategory> _categories;

  /// Các loại hình đã chọn (chọn nhiều). Rỗng = tất cả.
  @override
  @JsonKey()
  Set<ActivityCategory> get categories {
    if (_categories is EqualUnmodifiableSetView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_categories);
  }

  /// Khoảng giá đã chọn (chọn 1)
  @override
  @JsonKey()
  final ActivityPriceType priceType;

  /// Quận/Huyện đã chọn. null = tất cả.
  @override
  @JsonKey()
  final String? district;

  /// Tùy chọn sắp xếp
  @override
  @JsonKey()
  final SortOption sortOption;

  @override
  String toString() {
    return 'ActivityFilter(categories: $categories, priceType: $priceType, district: $district, sortOption: $sortOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityFilterImpl &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            (identical(other.priceType, priceType) ||
                other.priceType == priceType) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_categories),
    priceType,
    district,
    sortOption,
  );

  /// Create a copy of ActivityFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityFilterImplCopyWith<_$ActivityFilterImpl> get copyWith =>
      __$$ActivityFilterImplCopyWithImpl<_$ActivityFilterImpl>(
        this,
        _$identity,
      );
}

abstract class _ActivityFilter implements ActivityFilter {
  const factory _ActivityFilter({
    final Set<ActivityCategory> categories,
    final ActivityPriceType priceType,
    final String? district,
    final SortOption sortOption,
  }) = _$ActivityFilterImpl;

  /// Các loại hình đã chọn (chọn nhiều). Rỗng = tất cả.
  @override
  Set<ActivityCategory> get categories;

  /// Khoảng giá đã chọn (chọn 1)
  @override
  ActivityPriceType get priceType;

  /// Quận/Huyện đã chọn. null = tất cả.
  @override
  String? get district;

  /// Tùy chọn sắp xếp
  @override
  SortOption get sortOption;

  /// Create a copy of ActivityFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivityFilterImplCopyWith<_$ActivityFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RestaurantFilter {
  /// Danh mục đã chọn (chọn nhiều). Rỗng = tất cả.
  Set<RestaurantCuisine> get cuisines => throw _privateConstructorUsedError;

  /// Mức giá đã chọn (chọn 1)
  RestaurantPriceLevel get priceLevel => throw _privateConstructorUsedError;

  /// Tiện ích đã chọn (chọn nhiều)
  Set<RestaurantAmenity> get amenities => throw _privateConstructorUsedError;

  /// Tùy chọn sắp xếp
  SortOption get sortOption => throw _privateConstructorUsedError;

  /// Create a copy of RestaurantFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantFilterCopyWith<RestaurantFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantFilterCopyWith<$Res> {
  factory $RestaurantFilterCopyWith(
    RestaurantFilter value,
    $Res Function(RestaurantFilter) then,
  ) = _$RestaurantFilterCopyWithImpl<$Res, RestaurantFilter>;
  @useResult
  $Res call({
    Set<RestaurantCuisine> cuisines,
    RestaurantPriceLevel priceLevel,
    Set<RestaurantAmenity> amenities,
    SortOption sortOption,
  });
}

/// @nodoc
class _$RestaurantFilterCopyWithImpl<$Res, $Val extends RestaurantFilter>
    implements $RestaurantFilterCopyWith<$Res> {
  _$RestaurantFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestaurantFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cuisines = null,
    Object? priceLevel = null,
    Object? amenities = null,
    Object? sortOption = null,
  }) {
    return _then(
      _value.copyWith(
            cuisines: null == cuisines
                ? _value.cuisines
                : cuisines // ignore: cast_nullable_to_non_nullable
                      as Set<RestaurantCuisine>,
            priceLevel: null == priceLevel
                ? _value.priceLevel
                : priceLevel // ignore: cast_nullable_to_non_nullable
                      as RestaurantPriceLevel,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as Set<RestaurantAmenity>,
            sortOption: null == sortOption
                ? _value.sortOption
                : sortOption // ignore: cast_nullable_to_non_nullable
                      as SortOption,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RestaurantFilterImplCopyWith<$Res>
    implements $RestaurantFilterCopyWith<$Res> {
  factory _$$RestaurantFilterImplCopyWith(
    _$RestaurantFilterImpl value,
    $Res Function(_$RestaurantFilterImpl) then,
  ) = __$$RestaurantFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Set<RestaurantCuisine> cuisines,
    RestaurantPriceLevel priceLevel,
    Set<RestaurantAmenity> amenities,
    SortOption sortOption,
  });
}

/// @nodoc
class __$$RestaurantFilterImplCopyWithImpl<$Res>
    extends _$RestaurantFilterCopyWithImpl<$Res, _$RestaurantFilterImpl>
    implements _$$RestaurantFilterImplCopyWith<$Res> {
  __$$RestaurantFilterImplCopyWithImpl(
    _$RestaurantFilterImpl _value,
    $Res Function(_$RestaurantFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RestaurantFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cuisines = null,
    Object? priceLevel = null,
    Object? amenities = null,
    Object? sortOption = null,
  }) {
    return _then(
      _$RestaurantFilterImpl(
        cuisines: null == cuisines
            ? _value._cuisines
            : cuisines // ignore: cast_nullable_to_non_nullable
                  as Set<RestaurantCuisine>,
        priceLevel: null == priceLevel
            ? _value.priceLevel
            : priceLevel // ignore: cast_nullable_to_non_nullable
                  as RestaurantPriceLevel,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as Set<RestaurantAmenity>,
        sortOption: null == sortOption
            ? _value.sortOption
            : sortOption // ignore: cast_nullable_to_non_nullable
                  as SortOption,
      ),
    );
  }
}

/// @nodoc

class _$RestaurantFilterImpl implements _RestaurantFilter {
  const _$RestaurantFilterImpl({
    final Set<RestaurantCuisine> cuisines = const {},
    this.priceLevel = RestaurantPriceLevel.all,
    final Set<RestaurantAmenity> amenities = const {},
    this.sortOption = SortOption.none,
  }) : _cuisines = cuisines,
       _amenities = amenities;

  /// Danh mục đã chọn (chọn nhiều). Rỗng = tất cả.
  final Set<RestaurantCuisine> _cuisines;

  /// Danh mục đã chọn (chọn nhiều). Rỗng = tất cả.
  @override
  @JsonKey()
  Set<RestaurantCuisine> get cuisines {
    if (_cuisines is EqualUnmodifiableSetView) return _cuisines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_cuisines);
  }

  /// Mức giá đã chọn (chọn 1)
  @override
  @JsonKey()
  final RestaurantPriceLevel priceLevel;

  /// Tiện ích đã chọn (chọn nhiều)
  final Set<RestaurantAmenity> _amenities;

  /// Tiện ích đã chọn (chọn nhiều)
  @override
  @JsonKey()
  Set<RestaurantAmenity> get amenities {
    if (_amenities is EqualUnmodifiableSetView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_amenities);
  }

  /// Tùy chọn sắp xếp
  @override
  @JsonKey()
  final SortOption sortOption;

  @override
  String toString() {
    return 'RestaurantFilter(cuisines: $cuisines, priceLevel: $priceLevel, amenities: $amenities, sortOption: $sortOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantFilterImpl &&
            const DeepCollectionEquality().equals(other._cuisines, _cuisines) &&
            (identical(other.priceLevel, priceLevel) ||
                other.priceLevel == priceLevel) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_cuisines),
    priceLevel,
    const DeepCollectionEquality().hash(_amenities),
    sortOption,
  );

  /// Create a copy of RestaurantFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantFilterImplCopyWith<_$RestaurantFilterImpl> get copyWith =>
      __$$RestaurantFilterImplCopyWithImpl<_$RestaurantFilterImpl>(
        this,
        _$identity,
      );
}

abstract class _RestaurantFilter implements RestaurantFilter {
  const factory _RestaurantFilter({
    final Set<RestaurantCuisine> cuisines,
    final RestaurantPriceLevel priceLevel,
    final Set<RestaurantAmenity> amenities,
    final SortOption sortOption,
  }) = _$RestaurantFilterImpl;

  /// Danh mục đã chọn (chọn nhiều). Rỗng = tất cả.
  @override
  Set<RestaurantCuisine> get cuisines;

  /// Mức giá đã chọn (chọn 1)
  @override
  RestaurantPriceLevel get priceLevel;

  /// Tiện ích đã chọn (chọn nhiều)
  @override
  Set<RestaurantAmenity> get amenities;

  /// Tùy chọn sắp xếp
  @override
  SortOption get sortOption;

  /// Create a copy of RestaurantFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantFilterImplCopyWith<_$RestaurantFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HotelFilter {
  /// Giá tối thiểu (VNĐ). 0 = không giới hạn dưới.
  double get minPrice => throw _privateConstructorUsedError;

  /// Giá tối đa (VNĐ). 0 = không giới hạn trên.
  double get maxPrice => throw _privateConstructorUsedError;

  /// Loại hình lưu trú đã chọn (chọn nhiều). Rỗng = tất cả.
  Set<AccommodationType> get accommodationTypes =>
      throw _privateConstructorUsedError;

  /// Tiện nghi đã chọn (chọn nhiều)
  Set<HotelAmenity> get amenities => throw _privateConstructorUsedError;

  /// Tùy chọn sắp xếp
  SortOption get sortOption => throw _privateConstructorUsedError;

  /// Create a copy of HotelFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HotelFilterCopyWith<HotelFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HotelFilterCopyWith<$Res> {
  factory $HotelFilterCopyWith(
    HotelFilter value,
    $Res Function(HotelFilter) then,
  ) = _$HotelFilterCopyWithImpl<$Res, HotelFilter>;
  @useResult
  $Res call({
    double minPrice,
    double maxPrice,
    Set<AccommodationType> accommodationTypes,
    Set<HotelAmenity> amenities,
    SortOption sortOption,
  });
}

/// @nodoc
class _$HotelFilterCopyWithImpl<$Res, $Val extends HotelFilter>
    implements $HotelFilterCopyWith<$Res> {
  _$HotelFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HotelFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minPrice = null,
    Object? maxPrice = null,
    Object? accommodationTypes = null,
    Object? amenities = null,
    Object? sortOption = null,
  }) {
    return _then(
      _value.copyWith(
            minPrice: null == minPrice
                ? _value.minPrice
                : minPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            maxPrice: null == maxPrice
                ? _value.maxPrice
                : maxPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            accommodationTypes: null == accommodationTypes
                ? _value.accommodationTypes
                : accommodationTypes // ignore: cast_nullable_to_non_nullable
                      as Set<AccommodationType>,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as Set<HotelAmenity>,
            sortOption: null == sortOption
                ? _value.sortOption
                : sortOption // ignore: cast_nullable_to_non_nullable
                      as SortOption,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HotelFilterImplCopyWith<$Res>
    implements $HotelFilterCopyWith<$Res> {
  factory _$$HotelFilterImplCopyWith(
    _$HotelFilterImpl value,
    $Res Function(_$HotelFilterImpl) then,
  ) = __$$HotelFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double minPrice,
    double maxPrice,
    Set<AccommodationType> accommodationTypes,
    Set<HotelAmenity> amenities,
    SortOption sortOption,
  });
}

/// @nodoc
class __$$HotelFilterImplCopyWithImpl<$Res>
    extends _$HotelFilterCopyWithImpl<$Res, _$HotelFilterImpl>
    implements _$$HotelFilterImplCopyWith<$Res> {
  __$$HotelFilterImplCopyWithImpl(
    _$HotelFilterImpl _value,
    $Res Function(_$HotelFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HotelFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minPrice = null,
    Object? maxPrice = null,
    Object? accommodationTypes = null,
    Object? amenities = null,
    Object? sortOption = null,
  }) {
    return _then(
      _$HotelFilterImpl(
        minPrice: null == minPrice
            ? _value.minPrice
            : minPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        maxPrice: null == maxPrice
            ? _value.maxPrice
            : maxPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        accommodationTypes: null == accommodationTypes
            ? _value._accommodationTypes
            : accommodationTypes // ignore: cast_nullable_to_non_nullable
                  as Set<AccommodationType>,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as Set<HotelAmenity>,
        sortOption: null == sortOption
            ? _value.sortOption
            : sortOption // ignore: cast_nullable_to_non_nullable
                  as SortOption,
      ),
    );
  }
}

/// @nodoc

class _$HotelFilterImpl implements _HotelFilter {
  const _$HotelFilterImpl({
    this.minPrice = 0,
    this.maxPrice = 0,
    final Set<AccommodationType> accommodationTypes = const {},
    final Set<HotelAmenity> amenities = const {},
    this.sortOption = SortOption.none,
  }) : _accommodationTypes = accommodationTypes,
       _amenities = amenities;

  /// Giá tối thiểu (VNĐ). 0 = không giới hạn dưới.
  @override
  @JsonKey()
  final double minPrice;

  /// Giá tối đa (VNĐ). 0 = không giới hạn trên.
  @override
  @JsonKey()
  final double maxPrice;

  /// Loại hình lưu trú đã chọn (chọn nhiều). Rỗng = tất cả.
  final Set<AccommodationType> _accommodationTypes;

  /// Loại hình lưu trú đã chọn (chọn nhiều). Rỗng = tất cả.
  @override
  @JsonKey()
  Set<AccommodationType> get accommodationTypes {
    if (_accommodationTypes is EqualUnmodifiableSetView)
      return _accommodationTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_accommodationTypes);
  }

  /// Tiện nghi đã chọn (chọn nhiều)
  final Set<HotelAmenity> _amenities;

  /// Tiện nghi đã chọn (chọn nhiều)
  @override
  @JsonKey()
  Set<HotelAmenity> get amenities {
    if (_amenities is EqualUnmodifiableSetView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_amenities);
  }

  /// Tùy chọn sắp xếp
  @override
  @JsonKey()
  final SortOption sortOption;

  @override
  String toString() {
    return 'HotelFilter(minPrice: $minPrice, maxPrice: $maxPrice, accommodationTypes: $accommodationTypes, amenities: $amenities, sortOption: $sortOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HotelFilterImpl &&
            (identical(other.minPrice, minPrice) ||
                other.minPrice == minPrice) &&
            (identical(other.maxPrice, maxPrice) ||
                other.maxPrice == maxPrice) &&
            const DeepCollectionEquality().equals(
              other._accommodationTypes,
              _accommodationTypes,
            ) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    minPrice,
    maxPrice,
    const DeepCollectionEquality().hash(_accommodationTypes),
    const DeepCollectionEquality().hash(_amenities),
    sortOption,
  );

  /// Create a copy of HotelFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HotelFilterImplCopyWith<_$HotelFilterImpl> get copyWith =>
      __$$HotelFilterImplCopyWithImpl<_$HotelFilterImpl>(this, _$identity);
}

abstract class _HotelFilter implements HotelFilter {
  const factory _HotelFilter({
    final double minPrice,
    final double maxPrice,
    final Set<AccommodationType> accommodationTypes,
    final Set<HotelAmenity> amenities,
    final SortOption sortOption,
  }) = _$HotelFilterImpl;

  /// Giá tối thiểu (VNĐ). 0 = không giới hạn dưới.
  @override
  double get minPrice;

  /// Giá tối đa (VNĐ). 0 = không giới hạn trên.
  @override
  double get maxPrice;

  /// Loại hình lưu trú đã chọn (chọn nhiều). Rỗng = tất cả.
  @override
  Set<AccommodationType> get accommodationTypes;

  /// Tiện nghi đã chọn (chọn nhiều)
  @override
  Set<HotelAmenity> get amenities;

  /// Tùy chọn sắp xếp
  @override
  SortOption get sortOption;

  /// Create a copy of HotelFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HotelFilterImplCopyWith<_$HotelFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
