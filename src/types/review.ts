export interface Review {
  id: string;
  userAvatar: string;
  userName: string;
  locationId?: string;
  locationName: string;
  content: string;
  rating: number;
  reviewType?: string;
  date: string;
  status: 'Chờ duyệt' | 'Đã duyệt' | 'Vi phạm' | 'Đã ẩn';
  classification?: 'Ngắn hạn' | 'Dài hạn' | 'Cần xử lý' | 'Chưa phân loại';
}

export interface ItineraryReview {
  id: string;
  userAvatar: string;
  userName: string;
  itineraryName: string;
  content: string;
  rating: number;
  date: string;
  status: 'Chờ duyệt' | 'Đã duyệt' | 'Vi phạm' | 'Đã ẩn';
}

export interface ItineraryReviewStatsInfo {
  totalReviews: number;
  pendingReviews: number;
  violationReviews: number;
}

export interface ReviewDetailInfo {
  id: string;
  // Thông tin người đánh giá
  userAvatar: string;
  userName: string;
  totalReviews: number;
  totalReports: number;
  // Thông tin địa điểm
  locationName: string;
  locationAddress: string;
  // Nội dung đánh giá
  rating: number;
  reviewType?: string;
  datetime: string;
  content: string;
  images: string[];
  // Báo cáo vi phạm từ người dùng
  status?: 'Chờ duyệt' | 'Đã duyệt' | 'Vi phạm' | 'Đã ẩn';
  violation_reason?: string | null;
  classification: 'Ngắn hạn' | 'Dài hạn' | 'Cần xử lý' | 'Chưa phân loại';
  reportCount: number;
  reportReasons: string[];
  adminNote: string;
}

export interface ReviewStatsInfo {
  totalReviews: number;
  pendingReviews: number;
  violationReviews: number;
}

export interface ItineraryReviewDetailInfo {
  id: string;
  // Reviewer info
  userAvatar: string;
  userName: string;
  totalReviews: number;
  totalReports: number;
  // Itinerary info
  itineraryName: string;
  itineraryStartDate?: string;
  itineraryEndDate?: string;
  // Review content
  rating: number;
  datetime: string;
  content: string;
  images: string[];
  // Status / violations
  status?: 'Chờ duyệt' | 'Đã duyệt' | 'Vi phạm' | 'Đã ẩn';
  violation_reason?: string | null;
  reportCount: number;
  reportReasons: string[];
  adminNote: string;
}
