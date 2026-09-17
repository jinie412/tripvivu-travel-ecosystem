export interface OrderItem {
  name: string;
  quantity: number;
  price: number;
}

export interface Order {
  order_id: string;
  ordered_time: string;
  place_name: string;
  placeId: string;
  customer_name: string;
  foods: string;
  total_amount: number;
  status: string;
  notes?: string | null;
  tourist_id?: string;
  // legacy fields
  id?: string;
  time?: string;
  restaurantName?: string;
  customer?: { name: string };
  items?: OrderItem[];
  total?: string;
}
