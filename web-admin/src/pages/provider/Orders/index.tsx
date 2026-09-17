import React, { useState, useEffect, useMemo } from 'react';
import { ChevronRight, ChevronLeft } from 'lucide-react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { formatOrderCode, formatVietnamDateTime, getOrdersByPlace, normalizeOrderStatus, rememberOrderRoute } from '@/services/order.service';
import { Order } from '@/types/order.types';
import { getCurrentUser } from '@/utils/auth';
import { businessLocationAPI } from '@/services/businessLocationAPI';
import type { Location } from '@/types/location';

interface ProviderUser {
  businessId?: string;
  business_id?: string;
  vendorId?: string;
  vendor_id?: string;
  id?: string;
}

const ORDERS_PER_PAGE = 10;

const getVisiblePages = (currentPage: number, totalPages: number): Array<number | 'ellipsis'> => {
  if (totalPages <= 7) return Array.from({ length: totalPages }, (_, index) => index + 1);

  const pages: Array<number | 'ellipsis'> = [1];
  if (currentPage > 4) pages.push('ellipsis');
  const start = Math.max(2, currentPage - 1);
  const end = Math.min(totalPages - 1, currentPage + 1);
  for (let page = start; page <= end; page += 1) pages.push(page);
  if (currentPage < totalPages - 3) pages.push('ellipsis');
  pages.push(totalPages);
  return pages;
};

const getProviderIds = (user: ProviderUser | null): string[] => {
  return Array.from(new Set([
    user?.businessId,
    user?.id,
    user?.business_id,
    user?.vendorId,
    user?.vendor_id,
  ].filter((value): value is string => typeof value === 'string' && value.trim().length > 0)));
};

const OrdersPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const initialStatusFilter = searchParams.get('status') || 'all';
  const [statusFilter, setStatusFilter] = useState(initialStatusFilter);
  const [cityFilter, setCityFilter] = useState('all');
  const [restaurantFilter, setRestaurantFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const providerIds = useMemo(() => getProviderIds(getCurrentUser<ProviderUser>()), []);


  // --- State mới cho API ---
  const [orders, setOrders] = useState<Order[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const handleViewDetail = (orderId: string) => {
    navigate(`/orders/${rememberOrderRoute(orderId)}`);
  };

  // --- Fetch data khi component mount ---
  useEffect(() => {
    const fetchOrders = async () => {
      try {
        setLoading(true);
        setError(null);
        if (providerIds.length === 0) {
          setOrders([]);
          setError('Không tìm thấy thông tin đối tác. Vui lòng đăng nhập lại.');
          return;
        }

        const [ordersData, locationsData] = await Promise.all([
          getOrdersByPlace(providerIds[0]),
          businessLocationAPI.getLocations(
            { vendorId: providerIds[0], status: 'all', sort: 'newest', fields: 'basic' },
            { page: 1, limit: 500 },
          ),
        ]);

        setOrders(ordersData);
        setLocations(locationsData.locations);
      } catch (err) {
        setError('Không thể tải danh sách đơn hàng.');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, [providerIds]);

  const locationCityById = useMemo(() => {
    return new Map(locations.map((location) => [location.id, location.city || '']));
  }, [locations]);

  const locationCityByName = useMemo(() => {
    return new Map(locations.map((location) => [location.name.trim().toLowerCase(), location.city || '']));
  }, [locations]);

  const cities = useMemo(() => {
    return Array.from(new Set(locations.map((location) => location.city).filter((city): city is string => Boolean(city?.trim()))));
  }, [locations]);

  const getOrderCity = (order: Order): string => {
    const placeId = order.placeId || '';
    const placeName = String(order.place_name || '').trim().toLowerCase();
    return locationCityById.get(placeId) || locationCityByName.get(placeName) || '';
  };

  const filteredOrders = orders.filter(order => {
    if (statusFilter !== 'all' && normalizeOrderStatus(order) !== statusFilter) return false;
    if (cityFilter !== 'all' && getOrderCity(order) !== cityFilter) return false;
    if (restaurantFilter !== 'all' && String(order.place_name || '').trim() !== restaurantFilter) return false;
    return true;
  });

  const totalPages = Math.max(1, Math.ceil(filteredOrders.length / ORDERS_PER_PAGE));
  const paginatedOrders = filteredOrders.slice(
    (currentPage - 1) * ORDERS_PER_PAGE,
    currentPage * ORDERS_PER_PAGE,
  );

  useEffect(() => {
    setCurrentPage(1);
  }, [statusFilter, cityFilter, restaurantFilter]);

  useEffect(() => {
    if (currentPage > totalPages) setCurrentPage(totalPages);
  }, [currentPage, totalPages]);

  const restaurants = Array.from(new Set(
    orders
      .filter((order) => cityFilter === 'all' || getOrderCity(order) === cityFilter)
      .map(o => o.place_name)
      .filter(Boolean),
  ));

  return (
    <>
      <div style={{ padding: '0 20px' }}>
        <div style={{ marginBottom: '32px' }}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>Đơn đặt món</h2>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', marginBottom: '32px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ position: 'relative' }}>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                style={{ padding: '8px 32px 8px 12px', borderRadius: '10px', border: '1px solid #E2E8F0', background: 'white', outline: 'none', fontSize: '13px', color: '#475569', appearance: 'none', minWidth: '140px' }}
              >
                <option value="all">Mọi trạng thái</option>
                <option value="pending">Chờ xác nhận</option>
                <option value="processing">Đang xử lý</option>
                <option value="completed">Hoàn thành</option>
                <option value="cancelled">Đã hủy</option>
              </select>
              <div style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }}>
                <ChevronRight size={14} style={{ transform: 'rotate(90deg)', color: '#94a3b8' }} />
              </div>
            </div>
            <div style={{ position: 'relative' }}>
              <select
                value={cityFilter}
                onChange={(e) => {
                  setCityFilter(e.target.value);
                  setRestaurantFilter('all');
                }}
                style={{ padding: '8px 32px 8px 12px', borderRadius: '10px', border: '1px solid #E2E8F0', background: 'white', outline: 'none', fontSize: '13px', color: '#475569', appearance: 'none', minWidth: '170px' }}
              >
                <option value="all">Tất cả tỉnh/thành</option>
                {cities.map(city => <option key={city} value={city}>{city}</option>)}
              </select>
              <div style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }}>
                <ChevronRight size={14} style={{ transform: 'rotate(90deg)', color: '#94a3b8' }} />
              </div>
            </div>
            <div style={{ position: 'relative' }}>
              <select
                value={restaurantFilter}
                onChange={(e) => setRestaurantFilter(e.target.value)}
                style={{ padding: '8px 32px 8px 12px', borderRadius: '10px', border: '1px solid #E2E8F0', background: 'white', outline: 'none', fontSize: '13px', color: '#475569', appearance: 'none', minWidth: '160px' }}
              >
                <option value="all">Tất cả địa điểm</option>
                {restaurants.map(r => <option key={r} value={r}>{r}</option>)}
              </select>
              <div style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }}>
                <ChevronRight size={14} style={{ transform: 'rotate(90deg)', color: '#94a3b8' }} />
              </div>
            </div>
          </div>
        </div>

        <div style={{ background: 'white', borderRadius: '24px', border: '1px solid #F1F5F9', overflow: 'hidden', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', borderBottom: '1px solid #F1F5F9' }}>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Mã đơn</th>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Thời gian</th>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Nhà hàng</th>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Khách hàng</th>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Món ăn</th>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Tổng tiền</th>
                <th style={{ padding: '20px 24px', fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-secondary)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7} style={{ padding: '32px 24px', textAlign: 'center', color: '#94a3b8', fontWeight: 600 }}>
                    Đang tải danh sách đơn hàng...
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={7} style={{ padding: '32px 24px', textAlign: 'center', color: '#ef4444', fontWeight: 600 }}>
                    {error}
                  </td>
                </tr>
              ) : filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ padding: '32px 24px', textAlign: 'center', color: '#94a3b8', fontWeight: 600 }}>
                    Chưa có đơn đặt món phù hợp.
                  </td>
                </tr>
              ) : paginatedOrders.map((order, idx) => (
                <tr
                  key={order.order_id || idx}
                  onClick={() => handleViewDetail(order.order_id)}
                  style={{
                    borderBottom: idx < paginatedOrders.length - 1 ? '1px solid #F1F5F9' : 'none',
                    fontSize: '14px',
                    cursor: 'pointer',
                    transition: 'background 0.2s'
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = '#F8FAFC')}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  <td style={{ padding: '24px', color: '#3b82f6', fontWeight: '700' }}>
                    {formatOrderCode(order.order_id)}
                  </td>

                  <td style={{ padding: '24px', color: '#64748b' }}>
                    {formatVietnamDateTime(order.ordered_time)}
                  </td>

                  <td style={{ padding: '24px' }}>
                    <span style={{ fontWeight: '600', color: '#475569', fontSize: '13px' }}>
                      {order.place_name}
                    </span>
                  </td>

                  <td style={{ padding: '24px' }}>
                    <p style={{ fontWeight: '700', color: '#1e293b' }}>{order.customer_name}</p>
                  </td>

                  <td style={{
                    padding: '24px',
                    color: '#64748b',
                    maxWidth: '200px',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis'
                  }}>
                    {order.foods || 'Không có thông tin món'}
                  </td>

                  <td style={{ padding: '24px', fontWeight: '800', color: '#1e293b' }}>
                    {order.total_amount?.toLocaleString('vi-VN')} ₫
                  </td>

                  <td style={{ padding: '24px' }}>
                    {normalizeOrderStatus(order) === 'pending' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#f59e0b', fontSize: '12px', fontWeight: '700' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#f59e0b' }}></div>
                        Chờ xác nhận
                      </div>
                    ) : normalizeOrderStatus(order) === 'processing' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#3b82f6', fontSize: '12px', fontWeight: '700' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#3b82f6' }}></div>
                        Đang xử lý
                      </div>
                    ) : normalizeOrderStatus(order) === 'completed' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#10b981', fontSize: '12px', fontWeight: '700' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981' }}></div>
                        Hoàn thành
                      </div>
                    ) : normalizeOrderStatus(order) === 'cancelled' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#ef4444', fontSize: '12px', fontWeight: '700' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#ef4444' }}></div>
                        Đã hủy
                      </div>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div style={{ padding: '20px 24px', borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
            <span style={{ fontSize: '13px', color: '#94a3b8' }}>
              Hiển thị {filteredOrders.length === 0 ? 0 : (currentPage - 1) * ORDERS_PER_PAGE + 1}–{Math.min(currentPage * ORDERS_PER_PAGE, filteredOrders.length)} trong {filteredOrders.length} đơn hàng
            </span>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                type="button"
                aria-label="Trang trước"
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
                style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid #F1F5F9', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: currentPage === 1 ? '#E2E8F0' : '#64748b', cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
              >
                <ChevronLeft size={16} />
              </button>
              {getVisiblePages(currentPage, totalPages).map((page, index) => page === 'ellipsis' ? (
                <span key={`ellipsis-${index}`} style={{ width: '32px', height: '32px', display: 'grid', placeItems: 'center', color: '#94a3b8' }}>…</span>
              ) : (
                <button
                  key={page}
                  type="button"
                  aria-label={`Trang ${page}`}
                  aria-current={currentPage === page ? 'page' : undefined}
                  onClick={() => setCurrentPage(page)}
                  style={{ width: '32px', height: '32px', borderRadius: '8px', border: currentPage === page ? '1px solid #3b82f6' : '1px solid #F1F5F9', background: currentPage === page ? '#3b82f6' : 'white', color: currentPage === page ? 'white' : '#64748b', cursor: 'pointer', fontWeight: 700 }}
                >
                  {page}
                </button>
              ))}
              <button
                type="button"
                aria-label="Trang sau"
                disabled={currentPage === totalPages || filteredOrders.length === 0}
                onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
                style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid #F1F5F9', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: currentPage === totalPages || filteredOrders.length === 0 ? '#E2E8F0' : '#64748b', cursor: currentPage === totalPages || filteredOrders.length === 0 ? 'not-allowed' : 'pointer' }}
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

export default OrdersPage;
