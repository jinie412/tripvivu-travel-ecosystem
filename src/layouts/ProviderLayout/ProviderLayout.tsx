import React, { useState, useEffect, useRef, useMemo } from 'react';
import './ProviderLayout.css';
import { LayoutDashboard, Building2, ShoppingBag, LogOut, HelpCircle, Search, User } from 'lucide-react';
import { NavLink, useNavigate, Outlet } from 'react-router-dom';
import authAPI from '../../services/authService';
import Swal from 'sweetalert2';

import apiClient from '../../utils/apiClient';
import { getCurrentUser } from '../../utils/auth';
import { getOrdersByPlace, isPendingOrder } from '../../services/order.service';
import { businessLocationAPI } from '../../services/businessLocationAPI';
import type { Location } from '../../types/location';
import { NotificationBell } from '../../components/NotificationBell';

const defaultAvatar =
  'https://media.istockphoto.com/id/1477583639/vector/user-profile-icon-vector-avatar-or-person-icon-profile-picture-portrait-symbol-vector.jpg?s=612x612&w=0&k=20&c=OWGIPPkZIWLPvnQS14ZSyHMoGtVTn1zS8cAgLy1Uh24=';

const ProviderLayout: React.FC = () => {
  const navigate = useNavigate();

  const vendorId = useMemo(() => {
    const user = getCurrentUser<{
      businessId?: string;
      business_id?: string;
      vendorId?: string;
      vendor_id?: string;
      id?: string;
    }>();
    return (
      [
        user?.businessId,
        user?.business_id,
        user?.vendorId,
        user?.vendor_id,
        user?.id,
      ].find((value): value is string => typeof value === 'string' && value.trim().length > 0) || ''
    );
  }, []);

  const [pendingOrderCount, setPendingOrderCount] = useState(0);

  // --- Quick search (topbar) ---
  const [quickSearch, setQuickSearch] = useState('');
  const [quickSearchResults, setQuickSearchResults] = useState<Location[]>([]);
  const [quickSearchOpen, setQuickSearchOpen] = useState(false);
  const [quickSearchLoading, setQuickSearchLoading] = useState(false);
  const quickSearchRequestId = useRef(0);
  const quickSearchBoxRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const keyword = quickSearch.trim();
    if (!keyword || !vendorId) {
      setQuickSearchResults([]);
      setQuickSearchLoading(false);
      return;
    }

    const timer = setTimeout(async () => {
      const requestId = ++quickSearchRequestId.current;
      setQuickSearchLoading(true);
      try {
        const response = await businessLocationAPI.getLocations(
          { vendorId, search: keyword, status: 'all', fields: 'basic' },
          { page: 1, limit: 6 },
        );
        if (requestId === quickSearchRequestId.current) {
          setQuickSearchResults(response.locations);
        }
      } catch {
        if (requestId === quickSearchRequestId.current) {
          setQuickSearchResults([]);
        }
      } finally {
        if (requestId === quickSearchRequestId.current) {
          setQuickSearchLoading(false);
        }
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [quickSearch, vendorId]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (quickSearchBoxRef.current && !quickSearchBoxRef.current.contains(event.target as Node)) {
        setQuickSearchOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const goToLocation = (locationId: string) => {
    setQuickSearchOpen(false);
    setQuickSearch('');
    navigate(`/locations/${locationId}`);
  };

  const goToSearchResults = () => {
    const keyword = quickSearch.trim();
    if (!keyword) return;
    setQuickSearchOpen(false);
    navigate(`/locations?search=${encodeURIComponent(keyword)}`);
  };

  const [headerInfo, setHeaderInfo] = useState(() => {
    const user = getCurrentUser<{ fullName?: string; avatar_url?: string }>();
    if (user) {
      return {
        fullName: user.fullName || 'Đối tác',
        avatar: user.avatar_url || defaultAvatar,
      };
    }
    return {
      fullName: 'Đang tải...',
      avatar: defaultAvatar,
    };
  });

  // Fetch số đơn pending để hiển thị badge
  useEffect(() => {
    const user = getCurrentUser<{ businessId?: string; id?: string }>();
    const vendorId = user?.businessId || user?.id || '';
    if (!vendorId) return;

    getOrdersByPlace(vendorId)
      .then((orders) => {
        setPendingOrderCount(orders.filter(isPendingOrder).length);
      })
      .catch(() => {});
  }, []);

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

        const user = getCurrentUser<{ fullName?: string }>();
        if (user) {
          setHeaderInfo((prev) => ({ ...prev, fullName: user.fullName ?? prev.fullName }));
        }
      }
    };

    fetchHeaderInfo();

    const handleUserUpdate = () => {
      const user = getCurrentUser<{ fullName?: string; avatarUrl?: string; avatar_url?: string }>();
      if (user) {
        setHeaderInfo((prev) => ({
          ...prev,
          fullName: user.fullName || prev.fullName,
          avatar: user.avatarUrl || user.avatar_url || defaultAvatar,
        }));
      }
    };

    window.addEventListener('userUpdated', handleUserUpdate);
    return () => window.removeEventListener('userUpdated', handleUserUpdate);
  }, []);

  const handleLogout = async () => {
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

    authAPI.logout();
    navigate('/login');
  };

  const brandInitial = headerInfo.fullName?.charAt(0)?.toUpperCase() || 'P';

  return (
    <div className="provider-layout">
      {/* Sidebar */}
      <aside className="provider-sidebar">
        {/* Brand */}
        <div className="provider-sidebar-brand">
          <div className="provider-brand-icon">
            <span>{brandInitial}</span>
          </div>
          <span>Đối tác</span>
        </div>

        {/* Menu */}
        <nav className="provider-sidebar-menu">
          <div className="provider-menu-group">
            <h4 className="provider-menu-title">TỔNG QUAN</h4>
            <NavLink to="/dashboard" className={({ isActive }) => `provider-menu-item${isActive ? ' active' : ''}`}>
              <LayoutDashboard size={20} />
              <span>Dashboard</span>
            </NavLink>
          </div>

          <div className="provider-menu-group">
            <h4 className="provider-menu-title">QUẢN LÝ</h4>
            <NavLink to="/locations" className={({ isActive }) => `provider-menu-item${isActive ? ' active' : ''}`}>
              <Building2 size={20} />
              <span>Danh sách địa điểm</span>
            </NavLink>
            <NavLink to="/orders" className={({ isActive }) => `provider-menu-item${isActive ? ' active' : ''}`}>
              <ShoppingBag size={20} />
              <span>Đơn đặt món</span>
            </NavLink>
          </div>
        </nav>

        {/* Footer */}
        <div className="provider-sidebar-footer">
          <NavLink
            to="/profile"
            className={({ isActive }) => `provider-menu-item${isActive ? ' active' : ''}`}
            style={{ marginBottom: '8px' }}>
            <User size={20} />
            <span>Hồ sơ cá nhân</span>
          </NavLink>
          <button onClick={handleLogout} className="provider-logout-btn">
            <LogOut size={20} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="provider-main">
        {/* Topbar */}
        <header className="provider-topbar">
          {/* Search */}
          <div className="provider-topbar-search" ref={quickSearchBoxRef}>
            <Search size={16} className="provider-topbar-search-icon" />
            <input
              type="text"
              placeholder="Tìm kiếm nhanh..."
              value={quickSearch}
              onChange={(e) => {
                setQuickSearch(e.target.value);
                setQuickSearchOpen(true);
              }}
              onFocus={() => setQuickSearchOpen(true)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  goToSearchResults();
                }
              }}
            />
            {quickSearchOpen && quickSearch.trim().length > 0 && (
              <div className="provider-topbar-search-dropdown">
                {quickSearchLoading ? (
                  <div className="provider-topbar-search-empty">Đang tìm...</div>
                ) : quickSearchResults.length === 0 ? (
                  <div className="provider-topbar-search-empty">Không tìm thấy địa điểm phù hợp</div>
                ) : (
                  <>
                    {quickSearchResults.map((loc) => (
                      <button
                        type="button"
                        key={loc.id}
                        className="provider-topbar-search-item"
                        onMouseDown={(e) => {
                          e.preventDefault();
                          goToLocation(loc.id);
                        }}
                      >
                        <span className="provider-topbar-search-item-name">{loc.name}</span>
                        <span className="provider-topbar-search-item-address">{loc.address}</span>
                      </button>
                    ))}
                    <button
                      type="button"
                      className="provider-topbar-search-viewall"
                      onMouseDown={(e) => {
                        e.preventDefault();
                        goToSearchResults();
                      }}
                    >
                      Xem tất cả kết quả cho "{quickSearch.trim()}"
                    </button>
                  </>
                )}
              </div>
            )}
          </div>

          {/* Icon actions */}
          <div className="provider-topbar-actions">
            <NotificationBell />
            <button className="provider-topbar-icon-btn">
              <HelpCircle size={20} />
            </button>
          </div>

          {/* User info */}
          <div className="provider-topbar-user">
            <p className="provider-topbar-username">{headerInfo.fullName}</p>
            <div className="provider-topbar-avatar" onClick={() => navigate('/profile')}>
              <img src={headerInfo.avatar} alt="User Avatar" />
            </div>
          </div>
        </header>

        {/* Page Content */}
        <section className="provider-page-content">
          <Outlet />
        </section>
      </main>
    </div>
  );
};

export default ProviderLayout;
