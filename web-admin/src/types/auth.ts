export interface User {
  id: string;
  email: string;
  fullName: string;
  role: 'admin' | 'provider';
  avatar?: string;
}

export interface AuthResponse {
  accessToken: string;
  user: User;
}

export interface LoginDto {
  email: string;
  password?: string;
  phone?: string;
}

export interface RegisterDto {
  fullName: string;
  email: string;
  phone: string;
  password?: string;
}
