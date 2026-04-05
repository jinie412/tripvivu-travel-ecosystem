import { apiClient, extractResponseData } from './apiClient';
import { Location, LocationDetailInfo, LocationStatsInfo } from '../types/location';

type BackendPlaceStatus = 'pending' | 'approved' | 'rejected';

interface BackendPlaceItem {
  id: string;
  image_url?: string[] | string | null;
  name: string;
  address: string;
  category: string;
  vendor_name: string;
  status: BackendPlaceStatus;
  registered_date: string;
}

interface BackendPlaceListResponse {
  data: BackendPlaceItem[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    pages: number;
  };
}

interface SelectOption {
  value: string;
  label: string;
}

interface BackendPlaceCategoriesResponse {
  categories: SelectOption[];
}

interface BackendPlaceDetailResponse {
  id: string;
  name: string;
  description: string;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  category: string;
  registered_date: string;
  status: BackendPlaceStatus;
  contact_phone: string;
  contact_email: string;
  vendor: {
    id: string;
    name: string;
    email: string;
    phone: string;
    total_places: number;
    created_at?: string | null;
  } | null;
  image_url?: unknown;
  images?: unknown;
}

export interface LocationFilterParams {
  search?: string;
  status?: 'all' | 'pending' | 'approved' | 'rejected';
  categoryName?: string;
}

export interface LocationCategoryOptions {
  categories: SelectOption[];
}

const toUiStatus = (status: BackendPlaceStatus): Location['status'] => {
  if (status === 'approved') {
    return 'Đã duyệt';
  }
  if (status === 'rejected') {
    return 'Từ chối';
  }
  return 'Chờ duyệt';
};

const toApiStatus = (
  status?: 'all' | 'pending' | 'approved' | 'rejected',
): 'all' | 'pending' | 'approved' | 'rejected' => {
  if (!status) {
    return 'all';
  }
  return status;
};

const getInitials = (name: string): string => {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('');
};

const formatDate = (value?: string): string => {
  if (!value) {
    return 'N/A';
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return date.toLocaleDateString('vi-VN');
};

const normalizeImageUrls = (value: unknown): string[] => {
  const urls: string[] = [];

  const collect = (input: unknown): void => {
    if (Array.isArray(input)) {
      input.forEach((item) => collect(item));
      return;
    }

    if (typeof input === 'string') {
      const text = input.trim();
      if (!text) {
        return;
      }

      // Support Postgres array string format: {"url1","url2"}
      if (text.startsWith('{') && text.endsWith('}')) {
        const inner = text.slice(1, -1).trim();
        if (!inner) {
          return;
        }
        inner.split(',').forEach((part) => {
          const cleaned = part.trim().replace(/^"|"$/g, '');
          if (cleaned) {
            urls.push(cleaned);
          }
        });
        return;
      }

      urls.push(text);
      return;
    }

    if (input && typeof input === 'object') {
      const record = input as Record<string, unknown>;
      if ('url' in record) {
        collect(record.url);
      }
      if ('image_url' in record) {
        collect(record.image_url);
      }
      if ('images' in record) {
        collect(record.images);
      }
    }
  };

  collect(value);
  return urls.filter((url, index) => urls.indexOf(url) === index);
};

const getPrimaryImage = (value: string[] | string | null | undefined): string => {
  return normalizeImageUrls(value)[0] || '';
};

const mapLocation = (item: BackendPlaceItem): Location => {
  return {
    id: item.id,
    image: getPrimaryImage(item.image_url),
    name: item.name,
    address: item.address,
    category: item.category,
    userName: item.vendor_name,
    userAvatar: getInitials(item.vendor_name || 'N A'),
    publishDate: formatDate(item.registered_date),
    status: toUiStatus(item.status),
  };
};

const mapLocationDetail = (item: BackendPlaceDetailResponse): LocationDetailInfo => {
  const vendorName = item.vendor?.name || 'N/A';
  const imageUrlPhotos = normalizeImageUrls(item.image_url);
  const photos = imageUrlPhotos.length > 0 ? imageUrlPhotos : normalizeImageUrls(item.images);

  return {
    id: item.id,
    image: photos[0] || '',
    name: item.name,
    address: item.address,
    category: item.category,
    userName: vendorName,
    userAvatar: getInitials(vendorName),
    publishDate: formatDate(item.registered_date),
    status: toUiStatus(item.status),
    rejectionReason: item.status === 'rejected' ? 'Địa điểm đã bị từ chối bởi quản trị viên.' : undefined,
    description: item.description || 'Không có mô tả.',
    phone: item.contact_phone,
    email: item.contact_email,
    lat: item.latitude,
    lng: item.longitude,
    photos,
    senderStats: {
      totalLocations: item.vendor?.total_places || 0,
      joinedDate: formatDate(item.vendor?.created_at || undefined),
      role: 'Nhà cung cấp',
    },
  };
};

const getLocationCountByStatus = async (
  status: 'all' | 'pending' | 'approved' | 'rejected',
): Promise<number> => {
  const response = await apiClient.get<BackendPlaceListResponse>('/admin/places', {
    params: {
      status,
      page: 1,
      limit: 1,
    },
  });
  return response.data.pagination.total;
};

export const locationAPI = {
  getLocations: async (
    page = 1,
    limit = 10,
    filters: LocationFilterParams = {},
  ): Promise<{ data: Location[]; total: number }> => {
    const response = await apiClient.get<BackendPlaceListResponse>('/admin/places', {
      params: {
        page,
        limit,
        status: toApiStatus(filters.status),
        search: filters.search || undefined,
        category_name: filters.categoryName || undefined,
      },
    });

    return {
      data: response.data.data.map(mapLocation),
      total: response.data.pagination.total,
    };
  },

  getLocationStats: async (): Promise<LocationStatsInfo> => {
    const [totalLocations, pendingApproval, newestPage] = await Promise.all([
      getLocationCountByStatus('all'),
      getLocationCountByStatus('pending'),
      apiClient.get<BackendPlaceListResponse>('/admin/places', {
        params: { status: 'all', page: 1, limit: 100, sort: 'newest' },
      }),
    ]);

    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    const newThisMonth = newestPage.data.data.filter((item) => {
      if (!item.registered_date) {
        return false;
      }
      const date = new Date(item.registered_date);
      return (
        !Number.isNaN(date.getTime()) &&
        date.getMonth() === currentMonth &&
        date.getFullYear() === currentYear
      );
    }).length;

    return {
      totalLocations,
      pendingApproval,
      newThisMonth,
    };
  },

  getLocationById: async (id: string): Promise<LocationDetailInfo | null> => {
    try {
      const response = await apiClient.get<BackendPlaceDetailResponse>(`/admin/places/${id}`);
      return mapLocationDetail(extractResponseData(response));
    } catch {
      return null;
    }
  },

  getLocationCategories: async (): Promise<LocationCategoryOptions> => {
    const response = await apiClient.get<BackendPlaceCategoriesResponse>('/admin/places/categories');
    return extractResponseData(response);
  },

  approveLocation: async (id: string): Promise<void> => {
    await apiClient.patch(`/admin/places/${id}/approve`);
  },

  rejectLocation: async (id: string, reason?: string): Promise<void> => {
    await apiClient.patch(`/admin/places/${id}/reject`, {
      note: reason || undefined,
    });
  },
};
