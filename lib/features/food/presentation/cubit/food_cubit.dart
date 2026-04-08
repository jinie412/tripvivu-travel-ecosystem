import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';
import 'package:travel_advisor_mobile/features/food/domain/entities/food_item_entity.dart';

class FoodState extends Equatable {
  final String placeId;
  final String? itineraryDetailId;
  final String restaurantName;
  final List<FoodItemEntity> allItems;
  final List<String> mainCategories;
  final String selectedMainCategory;
  final String selectedSubCategory;
  final List<String> subCategories;
  final bool isSubmitting;

  const FoodState({
    required this.placeId,
    required this.itineraryDetailId,
    required this.restaurantName,
    required this.allItems,
    required this.mainCategories,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.subCategories,
    required this.isSubmitting,
  });

  factory FoodState.initial() => const FoodState(
        placeId: '',
        itineraryDetailId: null,
        restaurantName: '',
        allItems: [],
        mainCategories: ['Tất cả', 'Món chính', 'Đồ uống'],
        selectedMainCategory: 'Tất cả',
        selectedSubCategory: 'Tất cả',
        subCategories: ['Tất cả'],
        isSubmitting: false,
      );

  List<FoodItemEntity> get filteredItems {
    var items = allItems;

    if (selectedMainCategory != 'Tất cả') {
      if (selectedMainCategory == 'Đồ uống') {
        items = items.where((i) => i.category == 'drink').toList();
      } else {
        items = items.where((i) => i.category == 'main').toList();
      }
    }

    if (selectedSubCategory != 'Tất cả') {
      if (selectedSubCategory == 'Đồ uống') {
        items = items.where((i) => i.category == 'drink').toList();
      } else if (selectedSubCategory == 'Món chính') {
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
    bool? isSubmitting,
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
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
        isSubmitting,
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
        selectedMainCategory: 'Tất cả',
        selectedSubCategory: 'Tất cả',
      ));
    } catch (_) {
      final isComTam = restaurantName.contains('Cơm tấm');
      final mockItems = isComTam ? _comTamMenu() : _generalMenu();
      final subCats = _buildSubCategories(mockItems);

      emit(state.copyWith(
        placeId: placeId,
        itineraryDetailId: itineraryDetailId,
        restaurantName: restaurantName,
        allItems: mockItems,
        subCategories: subCats,
        selectedMainCategory: 'Tất cả',
        selectedSubCategory: 'Tất cả',
      ));
    }
  }

  List<String> _buildSubCategories(List<FoodItemEntity> items) {
    final sub = items
        .map((item) => item.category == 'drink' ? 'Đồ uống' : 'Món chính')
        .toSet()
        .toList();
    sub.sort();
    return ['Tất cả', ...sub];
  }

  void selectMainCategory(String cat) {
    emit(state.copyWith(selectedMainCategory: cat, selectedSubCategory: 'Tất cả'));
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

      final resetItems = state.allItems
          .map((item) => item.copyWith(quantity: 0))
          .toList();
      emit(state.copyWith(allItems: resetItems, isSubmitting: false));
      return result;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  List<FoodItemEntity> _comTamMenu() {
    return const [
      FoodItemEntity(
        id: 'food-001',
        title: 'Cơm tấm sườn bì chả',
        description:
            'Đặc sản trứ danh, sườn nướng mật ong béo ngậy kèm bì chả truyền thống.',
        price: 75000,
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
        category: 'main',
      ),
      FoodItemEntity(
        id: 'food-002',
        title: 'Cơm sườn non nướng',
        description:
            'Sườn non nguyên bẹ, ướp gia vị đậm đà, nướng than hồng thơm nức.',
        price: 95000,
        imageUrl:
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&q=80',
        category: 'main',
      ),
      FoodItemEntity(
        id: 'drink-001',
        title: 'Sữa hột gà',
        description: 'Thức uống bổ dưỡng truyền thống, béo ngậy hương vị xưa.',
        price: 35000,
        imageUrl:
            'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400&q=80',
        category: 'drink',
      ),
      FoodItemEntity(
        id: 'drink-002',
        title: 'Trà đá dư vị',
        description: 'Trà nồng ấm đá mát lạnh, giải nhiệt ngày nắng.',
        price: 5000,
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80',
        category: 'drink',
      ),
    ];
  }

  List<FoodItemEntity> _generalMenu() {
    return const [
      FoodItemEntity(
        id: 'food-gen-001',
        title: 'Món ăn đặc sắc',
        description: 'Vui lòng chọn nhà hàng cụ thể để xem thực đơn chính xác.',
        price: 50000,
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
        category: 'main',
      ),
    ];
  }
}
