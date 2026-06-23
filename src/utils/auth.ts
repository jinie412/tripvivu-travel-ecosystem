import axios from 'axios';

const TOKEN_KEY = (import.meta.env.VITE_TOKEN_KEY as string) ?? 'access_token';
const REFRESH_KEY = 'refresh_token';
const USER_KEY = 'userInfo';

export const getToken = (): string | null =>
  localStorage.getItem(TOKEN_KEY) || sessionStorage.getItem(TOKEN_KEY) || null;

export const getRefreshToken = (): string | null =>
  localStorage.getItem(REFRESH_KEY) || sessionStorage.getItem(REFRESH_KEY) || null;

/** Storage nơi session đang sống — xác định bằng vị trí của refreshToken. */
export const getActiveStorage = (): Storage =>
  localStorage.getItem(REFRESH_KEY) ? localStorage : sessionStorage;

export const clearAuthData = (): void => {
  [TOKEN_KEY, REFRESH_KEY, USER_KEY, 'token', 'user'].forEach((key) => {
    localStorage.removeItem(key);
    sessionStorage.removeItem(key);
  });
};

export const getCurrentUser = <T = Record<string, unknown>>(): T | null => {
  const raw =
    localStorage.getItem(USER_KEY) ||
    sessionStorage.getItem(USER_KEY) ||
    localStorage.getItem('user') ||
    sessionStorage.getItem('user');
  try {
    return raw ? (JSON.parse(raw) as T) : null;
  } catch {
    return null;
  }
};

// Shared state để tránh gọi refresh đồng thời nhiều lần
let isRefreshing = false;
let pendingQueue: Array<{ resolve: (t: string) => void; reject: (e: unknown) => void }> = [];

const flushQueue = (token: string | null, error: unknown = null) => {
  pendingQueue.forEach(({ resolve, reject }) =>
    token ? resolve(token) : reject(error),
  );
  pendingQueue = [];
};

/**
 * Tự động refresh access token bằng refresh token đang lưu.
 * Các request đồng thời sẽ được xếp hàng và nhận token mới cùng lúc
 * khi lần refresh đầu tiên hoàn tất.
 */
export const attemptTokenRefresh = (): Promise<string> => {
  const refreshToken = getRefreshToken();

  if (!refreshToken) {
    clearAuthData();
    window.location.href = '/login';
    return Promise.reject(new Error('No refresh token available'));
  }

  if (isRefreshing) {
    return new Promise<string>((resolve, reject) => {
      pendingQueue.push({ resolve, reject });
    });
  }

  isRefreshing = true;

  const apiUrl =
    (import.meta.env.VITE_API_BASE_URL as string) ||
    (import.meta.env.VITE_API_URL as string) ||
    'http://localhost:3000';

  return axios
    .post(`${apiUrl}/auth/refresh`, { refresh_token: refreshToken })
    .then(({ data }) => {
      const storage = getActiveStorage();
      storage.setItem(TOKEN_KEY, data.accessToken);
      storage.setItem(REFRESH_KEY, data.refreshToken);
      flushQueue(data.accessToken);
      return data.accessToken as string;
    })
    .catch((err) => {
      flushQueue(null, err);
      clearAuthData();
      window.location.href = '/login';
      return Promise.reject(err);
    })
    .finally(() => {
      isRefreshing = false;
    });
};
