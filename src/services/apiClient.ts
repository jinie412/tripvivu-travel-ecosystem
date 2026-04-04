import axios, { AxiosResponse } from "axios";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:3000";
const API_TIMEOUT = Number(import.meta.env.VITE_API_TIMEOUT || 15000);

export const USE_MOCK_API = false;

export const apiClient = axios.create({
  baseURL: API_URL,
  timeout: API_TIMEOUT,
  headers: {
    "Content-Type": "application/json",
  },
});

apiClient.interceptors.request.use((config) => {
  const tokenKey = import.meta.env.VITE_TOKEN_KEY || "access_token";
  const token = localStorage.getItem(tokenKey) || localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const extractResponseData = <T>(
  response: AxiosResponse<T | { data: T }>,
): T => {
  const payload = response.data as T | { data: T };
  if (payload && typeof payload === "object" && "data" in payload) {
    return payload.data;
  }
  return payload as T;
};
