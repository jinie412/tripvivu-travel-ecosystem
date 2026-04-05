export interface OrderItem {
  name: string;
  quantity: number;
  price: number;
}

export interface Order {
  id: string;
  time: string;
  restaurantName: string;
  placeId: string;
  customer: {
    name: string;
  };
  items: OrderItem[];
  total: string;
  status: 'confirm' | 'cooking' | 'completed';
}