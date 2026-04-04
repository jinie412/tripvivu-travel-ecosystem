import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import AuthLayout from '../../../layouts/AuthLayout/AuthLayout';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { Mail, AlertCircle, CheckCircle2, ArrowLeft } from 'lucide-react';
import loginBg from '../../../assets/login-bg.png';

// 1. Import apiClient thay vì axios thuần
import apiClient from '../../../utils/apiClient';

const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(false);

    // Bắt lỗi cơ bản ở FE trước khi gọi API
    if (!email) {
      setError('Email không được để trống');
      return;
    }

    try {
      setIsLoading(true);

      // 2. Gọi API quên mật khẩu bằng apiClient
      const response = await apiClient.post('/auth/forgot-password', { email });

      // 3. Hiển thị thông báo thành công thực tế từ Backend trả về
      setSuccess(true);
      setSuccessMessage(response.data.message || 'Đã gửi liên kết khôi phục! Vui lòng kiểm tra hộp thư của bạn.');
    } catch (err: any) {
      console.error('Lỗi khi gửi yêu cầu quên mật khẩu:', err);

      // 4. Bắt chính xác câu chữ báo lỗi từ DTO của Backend (ví dụ: "Email không đúng định dạng")
      if (err.response?.data?.message) {
        const backendMsg = err.response.data.message;
        // Xử lý trường hợp BE trả về mảng hoặc chuỗi
        setError(Array.isArray(backendMsg) ? backendMsg[0] : backendMsg);
      } else {
        setError('Có lỗi xảy ra khi gửi yêu cầu. Vui lòng thử lại sau!');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthLayout bgImage={loginBg}>
      <div style={{ marginBottom: '32px' }}>
        <h2 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '12px', color: 'var(--text-primary)' }}>Quên mật khẩu</h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '15px', lineHeight: '1.6' }}>
          Nhập email bạn đã đăng ký để nhận liên kết khôi phục mật khẩu.
        </p>
      </div>

      {/* Hiển thị lỗi màu đỏ */}
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

      {/* Hiển thị thành công màu xanh */}
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
          {successMessage}
        </div>
      )}

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column' }}>
        <Input
          label="Địa chỉ Email"
          placeholder="example@travel.com"
          type="text" // Chuyển thành text để FE không tự chặn, nhường đất cho DTO Backend thể hiện
          name="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          icon={<Mail size={18} />}
        />

        <Button
          type="submit"
          fullWidth
          disabled={isLoading}
          style={{ padding: '14px', fontSize: '16px', marginBottom: '24px', marginTop: '8px' }}>
          {isLoading ? 'Đang gửi...' : 'Gửi liên kết khôi phục'}
        </Button>

        <div style={{ textAlign: 'center', fontSize: '14px', color: 'var(--text-secondary)' }}>
          <Link
            to="/login"
            style={{
              fontWeight: '600',
              color: 'var(--secondary-blue)',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '4px',
              justifyContent: 'center',
            }}>
            <ArrowLeft size={16} /> Quay lại đăng nhập
          </Link>
        </div>
      </form>
    </AuthLayout>
  );
};

export default ForgotPasswordPage;
