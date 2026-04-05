import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Bell, Eye, EyeOff, Camera, ChevronDown } from 'lucide-react';
import apiClient from '../../../utils/apiClient'; // Import thư viện gọi API
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './AddUser.css';

export const AddUser: React.FC = () => {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false); // State quản lý loading khi submit

  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    role: '', // Chú ý: Value select đang dùng Tiếng Việt, cần map sang Enum trước khi gửi
    password: '',
    isActive: true,
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleToggleActive = () => {
    setFormData((prev) => ({
      ...prev,
      isActive: !prev.isActive,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      // 1. Chuẩn bị dữ liệu (Map về đúng Enum Backend mong đợi)
      let mappedRole = '';
      if (formData.role === 'Admin') mappedRole = 'ADMIN';
      else if (formData.role === 'Nhà cung cấp') mappedRole = 'BUSINESS';
      else if (formData.role === 'Khách du lịch') mappedRole = 'TOURIST';

      if (!mappedRole) {
        alert('Vui lòng chọn vai trò!');
        setIsSubmitting(false);
        return;
      }

      const payload = {
        fullName: formData.fullName,
        email: formData.email,
        phoneNumber: formData.phone,
        password: formData.password,
        role: mappedRole,
        status: formData.isActive ? 'ACTIVE' : 'LOCKED',
        // avatarUrl: ... (Tính năng upload ảnh xử lý riêng sau)
      };

      // 2. Gọi API POST để tạo người dùng
      await apiClient.post('/admin/users', payload);

      // 3. Hiển thị thông báo và điều hướng về trang danh sách
      alert('Thêm người dùng mới thành công!');
      navigate('/admin/users');
    } catch (error: any) {
      console.error('Lỗi khi thêm người dùng:', error);

      // Xử lý hiển thị lỗi từ Backend (ví dụ: Email đã tồn tại)
      const errorMessage = error.response?.data?.message || 'Có lỗi xảy ra khi tạo người dùng.';
      alert(`Thêm người dùng thất bại: ${Array.isArray(errorMessage) ? errorMessage[0] : errorMessage}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="page-container">
      {/* Top Header */}
      <header className="page-header">
        <div className="header-titles">
          <div className="breadcrumb">
            <Link to="/admin/users" className="text-muted">
              Quản lý người dùng
            </Link>
            <span className="separator">/</span>
            <span className="active-bread">Thêm người dùng</span>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn">
            <Bell size={20} />
          </button>
          <AdminHeaderProfile />
        </div>
      </header>

      <main className="add-user-content">
        <div className="content-header">
          <h1 className="content-title">Thêm người dùng mới</h1>
          <p className="content-subtitle">Vui lòng điền đầy đủ các thông tin cần thiết để tạo tài khoản mới trên hệ thống.</p>
        </div>

        <form className="add-user-form card" onSubmit={handleSubmit}>
          <div className="form-grid">
            <div className="form-group">
              <label htmlFor="fullName">Họ và tên</label>
              <input
                type="text"
                id="fullName"
                name="fullName"
                placeholder="Ví dụ: Nguyễn Văn A"
                value={formData.fullName}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="email">Email</label>
              <input
                type="email"
                id="email"
                name="email"
                placeholder="example@domain.com"
                value={formData.email}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="phone">Số điện thoại</label>
              <input
                type="text"
                id="phone"
                name="phone"
                placeholder="090x xxx xxx"
                value={formData.phone}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="role">Vai trò</label>
              <div className="select-wrapper">
                <select id="role" name="role" value={formData.role} onChange={handleChange} required>
                  <option value="" disabled>
                    Chọn vai trò
                  </option>
                  <option value="Admin">Admin</option>
                  <option value="Nhà cung cấp">Nhà cung cấp</option>
                  <option value="Khách du lịch">Khách du lịch</option>
                </select>
                <ChevronDown className="select-icon" size={18} />
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="password">Mật khẩu</label>
              <div className="password-input-wrapper">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="password"
                  name="password"
                  placeholder="••••••••"
                  value={formData.password}
                  onChange={handleChange}
                  required
                />
                <button type="button" className="password-toggle" onClick={() => setShowPassword(!showPassword)}>
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <div className="form-group">
              <label>Trạng thái</label>
              <div className="status-toggle-wrapper">
                <div className={`status-switch ${formData.isActive ? 'active' : ''}`} onClick={handleToggleActive}>
                  <div className="switch-handle"></div>
                </div>
                <span className="status-label">{formData.isActive ? 'Hoạt động' : 'Bị khóa'}</span>
              </div>
            </div>
          </div>

          <div className="form-divider"></div>

          <div className="avatar-section">
            <label>Ảnh đại diện</label>
            <div className="avatar-upload-container">
              <div className="avatar-placeholder">
                <Camera size={24} className="text-muted" />
              </div>
              <button type="button" className="upload-link">
                Tải ảnh lên
              </button>
            </div>
          </div>

          <div className="form-footer">
            <button type="button" className="btn-secondary" onClick={() => navigate('/admin/users')} disabled={isSubmitting}>
              Hủy
            </button>
            <button type="submit" className="btn-primary-large" disabled={isSubmitting}>
              {isSubmitting ? 'Đang lưu...' : 'Lưu người dùng'}
            </button>
          </div>
        </form>
      </main>
    </div>
  );
};
