import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { DetailHeader } from './components/DetailHeader';
import { ProfileCard } from './components/ProfileCard';
import { PersonalInfoCard } from './components/PersonalInfoCard';
import { AccountSettingsCard } from './components/AccountSettingsCard';
import { DetailFooter } from './components/DetailFooter';
import { User } from '../../../types/user';
import apiClient from '../../../utils/apiClient'; // Dùng apiClient thật của dự án
import Swal from 'sweetalert2';
import './UserDetail.css';

export const UserDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false); // Thêm state để khóa nút khi đang lưu

  // --- 1. API LẤY CHI TIẾT NGƯỜI DÙNG ---
  useEffect(() => {
    const fetchUserDetail = async () => {
      if (!id) return;

      setLoading(true);
      try {
        const response = await apiClient.get(`/admin/users/${id}`);
        setUser(response.data);
      } catch (error) {
        console.error('Lỗi khi lấy chi tiết người dùng:', error);
        Swal.fire({
          title: 'Lỗi',
          text: 'Không thể tải thông tin người dùng. Vui lòng thử lại.',
          icon: 'error',
          confirmButtonColor: '#3b82f6',
        });
      } finally {
        setLoading(false);
      }
    };

    fetchUserDetail();
  }, [id]);

  // --- 2. API CẬP NHẬT THÔNG TIN NGƯỜI DÙNG ---
  // Hàm này sẽ được truyền xuống các Component con (Card) dưới dạng Props
  const handleUpdateUser = async (updateData: Partial<User>) => {
    if (!id) return;

    setIsUpdating(true);
    try {
      // Gọi API PATCH lên Backend với dữ liệu mới
      await apiClient.patch(`/admin/users/${id}`, updateData);

      // Cập nhật lại State ở Frontend ngay lập tức để giao diện không cần load lại trang
      setUser((prevUser) => {
        if (!prevUser) return null;
        return { ...prevUser, ...updateData };
      });

      Swal.fire({
        title: 'Thành công!',
        text: 'Cập nhật thông tin thành công!',
        icon: 'success',
        confirmButtonColor: '#3b82f6',
      });
    } catch (error: any) {
      console.error('Lỗi khi cập nhật:', error);

      // Hiển thị lỗi từ Backend (nếu có validation errors)
      const errorMessage = error.response?.data?.message || 'Có lỗi xảy ra khi lưu thông tin.';
      Swal.fire({
        title: 'Cập nhật thất bại',
        text: Array.isArray(errorMessage) ? errorMessage[0] : errorMessage,
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    } finally {
      setIsUpdating(false);
    }
  };

  if (loading) {
    return <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-muted)' }}>Đang tải dữ liệu người dùng...</div>;
  }

  if (!user) {
    return <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-muted)' }}>Không tìm thấy người dùng.</div>;
  }

  const handleToggleStatus = async (newStatus: 'ACTIVE' | 'LOCKED') => {
    if (!id) return;

    // Bật Pop-up xác nhận báo cáo đẹp (UI sweetalert2)
    const result = await Swal.fire({
      title: newStatus === 'LOCKED' ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?',
      text:
        newStatus === 'LOCKED'
          ? 'Bạn có chắc chắn muốn KHÓA tài khoản này? Người dùng sẽ không thể đăng nhập.'
          : 'Bạn có chắc chắn muốn MỞ KHÓA tài khoản này?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: newStatus === 'LOCKED' ? '#ef4444' : '#3b82f6',
      cancelButtonColor: '#94a3b8',
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
    });

    if (!result.isConfirmed) return;

    setIsUpdating(true);
    try {
      // Gọi đúng API endpoint trạng thái mà bạn đã tạo
      await apiClient.patch(`/admin/users/${id}/status`, { status: newStatus });

      // Cập nhật State để giao diện tự render lại cục Badge và Nút
      setUser((prevUser) => {
        if (!prevUser) return null;
        return { ...prevUser, activeStatus: newStatus };
      });

      Swal.fire({
        title: 'Thành công!',
        text: `Đã ${newStatus === 'LOCKED' ? 'khóa' : 'mở khóa'} tài khoản thành công!`,
        icon: 'success',
        confirmButtonColor: '#3b82f6',
      });
    } catch (error) {
      console.error('Lỗi khi đổi trạng thái:', error);
      Swal.fire({
        title: 'Lỗi!',
        text: 'Có lỗi xảy ra, không thể thay đổi trạng thái.',
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    } finally {
      setIsUpdating(false);
    }
  };

  return (
    <div className="detail-page-container">
      <DetailHeader />

      <div className="detail-content-wrapper">
        <h1 className="detail-page-title">Chi tiết người dùng: {user.fullName}</h1>

        <div className="profile-section">
          {/* Truyền hàm update xuống nếu Card này có chức năng đổi Avatar/Tên */}
          <ProfileCard user={user} onUpdate={handleUpdateUser} isUpdating={isUpdating} />
        </div>

        <div className="details-grid">
          <div className="left-column">
            {/* Truyền hàm update xuống Card thông tin cá nhân (Tên, SĐT, Ngày sinh, Địa chỉ...) */}
            <PersonalInfoCard user={user} onUpdate={handleUpdateUser} isUpdating={isUpdating} />
          </div>

          <div className="right-column">
            {/* Truyền thêm hàm mới này xuống Card */}
            <AccountSettingsCard user={user} onUpdate={handleUpdateUser} onToggleStatus={handleToggleStatus} isUpdating={isUpdating} />
          </div>
        </div>
      </div>

      <DetailFooter />
    </div>
  );
};
