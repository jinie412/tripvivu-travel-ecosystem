import { apiClient } from './apiClient';
import { Review, ReviewDetailInfo, ReviewStatsInfo, ItineraryReview, ItineraryReviewStatsInfo, ItineraryReviewDetailInfo } from '../types/review';

type BackendReviewStatus = 'pending' | 'approved' | 'violation' | 'hidden';
type BackendReviewClassification = 'short-term' | 'long-term' | 'need-action' | 'unclassified';
type EditableBackendReviewClassification = 'short-term' | 'long-term';
type BackendReviewDateSent = 'all' | 'today' | 'yesterday' | 'last_7_days' | 'last_30_days';

interface BackendReviewItem {
  id: string;
  reviewer_name: string;
  place_id: string;
  place_name: string;
  rating: number;
  review_type: string;
  review_content: string | null;
  main_topic: string | null;
  time_label: string | null;
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
  review_type: string;
  main_topic: string | null;
  time_label: string | null;
  review_content: string | null;
  images: Array<{ url: string }>;
  status: BackendReviewStatus;
  violation_reason: string | null;
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

interface BackendItineraryReviewDetailResponse {
  id: string;
  reviewer: {
    id: string;
    name: string;
    review_count: number;
    report_count: number;
  };
  itinerary: {
    id: string;
    name: string;
    start_date?: string | null;
    end_date?: string | null;
  };
  rating: number;
  review_content: string | null;
  images: Array<{ url: string }>;
  status: BackendReviewStatus;
  violation_reason: string | null;
  created_at: string;
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
  if (status === 'hidden') {
    return 'Đã ẩn';
  }
  if (status === 'approved') {
    return 'Đã duyệt';
  }
  if (status === 'violation') {
    return 'Vi phạm';
  }
  return 'Chờ duyệt';
};

const mapClassification = (
  timeLabel: string | null,
): 'Ngắn hạn' | 'Dài hạn' | 'Cần xử lý' | 'Chưa phân loại' => {
  if (timeLabel === 'short-term') {
    return 'Ngắn hạn';
  }
  if (timeLabel === 'long-term') {
    return 'Dài hạn';
  }
  if (timeLabel === 'amb') {
    return 'Cần xử lý';
  }
  return 'Chưa phân loại';
};

const mapReview = (item: BackendReviewItem): Review => ({
  id: item.id,
  userAvatar: getInitials(item.reviewer_name || 'N A'),
  userName: item.reviewer_name || 'Người dùng ẩn danh',
  locationId: item.place_id,
  locationName: item.place_name,
  content: item.review_content || '(Không có nội dung)',
  rating: item.rating,
  reviewType: item.review_type,
  date: formatDateTime(item.created_at),
  status: mapStatus(item.status),
  classification:
    item.review_type === 'with_content'
      ? mapClassification(item.time_label)
      : undefined,
});

const mapReviewDetail = (item: BackendReviewDetailResponse): ReviewDetailInfo => ({
  id: item.id,
  userAvatar: getInitials(item.user.name || 'N A'),
  userName: item.user.name,
  totalReviews: item.user.review_count,
  totalReports: item.user.report_count,
  locationId: item.place.id,
  locationName: item.place.name,
  locationAddress: item.place.address,
  rating: item.rating,
  reviewType: item.review_type,
  datetime: formatDateTime(item.created_at),
  content: item.review_content || '(Không có nội dung)',
  images: item.images.map((image) => image.url),
  status: mapStatus(item.status),
  violation_reason: item.violation_reason ?? null,
  classification:
    item.review_type === 'with_content'
      ? mapClassification(item.time_label)
      : 'Chưa phân loại',
  reportCount: item.status === 'violation' ? Math.max(item.user.report_count, 1) : 0,
  reportReasons: item.status === 'violation' ? ['Nội dung bị đánh dấu vi phạm'] : [],
  adminNote: item.status === 'violation' ? 'Đánh giá đã được hệ thống gắn nhãn vi phạm.' : '',
});

const formatDate = (value: string): string => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString('vi-VN');
};

const mapItineraryReviewDetail = (item: BackendItineraryReviewDetailResponse): ItineraryReviewDetailInfo => ({
  id: item.id,
  userAvatar: getInitials(item.reviewer.name || 'N A'),
  userName: item.reviewer.name,
  totalReviews: item.reviewer.review_count,
  totalReports: item.reviewer.report_count,
  itineraryName: item.itinerary.name,
  itineraryStartDate: item.itinerary.start_date ? formatDate(item.itinerary.start_date) : undefined,
  itineraryEndDate: item.itinerary.end_date ? formatDate(item.itinerary.end_date) : undefined,
  rating: item.rating,
  datetime: formatDateTime(item.created_at),
  content: item.review_content || '(Không có nội dung)',
  images: item.images.map((img) => img.url),
  status: mapStatus(item.status),
  violation_reason: item.violation_reason ?? null,
  reportCount: item.status === 'violation' ? Math.max(item.reviewer.report_count, 1) : 0,
  reportReasons: item.status === 'violation' ? ['Nội dung bị đánh dấu vi phạm'] : [],
  adminNote: item.status === 'violation' ? 'Đánh giá đã được hệ thống gắn nhãn vi phạm.' : '',
});

const toBackendStatus = (status: Review['status']): 'approved' | 'violation' => {
  return status === 'Vi phạm' ? 'violation' : 'approved';
};

const toBackendTimeLabel = (
  classification: 'Ngắn hạn' | 'Dài hạn',
): EditableBackendReviewClassification => {
  return classification === 'Ngắn hạn' ? 'short-term' : 'long-term';
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

  updateReviewTimeLabel: async (
    id: string,
    classification: 'Ngắn hạn' | 'Dài hạn',
  ): Promise<{ status?: Review['status'] }> => {
    const response = await apiClient.put<{ status?: BackendReviewStatus }>(
      `/admin/reviews/${id}/time-label`,
      {
        time_label: toBackendTimeLabel(classification),
      },
    );

    return {
      status: response.data.status ? mapStatus(response.data.status) : undefined,
    };
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

  getItineraryReviewById: async (id: string): Promise<ItineraryReviewDetailInfo> => {
    try {
      const response = await apiClient.get<BackendItineraryReviewDetailResponse>(`/admin/itinerary-reviews/${id}`);
      return mapItineraryReviewDetail(response.data);
    } catch {
      // Mock data — dùng tạm khi backend chưa có endpoint GET /admin/itinerary-reviews/:id
      const mockSet: ItineraryReviewDetailInfo[] = [
        {
          id,
          userAvatar: 'NN',
          userName: 'Nguyễn Ngọc Hà',
          totalReviews: 8,
          totalReports: 0,
          itineraryName: 'Hành trình Hà Nội 3 ngày 2 đêm',
          itineraryStartDate: '05/04/2026',
          itineraryEndDate: '08/04/2026',
          rating: 5,
          datetime: '02:08 - 8/4/2026',
          content:
            'Lịch trình được sắp xếp rất hợp lý, các điểm tham quan phân bổ đều trong ngày không quá mệt. Bữa ăn tại các nhà hàng được gợi ý đều rất ngon và đúng gu ẩm thực địa phương. Đặc biệt buổi tối dạo phố cổ rất thú vị. Sẽ giới thiệu cho bạn bè!',
          images: [],
          status: 'Chờ duyệt',
          reportCount: 0,
          reportReasons: [],
          adminNote: '',
        },
        {
          id,
          userAvatar: 'NN',
          userName: 'Nguyễn Ngọc Hà',
          totalReviews: 8,
          totalReports: 0,
          itineraryName: 'Khám phá Đà Nẵng – Hội An cuối tuần',
          itineraryStartDate: '08/04/2026',
          itineraryEndDate: '10/04/2026',
          rating: 5,
          datetime: '00:59 - 8/4/2026',
          content: 'OK!',
          images: [],
          status: 'Chờ duyệt',
          reportCount: 0,
          reportReasons: [],
          adminNote: '',
        },
      ];
      // Dùng ký tự cuối của ID để luân phiên giữa 2 mock
      const idx = id.charCodeAt(id.length - 1) % 2;
      return mockSet[idx];
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
