import React, { useState, useMemo, useEffect } from 'react';
import ProviderLayout from '../../../layouts/ProviderLayout/ProviderLayout';
import { Building2, Utensils, BookOpen, Star, ArrowUpDown, ChevronUp, ChevronDown } from 'lucide-react';
import { getDashboardStats, getFoodPerformance } from '@/services/order.service';

const userInfo = localStorage.getItem('userInfo');
const parsedUser = userInfo ? JSON.parse(userInfo) : null;
const VENDOR_ID = parsedUser?.businessId || parsedUser?.id || '';

interface StatCardProps {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  change: string;
  badge?: string;
  color?: string;
}

const StatCard: React.FC<StatCardProps> = ({ icon, label, value, change, badge, color = '#3b82f6' }) => (
  <div
    style={{
      flex: 1,
      background: 'white',
      padding: '24px',
      borderRadius: '24px',
      display: 'flex',
      flexDirection: 'column',
      boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05)',
      border: '1px solid #F1F5F9',
      position: 'relative',
      minWidth: '240px',
    }}>
    {badge && (
      <span
        style={{
          position: 'absolute',
          top: '12px',
          right: '12px',
          background: '#f59e0b',
          color: 'white',
          fontSize: '10px',
          fontWeight: '800',
          padding: '3px 8px',
          borderRadius: '6px',
          textTransform: 'uppercase',
        }}>
        {badge}
      </span>
    )}
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
      <div style={{ background: `${color}10`, color: color, padding: '10px', borderRadius: '12px', display: 'flex' }}>{icon}</div>
      <span style={{ fontSize: '12px', fontWeight: '700', color: '#10B981' }}>{change}</span>
    </div>
    <span style={{ fontSize: '13px', color: '#64748b', fontWeight: '500', marginBottom: '4px' }}>{label}</span>
    <span style={{ fontSize: '32px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>{value}</span>
  </div>
);

type SortKey = 'name' | 'location' | 'price' | 'orders';
type SortDirection = 'asc' | 'desc';

const DashboardPage: React.FC = () => {
  const [sortConfig, setSortConfig] = useState<{ key: SortKey; direction: SortDirection }>({
    key: 'orders',
    direction: 'desc',
  });

  const [dashboardData, setDashboardData] = useState<any>(null);
  const [foodPerformance, setFoodPerformance] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [stats, foods] = await Promise.all([
          getDashboardStats(VENDOR_ID),
          getFoodPerformance(VENDOR_ID),
        ]);
        setDashboardData(stats);
        setFoodPerformance(foods);
      } catch (error) {
        console.error('Error fetching dashboard:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchAll();
  }, []);


  const sortedData = useMemo(() => {
    const sortableData = [...foodPerformance];
    sortableData.sort((a, b) => {
      let aValue = sortConfig.key === 'price' ? (a.price ?? 0)
        : sortConfig.key === 'orders' ? (a.order_count ?? 0)
        : sortConfig.key === 'location' ? (a.place_name ?? '')
        : (a.food_name ?? '');
      let bValue = sortConfig.key === 'price' ? (b.price ?? 0)
        : sortConfig.key === 'orders' ? (b.order_count ?? 0)
        : sortConfig.key === 'location' ? (b.place_name ?? '')
        : (b.food_name ?? '');
      if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
    return sortableData;
  }, [sortConfig, foodPerformance]);

  const requestSort = (key: SortKey) => {
    let direction: SortDirection = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const renderSortIndicator = (key: SortKey) => {
    if (sortConfig.key !== key) return <ArrowUpDown size={14} style={{ marginLeft: '8px', opacity: 0.3 }} />;
    return sortConfig.direction === 'asc' ? (
      <ChevronUp size={14} style={{ marginLeft: '8px', color: '#3b82f6' }} />
    ) : (
      <ChevronDown size={14} style={{ marginLeft: '8px', color: '#3b82f6' }} />
    );
  };

  return (
    <>
      {/* Stats Grid */}
      <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap', marginBottom: '40px' }}>
        <StatCard icon={<Building2 size={24} />} label="Địa điểm đã đăng ký" value={dashboardData?.total_places || 0}/>
        <StatCard icon={<Utensils size={24} />} label="Đơn đặt món mới" value={dashboardData?.total_orders || 0} badge="CẦN XỬ LÝ" color="#f59e0b" />
        <StatCard icon={<BookOpen size={24} />} label="Món ăn đang bán" value={dashboardData?.total_food_items || 0} color="#6366f1" />
        <StatCard icon={<Star size={24} />} label="Đánh giá trung bình" value={(dashboardData?.average_rating ?? 0).toFixed(1)} color="#eab308" />
      </div>

      {/* Main Section Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '24px' }}>
        <div>
          <h3
            style={{
              fontSize: '28px',
              fontWeight: '800',
              color: '#000000',
              fontFamily: "'Times New Roman', Times, serif",
              marginBottom: '4px',
            }}>
            Hiệu suất Sản phẩm / Dịch vụ
          </h3>
          <p style={{ fontSize: '14px', color: '#64748b' }}>Thống kê chi tiết tất cả các dịch vụ đang kinh doanh.</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <select
            style={{
              padding: '10px 16px',
              borderRadius: '12px',
              border: '1px solid #E2E8F0',
              background: 'white',
              fontSize: '14px',
              fontWeight: '600',
              outline: 'none',
              color: '#1e293b',
              cursor: 'pointer',
            }}>
            {Array.from({ length: 12 }, (_, i) => (
              <option key={i + 1} value={i + 1}>
                Tháng {(i + 1).toString().padStart(2, '0')}
              </option>
            ))}
          </select>
          <select
            style={{
              padding: '10px 16px',
              borderRadius: '12px',
              border: '1px solid #E2E8F0',
              background: 'white',
              fontSize: '14px',
              fontWeight: '600',
              outline: 'none',
              color: '#1e293b',
              cursor: 'pointer',
            }}
            defaultValue="2024">
            {Array.from({ length: 2030 - 2010 + 1 }, (_, i) => (
              <option key={2010 + i} value={2010 + i}>
                Năm {2010 + i}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Services Table Section */}
      <div
        style={{
          background: 'white',
          borderRadius: '24px',
          padding: '8px 0',
          boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
          border: '1px solid #F1F5F9',
        }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #F1F5F9' }}>
              <th
                onClick={() => requestSort('name')}
                style={{
                  textAlign: 'left',
                  padding: '20px 24px',
                  fontSize: '15px',
                  color: '#000000',
                  fontWeight: '800',
                  fontFamily: "'Times New Roman', Times, serif",
                  cursor: 'pointer',
                  userSelect: 'none',
                }}>
                <div style={{ display: 'flex', alignItems: 'center' }}>Sản phẩm / Dịch vụ {renderSortIndicator('name')}</div>
              </th>
              <th
                style={{
                  textAlign: 'left',
                  padding: '20px 24px',
                  fontSize: '15px',
                  color: '#000000',
                  fontWeight: '800',
                  fontFamily: "'Times New Roman', Times, serif",
                  userSelect: 'none',
                }}>
                <div style={{ display: 'flex', alignItems: 'center' }}>Địa điểm</div>
              </th>
              <th
                style={{
                  textAlign: 'left',
                  padding: '20px 24px',
                  fontSize: '15px',
                  color: '#000000',
                  fontWeight: '800',
                  fontFamily: "'Times New Roman', Times, serif",
                  userSelect: 'none',
                }}>
                <div style={{ display: 'flex', alignItems: 'center' }}>Phân loại</div>
              </th>
              <th
                onClick={() => requestSort('price')}
                style={{
                  padding: '20px 24px',
                  fontSize: '15px',
                  color: '#000000',
                  fontWeight: '800',
                  fontFamily: "'Times New Roman', Times, serif",
                  cursor: 'pointer',
                  userSelect: 'none',
                }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  Giá bán {renderSortIndicator('price')}
                </div>
              </th>
              <th
                onClick={() => requestSort('orders')}
                style={{
                  padding: '20px 24px',
                  fontSize: '15px',
                  color: '#000000',
                  fontWeight: '800',
                  fontFamily: "'Times New Roman', Times, serif",
                  cursor: 'pointer',
                  userSelect: 'none',
                }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  Lượt đặt {renderSortIndicator('orders')}
                </div>
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={5} style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>Đang tải dữ liệu...</td></tr>
            ) : sortedData.length === 0 ? (
              <tr><td colSpan={5} style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>Chưa có dữ liệu món ăn</td></tr>
            ) : sortedData.map((item, index) => (
              <tr key={item.food_id} style={{ borderBottom: index === sortedData.length - 1 ? 'none' : '1px solid #F8FAFC' }}>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <div style={{ position: 'relative', width: '52px', height: '52px', background: '#F1F5F9', borderRadius: '14px', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Utensils size={24} color="#94a3b8" />
                      {index < 3 && (
                        <span style={{
                          position: 'absolute', top: '-8px', left: '-8px',
                          background: index === 0 ? '#F59E0B' : index === 1 ? '#94A3B8' : '#B45309',
                          color: 'white', width: '22px', height: '22px', borderRadius: '50%',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          fontSize: '11px', fontWeight: '800', border: '2px solid white',
                          boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        }}>
                          {index + 1}
                        </span>
                      )}
                    </div>
                    <span style={{ fontWeight: '700', color: '#1e293b', fontSize: '15px' }}>{item.food_name}</span>
                  </div>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <span style={{ fontSize: '14px', fontWeight: '600', color: '#64748b' }}>{item.place_name}</span>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <span style={{ padding: '6px 12px', borderRadius: '8px', fontSize: '11px', fontWeight: '800', background: '#DBEAFE', color: '#2563EB', textTransform: 'uppercase' }}>
                    Món ăn
                  </span>
                </td>
                <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                  <span style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b' }}>
                    {Number(item.price).toLocaleString('vi-VN')}đ
                  </span>
                </td>
                <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                  <span style={{ fontSize: '16px', fontWeight: '800', color: '#10b981' }}>{item.order_count ?? 0}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
};

export default DashboardPage;
