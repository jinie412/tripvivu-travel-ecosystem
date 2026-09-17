export interface Location {
  id: string;
  name: string;
  address: string;
  city: string;
  district: string;
  type: string;
  typeColor: string;
  rating: number;
  reviewsCount: number | string;
  status: string;
  statusColor: string;
  image: string;
  openTime: string;
  closeTime: string;
  description: string;
  lat: string;
  lng: string;
  gallery: string[];
  services: { id: string; name: string; iconName: string }[];
  menu: { id: string; name: string; desc: string; category: string; price: string; image: string }[];
}

export const mockLocations: Location[] = [
  {
    id: 'LOC-001',
    name: 'Nhà hàng Biển Đông',
    address: 'Số 15, Đường Trần Hưng Đạo, Phường Lộc Thọ',
    city: 'Khánh Hòa',
    district: 'Nha Trang',
    type: 'Nhà hàng',
    typeColor: '#3b82f6',
    rating: 4.9,
    reviewsCount: 128,
    status: 'Đã duyệt',
    statusColor: '#22c55e',
    image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=400&fit=crop',
    openTime: '08:00 AM',
    closeTime: '10:00 PM',
    description: 'Nhà hàng Biển Đông tọa lạc tại vị trí đắc địa ven biển Nha Trang, chuyên phục vụ các món hải sản tươi sống được đánh bắt trong ngày. Với không gian rộng rãi, thoáng mát và tầm nhìn hướng biển tuyệt đẹp.',
    lat: '12.2458',
    lng: '109.1943',
    gallery: [
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&h=200&fit=crop',
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200&h=200&fit=crop',
      'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=200&h=200&fit=crop',
    ],
    services: [
        { id: '1', name: 'Wifi miễn phí', iconName: 'Wifi' },
        { id: '2', name: 'Chỗ đậu xe', iconName: 'Car' },
        { id: '3', name: 'Máy lạnh', iconName: 'Wind' },
        { id: '4', name: 'Thanh toán thẻ', iconName: 'CreditCard' },
    ],
    menu: [
        { id: '1', name: 'Cơm chiên hải sản', desc: 'Cơm chiên với tôm, mực, trứng...', category: 'Món chính', price: '125.000đ', image: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=100&h=100&fit=crop' },
        { id: '2', name: 'Lẩu Thái đặc biệt', desc: 'Lẩu chua cay, đầy đủ hải sản', category: 'Lẩu', price: '350.000đ', image: 'https://images.unsplash.com/photo-1595147353130-9759e663da5e?w=100&h=100&fit=crop' },
        { id: '3', name: 'Gỏi ngó sen tôm thịt', desc: 'Khai vị giòn tan, thanh mát', category: 'Khai vị', price: '85.000đ', image: 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=100&h=100&fit=crop' },
    ]
  },
  {
    id: 'LOC-002',
    name: 'Khách sạn Mường Thanh',
    address: 'Phường Hùng Thắng, Hạ Long',
    city: 'Quảng Ninh',
    district: 'Hạ Long',
    type: 'Lưu trú',
    typeColor: '#a855f7',
    rating: 4.7,
    reviewsCount: '2.1k',
    status: 'Đã duyệt',
    statusColor: '#22c55e',
    image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=400&fit=crop',
    openTime: 'Open 24/7',
    closeTime: '-',
    description: 'Tận hưởng kỳ nghỉ sang trọng tại Khách sạn Mường Thanh, nằm ngay trung tâm du lịch Hạ Long với chất lượng dịch vụ đạt chuẩn quốc tế.',
    lat: '20.9599',
    lng: '107.0456',
    gallery: [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=200&h=200&fit=crop',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=200&h=200&fit=crop',
    ],
    services: [
        { id: '1', name: 'Wifi miễn phí', iconName: 'Wifi' },
        { id: '2', name: 'Hồ bơi', iconName: 'Waves' },
    ],
    menu: []
  },
  {
    id: 'LOC-003',
    name: 'Dịch vụ Thuê xe',
    address: 'Cảng tàu Tuần Châu',
    city: 'Quảng Ninh',
    district: 'Hạ Long',
    type: 'Thuê xe',
    typeColor: '#64748b',
    rating: 0,
    reviewsCount: 0,
    status: 'Chờ duyệt',
    statusColor: '#f59e0b',
    image: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=400&h=400&fit=crop',
    openTime: '07:00 AM',
    closeTime: '08:00 PM',
    description: 'Dịch vụ cho thuê xe du lịch chất lượng cao, từ xe 4 chỗ đến 45 chỗ, phục vụ khách tham quan vịnh Hạ Long.',
    lat: '20.9333',
    lng: '107.0000',
    gallery: [],
    services: [],
    menu: []
  }
];
