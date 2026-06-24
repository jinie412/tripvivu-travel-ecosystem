export interface Location {
  id: string;
  image: string;
  name: string;
  address: string;
  category: string;
  userName: string;
  userAvatar: string;
  publishDate: string;
  status: 'Đã duyệt' | 'Chờ duyệt' | 'Từ chối';
  rejectionReason?: string;
  rating?: number;
  review_count?: number;
}

export interface LocationStatsInfo {
  totalLocations: number;
  pendingApproval: number;
  newThisMonth: number;
}

export interface LocationDetailInfo extends Location {
  description: string;
  phone?: string;
  email?: string;
  lat?: number;
  lng?: number;
  photos: string[];
  vendorId?: string;
  senderStats?: {
    totalLocations: number;
    joinedDate: string;
    role: string;
  };
}

export interface ProviderLocationSummary {
  id: string;
  name: string;
  statusLabel: 'Đã duyệt' | 'Chờ duyệt' | 'Từ chối';
  statusColor: string;
  isActive: boolean;
  category: string;
  rating: number;
  reviewCount: number;
  gallery: string[];
}

export interface ProviderLocationDraft {
  name: string;
  address: string;
  city: string;
  district: string;
  openTime: string;
  closeTime: string;
  description: string;
  latitude: string;
  longitude: string;
}

export interface ProviderLocationService {
  id: string;
  name: string;
  description: string;
  price: number | null;
  isActive: boolean;
}

export interface ProviderLocationReview {
  id: string;
  userName: string;
  rating: number;
  content: string;
  topic: string | null;
  images: string[];
  createdAt: string;
}
