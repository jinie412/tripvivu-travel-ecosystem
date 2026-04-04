export type Role = 'ADMIN' | 'BUSINESS' | 'TOURIST';

export type activeStatus = 'ACTIVE' | 'LOCKED';

export interface User {
  id: string;
  fullName: string;
  email: string;
  avatar: string;
  role: Role;
  activeStatus: activeStatus;
  deleteStatus: string;
  joinedDate: string;
  avatarUrl: string;
  address: string;
  phoneNumber: string;
  dateOfBirth: string;
  gender: string;
}

export interface UserStatsInfo {
  totalUsers: number;
  newThisMonth: number;
  totalAdmins: number;
}
