import React, { useState, useEffect } from 'react';
import { LayoutDashboard, Building2, ShoppingBag, Settings, LogOut, Bell, HelpCircle, Search } from 'lucide-react';
import { NavLink, useNavigate, Outlet } from 'react-router-dom';
import authAPI from '../../services/authService';
import Swal from 'sweetalert2';

import apiClient from '../../utils/apiClient';

interface SidebarItemProps {
  icon: React.ReactNode;
  label: string;
  to: string;
  badge?: number;
}

const SidebarItem: React.FC<SidebarItemProps> = ({ icon, label, to, badge }) => (
  <NavLink
    to={to}
    style={({ isActive }) => ({
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
      padding: '12px 16px',
      borderRadius: '12px',
      textDecoration: 'none',
      color: isActive ? 'white' : 'rgba(255, 255, 255, 0.7)',
      background: isActive ? 'rgba(255, 255, 255, 0.15)' : 'transparent',
      transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
      marginBottom: '4px',
      fontWeight: isActive ? '600' : '400',
      fontSize: '14px',
    })}>
    <div style={{ display: 'flex' }}>{icon}</div>
    <span style={{ flex: 1 }}>{label}</span>
    {badge && (
      <span
        style={{
          background: '#f59e0b',
          color: 'white',
          fontSize: '11px',
          fontWeight: '700',
          padding: '2px 6px',
          borderRadius: '10px',
          minWidth: '20px',
          textAlign: 'center',
        }}>
        {badge}
      </span>
    )}
  </NavLink>
);
const defaultAvatar =
  'https://media.istockphoto.com/id/1477583639/vector/user-profile-icon-vector-avatar-or-person-icon-profile-picture-portrait-symbol-vector.jpg?s=612x612&w=0&k=20&c=OWGIPPkZIWLPvnQS14ZSyHMoGtVTn1zS8cAgLy1Uh24=';

const ProviderLayout: React.FC = () => {
  const navigate = useNavigate();

  const [headerInfo, setHeaderInfo] = useState(() => {
    const storedUser = localStorage.getItem('userInfo');

    if (storedUser) {
      const parsedUser = JSON.parse(storedUser);
      return {
        fullName: parsedUser.fullName || 'Đối tác',
        avatar: parsedUser.avatar_url || defaultAvatar,
      };
    }

    return {
      fullName: 'Đang tải...',
      avatar: defaultAvatar,
    };
  });

  // 4. Gọi API lấy thông tin ngay khi Layout được load
  useEffect(() => {
    const fetchHeaderInfo = async () => {
      try {
        const response = await apiClient.get('/business/profile/me');
        setHeaderInfo({
          fullName: response.data.fullName,
          avatar: response.data.avatarUrl || defaultAvatar,
        });
      } catch (error) {
        console.error('Lỗi lấy dữ liệu Header:', error);

        const storedUser = localStorage.getItem('userInfo');
        if (storedUser) {
          const parsedUser = JSON.parse(storedUser);
          setHeaderInfo((prev) => ({
            ...prev,
            fullName: parsedUser.fullName,
          }));
        }
      }
    };

    fetchHeaderInfo();

    // 5. Lắng nghe sự kiện cập nhật profile để đổi Avatar/Tên ngay lập tức
    const handleUserUpdate = () => {
      const storedUser = localStorage.getItem('userInfo');
      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        setHeaderInfo((prev) => ({
          ...prev,
          fullName: parsedUser.fullName || prev.fullName,
          avatar: parsedUser.avatarUrl || parsedUser.avatar_url || defaultAvatar,
        }));
      }
    };

    window.addEventListener('userUpdated', handleUserUpdate);
    return () => window.removeEventListener('userUpdated', handleUserUpdate);
  }, []);

  // 5. Hàm xử lý Đăng xuất chuẩn xác
  const handleLogout = async () => {
    // Gọi màn hình xác nhận thay thế cho confirm gốc của trình duyệt
    const result = await Swal.fire({
      title: 'Đăng xuất?',
      text: 'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#3b82f6',
      cancelButtonColor: '#94a3b8',
      confirmButtonText: 'Đăng xuất',
      cancelButtonText: 'Hủy',
    });

    if (!result.isConfirmed) return;

    // 1. Clear dữ liệu LocalStorage (Tokens, User Info)
    authAPI.logout();

    // (Tuỳ chọn) Gọi API Backend nếu Backend của bạn yêu cầu thu hồi token (Revoke Token)
    // await apiClient.post('/auth/logout');

    // 2. Điều hướng người dùng về trang Login
    navigate('/login');
  };

  return (
    <div
      style={{
        display: 'flex',
        minHeight: '100vh',
        width: '100%',
        background: '#F8FAFC',
      }}>
      {/* Sidebar */}
      <aside
        style={{
          width: '280px',
          background: 'linear-gradient(180deg, #3b82f6 0%, #2563eb 100%)',
          color: 'white',
          display: 'flex',
          flexDirection: 'column',
          padding: '24px 16px',
          position: 'fixed',
          height: '100vh',
          zIndex: 100,
        }}>
        {/* Logo */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            marginBottom: '40px',
            padding: '0 8px',
          }}>
          <div
            style={{
              background: 'white',
              color: '#3b82f6',
              padding: '6px',
              borderRadius: '10px',
              display: 'flex',
            }}>
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round">
              <circle cx="12" cy="12" r="10" />
              <polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76" />
            </svg>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontWeight: '800', fontSize: '18px', lineHeight: 1 }}>Travel Portal</span>
            <span style={{ fontSize: '11px', opacity: 0.8, marginTop: '2px' }}>Quản lý đối tác</span>
          </div>
        </div>

        {/* Menu Section */}
        <nav style={{ flex: 1 }}>
          <SidebarItem icon={<LayoutDashboard size={20} />} label="Dashboard" to="/dashboard" />
          <SidebarItem icon={<Building2 size={20} />} label="Danh sách địa điểm" to="/locations" />
          <SidebarItem icon={<ShoppingBag size={20} />} label="Đơn đặt món" to="/orders" badge={12} />
          <SidebarItem icon={<Settings size={20} />} label="Cài đặt" to="/settings" />
        </nav>

        {/* Sidebar Footer */}
        <div style={{ marginTop: 'auto', padding: '0 8px' }}>
          <button
            onClick={handleLogout} // Gắn hàm handleLogout vào đây
            style={{
              width: '100%',
              background: 'transparent',
              color: 'white',
              opacity: 0.8,
              padding: '12px 16px',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              fontSize: '14px',
              fontWeight: '600',
              borderRadius: '12px',
              transition: 'all 0.2s',
              marginBottom: '10px',
            }}>
            <LogOut size={20} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main
        style={{
          flex: 1,
          paddingLeft: '280px',
          display: 'flex',
          flexDirection: 'column',
        }}>
        {/* Topbar */}
        <header
          style={{
            height: '70px',
            background: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
            padding: '0 32px',
            borderBottom: '1px solid #E2E8F0',
            position: 'sticky',
            top: 0,
            zIndex: 90,
          }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
            {/* Search */}
            <div style={{ position: 'relative', width: '300px' }}>
              <Search
                size={16}
                style={{
                  position: 'absolute',
                  left: '12px',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  color: '#94a3b8',
                }}
              />
              <input
                type="text"
                placeholder="Tìm kiếm nhanh..."
                style={{
                  width: '100%',
                  padding: '8px 12px 8px 36px',
                  borderRadius: '10px',
                  border: '1px solid #F1F5F9',
                  background: '#F8FAFC',
                  fontSize: '14px',
                  outline: 'none',
                }}
              />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <button
                style={{
                  padding: '8px',
                  color: '#64748b',
                  background: 'transparent',
                }}>
                <Bell size={20} />
              </button>
              <button
                style={{
                  padding: '8px',
                  color: '#64748b',
                  background: 'transparent',
                }}>
                <HelpCircle size={20} />
              </button>
            </div>

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                paddingLeft: '24px',
                borderLeft: '1px solid #F1F5F9',
              }}>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{headerInfo.fullName}</p>
              </div>
              <div
                onClick={() => navigate('/profile')}
                style={{
                  width: '40px',
                  height: '40px',
                  borderRadius: '12px',
                  overflow: 'hidden',
                  border: '2px solid #F1F5F9',
                  cursor: 'pointer',
                }}>
                {/* 7. Thay ảnh tĩnh bằng ảnh từ API */}
                <img src={headerInfo.avatar} alt="User Avatar" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <section style={{ padding: '32px' }}>
          <Outlet />
        </section>
      </main>
    </div>
  );
};

export default ProviderLayout;
