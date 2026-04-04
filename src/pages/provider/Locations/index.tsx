import React, { useState, useEffect } from 'react';
import Button from '../../../components/UI/Button';
import { Search, ChevronLeft, ChevronRight, Edit3, Trash2, Plus, Star } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import defaultLocationImage from '../../../assets/images/location-default.svg';

import { businessLocationAPI } from '../../../services/businessLocationAPI';
import type { Location } from '../../../types/location';

interface LocationsPageState {
  locations: Location[];
  loading: boolean;
  error: string | null;
  totalItems: number;
  search: string;
  statusFilter: '' | 'pending' | 'approved' | 'rejected';
  sortOrder: 'default' | 'popular' | 'newest';
}
const LocationsPage: React.FC = () => {
  const navigate = useNavigate();
  const [currentPage, setCurrentPage] = useState(1);
  const userInfo = localStorage.getItem('userInfo');
  const parsedUser = userInfo ? JSON.parse(userInfo) : null;
  const vendorId = parsedUser?.businessId || parsedUser?.id || '';
  const [state, setState] = useState<LocationsPageState>({
    locations: [],
    loading: true,
    error: null,
    totalItems: 0,
    search: '',
    statusFilter: '',
    sortOrder: 'newest'
  });

  // Fetch locations on mount and when filters change
  useEffect(() => {
    const fetchLocations = async () => {
      try {
        if (!vendorId) {
          setState(prev => ({
            ...prev,
            loading: false,
            locations: [],
            totalItems: 0,
            error: 'Không tìm thấy thông tin business. Vui lòng đăng nhập lại.'
          }));
          return;
        }

        setState(prev => ({ ...prev, loading: true, error: null }));
        const response = await businessLocationAPI.getLocations({
          vendorId,
          search: state.search,
          status: state.statusFilter || undefined,
          sort: state.sortOrder
        }, {
          page: currentPage,
          limit: 10
        });
        
        setState(prev => ({
          ...prev,
          locations: response.locations,
          totalItems: response.total,
          loading: false
        }));
      } catch (error) {
        setState(prev => ({
          ...prev,
          error: error instanceof Error ? error.message : 'Failed to fetch locations',
          loading: false
        }));
      }
    };

    fetchLocations();
  }, [currentPage, state.search, state.statusFilter, state.sortOrder, vendorId]);

  const getStatusColor = (status: string): string => {
    const statusColors: { [key: string]: string } = {
      'pending': '#f59e0b',
      'approved': '#10b981',
      'rejected': '#ef4444'
    };
    return statusColors[status] || '#94a3b8';
  };

  const getStatusLabel = (status: string): string => {
    const statusLabels: { [key: string]: string } = {
      'pending': 'Chờ duyệt',
      'approved': 'Đã duyệt',
      'rejected': 'Từ chối'
    };
    return statusLabels[status] || status;
  };

  return (
    <>
      <div style={{ padding: '0 20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
          <h2 style={{ fontSize: '28px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>Danh sách địa điểm quản lý</h2>
          <Button onClick={() => navigate('/add-location')} style={{ gap: '8px', padding: '10px 24px', borderRadius: '12px' }}>
            <Plus size={18} /> Thêm địa điểm
          </Button>
        </div>

        {/* Filter Bar */}
        <div style={{ background: 'white', padding: '16px', borderRadius: '20px', border: '1px solid #F1F5F9', marginBottom: '32px', display: 'flex', alignItems: 'center', gap: '20px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
          <div style={{ position: 'relative', flex: 1 }}>
            <Search size={18} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
            <input 
              type="text" 
              placeholder="Tìm kiếm tên địa điểm, mã số..." 
              value={state.search}
              onChange={(e) => {
                setState(prev => ({ ...prev, search: e.target.value }));
                setCurrentPage(1);
              }}
              style={{ width: '100%', padding: '12px 12px 12px 48px', borderRadius: '12px', border: '1px solid #F1F5F9', background: '#F8FAFC', outline: 'none', fontSize: '14px' }}
            />
          </div>
          <div style={{ position: 'relative' }}>
            <select 
              value={state.statusFilter}
              onChange={(e) => {
                setState(prev => ({ ...prev, statusFilter: e.target.value as LocationsPageState['statusFilter'] }));
                setCurrentPage(1);
              }}
              style={{ padding: '12px 36px 12px 16px', borderRadius: '12px', border: '1px solid #F1F5F9', background: '#F8FAFC', outline: 'none', fontSize: '14px', color: '#64748b', appearance: 'none', minWidth: '160px' }}>
              <option value="">Tất cả trạng thái</option>
              <option value="pending">Chờ duyệt</option>
              <option value="approved">Đã duyệt</option>
              <option value="rejected">Từ chối</option>
            </select>
            <ChevronLeft size={16} style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%) rotate(-90deg)', color: '#94a3b8', pointerEvents: 'none' }} />
          </div>
        </div>



        {/* Table Container */}
        {state.error && (
          <div style={{ marginBottom: '16px', padding: '12px 16px', borderRadius: '12px', background: '#fee2e2', color: '#b91c1c', fontSize: '14px', fontWeight: '600' }}>
            {state.error}
          </div>
        )}
        <div style={{ background: 'white', borderRadius: '24px', border: '1px solid #F1F5F9', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', background: '#FCFCFD', borderBottom: '1px solid #F1F5F9' }}>
                <th style={{ padding: '20px 24px', fontSize: '15px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>Tên địa điểm</th>
                <th style={{ padding: '20px 24px', fontSize: '15px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>Loại hình</th>
                <th style={{ padding: '20px 24px', fontSize: '15px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>Đánh giá</th>
                <th style={{ padding: '20px 24px', fontSize: '15px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>Trạng thái</th>
                <th style={{ padding: '20px 24px', fontSize: '15px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {state.loading ? (
                <tr>
                  <td colSpan={5} style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
                    Đang tải...
                  </td>
                </tr>
              ) : state.locations.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
                    Không tìm thấy địa điểm nào
                  </td>
                </tr>
              ) : (
                state.locations.map((loc, idx) => (
                <tr 
                  key={loc.id} 
                  onClick={() => navigate(`/locations/${loc.id}`)}
                  style={{ 
                    borderBottom: idx < state.locations.length - 1 ? '1px solid #F8FAFC' : 'none',
                    cursor: 'pointer',
                    transition: 'background 0.2s'
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = '#F8FAFC')}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  <td style={{ padding: '20px 24px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                      <img
                        src={loc.image || defaultLocationImage}
                        alt={loc.name}
                        style={{ width: '64px', height: '64px', borderRadius: '8px', objectFit: 'cover', flexShrink: 0 }}
                        onError={(event) => {
                          event.currentTarget.onerror = null;
                          event.currentTarget.src = defaultLocationImage;
                        }}
                      />
                      <div>
                        <p style={{ fontSize: '15px', fontWeight: '800', color: '#1e293b' }}>{loc.name}</p>
                        <p style={{ fontSize: '12px', color: '#94a3b8' }}>{loc.address}</p>
                      </div>
                    </div>
                  </td>
                    <td style={{ padding: '20px 24px' }}>
                      <span style={{ padding: '4px 12px', borderRadius: '20px', background: '#3b82f6' + '15', color: '#3b82f6', fontSize: '11px', fontWeight: '800' }}>
                        {loc.category || 'Khác'}
                      </span>
                    </td>
                  <td style={{ padding: '20px 24px' }}>
                    {loc.rating && loc.rating > 0 ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '13px', color: '#444' }}>
                        <Star size={14} fill="#fbbf24" color="#fbbf24" />
                        <span style={{ fontWeight: '800' }}>{loc.rating}</span>
                        <span style={{ color: '#94a3b8', fontSize: '12px' }}>({loc.review_count})</span>
                      </div>
                    ) : (
                      <span style={{ fontSize: '13px', color: '#94a3b8' }}>Chưa có đánh giá</span>
                    )}
                  </td>
                  <td style={{ padding: '20px 24px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: getStatusColor(loc.status), fontSize: '13px', fontWeight: '700' }}>
                      <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: getStatusColor(loc.status) }}></div>
                      {getStatusLabel(loc.status)}
                    </div>
                  </td>
                  <td style={{ padding: '20px 24px' }}>
                    <div style={{ display: 'flex', gap: '16px', color: '#94a3b8' }}>
                      <Edit3 size={18} style={{ cursor: 'pointer' }} onClick={() => navigate(`/locations/${loc.id}`)} />
                      <Trash2 size={18} style={{ cursor: 'pointer' }} />
                    </div>
                  </td>
                </tr>
              ))
              )}
            </tbody>
          </table>
          
          <div style={{ padding: '20px 24px', borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: '#94a3b8' }}>Hiển thị {(currentPage-1)*10 + 1} - {Math.min(currentPage*10, state.totalItems)} của {state.totalItems} địa điểm</span>
            <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
              <button 
                onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                disabled={currentPage === 1}
                style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid #F1F5F9', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: currentPage === 1 ? '#E2E8F0' : '#64748b', cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
              >
                <ChevronLeft size={16} />
              </button>
              <div style={{ display: 'flex', gap: '4px' }}>
                {Array.from({ length: Math.ceil(state.totalItems / 10) }, (_, i) => i + 1).map(page => (
                  <button 
                    key={page}
                    onClick={() => setCurrentPage(page)}
                    style={{ 
                      width: '32px', 
                      height: '32px', 
                      borderRadius: '8px', 
                      background: currentPage === page ? '#3b82f6' : 'transparent', 
                      color: currentPage === page ? 'white' : '#64748b', 
                      border: currentPage === page ? 'none' : '1px solid #F1F5F9', 
                      fontSize: '13px', 
                      fontWeight: currentPage === page ? '700' : '600',
                      cursor: 'pointer'
                    }}
                  >
                    {page}
                  </button>
                ))}
              </div>
              <button 
                onClick={() => setCurrentPage(prev => Math.min(Math.ceil(state.totalItems / 10), prev + 1))}
                disabled={currentPage >= Math.ceil(state.totalItems / 10)}
                style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid #F1F5F9', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: currentPage >= Math.ceil(state.totalItems / 10) ? '#E2E8F0' : '#64748b', cursor: currentPage >= Math.ceil(state.totalItems / 10) ? 'not-allowed' : 'pointer' }}
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default LocationsPage;
