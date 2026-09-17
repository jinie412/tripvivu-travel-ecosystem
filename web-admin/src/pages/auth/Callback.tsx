import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../utils/supabase'; // Lưu ý kiểm tra lại đường dẫn import này
import axios from 'axios';

const AuthCallback: React.FC = () => {
  const navigate = useNavigate();

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // 1. Supabase PKCE flow: Lấy code từ URL
        const params = new URLSearchParams(window.location.search);
        const code = params.get('code');

        let session = null;

        if (code) {
          const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code);
          if (exchangeError) throw exchangeError;
          session = data.session;
        } else {
          const { data, error } = await supabase.auth.getSession();
          if (error) throw error;
          session = data.session;
        }

        if (!session) {
          throw new Error('Không tìm thấy phiên đăng nhập sau khi xác thực');
        }

        const token = session.access_token;
        const apiUrl = import.meta.env.VITE_API_BASE_URL;
        const tokenKey = import.meta.env.VITE_TOKEN_KEY || 'access_token';

        // --- ĐIỂM SỬA QUAN TRỌNG SỐ 1: LẤY CỜ VÀ GỬI XUỐNG BACKEND ---
        const intendedRole = localStorage.getItem('intended_role');
        // localStorage.removeItem('intended_role'); // Dọn dẹp sau khi lấy

        // 2. Gọi API đồng bộ (Đã truyền body chứa intendedRole)
        const syncResponse = await axios.post(
          `${apiUrl}/auth/sync-oauth`,
          { requestedRole: intendedRole },
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          },
        );

        // Yêu cầu Supabase cấp lại Token mới để cập nhật chữ 'BUSINESS' vào Payload
        const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
        if (refreshError) {
          console.error('Lỗi làm mới phiên:', refreshError);
          throw new Error('Không thể làm mới phiên đăng nhập');
        }

        if (refreshData.session) {
          const newToken = refreshData.session.access_token;
          const freshRole = refreshData.session.user.user_metadata?.role;

          // Lưu token mới này vào LocalStorage để các request sau NestJS đọc đúng
          localStorage.setItem('access_token', newToken);
        } else {
          throw new Error('Không tìm thấy phiên sau khi làm mới');
        }

        // Lấy Token tươi mới (Fresh Token)
        const freshToken = refreshData.session.access_token;
        const user = refreshData.session.user;
        const roleFromBackend = syncResponse.data?.role || 'TOURIST';

        const userInfo = {
          id: user.id,
          email: user.email,
          role: roleFromBackend,
          fullName: user.user_metadata?.full_name || '',
          avatar_url: user.user_metadata?.avatar_url || '',
        };

        // 4. Lưu dữ liệu mới nhất vào LocalStorage
        localStorage.setItem(tokenKey, freshToken);
        localStorage.setItem('userInfo', JSON.stringify(userInfo));

        // 5. Điều hướng dựa trên Role thực tế
        if (userInfo.role === 'BUSINESS') {
          navigate('/dashboard');
        } else if (userInfo.role === 'ADMIN') {
          navigate('/admin/users');
        } else {
          navigate('/');
        }
      } catch (error) {
        console.error('[Callback] LỖI:', error);
        navigate('/login');
      }
    };

    handleAuthCallback();
  }, [navigate]);

  // Giao diện chờ
  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
      <h2>Đang xác thực thông tin tài khoản...</h2>
    </div>
  );
};

export default AuthCallback;
