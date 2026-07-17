import { apiClient } from './apiClient';

interface BackendBusinessReviewBreakdownItem {
  count: number;
  percent: number;
}

interface BackendBusinessReviewBreakdown {
  5: BackendBusinessReviewBreakdownItem;
  4: BackendBusinessReviewBreakdownItem;
  3: BackendBusinessReviewBreakdownItem;
  2: BackendBusinessReviewBreakdownItem;
  1: BackendBusinessReviewBreakdownItem;
}

interface BackendBusinessReviewItem {
  id: string;
  user_name: string;
  rating: number;
  content: string;
  main_topic: string | null;
  images: string[];
  created_at: string;
  reply: string | null;
  replied_at: string | null;
}

interface BackendBusinessReviewResponse {
  place: {
    id: string;
    name: string;
    status: 'pending' | 'approved' | 'rejected';
    is_active: boolean;
  };
  stats: {
    average_rating: number;
    total_reviews: number;
    breakdown: BackendBusinessReviewBreakdown;
  };
  ai_insight: string;
  filters: {
    available_topics: string[];
  };
  reviews: BackendBusinessReviewItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface BusinessReviewStats {
  averageRating: number;
  totalReviews: number;
  breakdown: Record<1 | 2 | 3 | 4 | 5, { count: number; percent: number }>;
  aiInsight: string;
}

export interface BusinessReviewFilterParams {
  vendorId: string;
  placeId: string;
  rating?: number;
  sort?: 'newest' | 'oldest' | 'highest_rating' | 'lowest_rating';
  topic?: string;
  hasImages?: boolean;
}

const mapBreakdown = (
  breakdown: BackendBusinessReviewBreakdown,
): Record<1 | 2 | 3 | 4 | 5, { count: number; percent: number }> => {
  return {
    5: breakdown[5],
    4: breakdown[4],
    3: breakdown[3],
    2: breakdown[2],
    1: breakdown[1],
  };
};

export const businessReviewAPI = {
  getReviews: async (
    params: BusinessReviewFilterParams,
    page = 1,
    limit = 10,
  ): Promise<{
    stats: BusinessReviewStats;
    reviews: Array<{
      id: string;
      userName: string;
      rating: number;
      content: string;
      topic: string | null;
      images: string[];
      createdAt: string;
      reply: string | null;
      repliedAt: string | null;
    }>;
    availableTopics: string[];
    pagination: { page: number; limit: number; total: number; pages: number };
  }> => {
    const response = await apiClient.get<BackendBusinessReviewResponse>(
      `/business/reviews/${params.placeId}`,
      {
        params: {
          vendor_id: params.vendorId,
          page,
          limit,
          rating: params.rating || undefined,
          sort: params.sort || 'newest',
          topic: params.topic || undefined,
          has_images: params.hasImages || undefined,
        },
      },
    );

    return {
      stats: {
        averageRating: response.data.stats.average_rating,
        totalReviews: response.data.stats.total_reviews,
        breakdown: mapBreakdown(response.data.stats.breakdown),
        aiInsight: response.data.ai_insight,
      },
      reviews: response.data.reviews.map((item) => ({
        id: item.id,
        userName: item.user_name,
        rating: item.rating,
        content: item.content,
        topic: item.main_topic,
        images: item.images,
        createdAt: item.created_at,
        reply: item.reply,
        repliedAt: item.replied_at,
      })),
      availableTopics: response.data.filters.available_topics,
      pagination: response.data.pagination,
    };
  },

  submitReply: async (params: {
    vendorId: string;
    placeId: string;
    reviewId: string;
    content: string;
  }): Promise<{ reply: string; repliedAt: string }> => {
    const response = await apiClient.put<{ id: string; reply: string; replied_at: string }>(
      `/business/reviews/${params.placeId}/${params.reviewId}/reply`,
      { content: params.content },
      { params: { vendor_id: params.vendorId } },
    );

    return { reply: response.data.reply, repliedAt: response.data.replied_at };
  },
};
