import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

const DynamicTitle = () => {
  const location = useLocation();

  useEffect(() => {
    const path = location.pathname;
    let title = 'Tripvivu';

    if (path.startsWith('/admin')) {
      if (path.includes('users')) title = 'Quản lý người dùng - Admin | Tripvivu';
      else if (path.includes('locations')) title = 'Quản lý địa điểm - Admin | Tripvivu';
      else if (path.includes('reviews')) title = 'Quản lý đánh giá - Admin | Tripvivu';
      else if (path.includes('itinerary-reviews')) title = 'Đánh giá lịch trình - Admin | Tripvivu';
      else if (path.includes('algorithm-settings')) title = 'Cài đặt thuật toán - Admin | Tripvivu';
      else if (path.includes('algorithm-runner')) title = 'Chạy thuật toán - Admin | Tripvivu';
      else if (path.includes('algorithm-history')) title = 'Lịch sử thuật toán - Admin | Tripvivu';
      else if (path.includes('profile')) title = 'Hồ sơ cá nhân - Admin | Tripvivu';
      else if (path.includes('dashboard')) title = 'Tổng quan - Admin | Tripvivu';
      else title = 'Admin | Tripvivu';
    } else if (path.startsWith('/login')) {
      title = 'Đăng nhập | Tripvivu';
    } else if (path.startsWith('/register')) {
      title = 'Đăng ký | Tripvivu';
    } else if (path.startsWith('/forgot-password')) {
      title = 'Quên mật khẩu | Tripvivu';
    } else if (path.startsWith('/reset-password')) {
      title = 'Đặt lại mật khẩu | Tripvivu';
    } else {
      // Provider pages
      if (path.includes('locations')) title = 'Quản lý địa điểm - Provider | Tripvivu';
      else if (path.includes('orders')) title = 'Quản lý đơn hàng - Provider | Tripvivu';
      else if (path.includes('profile')) title = 'Hồ sơ cá nhân - Provider | Tripvivu';
      else if (path.includes('dashboard')) title = 'Tổng quan - Provider | Tripvivu';
      else title = 'Provider | Tripvivu';
    }

    document.title = title;
  }, [location]);

  return null;
};

export default DynamicTitle;
