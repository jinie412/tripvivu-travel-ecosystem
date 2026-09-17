import { apiClient, extractResponseData } from './apiClient';
import { Location, LocationDetailInfo, LocationStatsInfo } from '../types/location';
import { applyLocationApprovalOverride, clearLocationApprovalOverride } from '../utils/locationApprovalOverride';

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

export interface AdminVendorOption {
  id: string;
  name: string;
  email: string;
  phone: string;
}

export interface AdminCreatePlacePayload {
  sourceMode: 'system' | 'vendor';
  p_name: string;
  p_address: string;
  p_city: string;
  p_lat: number;
  p_lng: number;
  p_vendor_id?: string;
  p_email: string;
  p_phone?: string;
  p_type_id: string;
  p_type_name: string;
  p_categories: string[];
  p_open_time?: string;
  p_close_time?: string;
  p_open_hour_compressed?: Record<string, [string, string][]>;
  p_description?: string;
  p_estimated_preparation_time?: number | null;
  p_services: Array<{ name: string; description: string; service_id?: string }>;
  p_menu: Array<{ name: string; description: string; price: number; quantity?: number; image_url?: string }>;
  p_rooms?: Array<{ name: string; price: number; quantity: number }>;
  p_images?: string[];
}

interface BackendPlaceCategoriesResponse {
  categories: SelectOption[];
}

interface BackendPlaceStatsResponse {
  totalLocations: number;
  pendingApproval: number;
  newThisMonth: number;
}

interface BackendPlaceCoordinatesResponse {
  id: string;
  latitude: number;
  longitude: number;
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
  rejection_reason?: string | null;
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
  vendorId?: string;
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
    rejectionReason:
      item.status === 'rejected'
        ? item.rejection_reason || 'Địa điểm đã bị từ chối bởi quản trị viên.'
        : undefined,
    description: item.description || 'Không có mô tả.',
    phone: item.contact_phone,
    email: item.contact_email,
    lat: item.latitude,
    lng: item.longitude,
    photos,
    vendorId: item.vendor?.id,
    senderStats: {
      totalLocations: item.vendor?.total_places || 0,
      joinedDate: formatDate(item.vendor?.created_at || undefined),
      role: 'Nhà cung cấp',
    },
  };
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
        vendor_id: filters.vendorId || undefined,
      },
    });

    return {
      data: response.data.data.map(mapLocation).map(applyLocationApprovalOverride),
      total: response.data.pagination.total,
    };
  },

  getLocationStats: async (): Promise<LocationStatsInfo> => {
    const response = await apiClient.get<BackendPlaceStatsResponse>('/admin/places/stats');
    const stats = extractResponseData(response);

    return {
      totalLocations: stats.totalLocations,
      pendingApproval: stats.pendingApproval,
      newThisMonth: stats.newThisMonth,
    };
  },

  getLocationById: async (id: string): Promise<LocationDetailInfo | null> => {
    try {
      const response = await apiClient.get<BackendPlaceDetailResponse>(`/admin/places/${id}`);
      return applyLocationApprovalOverride(mapLocationDetail(extractResponseData(response)));
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
    clearLocationApprovalOverride(id);
  },

  rejectLocation: async (id: string, reason?: string): Promise<void> => {
    await apiClient.patch(`/admin/places/${id}/reject`, {
      note: reason || undefined,
    });
    clearLocationApprovalOverride(id);
  },

  deleteLocation: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/places/${id}`);
    clearLocationApprovalOverride(id);
  },

  updateLocationCoordinates: async (
    id: string,
    coordinates: { latitude: number; longitude: number },
  ): Promise<{ latitude: number; longitude: number }> => {
    const response = await apiClient.patch<BackendPlaceCoordinatesResponse>(
      `/admin/places/${id}/coordinates`,
      coordinates,
    );
    const data = extractResponseData(response);
    return {
      latitude: data.latitude,
      longitude: data.longitude,
    };
  },

  getBusinessVendors: async (): Promise<AdminVendorOption[]> => {
    try {
      const response = await apiClient.get<{ data: AdminVendorOption[] }>('/admin/places/vendors');
      const payload = response.data;
      return Array.isArray(payload.data) ? payload.data : [];
    } catch (error) {
      const response = await apiClient.get<{
        data: Array<{
          id: string;
          fullName?: string;
          full_name?: string;
          email?: string;
          phone?: string;
          phoneNumber?: string;
          phone_number?: string;
        }>;
      }>('/admin/users', {
        params: {
          role: 'BUSINESS',
          limit: 200,
        },
      });
      const payload = response.data;
      return Array.isArray(payload.data)
        ? payload.data.map((user) => ({
          id: user.id,
          name: user.fullName || user.full_name || user.email || user.id,
          email: user.email || '',
          phone: user.phone || user.phoneNumber || user.phone_number || '',
        }))
        : [];
    }
  },

  createFullLocation: async (payload: AdminCreatePlacePayload): Promise<{ placeId: string }> => {
    const response = await apiClient.post('/admin/places/full', payload);
    return extractResponseData(response);
  },
};
