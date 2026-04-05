import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AuthLayout from '../../../layouts/AuthLayout/AuthLayout';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { Lock, Eye, EyeOff, AlertCircle, CheckCircle2 } from 'lucide-react';
import loginBg from '../../../assets/login-bg.png';

// Dùng apiClient thay vì axios thuần
import apiClient from '../../../utils/apiClient';

const ResetPasswordPage: React.FC = () => {
  const navigate = useNavigate();

  // Khởi tạo state để chứa token lấy từ URL
  const [accessToken, setAccessToken] = useState<string | null>(null);

  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [formData, setFormData] = useState({
    password: '',
    confirmPassword: '',
  });

  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Lấy chính xác access_token từ URL băm (Hash) của Supabase trả về
  useEffect(() => {
    const hash = window.location.hash;
    if (hash) {
      const urlParams = new URLSearchParams(hash.substring(1));
      const token = urlParams.get('access_token');
      if (token) {
        setAccessToken(token);
      }
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!formData.password || !formData.confirmPassword) {
      setError('Vui lòng điền đầy đủ thông tin!');
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      setError('Mật khẩu xác nhận không khớp!');
      return;
    }

    if (!accessToken) {
      setError('Không tìm thấy mã xác thực. Vui lòng nhấp lại vào liên kết trong email.');
      return;
    }

    try {
      setIsLoading(true);

      // Gọi API thật xuống Backend bằng apiClient
      await apiClient.post('/auth/update-password', {
        accessToken: accessToken,
        newPassword: formData.password,
      });

      setSuccess(true);
      setTimeout(() => {
        navigate('/login');
      }, 3000);
    } catch (err: any) {
      console.error('Lỗi khi đặt lại mật khẩu:', err);

      // ĐÃ XÓA MOCK SUCCESS. Bắt lỗi thực tế từ Backend trả về
      if (err.response?.data?.message) {
        const backendMsg = err.response.data.message;
        setError(Array.isArray(backendMsg) ? backendMsg[0] : backendMsg);
      } else {
        setError('Có lỗi xảy ra khi đổi mật khẩu. Đảm bảo liên kết còn hạn.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthLayout bgImage={loginBg}>
      <div style={{ marginBottom: '32px' }}>
        <h2 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '12px', color: 'var(--text-primary)' }}>Đặt lại mật khẩu</h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '15px', lineHeight: '1.6' }}>
          Vui lòng nhập mật khẩu mới cho tài khoản của bạn.
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

      {success && (
        <div
          style={{
            background: 'rgba(34, 197, 94, 0.1)',
            color: '#22c55e',
            padding: '12px 16px',
            borderRadius: '8px',
            marginBottom: '24px',
            fontSize: '14px',
            fontWeight: '500',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            border: '1px solid rgba(34, 197, 94, 0.2)',
          }}>
          <CheckCircle2 size={18} />
          Đổi mật khẩu thành công! Đang chuyển hướng đến đăng nhập...
        </div>
      )}

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column' }}>
        <Input
          label="Mật khẩu mới"
          placeholder="********"
          type={showPassword ? 'text' : 'password'}
          name="password"
          value={formData.password}
          onChange={(e) => setFormData({ ...formData, password: e.target.value })}
          icon={<Lock size={18} />}
          rightIcon={
            <div onClick={() => setShowPassword(!showPassword)} style={{ cursor: 'pointer' }}>
              {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </div>
          }
        />

        <Input
          label="Xác nhận mật khẩu mới"
          placeholder="********"
          type={showConfirmPassword ? 'text' : 'password'}
          name="confirmPassword"
          value={formData.confirmPassword}
          onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
          icon={<Lock size={18} />}
          rightIcon={
            <div onClick={() => setShowConfirmPassword(!showConfirmPassword)} style={{ cursor: 'pointer' }}>
              {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </div>
          }
          style={{ marginBottom: '0' }}
        />

        <Button
          type="submit"
          fullWidth
          disabled={isLoading || success}
          style={{ padding: '14px', fontSize: '16px', marginBottom: '24px', marginTop: '16px' }}>
          {isLoading ? 'Đang xử lý...' : 'Xác nhận đổi mật khẩu'}
        </Button>

        <div style={{ textAlign: 'center', fontSize: '14px', color: 'var(--text-secondary)' }}>
          Tôi đã nhớ ra mật khẩu?{' '}
          <Link to="/login" style={{ fontWeight: '700', color: 'var(--secondary-blue)' }}>
            Đăng nhập
          </Link>
        </div>
      </form>
    </AuthLayout>
  );
};

export default ResetPasswordPage;
