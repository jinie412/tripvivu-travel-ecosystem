import { User } from '../types/auth';

export interface MockUser extends User {
  password: string;
}

export const MOCK_USERS: MockUser[] = [
  {
    id: 'admin-1',
    email: 'admin@travel.com',
    fullName: 'System Administrator',
    role: 'admin',
    password: 'admin123',
    avatar: 'https://i.pravatar.cc/150?u=admin'
  },
  {
    id: 'provider-1',
    email: 'provider@travel.com',
    fullName: 'Happy Travel Co.',
    role: 'provider',
    password: 'provider123',
    avatar: 'https://i.pravatar.cc/150?u=provider'
  }
];
