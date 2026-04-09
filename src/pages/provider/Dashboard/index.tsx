import React, { useState, useMemo, useEffect } from 'react';
import ProviderLayout from '../../../layouts/ProviderLayout/ProviderLayout';
import { Building2, Utensils, BookOpen, Star, ArrowUpDown, ChevronUp, ChevronDown } from 'lucide-react';
import { getDashboardStats } from '@/services/order.service';

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

type SortKey = 'name' | 'location' | 'category' | 'price' | 'orders';
type SortDirection = 'asc' | 'desc';

const DashboardPage: React.FC = () => {
  const [sortConfig, setSortConfig] = useState<{ key: SortKey; direction: SortDirection }>({
    key: 'orders',
    direction: 'desc',
  });

  const [dashboardData, setDashboardData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardStats = async () => {
      try {
        const data = await getDashboardStats(VENDOR_ID);
        setDashboardData(data);
      } catch (error) {
        console.error('Error fetching dashboard stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardStats();
  }, []);

  const allData = [
    {
      id: 1,
      name: 'Nhà hàng Biển Đông',
      address: '24 Trần Phú, Nha Trang',
      type: 'NHÀ HÀNG',
      status: 'Đã duyệt',
      rating: 4.9,
      img: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=100&h=100&fit=crop',
    },
    {
      id: 2,
      name: 'Khách sạn Mường Thanh',
      address: '60 Võ Nguyên Giáp, Đà Nẵng',
      type: 'LƯU TRÚ',
      status: 'Đã duyệt',
      rating: 4.7,
      img: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=100&h=100&fit=crop',
    },
    {
      id: 3,
      name: 'Dịch vụ Thuê xe máy',
      address: 'Quận Ngũ Hành Sơn, Đà Nẵng',
      type: 'THUÊ XE',
      status: 'Đang chờ',
      rating: null,
      img: 'https://images.unsplash.com/photo-1558981403-c5f91cbba527?w=100&h=100&fit=crop',
    },
    // Mocking second page
    {
      id: 4,
      name: 'Quán Coffee Sky',
      address: '12 Bạch Đằng, Đà Nẵng',
      type: 'NHÀ HÀNG',
      status: 'Đã duyệt',
      rating: 4.5,
      img: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=100&h=100&fit=crop',
    },
    {
      id: 5,
      name: 'Resort Hòa Bình',
      address: 'Bãi biển Mỹ Khê, Đà Nẵng',
      type: 'LƯU TRÚ',
      status: 'Đã duyệt',
      rating: 4.8,
      img: 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=100&h=100&fit=crop',
    },
  ];

  const servicesData = [
    {
      id: 1,
      name: 'Lẩu hải sản đặc biệt',
      location: 'Nhà hàng Biển Đông',
      category: 'Món ăn',
      priceValue: 350000,
      price: '350.000đ',
      orders: 156,
      rating: 4.9,
      img: 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 2,
      name: 'Cua rang me',
      location: 'Nhà hàng Biển Đông',
      category: 'Món ăn',
      priceValue: 450000,
      price: '450.000đ',
      orders: 128,
      rating: 4.8,
      img: 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 3,
      name: 'Gỏi cá mai',
      location: 'Nhà hàng Biển Đông',
      category: 'Món ăn',
      priceValue: 120000,
      price: '120.000đ',
      orders: 95,
      rating: 4.7,
      img: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 4,
      name: 'Tôm hùm nướng bơ tỏi',
      location: 'Nhà hàng Biển Đông',
      category: 'Món ăn',
      priceValue: 850000,
      price: '850.000đ',
      orders: 82,
      rating: 5.0,
      img: 'https://images.unsplash.com/photo-1559742811-824289511f48?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 5,
      name: 'Thuê xe máy SH',
      location: 'Dịch vụ Thuê xe máy',
      category: 'Dịch vụ',
      priceValue: 250000,
      price: '250.000đ',
      orders: 64,
      rating: 4.6,
      img: 'https://images.unsplash.com/photo-1558981403-c5f91cbba527?auto=format&fit=crop&w=200&h=200&fit=crop',
    },
    {
      id: 6,
      name: 'Phòng Deluxe Sea View',
      location: 'Khách sạn Mường Thanh',
      category: 'Phòng nghỉ',
      priceValue: 1200000,
      price: '1.200.000đ',
      orders: 45,
      rating: 4.9,
      img: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 7,
      name: ' Buffet sáng cao cấp',
      location: 'Khách sạn Mường Thanh',
      category: 'Dịch vụ',
      priceValue: 250000,
      price: '250.000đ',
      orders: 210,
      rating: 4.5,
      img: 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 8,
      name: 'Cà phê muối đặc biệt',
      location: 'Quán Coffee Sky',
      category: 'Đồ uống',
      priceValue: 45000,
      price: '45.000đ',
      orders: 320,
      rating: 4.9,
      img: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 9,
      name: 'Trà trái cây nhiệt đới',
      location: 'Quán Coffee Sky',
      category: 'Đồ uống',
      priceValue: 55000,
      price: '55.000đ',
      orders: 180,
      rating: 4.7,
      img: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=200&q=80',
    },
    {
      id: 10,
      name: 'Tour lặn ngắm san hô',
      location: 'Nhà hàng Biển Đông',
      category: 'Dịch vụ',
      priceValue: 650000,
      price: '650.000đ',
      orders: 32,
      rating: 4.8,
      img: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=200&q=80',
    },
  ];

  const sortedData = useMemo(() => {
    let sortableData = [...servicesData];
    if (sortConfig.key) {
      sortableData.sort((a, b) => {
        let aValue: any = a[sortConfig.key];
        let bValue: any = b[sortConfig.key];

        // Special handling for pricing
        if (sortConfig.key === 'price') {
          aValue = a.priceValue;
          bValue = b.priceValue;
        }

        if (aValue < bValue) {
          return sortConfig.direction === 'asc' ? -1 : 1;
        }
        if (aValue > bValue) {
          return sortConfig.direction === 'asc' ? 1 : -1;
        }
        return 0;
      });
    }
    return sortableData;
  }, [sortConfig, servicesData]);

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
                onClick={() => requestSort('category')}
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
                <div style={{ display: 'flex', alignItems: 'center' }}>Phân loại {renderSortIndicator('category')}</div>
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
            {sortedData.map((item, index) => (
              <tr key={item.id} style={{ borderBottom: index === sortedData.length - 1 ? 'none' : '1px solid #F8FAFC' }}>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <div
                      style={{
                        position: 'relative',
                        width: '52px',
                        height: '52px',
                        background: '#F1F5F9',
                        borderRadius: '14px',
                        flexShrink: 0,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        overflow: 'visible',
                      }}>
                      <img
                        src={item.img}
                        alt=""
                        style={{
                          width: '100%',
                          height: '100%',
                          borderRadius: '14px',
                          objectFit: 'cover',
                          display: 'block',
                        }}
                      />
                      {index < 3 && (
                        <span
                          style={{
                            position: 'absolute',
                            top: '-8px',
                            left: '-8px',
                            background: index === 0 ? '#F59E0B' : index === 1 ? '#94A3B8' : index === 2 ? '#B45309' : 'transparent',
                            color: 'white',
                            width: '22px',
                            height: '22px',
                            borderRadius: '50%',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '11px',
                            fontWeight: '800',
                            border: '2px solid white',
                            boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                          }}>
                          {index + 1}
                        </span>
                      )}
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
                      <span style={{ fontWeight: '700', color: '#1e293b', fontSize: '15px' }}>{item.name}</span>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <Star size={12} fill="#EAB308" color="#EAB308" />
                        <span style={{ fontSize: '12px', color: '#64748b', fontWeight: '600' }}>{item.rating}</span>
                      </div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <span style={{ fontSize: '14px', fontWeight: '600', color: '#64748b' }}>{item.location}</span>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <span
                    style={{
                      padding: '6px 12px',
                      borderRadius: '8px',
                      fontSize: '11px',
                      fontWeight: '800',
                      background: item.category === 'Món ăn' ? '#DBEAFE' : item.category === 'Phòng nghỉ' ? '#DCFCE7' : '#F3E8FF',
                      color: item.category === 'Món ăn' ? '#2563EB' : item.category === 'Phòng nghỉ' ? '#16A34A' : '#9333EA',
                      textTransform: 'uppercase',
                    }}>
                    {item.category}
                  </span>
                </td>
                <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                  <span style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b' }}>{item.price}</span>
                </td>
                <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                  <span style={{ fontSize: '16px', fontWeight: '800', color: '#10b981' }}>{item.orders}</span>
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
