import { apiClient } from './apiClient';
import { Location } from '../types/location';
import { applyLocationApprovalOverride } from '../utils/locationApprovalOverride';

interface BackendBusinessPlaceItem {
  id: string;
  image_url?: string[] | string | null;
  name: string;
  address: string;
  city?: string;
  city_name?: string;
  province?: string;
  categories: string[];
  rating: number;
  review_count: number;
  status: 'pending' | 'approved' | 'rejected';
  registered_date: string;
}

interface BackendBusinessPlaceListResponse {
  data: BackendBusinessPlaceItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
  images: string[];
}

export interface BusinessLocationFilterParams {
  vendorId: string;
  search?: string;
  status?: 'all' | 'pending' | 'approved' | 'rejected';
  sort?: 'default' | 'popular' | 'newest';
}

const toUiStatus = (status: 'pending' | 'approved' | 'rejected'): Location['status'] => {
  if (status === 'approved') {
    return 'Đã duyệt';
  }
  if (status === 'rejected') {
    return 'Từ chối';
  }
  return 'Chờ duyệt';
};

const getPrimaryImage = (imageUrl: string[] | string | null | undefined): string => {
  if (Array.isArray(imageUrl)) {
    return imageUrl.find((item) => typeof item === 'string' && item.trim().length > 0) || '';
  }
  if (typeof imageUrl === 'string' && imageUrl.trim().length > 0) {
    return imageUrl;
  }
  return '';
};

const mapLocation = (item: BackendBusinessPlaceItem): Location => {
  return {
    id: item.id,
    image: getPrimaryImage(item.image_url),
    name: item.name,
    address: item.address,
    city: item.city || item.city_name || item.province || '',
    category: item.categories.join(', ') || 'Khác',
    userName: 'Nhà cung cấp',
    userAvatar: 'NC',
    publishDate: item.registered_date ? new Date(item.registered_date).toLocaleDateString('vi-VN') : 'N/A',
    status: toUiStatus(item.status),
    rating: item.rating,
    review_count: item.review_count,
  };
};

export const businessLocationAPI = {
  getLocations: async (
    params: BusinessLocationFilterParams,
    pagination?: { page: number; limit: number }
  ): Promise<{ locations: Location[]; total: number }> => {
    const page = pagination?.page || 1;
    const limit = pagination?.limit || 10;
    const response = await apiClient.get<BackendBusinessPlaceListResponse>(
      '/business/places',
      {
        params: {
          vendor_id: params.vendorId,
          page,
          limit,
          search: params.search || undefined,
          status: params.status || 'all',
          sort: params.sort || 'default',
        },
      },
    );

    return {
      locations: response.data.data.map(mapLocation).map(applyLocationApprovalOverride),
      total: response.data.pagination.total,
    };
  },
};
