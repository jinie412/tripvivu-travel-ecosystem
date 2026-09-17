import { User, UserStatsInfo } from '../types/user';

const mockUsers: User[] = Array.from({ length: 35 }).map((_, i) => ({
  id: `${i + 1}`,
  fullName: i === 0 ? 'Nguyen Admin' : `User ${i + 1}`,
  email: i === 0 ? 'admin@system.com' : `user${i + 1}@example.com`,
  avatar: i === 0 ? 'A' : `U${(i + 1) % 10}`,
  role: i === 0 ? 'ADMIN' : i % 3 === 0 ? 'BUSINESS' : 'TOURIST',
  activeStatus: i % 4 === 0 ? 'LOCKED' : 'ACTIVE',
  deleteStatus: i % 4 === 0 ? 'true' : 'false',
  joinedDate: `1${(i % 9) + 1}/03/2023`,
  avatarUrl: i === 0 ? 'A' : `U${(i + 1) % 10}`,
  address: 'Default Address',
  phoneNumber: '0123456789',
  dateOfBirth: '2000-01-01',
  gender: 'MALE',
}));

export const userAPI = {
  getUsers: async (page = 1, limit = 10): Promise<{ data: User[]; total: number }> => {
    return new Promise((resolve) => {
      setTimeout(() => {
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + limit;
        const paginatedUsers = mockUsers.slice(startIndex, endIndex);
        resolve({ data: paginatedUsers, total: mockUsers.length });
      }, 500);
    });
  },

  getUserStats: async (): Promise<UserStatsInfo> => {
    return new Promise((resolve) => {
      setTimeout(
        () =>
          resolve({
            totalUsers: 12450,
            newThisMonth: 124,
            totalAdmins: 8,
          }),
        500,
      );
    });
  },

  getUserById: async (id: string): Promise<User | undefined> => {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(mockUsers.find((user) => user.id === id));
      }, 300);
    });
  },
};
