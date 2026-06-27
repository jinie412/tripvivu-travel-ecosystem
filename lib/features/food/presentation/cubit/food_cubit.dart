import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';
import 'package:travel_advisor_mobile/features/food/domain/entities/food_item_entity.dart';

class FoodState extends Equatable {
  static const allCategoryLabel = 'Tất cả';
  static const mainCategoryLabel = 'Món chính';
  static const drinkCategoryLabel = 'Đồ uống';

  final String placeId;
  final String? itineraryDetailId;
  final String restaurantName;
  final List<FoodItemEntity> allItems;
  final List<String> mainCategories;
  final String selectedMainCategory;
  final String selectedSubCategory;
  final List<String> subCategories;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const FoodState({
    required this.placeId,
    required this.itineraryDetailId,
    required this.restaurantName,
    required this.allItems,
    required this.mainCategories,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.subCategories,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  factory FoodState.initial() => const FoodState(
        placeId: '',
        itineraryDetailId: null,
        restaurantName: '',
        allItems: [],
        mainCategories: [
          FoodState.allCategoryLabel,
          FoodState.mainCategoryLabel,
          FoodState.drinkCategoryLabel,
        ],
        selectedMainCategory: FoodState.allCategoryLabel,
        selectedSubCategory: FoodState.allCategoryLabel,
        subCategories: [FoodState.allCategoryLabel],
        isLoading: false,
        isSubmitting: false,
        errorMessage: null,
      );

  List<FoodItemEntity> get filteredItems {
    var items = allItems;

    if (selectedMainCategory != FoodState.allCategoryLabel) {
      if (selectedMainCategory == FoodState.drinkCategoryLabel) {
        items = items.where((i) => i.category == 'drink').toList();
      } else {
        items = items.where((i) => i.category == 'main').toList();
      }
    }

    if (selectedSubCategory != FoodState.allCategoryLabel) {
      if (selectedSubCategory == FoodState.drinkCategoryLabel) {
        items = items.where((i) => i.category == 'drink').toList();
      } else if (selectedSubCategory == FoodState.mainCategoryLabel) {
        items = items.where((i) => i.category == 'main').toList();
      }
    }

    return items;
  }

  double get totalPrice =>
      allItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get totalItems => allItems.fold(0, (sum, item) => sum + item.quantity);

  FoodState copyWith({
    String? placeId,
    String? itineraryDetailId,
    bool clearItineraryDetailId = false,
    String? restaurantName,
    List<FoodItemEntity>? allItems,
    String? selectedMainCategory,
    String? selectedSubCategory,
    List<String>? subCategories,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return FoodState(
      placeId: placeId ?? this.placeId,
      itineraryDetailId: clearItineraryDetailId
          ? null
          : (itineraryDetailId ?? this.itineraryDetailId),
      restaurantName: restaurantName ?? this.restaurantName,
      allItems: allItems ?? this.allItems,
      mainCategories: mainCategories,
      selectedMainCategory: selectedMainCategory ?? this.selectedMainCategory,
      selectedSubCategory: selectedSubCategory ?? this.selectedSubCategory,
      subCategories: subCategories ?? this.subCategories,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        placeId,
        itineraryDetailId,
        restaurantName,
        allItems,
        mainCategories,
        selectedMainCategory,
        selectedSubCategory,
        subCategories,
        isLoading,
        isSubmitting,
        errorMessage,
      ];
}

class FoodCubit extends Cubit<FoodState> {
  final FoodRemoteDataSource _remote;

  FoodCubit({required FoodRemoteDataSource remote})
      : _remote = remote,
        super(FoodState.initial());

  Future<void> loadRestaurantMenu({
    required String placeId,
    required String restaurantName,
    String? itineraryDetailId,
  }) async {
    print('[FoodCubit] loadRestaurantMenu called | placeId="$placeId" | restaurant="$restaurantName"');
    emit(state.copyWith(
      placeId: placeId,
      itineraryDetailId: itineraryDetailId,
      restaurantName: restaurantName,
      allItems: const [],
      subCategories: const [FoodState.allCategoryLabel],
      selectedMainCategory: FoodState.allCategoryLabel,
      selectedSubCategory: FoodState.allCategoryLabel,
      isLoading: true,
      clearErrorMessage: true,
    ));

    try {
      final result = await _remote.getFoodItems(placeId: placeId);
      final subCats = _buildSubCategories(result.items);

      emit(state.copyWith(
        placeId: placeId,
        itineraryDetailId: itineraryDetailId,
        restaurantName:
            result.placeName.isNotEmpty ? result.placeName : restaurantName,
        allItems: result.items,
        subCategories: subCats,
        selectedMainCategory: FoodState.allCategoryLabel,
        selectedSubCategory: FoodState.allCategoryLabel,
        isLoading: false,
        clearErrorMessage: true,
      ));
    } catch (e, st) {
      print('[FoodCubit] loadRestaurantMenu error | placeId=$placeId | $e');
      print(st);
      emit(state.copyWith(
        placeId: placeId,
        itineraryDetailId: itineraryDetailId,
        restaurantName: restaurantName,
        allItems: const [],
        subCategories: const [FoodState.allCategoryLabel],
        selectedMainCategory: FoodState.allCategoryLabel,
        selectedSubCategory: FoodState.allCategoryLabel,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  List<String> _buildSubCategories(List<FoodItemEntity> items) {
    final sub = items
        .map(
          (item) => item.category == 'drink'
              ? FoodState.drinkCategoryLabel
              : FoodState.mainCategoryLabel,
        )
        .toSet()
        .toList();
    sub.sort();
    return [FoodState.allCategoryLabel, ...sub];
  }

  void selectMainCategory(String cat) {
    emit(state.copyWith(
      selectedMainCategory: cat,
      selectedSubCategory: FoodState.allCategoryLabel,
    ));
  }

  void selectSubCategory(String subCat) {
    emit(state.copyWith(selectedSubCategory: subCat));
  }

  void updateQuantity(String id, int delta) {
    final newItems = state.allItems.map((item) {
      if (item.id == id) {
        final newQty = (item.quantity + delta).clamp(0, 99);
        return item.copyWith(quantity: newQty);
      }
      return item;
    }).toList();
    emit(state.copyWith(allItems: newItems));
  }

  Future<CreateOrderResult> submitOrder({String? notes}) async {
    final selectedItems = state.allItems
        .where((item) => item.quantity > 0)
        .map(
          (item) => CreateOrderItemInput(
            foodItemId: item.id,
            quantity: item.quantity,
          ),
        )
        .toList();

    if (selectedItems.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất một món');
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final result = await _remote.createOrder(
        placeId: state.placeId,
        itineraryDetailId: state.itineraryDetailId,
        notes: notes,
        items: selectedItems,
      );

      final resetItems =
          state.allItems.map((item) => item.copyWith(quantity: 0)).toList();
      emit(state.copyWith(allItems: resetItems, isSubmitting: false));
      return result;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
