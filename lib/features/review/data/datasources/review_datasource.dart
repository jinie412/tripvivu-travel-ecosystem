import '../models/itinerary_review_model.dart';
import '../models/location_review_model.dart';

abstract class ReviewDataSource {
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId);
}

class MockReviewDataSource implements ReviewDataSource {
  @override
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return const ItineraryReviewModel(
      id: 'it1',
      title: 'Du lịch thành phố Hồ Chí Minh',
      imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=2070',
      dateRange: 'July 15 - July 26, 2026',
      status: 'HOÀN THÀNH',
      locations: [
        LocationReviewModel(
          id: 'loc1',
          name: 'Nhà thờ Đức Bà',
          imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?q=80&w=2128',
          day: 1,
        ),
        LocationReviewModel(
          id: 'loc2',
          name: 'Bưu điện thành phố',
          imageUrl: 'https://images.unsplash.com/photo-1582299537637-77db8b22a000?q=80&w=2128',
          day: 2,
        ),
        LocationReviewModel(
          id: 'loc3',
          name: 'Chợ Bến Thành',
          imageUrl: 'https://images.unsplash.com/photo-1616052787884-255d6b49079a?q=80&w=2070',
          day: 2,
        ),
      ],
    );
  }
}
