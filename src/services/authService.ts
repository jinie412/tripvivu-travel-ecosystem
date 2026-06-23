import axios from 'axios';
import { LoginDto, AuthResponse } from '../types/auth';
import { clearAuthData, getCurrentUser } from '../utils/auth';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

const authAPI = {
  login: async (credentials: LoginDto): Promise<AuthResponse> => {
    const response = await axios.post(`${API_URL}/auth/login`, credentials);
    return response.data;
  },

  logout: () => {
    clearAuthData();
  },

  getCurrentUser: () => getCurrentUser(),
};

export default authAPI;
