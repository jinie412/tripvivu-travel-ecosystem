import api from './api'

export const getOrdersByPlace = async (placeId: string) => {
  const res = await api.get('/business/orders', { params: { placeId } });
  
  console.log('1 order sample:', JSON.stringify(res.data[0], null, 2)); // 👈
  return res.data;
};

export const getOrderDetail = async (orderId: string) => {
  const res = await api.get('/business/order-detail', {
    params: { orderId }
  });
  return res.data;
};

export const getDashboardStats = async (vendorId: string) => {
  const res = await api.get('/business/dashboard', {
    params: { vendorId }
  });
  return res.data;
};

export const getPlaceDetail = async (placeId: string) => {
  const res = await api.get('/business/place-detail', {
    params: { placeId }
  });
  return res.data[0]; // API returns array, we take first element
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
}) => {
  try {
    const res = await api.post('/business/add-new-place', payload);
    return res.data;
  } catch (error) {
    console.error('Error in addNewPlace:', error);
    throw error;
  }
};

export const getPlaceServicesByType = async (placeId: string) => {
  try {
    const res = await api.get('/business/place-services-by-type', {
      params: { placeId }
    });
    return res.data; // Returns { freeServices: [...], paidServices: [...], total: number }
  } catch (error) {
    console.error('Error fetching place services by type:', error);
    throw error;
  }
};