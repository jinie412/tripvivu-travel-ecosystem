export interface OrderItem {
  name: string;
  quantity: number;
  price: string;
}

export interface Order {
  id: string;
  time: string;
  customer: {
    name: string;
    phone: string;
    email: string;
    location: string;
    avatar: string;
    label?: string;
    detail: string;
  };
  items: OrderItem[];
  total: string;
  note: string;
  timeInfo: {
    ordered: string;
    expected: string;
  };
  status: 'confirm' | 'cooking' | 'completed';
  statusText: string;
  restaurantName: string;
}

export const mockOrders: Order[] = [
  {
    id: 'ORD-001',
    time: '11:30 AM',
    customer: {
      name: 'Nguyễn Văn A',
      phone: '090xxxxxxx',
      email: 'nguyvana@email.com',
      location: 'Khu vực TP. Hồ Chí Minh',
      avatar: 'https://images.unsplash.com/photo-1543132220-3ce99c5ae497?w=120&h=120&fit=crop',
      detail: 'Bàn số 5',
    },
    items: [
      { name: 'Phở bò Đặc Biệt', quantity: 1, price: '65.000đ' },
      { name: 'Bánh Mì Thịt Nướng', quantity: 2, price: '80.000đ' },
      { name: 'Trà Đá Chanh', quantity: 1, price: '5.000đ' },
    ],
    total: '150.000đ',
    note: '"Không hành"',
    timeInfo: {
      ordered: '11:30, 24/05/2024',
      expected: '12:00, 24/05/2024',
    },
    status: 'confirm',
    statusText: 'Chờ xác nhận',
    restaurantName: 'Nhà hàng Biển Đông',
  },
  {
    id: 'ORD-002',
    time: '12:00 PM',
    customer: {
      name: 'Trần Thị B',
      phone: '091xxxxxxx',
      email: 'tranthib@email.com',
      location: 'Khu vực Hà Nội',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop',
      detail: 'Mang về',
    },
    items: [
      { name: 'Lẩu thái đặc biệt (L)', quantity: 1, price: '350.000đ' },
      { name: 'Trà đào cam sả', quantity: 2, price: '50.000đ' },
    ],
    total: '400.000đ',
    note: '"Cho nhiều ớt"',
    timeInfo: {
      ordered: '12:00, 24/05/2024',
      expected: '12:30, 24/05/2024',
    },
    status: 'cooking',
    statusText: 'Đang chuẩn bị',
    restaurantName: 'Nhà hàng Biển Đông',
  },
  {
    id: 'ORD-003',
    time: '12:15 PM',
    customer: {
      name: 'Lê Minh C',
      phone: '092xxxxxxx',
      email: 'leminhc@email.com',
      location: 'Khu vực Đà Nẵng',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop',
      detail: 'Bàn số 12',
    },
    items: [
      { name: 'Bún bò Huế ngự uyển', quantity: 1, price: '75.000đ' },
      { name: 'Sữa đậu nành', quantity: 1, price: '10.000đ' },
    ],
    total: '85.000đ',
    note: '"Ít bún nhiều thịt"',
    timeInfo: {
      ordered: '12:15, 24/05/2024',
      expected: '12:45, 24/05/2024',
    },
    status: 'confirm',
    statusText: 'Chờ xác nhận',
    restaurantName: 'Nhà hàng Biển Đông',
  },
  {
    id: 'ORD-004',
    time: '12:30 PM',
    customer: {
      name: 'Võ Thị D',
      phone: '094xxxxxxx',
      email: 'vothid@email.com',
      location: 'Khu vực Cần Thơ',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&h=120&fit=crop',
      detail: 'Bàn số 8',
    },
    items: [
      { name: 'Cơm tấm Sườn Bì Chả', quantity: 2, price: '110.000đ' },
      { name: 'Cà phê đá', quantity: 2, price: '30.000đ' },
    ],
    total: '140.000đ',
    note: '"Nhiều mỡ hành"',
    timeInfo: {
      ordered: '12:30, 24/05/2024',
      expected: '13:00, 24/05/2024',
    },
    status: 'completed',
    statusText: 'Hoàn thành',
    restaurantName: 'Khách sạn Mường Thanh',
  },
];
