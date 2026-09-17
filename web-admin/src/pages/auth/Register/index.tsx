import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom'; // 1. Import thêm useNavigate
import AuthLayout from '../../../layouts/AuthLayout/AuthLayout';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { User, Mail, Phone, Lock, ShieldCheck } from 'lucide-react';
import loginBg from '../../../assets/login-bg.png';
import { supabase } from '../../../utils/supabase';

// 2. Import apiClient
import apiClient from '../../../utils/apiClient';
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
    Swal.fire({ text: 'Không thể kết nối với Google. Vui lòng thử lại.', icon: 'error' });
  }
};

const RegisterPage: React.FC = () => {
  const navigate = useNavigate(); // Khởi tạo hook điều hướng
  const [isLoading, setIsLoading] = useState(false); // State để disable nút khi đang gọi API

  const [formData, setFormData] = useState({
    fullName: '',
    phone: '',
    email: '',
    password: '',
    confirmPassword: '',
    agree: false,
  });

  // 3. Nâng cấp hàm handleSubmit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // --- BƯỚC 1: VALIDATION CƠ BẢN Ở FRONTEND ---
    if (!formData.fullName || !formData.email || !formData.phone || !formData.password) {
      Swal.fire({ text: 'Vui lòng điền đầy đủ các trường thông tin bắt buộc.', icon: 'warning' });
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      Swal.fire({ text: 'Mật khẩu và Xác nhận mật khẩu không khớp nhau!', icon: 'warning' });
      return;
    }

    if (!formData.agree) {
      Swal.fire({ text: 'Bạn phải đồng ý với các Điều khoản & Chính sách để tiếp tục.', icon: 'warning' });
      return;
    }

    // --- BƯỚC 2: CHUẨN BỊ PAYLOAD VÀ GỌI API ---
    setIsLoading(true);
    try {
      // Map dữ liệu FE sang đúng định dạng mà DTO của BE yêu cầu
      const payload = {
        fullName: formData.fullName,
        phone: formData.phone,
        email: formData.email,
        password: formData.password,
        agreeToTerms: formData.agree, // Đổi tên 'agree' thành 'agreeToTerms' cho khớp BE
      };

      // Gọi API xuống Backend (Giả định endpoint của BE là /auth/register/business)
      const response = await apiClient.post('/auth/register/business', payload);

      // --- BƯỚC 3: XỬ LÝ KHI THÀNH CÔNG ---
      // response.data.message sẽ chứa câu: "Đăng ký tài khoản đối tác thành công..." từ BE trả về
      Swal.fire({ title: response.data.message || 'Đăng ký thành công!', icon: 'success', toast: true, position: 'bottom-end', showConfirmButton: false, timer: 2000 });

      // Chuyển hướng người dùng về trang đăng nhập
      navigate('/login');
    } catch (error: any) {
      // --- BƯỚC 4: XỬ LÝ KHI CÓ LỖI ---
      // Nếu BE ném ra BadRequestException (lỗi 400), ta lấy message ra hiển thị
      if (error.response && error.response.data && error.response.data.message) {
        // Có thể BE trả về mảng các lỗi validation, hoặc chuỗi
        const errorMsg = Array.isArray(error.response.data.message) ? error.response.data.message[0] : error.response.data.message;
        Swal.fire({ text: `Lỗi đăng ký: ${errorMsg}`, icon: 'error' });
      } else {
        Swal.fire({ text: 'Có lỗi xảy ra khi kết nối với máy chủ. Vui lòng thử lại sau.', icon: 'error' });
      }
      console.error('Register error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthLayout bgImage={loginBg}>
      <div style={{ marginBottom: '24px', textAlign: 'center' }}>
        <h2 style={{ fontSize: '28px', fontWeight: '800', marginBottom: '8px', color: 'var(--text-primary)' }}>Đăng ký đối tác mới</h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>Vui lòng điền thông tin bên dưới để bắt đầu hợp tác.</p>
      </div>

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column' }}>
        {/* ... Toàn bộ các Input của bạn giữ nguyên ... */}
        <Input
          label="Họ và tên"
          placeholder="Nhập họ và tên"
          name="fullName"
          value={formData.fullName}
          onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
          icon={<User size={18} />}
          style={{ marginBottom: '12px' }}
        />

        <Input
          label="Số điện thoại"
          placeholder="Nhập số điện thoại"
          name="phone"
          value={formData.phone}
          onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
          icon={<Phone size={18} />}
          style={{ marginBottom: '12px' }}
        />

        <Input
          label="Email"
          placeholder="Nhập địa chỉ email"
          type="email"
          name="email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          icon={<Mail size={18} />}
          style={{ marginBottom: '12px' }}
        />

        <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
          <div style={{ flex: 1 }}>
            <Input
              label="Mật khẩu"
              placeholder="********"
              type="password"
              name="password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              icon={<Lock size={18} />}
              style={{ marginBottom: '0' }}
            />
          </div>
          <div style={{ flex: 1 }}>
            <Input
              label="Xác nhận"
              placeholder="********"
              type="password"
              name="confirmPassword"
              value={formData.confirmPassword}
              onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
              icon={<ShieldCheck size={18} />}
              style={{ marginBottom: '0' }}
            />
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
          <input
            type="checkbox"
            id="agree"
            checked={formData.agree}
            onChange={(e) => setFormData({ ...formData, agree: e.target.checked })}
            style={{ width: '16px', height: '16px', borderRadius: '4px' }}
          />
          <label htmlFor="agree" style={{ fontSize: '13px', color: 'var(--text-secondary)', userSelect: 'none' }}>
            Tôi đồng ý với{' '}
            <a href="#" style={{ fontWeight: '600' }}>
              Điều khoản & Chính sách
            </a>{' '}
            của Travel Partner.
          </label>
        </div>

        {/* 4. Thêm trạng thái disabled và đổi chữ khi đang load */}
        <Button type="submit" fullWidth style={{ padding: '14px', fontSize: '16px', marginBottom: '16px' }} disabled={isLoading}>
          {isLoading ? 'Đang xử lý...' : 'Đăng ký ngay'}
        </Button>

        {/* ... Phần Footer Hoặc Đăng nhập bằng Google, Facebook giữ nguyên ... */}
        <div style={{ position: 'relative', margin: '8px 0 16px', textAlign: 'center' }}>
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
              fontSize: '12px',
              color: 'var(--text-secondary)',
              zIndex: 1,
              textTransform: 'uppercase',
              letterSpacing: '1px',
            }}>
            HOẶC
          </span>
        </div>

        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <Button variant="secondary" fullWidth style={{ fontWeight: '600', fontSize: '14px' }} type="button" onClick={handleGoogleLogin}>
            <GoogleIcon size={18} />
            Google
          </Button>
          {/* <Button variant="secondary" fullWidth style={{ fontWeight: '600', fontSize: '14px' }} type="button">
            <FacebookIcon size={18} />
            Facebook
          </Button> */}
        </div>

        <div style={{ textAlign: 'center', fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '40px' }}>
          Đã có tài khoản?{' '}
          <Link to="/login" style={{ fontWeight: '700', color: 'var(--secondary-blue)' }}>
            Đăng nhập
          </Link>
        </div>

        <div
          style={{
            display: 'flex',
            justifyContent: 'center',
            gap: '20px',
            fontSize: '12px',
            color: 'var(--text-secondary)',
            opacity: 0.7,
          }}>
          <a href="#" style={{ color: 'inherit' }}>
            Trợ giúp
          </a>
          <a href="#" style={{ color: 'inherit' }}>
            Quyền riêng tư
          </a>
          <a href="#" style={{ color: 'inherit' }}>
            Liên hệ
          </a>
        </div>
      </form>
    </AuthLayout>
  );
};

export default RegisterPage;
