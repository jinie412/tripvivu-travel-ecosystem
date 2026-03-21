import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/food_item_entity.dart';

class FoodState extends Equatable {
  final String restaurantName;
  final List<FoodItemEntity> allItems;
  final List<String> mainCategories;
  final String selectedMainCategory;
  final String selectedSubCategory; // For the dropdown
  final List<String> subCategories;

  const FoodState({
    required this.restaurantName,
    required this.allItems,
    required this.mainCategories,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.subCategories,
  });

  factory FoodState.initial() => const FoodState(
        restaurantName: '',
        allItems: [],
        mainCategories: ['Tất cả', 'Món chính', 'Đồ uống'],
        selectedMainCategory: 'Tất cả',
        selectedSubCategory: 'Tất cả',
        subCategories: ['Tất cả'],
      );

  List<FoodItemEntity> get filteredItems {
    var items = allItems;
    if (selectedMainCategory != 'Tất cả') {
       // Simple mock filtering logic
       if (selectedMainCategory == 'Đồ uống') {
         items = items.where((i) => i.id.contains('drink')).toList();
       } else {
         items = items.where((i) => !i.id.contains('drink')).toList();
       }
    }
    
    if (selectedSubCategory != 'Tất cả') {
      items = items.where((i) => i.title.contains(selectedSubCategory)).toList();
    }
    
    return items;
  }

  double get totalPrice => allItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get totalItems => allItems.fold(0, (sum, item) => sum + item.quantity);

  FoodState copyWith({
    String? restaurantName,
    List<FoodItemEntity>? allItems,
    String? selectedMainCategory,
    String? selectedSubCategory,
    List<String>? subCategories,
  }) {
    return FoodState(
      restaurantName: restaurantName ?? this.restaurantName,
      allItems: allItems ?? this.allItems,
      mainCategories: mainCategories,
      selectedMainCategory: selectedMainCategory ?? this.selectedMainCategory,
      selectedSubCategory: selectedSubCategory ?? this.selectedSubCategory,
      subCategories: subCategories ?? this.subCategories,
    );
  }

  @override
  List<Object?> get props => [
        restaurantName,
        allItems,
        mainCategories,
        selectedMainCategory,
        selectedSubCategory,
        subCategories,
      ];
}

class FoodCubit extends Cubit<FoodState> {
  FoodCubit() : super(FoodState.initial());

  void loadRestaurantMenu(String restaurantName) {
    // Mock "database" load for specific restaurant
    final isComTam = restaurantName.contains('Cơm tấm');
    
    final mockItems = isComTam ? _comTamMenu() : _generalMenu();
    final subCats = isComTam ? ['Tất cả', 'Cơm tấm', 'Sườn non', 'Khác'] : ['Tất cả', 'Phở', 'Bún', 'Bánh mì'];

    emit(state.copyWith(
      restaurantName: restaurantName,
      allItems: mockItems,
      subCategories: subCats,
      selectedMainCategory: 'Tất cả',
      selectedSubCategory: 'Tất cả',
    ));
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

  List<FoodItemEntity> _comTamMenu() {
    return [
      const FoodItemEntity(
        id: 'food-001',
        title: 'Cơm tấm sườn bì chả',
        description: 'Đặc sản trứ danh, sườn nướng mật ong béo ngậy kèm bì chả truyền thống.',
        price: 75000,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
      ),
      const FoodItemEntity(
        id: 'food-002',
        title: 'Cơm sườn non nướng',
        description: 'Sườn non nguyên bẹ, ướp gia vị đậm đà, nướng than hồng thơm nức.',
        price: 95000,
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&q=80',
      ),
       const FoodItemEntity(
        id: 'drink-001',
        title: 'Sữa hột gà',
        description: 'Thức uống bổ dưỡng truyền thống, béo ngậy hương vị xưa.',
        price: 35000,
        imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400&q=80',
      ),
       const FoodItemEntity(
        id: 'drink-002',
        title: 'Trà đá dư vị',
        description: 'Trà nồng ấm đá mát lạnh, giải nhiệt ngày nắng.',
        price: 5000,
        imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80',
      ),
    ];
  }

  List<FoodItemEntity> _generalMenu() {
    return [
       const FoodItemEntity(
        id: 'food-gen-001',
        title: 'Món ăn đặc sắc',
        description: 'Vui lòng chọn nhà hàng cụ thể để xem thực đơn chính xác.',
        price: 50000,
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
      ),
    ];
  }
}
