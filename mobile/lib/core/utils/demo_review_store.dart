class DemoReviewStore {
  /// Lưu trữ đánh giá của địa điểm: locationId -> rating
  static final Map<String, double> userRatings = {};
  
  /// Lưu trữ bình luận của địa điểm: locationId -> comment
  static final Map<String, String> userComments = {};

  /// Lưu trữ đánh giá tổng thể lịch trình: itineraryId -> rating
  static final Map<String, double> itineraryOverallRatings = {};
  
  /// Lưu trữ bình luận tổng thể lịch trình: itineraryId -> comment
  static final Map<String, String> itineraryOverallComments = {};

  /// Lưu đánh giá của một địa điểm cụ thể
  static void saveLocationRating(String locationId, double rating, {String? comment}) {
    userRatings[locationId] = rating;
    if (comment != null) userComments[locationId] = comment;
  }

  /// Lấy đánh giá của một địa điểm
  static double? getLocationRating(String locationId) {
    return userRatings[locationId];
  }

  /// Lưu đánh giá tổng thể lịch trình
  static void saveItineraryReview(String itineraryId, double rating, {String? comment}) {
    itineraryOverallRatings[itineraryId] = rating;
    if (comment != null) itineraryOverallComments[itineraryId] = comment;
  }
}
