import { apiClient, extractResponseData } from './apiClient';

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
  is_active?: boolean | number | string;
  active?: boolean | number | string;
  status?: boolean | number | string;
}

export interface PlaceServicesResponse {
  freeServices?: PlaceServiceItemResponse[];
  paidServices?: PlaceServiceItemResponse[];
  total?: number;
  data?: {
    freeServices?: PlaceServiceItemResponse[];
    paidServices?: PlaceServiceItemResponse[];
    total?: number;
  };
}

const isRecord = (value: unknown): value is Record<string, unknown> => {
  return typeof value === 'object' && value !== null;
};

export const getOrdersByPlace = async (placeId: string): Promise<any[]> => {
  const res = await apiClient.get('/business/orders', { params: { placeId } });
  const payload = extractResponseData<any[]>(res as any);
  return Array.isArray(payload) ? payload : [];
};

export const getOrderDetail = async (orderId: string): Promise<any> => {
  const res = await apiClient.get('/business/order-detail', {
    params: { orderId }
  });
  return extractResponseData<any>(res as any);
};

export const getDashboardStats = async (vendorId: string): Promise<any> => {
  const res = await apiClient.get('/business/dashboard', {
    params: { vendorId }
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

export const addNewPlace = async (payload: {
  p_name: string;
  p_address: string;
  p_city: string;
  p_lat: number;
  p_lng: number;
  p_categories: string[];
  p_services: Array<{ name: string; description: string }>;
  p_menu: Array<{ name: string; description: string; price: number }>;
}): Promise<any> => {
  try {
    const res = await apiClient.post('/business/add-new-place', payload);
    return extractResponseData<any>(res as any);
  } catch (error) {
    console.error('Error in addNewPlace:', error);
    throw error;
  }
};

export const getFoodPerformance = async (vendorId: string): Promise<any[]> => {
  const res = await apiClient.get('/business/food-performance', { params: { vendorId } });
  const payload = extractResponseData<any[]>(res as any);
  return Array.isArray(payload) ? payload : [];
};

export const updateOrderStatus = async (orderId: string, status: string): Promise<any> => {
  const res = await apiClient.put('/business/update-order-status', { orderId, status });
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