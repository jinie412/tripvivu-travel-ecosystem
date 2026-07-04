import { apiClient, extractResponseData } from './apiClient';
import type { Order } from '@/types/order.types';

export interface PlaceDetailResponse {
  id?: string;
  place_id?: string;
  placeId?: string;
  name?: string;
  place_name?: string;
  title?: string;
  address?: string;
  place_address?: string;
  city?: string;
  place_city?: string;
  province?: string;
  district?: string;
  district_name?: string;
  description?: string;
  place_description?: string;
  latitude?: number | string;
  lat?: number | string;
  p_lat?: number | string;
  longitude?: number | string;
  lng?: number | string;
  p_lng?: number | string;
  open_time?: string;
  openTime?: string;
  opening_time?: string;
  close_time?: string;
  closeTime?: string;
  closing_time?: string;
  category?: string;
  type?: string;
  place_type?: string;
  status?: string;
  is_active?: boolean;
  active?: boolean;
  rating?: number;
  average_rating?: number;
  review_count?: number;
  reviews_count?: number;
  total_reviews?: number;
  image_url?: string | null;
  images?: string[];
  gallery?: string[];
  image_urls?: string[];
}

export interface PlaceServiceItemResponse {
  id?: string | number;
  service_id?: string | number;
  serviceId?: string | number;
  name?: string;
  service_name?: string;
  title?: string;
  description?: string;
  service_description?: string;
  price?: number | string | null;
  service_price?: number | string | null;
  amount?: number | string | null;
  quantity?: number | string | null;
  is_active?: boolean | number | string;
  active?: boolean | number | string;
  status?: boolean | number | string;
  image_url?: string | null;
  imageUrl?: string | null;
  photo?: string | null;
  food_image?: string | null;
  thumbnail?: string | null;
  menu_image?: string | null;
  item_image?: string | null;
  photo_url?: string | null;
}

export interface PlaceServicesResponse {
  freeServices?: PlaceServiceItemResponse[];
  paidServices?: PlaceServiceItemResponse[];
  menuItems?: PlaceServiceItemResponse[];
  rooms?: PlaceServiceItemResponse[];
  total?: number;
  data?: {
    freeServices?: PlaceServiceItemResponse[];
    paidServices?: PlaceServiceItemResponse[];
    menuItems?: PlaceServiceItemResponse[];
    rooms?: PlaceServiceItemResponse[];
    total?: number;
  };
}

const isRecord = (value: unknown): value is Record<string, unknown> => {
  return typeof value === 'object' && value !== null;
};

const textFrom = (...values: unknown[]): string => {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) {
      return value.trim();
    }
  }
  return '';
};

const hasExplicitTimezone = (value: string): boolean => {
  return /(?:z|[+-]\d{2}:?\d{2})$/i.test(value.trim());
};

const normalizeDateTimeInput = (value: string): string => {
  return hasExplicitTimezone(value) ? value : `${value}Z`;
};

export const formatVietnamDateTime = (value: unknown, fallback = '-'): string => {
  const rawValue = textFrom(value);
  if (!rawValue) {
    return fallback;
  }

  const date = new Date(normalizeDateTimeInput(rawValue));
  if (Number.isNaN(date.getTime())) {
    return rawValue;
  }

  return new Intl.DateTimeFormat('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(date);
};

export const addMinutesToDateTime = (value: unknown, minutes: number): string => {
  const rawValue = textFrom(value);
  if (!rawValue) {
    return '';
  }

  const date = new Date(normalizeDateTimeInput(rawValue));
  if (Number.isNaN(date.getTime())) {
    return rawValue;
  }

  return new Date(date.getTime() + minutes * 60000).toISOString();
};

export const normalizeOrderStatus = (orderOrStatus: unknown): string => {
  const rawStatus = isRecord(orderOrStatus)
    ? textFrom(
      orderOrStatus.status,
      orderOrStatus.order_status,
      orderOrStatus.orderStatus,
      orderOrStatus.status_name,
      orderOrStatus.state,
    )
    : textFrom(orderOrStatus);
  const status = rawStatus.toLowerCase().trim().replace(/[\s-]+/g, '_');

  if (['new', 'created'].includes(status)) {
    return 'new';
  }
  if (['pending', 'waiting', 'wait_confirm', 'waiting_confirm', 'awaiting_confirmation'].includes(status)) {
    return 'pending';
  }
  if (['processing', 'confirmed', 'confirm', 'in_progress'].includes(status)) {
    return 'processing';
  }
  if ([
    'completed',
    'complete',
    'done',
    'finished',
    'delivered',
    'success',
    'succeeded',
    'paid',
    'hoàn_thành',
    'hoan_thanh',
    'đã_hoàn_thành',
    'da_hoan_thanh',
  ].includes(status)) {
    return 'completed';
  }
  if (['cancelled', 'canceled', 'cancel'].includes(status)) {
    return 'cancelled';
  }

  return status;
};

export const isPendingOrder = (orderOrStatus: unknown): boolean => {
  return normalizeOrderStatus(orderOrStatus) === 'pending';
};

const numberFrom = (...values: unknown[]): number => {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
    if (typeof value === 'string' && value.trim()) {
      const parsed = Number(value.replace(/[^\d.-]/g, ''));
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }
  return 0;
};

const getNestedArray = (payload: unknown): unknown[] => {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (!isRecord(payload)) {
    return [];
  }

  const candidates = [
    payload.orders,
    payload.items,
    payload.rows,
    payload.results,
    payload.data,
  ];

  for (const candidate of candidates) {
    if (Array.isArray(candidate)) {
      return candidate;
    }
    if (isRecord(candidate)) {
      const nested = getNestedArray(candidate);
      if (nested.length > 0) {
        return nested;
      }
    }
  }

  return [];
};

const getOrderFoodsText = (order: Record<string, unknown>): string => {
  const foodsText = textFrom(order.foods, order.food_names, order.service_names, order.items_text);
  if (foodsText) {
    return foodsText;
  }

  const rawItems = Array.isArray(order.foods)
    ? order.foods
    : Array.isArray(order.items)
      ? order.items
      : Array.isArray(order.order_items)
        ? order.order_items
        : [];

  return rawItems
    .map((item) => {
      if (!isRecord(item)) {
        return '';
      }

      const food = isRecord(item.food) ? item.food : isRecord(item.food_item) ? item.food_item : {};
      const name = textFrom(
        item.food_name,
        item.name,
        item.service_name,
        food.name,
        food.food_name,
        food.service_name,
      );
      const quantity = numberFrom(item.quantity, item.qty);
      return name ? `${name}${quantity > 1 ? ` x${quantity}` : ''}` : '';
    })
    .filter(Boolean)
    .join(', ');
};

const normalizeOrder = (order: unknown): Order => {
  const data = isRecord(order) ? order : {};
  const orderId = textFrom(data.order_id, data.orderId, data.id);

  return {
    ...(data as Partial<Order>),
    order_id: orderId,
    id: textFrom(data.id) || orderId,
    ordered_time: textFrom(data.ordered_time, data.orderedAt, data.ordered_at, data.created_at, data.createdAt),
    place_name: textFrom(data.place_name, data.placeName, data.restaurant_name, data.location_name) || 'Chưa rõ địa điểm',
    placeId: textFrom(data.placeId, data.place_id, data.location_id),
    customer_name: textFrom(data.customer_name, data.customerName, data.tourist_name, data.user_name) || 'Khách hàng',
    foods: getOrderFoodsText(data),
    total_amount: numberFrom(data.total_amount, data.totalAmount, data.total, data.amount),
    status: normalizeOrderStatus(data),
    notes: textFrom(data.notes) || null,
    tourist_id: textFrom(data.tourist_id, data.touristId),
  };
};

export const getOrdersByPlace = async (placeId: string): Promise<Order[]> => {
  const res = await apiClient.get('/business/orders', { params: { placeId } });
  const payload = extractResponseData<unknown>(res as any);
  const all = getNestedArray(payload).map(normalizeOrder).filter((order) => order.order_id);

  // Deduplicate by order_id — backend JOIN can return multiple rows per order
  const seen = new Set<string>();
  return all.filter((order) => {
    if (seen.has(order.order_id)) return false;
    seen.add(order.order_id);
    return true;
  });
};

export const getOrderDetail = async (orderId: string): Promise<any> => {
  const res = await apiClient.get('/business/order-detail', {
    params: { orderId }
  });
  return extractResponseData<any>(res as any);
};

export interface DashboardPeriodParams {
  month?: number;
  year?: number;
}

export const getDashboardStats = async (
  vendorId: string,
  period: DashboardPeriodParams = {},
): Promise<any> => {
  const res = await apiClient.get('/business/dashboard', {
    params: {
      vendorId,
      month: period.month,
      year: period.year,
    },
  });
  return extractResponseData<any>(res as any);
};

export const getPlaceDetail = async (placeId: string) => {
  const res = await apiClient.get('/business/place-detail', {
    params: { placeId }
  });
  const payload = extractResponseData(res as any);

  if (Array.isArray(payload)) {
    return payload[0] as PlaceDetailResponse | undefined;
  }

  if (isRecord(payload) && Array.isArray(payload.data)) {
    return payload.data[0] as PlaceDetailResponse | undefined;
  }

  return payload as PlaceDetailResponse | undefined;
};

export const fetchAllServices = async (): Promise<Array<{ id: string; name: string; description?: string }>> => {
  try {
    const res = await apiClient.get('/services');
    const data = extractResponseData<any>(res as any);
    const list = Array.isArray(data) ? data : Array.isArray(data?.data) ? data.data : [];
    return list.map((s: any) => ({
      id: String(s.id ?? s.service_id ?? ''),
      name: String(s.name ?? s.service_name ?? ''),
      description: String(s.description ?? s.service_description ?? ''),
    })).filter((s: any) => s.id && s.name);
  } catch {
    return [];
  }
};

export const addNewPlace = async (payload: {
  p_name: string;
  p_address: string;
  p_city: string;
  p_lat: number;
  p_lng: number;
  p_vendor_id?: string;
  p_email?: string;
  p_phone?: string;
  p_type_id?: string;
  p_type_name?: string;
  p_categories: string[];
  p_open_time?: string;
  p_close_time?: string;
  p_open_hour_compressed?: Record<string, [string, string][]>;
  p_description?: string;
  p_services: Array<{ name: string; description: string; service_id?: string }>;
  p_menu: Array<{ name: string; description: string; price: number; image_url?: string }>;
  p_rooms?: Array<{ name: string; price: number; quantity: number }>;
  p_images?: string[];
}): Promise<any> => {
  try {
    const res = await apiClient.post('/business/add-new-place', payload);
    return extractResponseData<any>(res as any);
  } catch (error) {
    console.error('Error in addNewPlace:', error);
    throw error;
  }
};

export const getFoodPerformance = async (
  vendorId: string,
  period: DashboardPeriodParams = {},
): Promise<any[]> => {
  const res = await apiClient.get('/business/food-performance', {
    params: {
      vendorId,
      month: period.month,
      year: period.year,
    },
  });
  const payload = extractResponseData<any[] | { items?: any[]; data?: any[] }>(res as any);

  if (Array.isArray(payload)) {
    return payload;
  }

  if (payload && typeof payload === 'object') {
    if (Array.isArray(payload.items)) {
      return payload.items;
    }
    if (Array.isArray(payload.data)) {
      return payload.data;
    }
  }

  return [];
};

export const updateOrderStatus = async (orderId: string, status: string): Promise<any> => {
  const res = await apiClient.put('/business/update-order-status', { orderId, status });
  return extractResponseData<any>(res as any);
};

export const updatePlaceDetail = async (payload: {
  placeId: string;
  vendorId: string;
  name: string;
  address: string;
  city?: string;
  email?: string;
  phone?: string;
  p_email?: string;
  p_phone?: string;
  latitude?: number | string;
  longitude?: number | string;
  estimated_preparation_time?: number | string | null;
  p_estimated_preparation_time?: number | string | null;
  openTime?: string;
  closeTime?: string;
  description?: string;
  imageUrls?: string[];
  isActive?: boolean;
  status?: 'pending' | 'approved' | 'rejected';
  placeStatus?: 'pending' | 'approved' | 'rejected';
  approvalStatus?: 'pending' | 'approved' | 'rejected';
  place_status?: 'pending' | 'approved' | 'rejected';
  approval_status?: 'pending' | 'approved' | 'rejected';
  isApproved?: boolean;
  is_approved?: boolean;
  approved?: boolean;
}): Promise<any> => {
  const res = await apiClient.put('/business/place-detail', payload);
  return extractResponseData<any>(res as any);
};

export const deletePlaceDetail = async (payload: {
  placeId: string;
  vendorId: string;
}): Promise<any> => {
  const res = await apiClient.delete('/business/place-detail', { data: payload });
  return extractResponseData<any>(res as any);
};

export const uploadPlaceImage = async (file: File, placeId?: string) => {
  const formData = new FormData();
  formData.append('file', file);
  if (placeId) {
    formData.append('placeId', placeId);
  }
  
  // Gọi đến endpoint upload của bạn (giả định là /upload/place-image)
  const response = await apiClient.post('/upload/place-image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  
  // Trả về URL từ server (Cloudflare/S3)
  return response.data.url || response.data; 
};

export const uploadFoodDraftImage = async (file: File) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await apiClient.post('/upload/food-draft', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });

  return response.data.url || response.data;
};

export const addPlaceMenuItem = async (payload: {
  placeId: string;
  name: string;
  description?: string;
  price: number;
}): Promise<{ message?: string; item?: { id: string; name: string; description: string | null; price: number } }> => {
  const res = await apiClient.post('/business/menu-item', payload);
  return extractResponseData<any>(res as any);
};

export const updatePlaceMenuItem = async (payload: {
  itemId: string;
  placeId: string;
  name: string;
  description?: string;
  price: number;
}): Promise<any> => {
  const res = await apiClient.put('/business/menu-item', payload);
  return extractResponseData<any>(res as any);
};

export const deletePlaceMenuItem = async (payload: {
  itemId: string;
  placeId: string;
}): Promise<any> => {
  const res = await apiClient.delete('/business/menu-item', { data: payload });
  return extractResponseData<any>(res as any);
};

export const addPlaceFreeService = async (payload: {
  placeId: string;
  name: string;
}): Promise<{ message?: string; id?: string }> => {
  const res = await apiClient.post('/business/free-service', payload);
  return extractResponseData<any>(res as any);
};

export const updatePlaceFreeService = async (payload: {
  serviceId: string;
  placeId: string;
  name: string;
}): Promise<any> => {
  const res = await apiClient.put('/business/free-service', payload);
  return extractResponseData<any>(res as any);
};

export const deletePlaceFreeService = async (payload: {
  serviceId: string;
  placeId: string;
}): Promise<any> => {
  const res = await apiClient.delete('/business/free-service', { data: payload });
  return extractResponseData<any>(res as any);
};

export const getPlaceServicesByType = async (placeId: string) => {
  try {
    const res = await apiClient.get('/business/place-services-by-type', {
      params: { placeId }
    });
    const payload = extractResponseData(res as any);

    if (isRecord(payload) && isRecord(payload.data)) {
      return payload.data as PlaceServicesResponse;
    }

    return payload as PlaceServicesResponse;
  } catch (error) {
    console.error('Error fetching place services by type:', error);
    throw error;
  }
};
