import axios from "axios";

// Khởi tạo instance của Axios với Base URL từ biến môi trường Vite
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:3000",
  headers: {
    "Content-Type": "application/json",
  },
});

// Interceptor 1: Trạm kiểm soát TRƯỚC khi gửi request (Tự động kẹp Token)
apiClient.interceptors.request.use(
  (config) => {
    // Lấy tên key cấu hình trong .env, mặc định là 'access_token'
    const tokenKey = import.meta.env.VITE_TOKEN_KEY || "access_token";
    const token = localStorage.getItem(tokenKey);

    // Nếu trong bộ nhớ có vé (Token), dán nó vào Header
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  },
);

// Interceptor 2: Trạm kiểm soát SAU khi nhận kết quả (Xử lý lỗi 401 tự động)
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      console.warn("Phiên đăng nhập hết hạn hoặc không hợp lệ.");
      const tokenKey = import.meta.env.VITE_TOKEN_KEY || "access_token";

      // Xóa thông tin cũ
      localStorage.removeItem(tokenKey);
      localStorage.removeItem("userInfo");

      // Đá văng về trang đăng nhập
      window.location.href = "/login";
    }
    return Promise.reject(error);
  },
);

export default apiClient;
