import { apiClient } from './apiClient';
import { Review, ReviewDetailInfo, ReviewStatsInfo, ItineraryReview, ItineraryReviewStatsInfo } from '../types/review';

type BackendReviewStatus = 'pending' | 'approved' | 'violation';
type BackendReviewClassification = 'short-term' | 'long-term' | 'need-action' | 'unclassified';
type BackendReviewDateSent = 'all' | 'today' | 'yesterday' | 'last_7_days' | 'last_30_days';

interface BackendReviewItem {
  id: string;
  reviewer_name: string;
  place_name: string;
  rating: number;
  review_content: string | null;
  main_topic: string | null;
  status: BackendReviewStatus;
  created_at: string;
}

interface BackendReviewListResponse {
  data: BackendReviewItem[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    total_pages: number;
  };
  summary: {
    total_reviews: number;
    pending_count: number;
    approved_count: number;
    violation_count: number;
  };
}

interface BackendReviewDetailResponse {
  id: string;
  user: {
    id: string;
    name: string;
    review_count: number;
    report_count: number;
  };
  place: {
    id: string;
    name: string;
    address: string;
  };
  rating: number;
  main_topic: string | null;
  review_content: string | null;
  images: Array<{ url: string }>;
  status: BackendReviewStatus;
  created_at: string;
}

interface BackendItineraryReviewItem {
  id: string;
  reviewer_id: string;
  reviewer_name: string;
  reviewer_review_count: number;
  reviewer_report_count: number;
  itinerary_id: string;
  itinerary_name: string;
  itinerary_start_date?: string | null;
  itinerary_end_date?: string | null;
  rating: number;
  review_content: string | null;
  status: BackendReviewStatus;
  created_at: string;
  has_images: boolean;
}

interface BackendItineraryReviewListResponse {
  data: BackendItineraryReviewItem[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    total_pages: number;
  };
  summary: {
    total_reviews: number;
    pending_count: number;
    approved_count: number;
    violation_count: number;
  };
}

export interface ReviewFilterParams {
  search?: string;
  status?: BackendReviewStatus | 'all';
  classification?: BackendReviewClassification | 'all';
  dateSent?: BackendReviewDateSent;
  dateExact?: string;
  rating?: number;
  sort?: 'newest' | 'oldest' | 'highest_rating' | 'lowest_rating';
}

export interface ItineraryReviewFilterParams {
  search?: string;
  status?: BackendReviewStatus | 'all';
  dateSent?: BackendReviewDateSent;
  dateExact?: string;
  rating?: number;
  sort?: 'newest' | 'oldest' | 'highest_rating' | 'lowest_rating';
}

const getInitials = (name: string): string => {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('');
};

const formatDateTime = (value: string): string => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return `${date.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
  })} - ${date.toLocaleDateString('vi-VN')}`;
};

const mapStatus = (status: BackendReviewStatus): Review['status'] => {
  if (status === 'approved') {
    return 'Đã duyệt';
  }
  if (status === 'violation') {
    return 'Vi phạm';
  }
  return 'Chờ duyệt';
};

const mapClassification = (
  topic: string | null,
): 'Ngắn hạn' | 'Dài hạn' | 'Cần xử lý' | 'Chưa phân loại' => {
  if (topic === 'short_term') {
    return 'Ngắn hạn';
  }
  if (topic === 'long_term') {
    return 'Dài hạn';
  }
  if (topic === 'unknown') {
    return 'Cần xử lý';
  }
  return 'Chưa phân loại';
};

const mapReview = (item: BackendReviewItem): Review => ({
  id: item.id,
  userAvatar: getInitials(item.reviewer_name || 'N A'),
  userName: item.reviewer_name || 'Người dùng ẩn danh',
  locationName: item.place_name,
  content: item.review_content || '(Không có nội dung)',
  rating: item.rating,
  date: formatDateTime(item.created_at),
  status: mapStatus(item.status),
  classification: mapClassification(item.main_topic),
});

const mapReviewDetail = (item: BackendReviewDetailResponse): ReviewDetailInfo => ({
  id: item.id,
  userAvatar: getInitials(item.user.name || 'N A'),
  userName: item.user.name,
  totalReviews: item.user.review_count,
  totalReports: item.user.report_count,
  locationName: item.place.name,
  locationAddress: item.place.address,
  rating: item.rating,
  datetime: formatDateTime(item.created_at),
  content: item.review_content || '(Không có nội dung)',
  images: item.images.map((image) => image.url),
  status: mapStatus(item.status),
  classification: mapClassification(item.main_topic),
  reportCount: item.status === 'violation' ? Math.max(item.user.report_count, 1) : 0,
  reportReasons: item.status === 'violation' ? ['Nội dung bị đánh dấu vi phạm'] : [],
  adminNote: item.status === 'violation' ? 'Đánh giá đã được hệ thống gắn nhãn vi phạm.' : '',
});

const toBackendStatus = (status: Review['status']): 'approved' | 'violation' => {
  return status === 'Vi phạm' ? 'violation' : 'approved';
};

export const reviewAPI = {
  getReviews: async (
    page = 1,
    limit = 10,
    filters: ReviewFilterParams = {},
  ): Promise<{ data: Review[]; total: number }> => {
    const response = await apiClient.get<BackendReviewListResponse>('/admin/reviews', {
      params: {
        page,
        limit,
        search: filters.search || undefined,
        status: filters.status && filters.status !== 'all' ? filters.status : undefined,
        sort: filters.sort || 'newest',
        classification:
          filters.classification && filters.classification !== 'all'
            ? filters.classification
            : undefined,
        date_sent: filters.dateSent || 'all',
        date_exact: filters.dateExact || undefined,
        rating: filters.rating || undefined,
      },
    });

    return {
      data: response.data.data.map(mapReview),
      total: response.data.pagination.total,
    };
  },

  getReviewStats: async (): Promise<ReviewStatsInfo> => {
    const response = await apiClient.get<BackendReviewListResponse>('/admin/reviews', {
      params: {
        page: 1,
        limit: 1,
      },
    });

    return {
      totalReviews: response.data.summary.total_reviews,
      pendingReviews: response.data.summary.pending_count,
      violationReviews: response.data.summary.violation_count,
    };
  },

  getReviewById: async (id: string): Promise<ReviewDetailInfo> => {
    const response = await apiClient.get<BackendReviewDetailResponse>(`/admin/reviews/${id}`);
    return mapReviewDetail(response.data);
  },

  updateReviewStatus: async (
    id: string,
    status: Review['status'],
    reason?: string,
  ): Promise<void> => {
    const backendStatus = toBackendStatus(status);

    if (backendStatus === 'approved') {
      await apiClient.put(`/admin/reviews/${id}/approve`);
      return;
    }

    await apiClient.put(`/admin/reviews/${id}/reject`, {
      status: 'violation',
      reason: reason || 'Đánh giá vi phạm chính sách nội dung.',
    });
  },
};

export const itineraryReviewAPI = {
  getItineraryReviews: async (
    page = 1,
    limit = 10,
    filters: ItineraryReviewFilterParams = {},
  ): Promise<{ data: ItineraryReview[]; total: number }> => {
    try {
      const response = await apiClient.get<BackendItineraryReviewListResponse>('/admin/itinerary-reviews', {
        params: {
          page,
          limit,
          search: filters.search || undefined,
          status: filters.status && filters.status !== 'all' ? filters.status : undefined,
          sort: filters.sort || 'newest',
          date_sent: filters.dateSent || 'all',
          date_exact: filters.dateExact || undefined,
          rating: filters.rating || undefined,
        },
      });

      return {
        data: response.data.data.map((item) => ({
          id: item.id,
          userAvatar: getInitials(item.reviewer_name || 'N A'),
          userName: item.reviewer_name || 'Người dùng ẩn danh',
          itineraryName: item.itinerary_name,
          content: item.review_content || '(Không có nội dung)',
          rating: item.rating,
          date: formatDateTime(item.created_at),
          status: mapStatus(item.status),
        })),
        total: response.data.pagination.total,
      };
    } catch {
      return { data: [], total: 0 };
    }
  },

  getItineraryReviewStats: async (): Promise<ItineraryReviewStatsInfo> => {
    try {
      const response = await apiClient.get<BackendItineraryReviewListResponse>('/admin/itinerary-reviews', {
        params: { page: 1, limit: 1 },
      });

      return {
        totalReviews: response.data.summary.total_reviews,
        pendingReviews: response.data.summary.pending_count,
        violationReviews: response.data.summary.violation_count,
      };
    } catch {
      return { totalReviews: 0, pendingReviews: 0, violationReviews: 0 };
    }
  },

  updateItineraryReviewStatus: async (
    id: string,
    status: ItineraryReview['status'],
    reason?: string,
  ): Promise<void> => {
    const backendStatus = toBackendStatus(status);

    if (backendStatus === 'approved') {
      await apiClient.put(`/admin/itinerary-reviews/${id}/approve`);
      return;
    }

    await apiClient.put(`/admin/itinerary-reviews/${id}/reject`, {
      status: 'violation',
      reason: reason || 'Đánh giá vi phạm chính sách nội dung.',
    });
  },
};
