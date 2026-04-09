import React, { useState, useEffect } from 'react';
import Button from '../../../components/UI/Button';
import { ChevronRight, ChevronLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { getOrdersByPlace, updateOrderStatus } from '@/services/order.service';
import { Order } from '@/types/order.types';

const userInfo = localStorage.getItem('userInfo');
const parsedUser = userInfo ? JSON.parse(userInfo) : null;
const PLACE_ID = parsedUser?.businessId || parsedUser?.id || '';

const OrdersPage: React.FC = () => {
  const navigate = useNavigate();
  const [statusFilter, setStatusFilter] = useState('all');
  const [restaurantFilter, setRestaurantFilter] = useState('all');


  // --- State mới cho API ---
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const handleViewDetail = (orderId: string) => {
    navigate(`/orders/${orderId}`);
  };

  const handleConfirm = async (e: React.MouseEvent, orderId: string) => {
    e.stopPropagation();
    try {
      await updateOrderStatus(orderId, 'processing');
      setOrders(prev => prev.map(o => o.order_id === orderId ? { ...o, status: 'processing' } : o));
    } catch (err) {
      console.error('Không thể cập nhật trạng thái đơn:', err);
    }
  };
  // --- Fetch data khi component mount ---
  useEffect(() => {
    const fetchOrders = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await getOrdersByPlace(PLACE_ID);
        setOrders(data); // điều chỉnh nếu API trả về { orders: [...] }
      } catch (err) {
        setError('Không thể tải danh sách đơn hàng.');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, []);

  const filteredOrders = orders.filter(order => {
    if (statusFilter !== 'all' && order.status !== statusFilter) return false;
    if (restaurantFilter !== 'all' && String(order.place_name || '').trim() !== restaurantFilter) return false;
    return true;
  });

  const restaurants = Array.from(new Set(orders.map(o => o.place_name).filter(Boolean)));

  return (
    <>
      <div style={{ padding: '0 20px' }}>
        <div style={{ marginBottom: '32px' }}>
          <h2 style={{ fontSize: '28px', fontWeight: '800', color: '#1e293b', fontFamily: "'Times New Roman', Times, serif" }}>Đơn đặt món</h2>
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
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Mã đơn</th>
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Thời gian</th>
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Nhà hàng</th>
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Khách hàng</th>
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Món ăn</th>
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Tổng tiền</th>
                <th style={{ padding: '20px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {filteredOrders.map((order, idx) => (
                <tr
                  key={order.order_id || idx}
                  onClick={() => handleViewDetail(order.order_id)}
                  style={{
                    borderBottom: idx < filteredOrders.length - 1 ? '1px solid #F1F5F9' : 'none',
                    fontSize: '14px',
                    cursor: 'pointer',
                    transition: 'background 0.2s'
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = '#F8FAFC')}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  <td style={{ padding: '24px', color: '#3b82f6', fontWeight: '700' }}>
                    #{order.order_id?.slice(0, 8)}...
                  </td>

                  <td style={{ padding: '24px', color: '#64748b' }}>
                    {order.ordered_time ? new Date(order.ordered_time).toLocaleString('vi-VN') : '-'}
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
                    {order.status === 'pending' ? (
                      <Button
                        style={{ padding: '8px 16px', fontSize: '12px', borderRadius: '8px' }}
                        onClick={(e) => handleConfirm(e, order.order_id)}
                      >
                        Xác nhận
                      </Button>
                    ) : order.status === 'processing' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#3b82f6', fontSize: '12px', fontWeight: '700' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#3b82f6' }}></div>
                        Đang xử lý
                      </div>
                    ) : order.status === 'completed' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#10b981', fontSize: '12px', fontWeight: '700' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981' }}></div>
                        Hoàn thành
                      </div>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div style={{ padding: '20px 24px', borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'flex-end', alignItems: 'center' }}>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid #F1F5F9', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#E2E8F0', cursor: 'not-allowed' }}>
                <ChevronLeft size={16} />
              </button>
              <button style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid #F1F5F9', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748b', cursor: 'pointer' }}>
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
