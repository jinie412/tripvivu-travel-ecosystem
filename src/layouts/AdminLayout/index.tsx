import React, { useState, useEffect } from 'react';
import './AdminLayout.css';
import { LayoutDashboard, Users, MapPin, Star, LogOut, ChevronDown, MapPinned, CalendarDays, SlidersHorizontal, History, Play, User } from 'lucide-react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import authAPI from '../../services/authService';
import Swal from 'sweetalert2';

export const AdminLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();

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

  const isDashboardActive = location.pathname === '/admin/dashboard' || location.pathname === '/admin';
  const isUserActive = location.pathname.startsWith('/admin/users');
  const isLocationActive = location.pathname.startsWith('/admin/locations');
  const isReviewActive =
    location.pathname.startsWith('/admin/reviews') ||
    location.pathname.startsWith('/admin/itinerary-reviews');
  const isAlgoActive = location.pathname.startsWith('/admin/algorithm-settings');
  const isAlgoRunnerActive = location.pathname.startsWith('/admin/algorithm-runner');
  const isAlgoHistoryActive = location.pathname.startsWith('/admin/algorithm-history');

  const [reviewOpen, setReviewOpen] = useState(isReviewActive);

  // Tự mở submenu khi điều hướng vào /admin/reviews hoặc /admin/itinerary-reviews
  useEffect(() => {
    if (isReviewActive) setReviewOpen(true);
  }, [isReviewActive]);

  const isLocationReviewActive =
    location.pathname.startsWith('/admin/reviews') &&
    !location.search.includes('tab=itinerary');
  const isItineraryReviewActive =
    location.search.includes('tab=itinerary') ||
    location.pathname.startsWith('/admin/itinerary-reviews');

  return (
    <div className="admin-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-icon">
            <span className="brand-logo">G</span>
          </div>
          <span className="brand-name">Admin</span>
        </div>

        <div className="sidebar-menu">
          <div className="menu-group">
            <h4 className="menu-title">TỔNG QUAN</h4>
            <Link
              to="/admin/dashboard"
              className={`menu-item ${isDashboardActive ? 'active' : ''}`}>
              <LayoutDashboard size={20} />
              <span>Dashboard</span>
            </Link>
          </div>

          <div className="menu-group">
            <h4 className="menu-title">QUẢN LÝ</h4>
            <Link to="/admin/users" className={`menu-item ${isUserActive ? 'active' : ''}`}>
              <Users size={20} />
              <span>Người dùng</span>
            </Link>
            <Link to="/admin/locations" className={`menu-item ${isLocationActive ? 'active' : ''}`}>
              <MapPin size={20} />
              <span>Địa điểm</span>
            </Link>
            <button
              className={`menu-item menu-item--expandable ${isReviewActive ? 'active' : ''}`}
              onClick={() => setReviewOpen(prev => !prev)}
            >
              <Star size={20} />
              <span>Đánh giá</span>
              <ChevronDown
                size={14}
                className={`submenu-chevron ${reviewOpen ? 'submenu-chevron--open' : ''}`}
              />
            </button>

            {reviewOpen && (
              <div className="submenu">
                <Link
                  to="/admin/reviews"
                  className={`submenu-item ${isLocationReviewActive ? 'submenu-item--active' : ''}`}
                >
                  <MapPinned size={15} />
                  Đánh giá địa điểm
                </Link>
                <Link
                  to="/admin/reviews?tab=itinerary"
                  className={`submenu-item ${isItineraryReviewActive ? 'submenu-item--active' : ''}`}
                >
                  <CalendarDays size={15} />
                  Đánh giá lịch trình
                </Link>
              </div>
            )}
          </div>

          <div className="menu-group">
            <h4 className="menu-title">CÀI ĐẶT</h4>
            <Link
              to="/admin/algorithm-settings"
              className={`menu-item ${isAlgoActive ? 'active' : ''}`}>
              <SlidersHorizontal size={20} />
              <span>Thiết lập thuật toán</span>
            </Link>
            <Link
              to="/admin/algorithm-runner"
              className={`menu-item ${isAlgoRunnerActive ? 'active' : ''}`}>
              <Play size={20} />
              <span>Lịch chạy thuật toán</span>
            </Link>
            <Link
              to="/admin/algorithm-history"
              className={`menu-item ${isAlgoHistoryActive ? 'active' : ''}`}>
              <History size={20} />
              <span>Lịch sử thiết lập và chạy thuật toán</span>
            </Link>
          </div>
        </div>

        <div className="sidebar-footer">
          <Link
            to="/admin/profile"
            className={`menu-item ${location.pathname === '/admin/profile' ? 'active' : ''}`}
            style={{ marginBottom: '8px' }}>
            <User size={20} />
            <span>Hồ sơ cá nhân</span>
          </Link>
          <button
            onClick={handleLogout}
            className="menu-item logout"
            style={{
              width: '100%',
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              textAlign: 'left',
            }}>
            <LogOut size={20} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>

      <main className="main-content">{children}</main>
    </div>
  );
};
