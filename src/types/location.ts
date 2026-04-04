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
  senderStats?: {
    totalLocations: number;
    joinedDate: string;
    role: string;
  };
}
