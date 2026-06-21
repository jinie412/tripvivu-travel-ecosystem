import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

enum SearchType { itinerary, activity, restaurant, hotel }

class SearchTypeCount<T> {
  final List<T> data;
  final int total;
  const SearchTypeCount({required this.data, required this.total});
}

class SearchMultiResults {
  final SearchTypeCount<CityItinerary> itineraries;
  final SearchTypeCount<CityActivity> activities;
  final SearchTypeCount<CityRestaurant> restaurants;
  final SearchTypeCount<CityHotel> hotels;
  final Map<String, String> cityById;

  const SearchMultiResults({
    required this.itineraries,
    required this.activities,
    required this.restaurants,
    required this.hotels,
    this.cityById = const {},
  });

  bool get isEmpty =>
      itineraries.data.isEmpty &&
      activities.data.isEmpty &&
      restaurants.data.isEmpty &&
      hotels.data.isEmpty;

  static SearchMultiResults empty() => const SearchMultiResults(
        itineraries: SearchTypeCount(data: [], total: 0),
        activities: SearchTypeCount(data: [], total: 0),
        restaurants: SearchTypeCount(data: [], total: 0),
        hotels: SearchTypeCount(data: [], total: 0),
      );
}

class SearchPageResult {
  final List<dynamic> data;
  final int total;
  final int page;
  final int pages;

  const SearchPageResult({
    required this.data,
    required this.total,
    required this.page,
    required this.pages,
  });

  bool get hasMore => page < pages;
}

class FlatSearchItem {
  final SearchType type;
  final String id;
  final dynamic data;
  final String city;

  const FlatSearchItem({
    required this.type,
    required this.id,
    required this.data,
    required this.city,
  });
}
