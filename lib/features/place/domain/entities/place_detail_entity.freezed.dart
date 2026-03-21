// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_detail_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlaceDetailEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  int get totalReviews => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get openingHours => throw _privateConstructorUsedError;
  String get closingHours => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  List<PlaceReviewEntity> get reviews => throw _privateConstructorUsedError;
  List<PlaceEntity> get relatedPlaces => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;

  /// Create a copy of PlaceDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaceDetailEntityCopyWith<PlaceDetailEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaceDetailEntityCopyWith<$Res> {
  factory $PlaceDetailEntityCopyWith(
    PlaceDetailEntity value,
    $Res Function(PlaceDetailEntity) then,
  ) = _$PlaceDetailEntityCopyWithImpl<$Res, PlaceDetailEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    String district,
    String city,
    double rating,
    int totalReviews,
    List<String> tags,
    List<String> images,
    String description,
    String openingHours,
    String closingHours,
    String phone,
    List<PlaceReviewEntity> reviews,
    List<PlaceEntity> relatedPlaces,
    bool isFavorite,
  });
}

/// @nodoc
class _$PlaceDetailEntityCopyWithImpl<$Res, $Val extends PlaceDetailEntity>
    implements $PlaceDetailEntityCopyWith<$Res> {
  _$PlaceDetailEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaceDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? district = null,
    Object? city = null,
    Object? rating = null,
    Object? totalReviews = null,
    Object? tags = null,
    Object? images = null,
    Object? description = null,
    Object? openingHours = null,
    Object? closingHours = null,
    Object? phone = null,
    Object? reviews = null,
    Object? relatedPlaces = null,
    Object? isFavorite = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            district: null == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            totalReviews: null == totalReviews
                ? _value.totalReviews
                : totalReviews // ignore: cast_nullable_to_non_nullable
                      as int,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            openingHours: null == openingHours
                ? _value.openingHours
                : openingHours // ignore: cast_nullable_to_non_nullable
                      as String,
            closingHours: null == closingHours
                ? _value.closingHours
                : closingHours // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            reviews: null == reviews
                ? _value.reviews
                : reviews // ignore: cast_nullable_to_non_nullable
                      as List<PlaceReviewEntity>,
            relatedPlaces: null == relatedPlaces
                ? _value.relatedPlaces
                : relatedPlaces // ignore: cast_nullable_to_non_nullable
                      as List<PlaceEntity>,
            isFavorite: null == isFavorite
                ? _value.isFavorite
                : isFavorite // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaceDetailEntityImplCopyWith<$Res>
    implements $PlaceDetailEntityCopyWith<$Res> {
  factory _$$PlaceDetailEntityImplCopyWith(
    _$PlaceDetailEntityImpl value,
    $Res Function(_$PlaceDetailEntityImpl) then,
  ) = __$$PlaceDetailEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    String district,
    String city,
    double rating,
    int totalReviews,
    List<String> tags,
    List<String> images,
    String description,
    String openingHours,
    String closingHours,
    String phone,
    List<PlaceReviewEntity> reviews,
    List<PlaceEntity> relatedPlaces,
    bool isFavorite,
  });
}

/// @nodoc
class __$$PlaceDetailEntityImplCopyWithImpl<$Res>
    extends _$PlaceDetailEntityCopyWithImpl<$Res, _$PlaceDetailEntityImpl>
    implements _$$PlaceDetailEntityImplCopyWith<$Res> {
  __$$PlaceDetailEntityImplCopyWithImpl(
    _$PlaceDetailEntityImpl _value,
    $Res Function(_$PlaceDetailEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaceDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? district = null,
    Object? city = null,
    Object? rating = null,
    Object? totalReviews = null,
    Object? tags = null,
    Object? images = null,
    Object? description = null,
    Object? openingHours = null,
    Object? closingHours = null,
    Object? phone = null,
    Object? reviews = null,
    Object? relatedPlaces = null,
    Object? isFavorite = null,
  }) {
    return _then(
      _$PlaceDetailEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        district: null == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        totalReviews: null == totalReviews
            ? _value.totalReviews
            : totalReviews // ignore: cast_nullable_to_non_nullable
                  as int,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        openingHours: null == openingHours
            ? _value.openingHours
            : openingHours // ignore: cast_nullable_to_non_nullable
                  as String,
        closingHours: null == closingHours
            ? _value.closingHours
            : closingHours // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        reviews: null == reviews
            ? _value._reviews
            : reviews // ignore: cast_nullable_to_non_nullable
                  as List<PlaceReviewEntity>,
        relatedPlaces: null == relatedPlaces
            ? _value._relatedPlaces
            : relatedPlaces // ignore: cast_nullable_to_non_nullable
                  as List<PlaceEntity>,
        isFavorite: null == isFavorite
            ? _value.isFavorite
            : isFavorite // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$PlaceDetailEntityImpl implements _PlaceDetailEntity {
  const _$PlaceDetailEntityImpl({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.rating,
    required this.totalReviews,
    final List<String> tags = const [],
    final List<String> images = const [],
    required this.description,
    required this.openingHours,
    required this.closingHours,
    required this.phone,
    final List<PlaceReviewEntity> reviews = const [],
    final List<PlaceEntity> relatedPlaces = const [],
    this.isFavorite = false,
  }) : _tags = tags,
       _images = images,
       _reviews = reviews,
       _relatedPlaces = relatedPlaces;

  @override
  final String id;
  @override
  final String name;
  @override
  final String address;
  @override
  final String district;
  @override
  final String city;
  @override
  final double rating;
  @override
  final int totalReviews;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final String description;
  @override
  final String openingHours;
  @override
  final String closingHours;
  @override
  final String phone;
  final List<PlaceReviewEntity> _reviews;
  @override
  @JsonKey()
  List<PlaceReviewEntity> get reviews {
    if (_reviews is EqualUnmodifiableListView) return _reviews;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reviews);
  }

  final List<PlaceEntity> _relatedPlaces;
  @override
  @JsonKey()
  List<PlaceEntity> get relatedPlaces {
    if (_relatedPlaces is EqualUnmodifiableListView) return _relatedPlaces;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedPlaces);
  }

  @override
  @JsonKey()
  final bool isFavorite;

  @override
  String toString() {
    return 'PlaceDetailEntity(id: $id, name: $name, address: $address, district: $district, city: $city, rating: $rating, totalReviews: $totalReviews, tags: $tags, images: $images, description: $description, openingHours: $openingHours, closingHours: $closingHours, phone: $phone, reviews: $reviews, relatedPlaces: $relatedPlaces, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceDetailEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.totalReviews, totalReviews) ||
                other.totalReviews == totalReviews) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.openingHours, openingHours) ||
                other.openingHours == openingHours) &&
            (identical(other.closingHours, closingHours) ||
                other.closingHours == closingHours) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            const DeepCollectionEquality().equals(other._reviews, _reviews) &&
            const DeepCollectionEquality().equals(
              other._relatedPlaces,
              _relatedPlaces,
            ) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    address,
    district,
    city,
    rating,
    totalReviews,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_images),
    description,
    openingHours,
    closingHours,
    phone,
    const DeepCollectionEquality().hash(_reviews),
    const DeepCollectionEquality().hash(_relatedPlaces),
    isFavorite,
  );

  /// Create a copy of PlaceDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceDetailEntityImplCopyWith<_$PlaceDetailEntityImpl> get copyWith =>
      __$$PlaceDetailEntityImplCopyWithImpl<_$PlaceDetailEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _PlaceDetailEntity implements PlaceDetailEntity {
  const factory _PlaceDetailEntity({
    required final String id,
    required final String name,
    required final String address,
    required final String district,
    required final String city,
    required final double rating,
    required final int totalReviews,
    final List<String> tags,
    final List<String> images,
    required final String description,
    required final String openingHours,
    required final String closingHours,
    required final String phone,
    final List<PlaceReviewEntity> reviews,
    final List<PlaceEntity> relatedPlaces,
    final bool isFavorite,
  }) = _$PlaceDetailEntityImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get address;
  @override
  String get district;
  @override
  String get city;
  @override
  double get rating;
  @override
  int get totalReviews;
  @override
  List<String> get tags;
  @override
  List<String> get images;
  @override
  String get description;
  @override
  String get openingHours;
  @override
  String get closingHours;
  @override
  String get phone;
  @override
  List<PlaceReviewEntity> get reviews;
  @override
  List<PlaceEntity> get relatedPlaces;
  @override
  bool get isFavorite;

  /// Create a copy of PlaceDetailEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaceDetailEntityImplCopyWith<_$PlaceDetailEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
