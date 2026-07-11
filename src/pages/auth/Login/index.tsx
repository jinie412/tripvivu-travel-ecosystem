import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AuthLayout from '../../../layouts/AuthLayout/AuthLayout';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { Mail, Lock, Eye, EyeOff, Linkedin, AlertCircle } from 'lucide-react';
import loginBg from '../../../assets/login-bg.png';
import axios from 'axios';
import { supabase } from '../../../utils/supabase';
import Swal from 'sweetalert2';

const GoogleIcon = ({ size = 18 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 48 48">
    <path
      fill="#EA4335"
      d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
    />
    <path
      fill="#4285F4"
      d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
    />
    <path
      fill="#FBBC05"
      d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
    />
    <path
      fill="#34A853"
      d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
    />
  </svg>
);
const FacebookIcon = ({ size = 18 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path
      fill="#1877F2"
      d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.469h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.469h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"
    />
    <path
      fill="#fff"
      d="M16.671 15.542l.532-3.469h-3.328v-2.25c0-.949.465-1.874 1.956-1.874h1.513V5.006s-1.374-.235-2.686-.235c-2.741 0-4.533 1.662-4.533 4.669v2.57H7.078v3.469h3.047v8.385a12.09 12.09 0 003.75 0v-8.385h2.796z"
    />
  </svg>
);
const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    remember: false,
  });
  const handleGoogleLogin = async () => {
    try {
      localStorage.setItem('intended_role', 'BUSINESS');
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: 'http://localhost:5173/auth/callback',
        },
      });

      if (error) throw error;
    } catch (err: any) {
      console.error('Lỗi đăng nhập Google:', err.message);
      setError('Không thể kết nối với Google. Vui lòng thử lại.');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    try {
      const apiUrl = import.meta.env.VITE_API_BASE_URL;
      const tokenKey = import.meta.env.VITE_TOKEN_KEY || 'access_token';

      const response = await axios.post(`${apiUrl}/auth/login`, {
        emailOrPhone: formData.email,
        password: formData.password,
      });

      const { accessToken, refreshToken, user } = response.data;

      // Lưu vào localStorage nếu "ghi nhớ", sessionStorage nếu không
      const storage = formData.remember ? localStorage : sessionStorage;
      storage.setItem(tokenKey, accessToken);
      if (refreshToken) storage.setItem('refresh_token', refreshToken);
      storage.setItem('userInfo', JSON.stringify(user));

      if (user.role === 'BUSINESS') {
        Swal.fire({ title: 'Đăng nhập thành công!', icon: 'success', toast: true, position: 'bottom-end', showConfirmButton: false, timer: 1500 });
        navigate('/dashboard');
      } else if (user.role === 'ADMIN') {
        Swal.fire({ title: 'Đăng nhập thành công!', icon: 'success', toast: true, position: 'bottom-end', showConfirmButton: false, timer: 1500 });
        navigate('/admin');
      } else {
        setError('Tài khoản của bạn không có quyền truy cập trang dành cho Đối tác!');
        storage.removeItem(tokenKey);
        storage.removeItem('refresh_token');
        storage.removeItem('userInfo');
      }
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.status === 401) {
        setError('Sai email hoặc mật khẩu. Vui lòng thử lại!');
      } else {
        setError('Có lỗi xảy ra khi kết nối với máy chủ!');
        console.error('Login error:', err);
      }
    }
  };

  return (
    <AuthLayout bgImage={loginBg}>
      <div style={{ marginBottom: '32px' }}>
        <h2
          style={{
            fontSize: '32px',
            fontWeight: '800',
            marginBottom: '12px',
            color: 'var(--text-primary)',
          }}>
          Đăng nhập
        </h2>
        <p
          style={{
            color: 'var(--text-secondary)',
            fontSize: '15px',
            lineHeight: '1.6',
          }}>
          Chào mừng trở lại! Vui lòng nhập thông tin để truy cập hệ thống quản trị.
        </p>
      </div>

      {error && (
        <div
          style={{
            background: 'rgba(255, 71, 71, 0.1)',
            color: '#ff4747',
            padding: '12px 16px',
            borderRadius: '8px',
            marginBottom: '24px',
            fontSize: '14px',
            fontWeight: '500',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            border: '1px solid rgba(255, 71, 71, 0.2)',
          }}>
          <AlertCircle size={18} />
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column' }}>
        <Input
          label="Email hoặc Số điện thoại"
          placeholder="example@travel.com"
          type="text"
          name="email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          icon={<Mail size={18} />}
        />

        <div style={{ marginBottom: '8px' }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '4px',
            }}>
            <label
              style={{
                fontSize: '14px',
                fontWeight: '600',
                color: 'var(--text-primary)',
              }}>
              Mật khẩu
            </label>
            <Link
              to="/forgot-password"
              style={{
                fontSize: '14px',
                fontWeight: '600',
                color: 'var(--secondary-blue)',
              }}>
              Quên mật khẩu?
            </Link>
          </div>
          <Input
            placeholder="********"
            type={showPassword ? 'text' : 'password'}
            name="password"
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            icon={<Lock size={18} />}
            rightIcon={<div onClick={() => setShowPassword(!showPassword)}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</div>}
            style={{ marginBottom: '0' }}
          />
        </div>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            marginBottom: '24px',
            cursor: 'pointer',
          }}>
          <input
            type="checkbox"
            id="remember"
            checked={formData.remember}
            onChange={(e) => setFormData({ ...formData, remember: e.target.checked })}
            style={{ width: '16px', height: '16px', borderRadius: '4px' }}
          />
          <label
            htmlFor="remember"
            style={{
              fontSize: '14px',
              color: 'var(--text-secondary)',
              userSelect: 'none',
            }}>
            Ghi nhớ đăng nhập
          </label>
        </div>

        <Button type="submit" fullWidth style={{ padding: '14px', fontSize: '16px', marginBottom: '32px' }}>
          Đăng nhập ngay
        </Button>

        <div
          style={{
            position: 'relative',
            marginBottom: '32px',
            textAlign: 'center',
          }}>
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: 0,
              right: 0,
              height: '1px',
              background: 'var(--medium-gray)',
              zIndex: 0,
            }}></div>
          <span
            style={{
              position: 'relative',
              background: 'white',
              padding: '0 16px',
              fontSize: '13px',
              color: 'var(--text-secondary)',
              zIndex: 1,
            }}>
            Hoặc tiếp tục với
          </span>
        </div>

        <div style={{ display: 'flex', gap: '16px', marginBottom: '40px' }}>
          <Button type="button" variant="secondary" fullWidth style={{ fontWeight: '600' }} onClick={handleGoogleLogin}>
            <GoogleIcon size={18} />
            Google
          </Button>
          {/* <Button variant="secondary" fullWidth style={{ fontWeight: '600', fontSize: '14px' }} type="button">
            <FacebookIcon size={18} />
            Facebook
          </Button> */}
        </div>

        <div
          style={{
            textAlign: 'center',
            fontSize: '14px',
            color: 'var(--text-secondary)',
          }}>
          Chưa có tài khoản dành cho đối tác?{' '}
          <Link to="/register" style={{ fontWeight: '700', color: 'var(--secondary-blue)' }}>
            Đăng ký tài khoản mới
          </Link>
        </div>
      </form>
    </AuthLayout>
  );
};

export default LoginPage;
