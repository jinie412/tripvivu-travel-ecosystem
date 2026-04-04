import React, { useEffect, useMemo, useState } from 'react';
import Input from '../../../../components/UI/Input';
import Button from '../../../../components/UI/Button';
import {
  Clock,
  MapPin,
  Upload,
  Wifi,
  Car,
  Wind,
  CreditCard,
  Search,
  Plus,
  Trash2,
  Edit2,
  ChevronLeft,
  ChevronRight,
  Star,
  Waves,
} from 'lucide-react';
import { useNavigate, useParams } from 'react-router-dom';
import { businessLocationAPI } from '../../../../services/businessLocationAPI';
import { businessReviewAPI } from '../../../../services/businessReviewAPI';
import type { Location } from '../../../../types/location';

const LocationEditPage: React.FC = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const userInfo = localStorage.getItem('userInfo');
  const parsedUser = userInfo ? JSON.parse(userInfo) : null;
  const vendorId = parsedUser?.businessId || parsedUser?.id || '';
  const [activeTab, setActiveTab] = useState('Thông tin chung');
  const [isActive, setIsActive] = useState(true);
  const [replyingToId, setReplyingToId] = useState<string | null>(null);
  const [location, setLocation] = useState<Location | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reviewRating, setReviewRating] = useState<number | undefined>(undefined);
  const [reviewSort, setReviewSort] = useState<'newest' | 'oldest' | 'highest_rating' | 'lowest_rating'>('newest');
  const [reviewHasImages, setReviewHasImages] = useState(false);
  const [reviewData, setReviewData] = useState<{
    stats: {
      averageRating: number;
      totalReviews: number;
      breakdown: Record<1 | 2 | 3 | 4 | 5, { count: number; percent: number }>;
      aiInsight: string;
    };
    reviews: Array<{ id: string; userName: string; rating: number; content: string; topic: string | null; images: string[]; createdAt: string }>;
    availableTopics: string[];
  } | null>(null);

  useEffect(() => {
    const fetchLocation = async () => {
      if (!id) {
        return;
      }
      if (!vendorId) {
        setError('Không tìm thấy thông tin business. Vui lòng đăng nhập lại.');
        setLoading(false);
        return;
      }
      try {
        setLoading(true);
        setError(null);
        const locationRes = await businessLocationAPI.getLocations(
          {
            vendorId,
            search: id,
          },
          { page: 1, limit: 50 },
        );
        const matchedLocation = locationRes.locations.find((item) => item.id === id) || locationRes.locations[0] || null;
        setLocation(matchedLocation);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Không thể tải thông tin địa điểm');
      } finally {
        setLoading(false);
      }
    };

    fetchLocation();
  }, [id, vendorId]);

  useEffect(() => {
    const fetchReviews = async () => {
      if (!id || activeTab !== 'Đánh giá') {
        return;
      }
      try {
        const response = await businessReviewAPI.getReviews(
          {
            vendorId,
            placeId: id,
            rating: reviewRating,
            sort: reviewSort,
            hasImages: reviewHasImages || undefined,
          },
          1,
          20,
        );
        setReviewData({
          stats: response.stats,
          reviews: response.reviews,
          availableTopics: response.availableTopics,
        });
      } catch {
        setReviewData(null);
      }
    };

    fetchReviews();
  }, [activeTab, id, reviewRating, reviewSort, reviewHasImages, vendorId]);

  const locationData = useMemo(() => {
    const status = location?.status || 'Chờ duyệt';
    const statusColor = status === 'Đã duyệt' ? '#22c55e' : status === 'Từ chối' ? '#ef4444' : '#f59e0b';
    return {
      id: location?.id || '',
      name: location?.name || 'Đang tải...',
      address: location?.address || 'Chưa có địa chỉ',
      city: '',
      district: '',
      type: location?.category || 'Địa điểm',
      typeColor: '#3b82f6',
      rating: location?.rating || 0,
      reviewsCount: location?.review_count || 0,
      status,
      statusColor,
      image: location?.image || 'https://picsum.photos/seed/location/400/400',
      openTime: '08:00 AM',
      closeTime: '10:00 PM',
      description: '',
      lat: '',
      lng: '',
      gallery: [location?.image || 'https://picsum.photos/seed/location/200/200'],
      services: [
        { id: '1', name: 'Wifi miễn phí', icon: <Wifi size={16} /> },
        { id: '2', name: 'Chỗ đậu xe', icon: <Car size={16} /> },
        { id: '3', name: 'Máy lạnh', icon: <Wind size={16} /> },
        { id: '4', name: 'Thanh toán thẻ', icon: <CreditCard size={16} /> },
        { id: '5', name: 'Hồ bơi', icon: <Waves size={16} /> },
      ],
      menu: [] as Array<{ id: string; name: string; desc: string; category: string; price: string; image: string }>,
      reviews: {
        average: reviewData?.stats.averageRating || 0,
        total: reviewData?.stats.totalReviews || 0,
        distribution: [5, 4, 3, 2, 1].map((score) => ({
          score,
          percentage: reviewData?.stats.breakdown[score as 1 | 2 | 3 | 4 | 5]?.percent || 0,
        })),
        aiInsight: reviewData?.stats.aiInsight || 'Chưa có dữ liệu phân tích AI.',
        list: (reviewData?.reviews || []).map((review) => ({
          id: review.id,
          user: review.userName,
          date: new Date(review.createdAt).toLocaleDateString('vi-VN'),
          avatar: 'https://picsum.photos/seed/user/100/100',
          rating: review.rating,
          content: review.content,
          images: review.images,
          tags: review.topic ? [{ name: review.topic, color: '#3b82f6' }] : [],
        })),
      },
    };
  }, [location, reviewData]);

  const renderGeneralInfo = () => (
    <div
      style={{
        background: 'white',
        border: '1px solid #F1F5F9',
        borderRadius: '24px',
        padding: '32px',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
      }}>
      <div style={{ display: 'flex', gap: '48px' }}>
        {/* Left Column */}
        <div style={{ flex: 1.2 }}>
          <Input label="Tên địa điểm" value={locationData.name} />
          <Input label="Địa chỉ chi tiết" value={locationData.address} />

          <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <Input label="Tỉnh/Thành phố" value={locationData.city} style={{ marginBottom: 0 }} />
            </div>
            <div style={{ flex: 1 }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
                Quận/Huyện
              </label>
              <select
                style={{
                  width: '100%',
                  padding: '14px 16px',
                  borderRadius: '12px',
                  border: '1px solid #E2E8F0',
                  background: '#fcfcfc',
                  outline: 'none',
                  fontSize: '15px',
                }}>
                <option>{locationData.district}</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <Input label="Giờ mở cửa" value={locationData.openTime} icon={<Clock size={16} />} style={{ marginBottom: 0 }} />
            </div>
            <div style={{ flex: 1 }}>
              <Input label="Giờ đóng cửa" value={locationData.closeTime} icon={<Clock size={16} />} style={{ marginBottom: 0 }} />
            </div>
          </div>

          <div>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
              Mô tả địa điểm
            </label>
            <textarea
              style={{
                width: '100%',
                minHeight: '160px',
                padding: '16px',
                borderRadius: '12px',
                border: '1px solid #E2E8F0',
                background: '#fcfcfc',
                outline: 'none',
                fontSize: '15px',
                color: '#1e293b',
                lineHeight: '1.6',
                resize: 'vertical',
              }}
              defaultValue={locationData.description}
            />
          </div>
        </div>

        {/* Right Column */}
        <div style={{ flex: 1 }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>
            Vị trí trên bản đồ
          </label>
          <div
            style={{
              width: '100%',
              height: '240px',
              background: '#f8fafc',
              borderRadius: '16px',
              border: '1px solid #E2E8F0',
              overflow: 'hidden',
              position: 'relative',
              marginBottom: '24px',
            }}>
            <img
              src="https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=600&h=400&fit=crop"
              alt="Map"
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -100%)', color: '#ef4444' }}>
              <MapPin size={32} fill="#ef444433" />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '16px', marginBottom: '32px' }}>
            <div style={{ flex: 1 }}>
              <Input label="Kinh độ (Latitude)" value={locationData.lat} style={{ marginBottom: 0 }} />
            </div>
            <div style={{ flex: 1 }}>
              <Input label="Vĩ độ (Longitude)" value={locationData.lng} style={{ marginBottom: 0 }} />
            </div>
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>
                Hình ảnh địa điểm ({locationData.gallery.length})
              </label>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px' }}>
              {locationData.gallery.map((img, i) => (
                <div key={i} style={{ aspectRatio: '1', borderRadius: '12px', overflow: 'hidden', border: '1px solid #F1F5F9' }}>
                  <img src={img} alt={`Gallery ${i}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              ))}
              <div
                style={{
                  aspectRatio: '1',
                  borderRadius: '12px',
                  border: '2px dashed #E2E8F0',
                  background: '#F8FAFC',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '4px',
                  cursor: 'pointer',
                  color: '#94a3b8',
                }}>
                <Upload size={20} />
                <span style={{ fontSize: '10px', fontWeight: '800' }}>TẢI LÊN</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        style={{
          marginTop: '48px',
          paddingTop: '32px',
          borderTop: '1px solid #F1F5F9',
          display: 'flex',
          justifyContent: 'flex-end',
          gap: '16px',
          alignItems: 'center',
        }}>
        <span onClick={() => navigate('/locations')} style={{ color: '#64748b', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>
          Hủy bỏ
        </span>
        <Button style={{ padding: '12px 32px', borderRadius: '12px' }}>Lưu thay đổi</Button>
      </div>
    </div>
  );

  const renderServiceSection = (title: string, showSearch = true) => (
    <div style={{ marginBottom: '48px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h5 style={{ fontSize: '18px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>{title}</h5>
        <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          {showSearch && (
            <div style={{ position: 'relative', width: '280px' }}>
              <Search
                size={16}
                style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }}
              />
              <input
                type="text"
                placeholder="Tìm kiếm món ăn..."
                style={{
                  width: '100%',
                  padding: '10px 12px 10px 36px',
                  borderRadius: '10px',
                  border: '1px solid #F1F5F9',
                  fontSize: '13px',
                  outline: 'none',
                }}
              />
            </div>
          )}
          <Button style={{ borderRadius: '10px', fontSize: '13px', gap: '8px', padding: '8px 16px' }}>
            <Plus size={16} /> Thêm {title === 'Dịch vụ tiện ích' ? 'dịch vụ' : 'món'} mới
          </Button>
        </div>
      </div>

      {title === 'Dịch vụ tiện ích' ? (
        <div
          style={{
            background: 'white',
            borderRadius: '20px',
            border: '1px solid #F1F5F9',
            padding: '24px',
            display: 'flex',
            gap: '16px',
            flexWrap: 'wrap',
          }}>
          {locationData.services.map((s) => (
            <div
              key={s.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: '10px 20px',
                background: '#EFF6FF',
                color: '#3b82f6',
                borderRadius: '16px',
                fontSize: '14px',
                fontWeight: '600',
              }}>
              {s.icon} <span>{s.name}</span>
            </div>
          ))}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '10px 20px',
              border: '1px solid #E2E8F0',
              borderStyle: 'dashed',
              color: '#94a3b8',
              borderRadius: '16px',
              fontSize: '14px',
              fontWeight: '600',
              cursor: 'pointer',
            }}>
            <Plus size={16} /> <span>Thêm dịch vụ</span>
          </div>
        </div>
      ) : (
        <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '20px', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', background: '#FCFCFD', borderBottom: '1px solid #F1F5F9' }}>
                <th
                  style={{
                    padding: '16px 24px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                  }}>
                  Hình ảnh
                </th>
                <th
                  style={{
                    padding: '16px 24px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                  }}>
                  Tên món
                </th>
                <th
                  style={{
                    padding: '16px 24px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                  }}>
                  Giá bán
                </th>
                <th
                  style={{
                    padding: '16px 24px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                  }}>
                  Trạng thái
                </th>
                <th
                  style={{
                    padding: '16px 24px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                  }}>
                  Thao tác
                </th>
              </tr>
            </thead>
            <tbody>
              {locationData.menu.length > 0 ? (
                locationData.menu.map((item, idx) => (
                  <tr key={idx} style={{ borderBottom: idx < locationData.menu.length - 1 ? '1px solid #F8FAFC' : 'none' }}>
                    <td style={{ padding: '16px 24px' }}>
                      <img
                        src={item.image}
                        alt={item.name}
                        style={{ width: '64px', height: '64px', borderRadius: '12px', objectFit: 'cover' }}
                      />
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <p style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>{item.name}</p>
                      <p style={{ fontSize: '11px', color: '#94a3b8' }}>{item.desc}</p>
                    </td>
                    <td style={{ padding: '16px 24px', fontSize: '14px', fontWeight: '800', color: '#3b82f6' }}>{item.price}</td>
                    <td style={{ padding: '16px 24px' }}>
                      <div
                        style={{
                          width: '40px',
                          height: '20px',
                          background: '#3b82f6',
                          borderRadius: '20px',
                          position: 'relative',
                          cursor: 'pointer',
                        }}>
                        <div
                          style={{
                            position: 'absolute',
                            right: '4px',
                            top: '4px',
                            width: '12px',
                            height: '12px',
                            background: 'white',
                            borderRadius: '50%',
                          }}></div>
                      </div>
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <div style={{ display: 'flex', gap: '12px', color: '#94a3b8' }}>
                        <Edit2 size={16} /> <Trash2 size={16} />
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} style={{ padding: '32px', textAlign: 'center', color: '#94a3b8', fontSize: '14px' }}>
                    Chưa có món ăn nào trong thực đơn
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          <div
            style={{
              padding: '16px 24px',
              borderTop: '1px solid #F1F5F9',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}>
            <span style={{ fontSize: '12px', color: '#94a3b8' }}>Hiển thị {locationData.menu.length} món ăn</span>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '6px',
                  border: '1px solid #F1F5F9',
                  background: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#E2E8F0',
                }}>
                <ChevronLeft size={14} />
              </button>
              <button
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '6px',
                  background: '#3b82f6',
                  color: 'white',
                  border: 'none',
                  fontSize: '12px',
                  fontWeight: '700',
                }}>
                1
              </button>
              <button
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '6px',
                  border: '1px solid #F1F5F9',
                  background: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#64748b',
                }}>
                <ChevronRight size={14} />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  const renderServicesMenu = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '48px' }}>
      {/* TIỆN ÍCH MIỄN PHÍ */}
      <div>
        <h5
          style={{
            fontSize: '18px',
            fontWeight: '800',
            color: '#000000',
            fontFamily: "'Times New Roman', Times, serif",
            marginBottom: '24px',
          }}>
          Tiện ích miễn phí
        </h5>
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
          {locationData.services.map((s) => (
            <div
              key={s.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: '12px 24px',
                background: '#F8FAFC',
                border: '1px solid #F1F5F9',
                color: '#475569',
                borderRadius: '20px',
                fontSize: '14px',
                fontWeight: '600',
              }}>
              <span style={{ color: '#94a3b8' }}>{s.icon}</span> <span>{s.name}</span>
            </div>
          ))}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '12px 24px',
              border: '1px solid #E2E8F0',
              borderStyle: 'dashed',
              color: '#94a3b8',
              borderRadius: '20px',
              fontSize: '14px',
              fontWeight: '600',
              cursor: 'pointer',
              background: 'transparent',
            }}>
            <Plus size={16} /> <span>Thêm tiện ích</span>
          </div>
        </div>
      </div>

      {/* DỊCH VỤ TÍNH PHÍ */}
      <div>
        <h5
          style={{
            fontSize: '18px',
            fontWeight: '800',
            color: '#000000',
            fontFamily: "'Times New Roman', Times, serif",
            marginBottom: '24px',
          }}>
          Dịch vụ tính phí
        </h5>
        <div
          style={{
            background: 'white',
            border: '1px solid #F1F5F9',
            borderRadius: '24px',
            overflow: 'hidden',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
          }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', background: '#FCFCFD', borderBottom: '1px solid #F1F5F9' }}>
                <th
                  style={{
                    padding: '20px 32px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                  }}>
                  Tên dịch vụ
                </th>
                <th
                  style={{
                    padding: '20px 32px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                    textAlign: 'center',
                  }}>
                  Giá dịch vụ
                </th>
                <th
                  style={{
                    padding: '20px 32px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                    textAlign: 'center',
                  }}>
                  Trạng thái
                </th>
                <th
                  style={{
                    padding: '20px 32px',
                    fontSize: '15px',
                    fontWeight: '800',
                    color: '#000000',
                    fontFamily: "'Times New Roman', Times, serif",
                    textAlign: 'center',
                  }}>
                  Thao tác
                </th>
              </tr>
            </thead>
            <tbody>
              {[
                { id: 1, name: 'Phòng VIP riêng tư', category: 'Dịch vụ phòng', price: '200.000 đ', active: true },
                { id: 2, name: 'Trang trí tiệc sinh nhật', category: 'Sự kiện', price: '500.000 đ', active: true },
                { id: 3, name: 'Karaoke tại phòng', category: 'Giải trí', price: '150.000 đ', active: false },
              ].map((item, idx, arr) => (
                <tr key={item.id} style={{ borderBottom: idx < arr.length - 1 ? '1px solid #F8FAFC' : 'none' }}>
                  <td style={{ padding: '24px 32px', fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{item.name}</td>
                  <td
                    style={{
                      padding: '24px 32px',
                      fontSize: '15px',
                      fontWeight: '800',
                      color: '#3b82f6',
                      textAlign: 'center',
                      textDecoration: 'underline',
                    }}>
                    {item.price}
                  </td>
                  <td style={{ padding: '24px 32px', textAlign: 'center' }}>
                    <div
                      style={{
                        width: '44px',
                        height: '24px',
                        background: item.active ? '#3b82f6' : '#E2E8F0',
                        borderRadius: '20px',
                        position: 'relative',
                        cursor: 'pointer',
                        display: 'inline-block',
                        verticalAlign: 'middle',
                        transition: '0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                      }}>
                      <div
                        style={{
                          position: 'absolute',
                          right: item.active ? '4px' : 'auto',
                          left: item.active ? 'auto' : '4px',
                          top: '4px',
                          width: '16px',
                          height: '16px',
                          background: 'white',
                          borderRadius: '50%',
                          transition: '0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                          boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
                        }}></div>
                    </div>
                  </td>
                  <td style={{ padding: '24px 32px', textAlign: 'center' }}>
                    <div style={{ display: 'flex', gap: '16px', color: '#94a3b8', justifyContent: 'center' }}>
                      <Edit2 size={18} style={{ cursor: 'pointer' }} />
                      <Trash2 size={18} style={{ cursor: 'pointer' }} />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Optional Menu Section for Restaurants */}
      {locationData.type === 'Nhà hàng' && renderServiceSection('Quản lý thực đơn món ăn')}
    </div>
  );

  const renderReviews = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <div
        style={{
          background: 'white',
          borderRadius: '24px',
          padding: '32px',
          border: '1px solid #F1F5F9',
          display: 'flex',
          gap: '48px',
          alignItems: 'center',
        }}>
        <div style={{ textAlign: 'center', paddingRight: '48px', borderRight: '1px solid #F1F5F9' }}>
          <h1 style={{ fontSize: '48px', fontWeight: '800', color: '#1e293b', marginBottom: '8px' }}>{locationData.reviews.average}</h1>
          <div style={{ display: 'flex', gap: '4px', justifyContent: 'center', color: '#fbbf24', marginBottom: '8px' }}>
            {[1, 2, 3, 4, 5].map((s) => (
              <Star key={s} size={20} fill="#fbbf24" color="#fbbf24" />
            ))}
          </div>
          <p style={{ fontSize: '13px', color: '#94a3b8', fontWeight: '600' }}>{locationData.reviews.total} đánh giá</p>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {locationData.reviews.distribution.map((d) => (
            <div key={d.score} style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              <span style={{ fontSize: '13px', fontWeight: '800', color: '#64748b', minWidth: '12px' }}>{d.score}</span>
              <div style={{ flex: 1, height: '8px', background: '#F8FAFC', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${d.percentage}%`, background: '#3b82f6' }}></div>
              </div>
              <span style={{ fontSize: '12px', fontWeight: '600', color: '#94a3b8', minWidth: '32px' }}>{d.percentage}%</span>
            </div>
          ))}
        </div>
      </div>

      <div>
        <h5 style={{ fontSize: '16px', fontWeight: '800', color: '#1e293b', marginBottom: '20px' }}>Bộ lọc đánh giá</h5>
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
          <select
            value={reviewRating ?? ''}
            onChange={(e) => setReviewRating(e.target.value ? Number(e.target.value) : undefined)}
            style={{ padding: '8px 16px', borderRadius: '10px', border: '1px solid #E2E8F0', fontSize: '13px', background: 'white' }}>
            <option value="">Tất cả sao</option>
            <option value="5">5 sao</option>
            <option value="4">4 sao</option>
            <option value="3">3 sao</option>
            <option value="2">2 sao</option>
            <option value="1">1 sao</option>
          </select>
          <Button
            variant="outline"
            onClick={() => setReviewSort('newest')}
            style={{
              borderRadius: '10px',
              fontSize: '13px',
              padding: '8px 20px',
              background: reviewSort === 'newest' ? '#EFF6FF' : 'white',
              borderColor: reviewSort === 'newest' ? '#3b82f6' : '#E2E8F0',
              color: reviewSort === 'newest' ? '#3b82f6' : '#64748b',
              fontWeight: '700',
            }}>
            Mới nhất
          </Button>
          <Button
            variant="outline"
            onClick={() => setReviewHasImages((prev) => !prev)}
            style={{
              borderRadius: '10px',
              fontSize: '13px',
              padding: '8px 20px',
              color: reviewHasImages ? '#3b82f6' : '#64748b',
              borderColor: reviewHasImages ? '#3b82f6' : '#E2E8F0',
              background: reviewHasImages ? '#EFF6FF' : 'white',
            }}>
            Có hình ảnh
          </Button>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {locationData.reviews.list.map((rev) => (
          <div key={rev.id} style={{ background: 'white', borderRadius: '24px', padding: '32px', border: '1px solid #F1F5F9' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px' }}>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                <img src={rev.avatar} alt="Avatar" style={{ width: '48px', height: '48px', borderRadius: '50%', objectFit: 'cover' }} />
                <div>
                  <p style={{ fontSize: '15px', fontWeight: '800', color: '#1e293b', marginBottom: '4px' }}>{rev.user}</p>
                  <p style={{ fontSize: '12px', color: '#94a3b8' }}>Đã ghé thăm ngày {rev.date}</p>
                </div>
              </div>
              <div style={{ display: 'flex', gap: '4px', color: '#fbbf24' }}>
                {[1, 2, 3, 4, 5].map((s) => (
                  <Star key={s} size={16} fill={s <= rev.rating ? '#fbbf24' : 'none'} color="#fbbf24" />
                ))}
              </div>
            </div>

            <p style={{ fontSize: '15px', color: '#475569', lineHeight: '1.7', marginBottom: '24px' }}>{rev.content}</p>

            {rev.images && (
              <div style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
                {rev.images.map((img, i) => (
                  <img
                    key={i}
                    src={img}
                    alt="Review"
                    style={{ width: '120px', height: '90px', borderRadius: '12px', objectFit: 'cover' }}
                  />
                ))}
              </div>
            )}

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                {rev.tags.map((tag) => (
                  <span
                    key={tag.name}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                      padding: '4px 12px',
                      background: '#F1F5F9',
                      color: '#64748b',
                      borderRadius: '8px',
                      fontSize: '12px',
                      fontWeight: '700',
                    }}>
                    {tag.name}
                  </span>
                ))}
              </div>
              <Button
                variant="outline"
                onClick={() => setReplyingToId(replyingToId === rev.id ? null : rev.id)}
                style={{
                  borderRadius: '10px',
                  fontSize: '13px',
                  padding: '6px 20px',
                  color: '#3b82f6',
                  borderColor: '#EFF6FF',
                  background: '#EFF6FF',
                }}>
                {replyingToId === rev.id ? 'Hủy' : 'Trả lời'}
              </Button>
            </div>

            {replyingToId === rev.id && (
              <div
                style={{
                  marginTop: '24px',
                  padding: '24px',
                  background: '#F8FAFC',
                  borderRadius: '16px',
                  border: '1px solid #F1F5F9',
                  animation: 'fadeIn 0.2s ease-out',
                }}>
                <label style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', display: 'block', marginBottom: '12px' }}>
                  Nội dung phản hồi khách hàng
                </label>
                <textarea
                  placeholder="Cảm ơn bạn đã phản hồi, chúng tôi sẽ sớm cải thiện..."
                  style={{
                    width: '100%',
                    minHeight: '100px',
                    padding: '16px',
                    borderRadius: '12px',
                    border: '1px solid #E2E8F0',
                    outline: 'none',
                    fontSize: '14px',
                    lineHeight: '1.6',
                    marginBottom: '16px',
                    resize: 'vertical',
                  }}
                />
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                  <Button
                    variant="outline"
                    onClick={() => setReplyingToId(null)}
                    style={{ padding: '8px 20px', borderRadius: '8px', fontSize: '13px' }}>
                    Hủy bỏ
                  </Button>
                  <Button onClick={() => setReplyingToId(null)} style={{ padding: '8px 24px', borderRadius: '8px', fontSize: '13px' }}>
                    Gửi phản hồi
                  </Button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <>
      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>Đang tải dữ liệu địa điểm...</div>
      ) : error ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#ef4444' }}>{error}</div>
      ) : (
      <div style={{ padding: '0 20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '32px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#94a3b8', marginBottom: '12px' }}>
              <span style={{ cursor: 'pointer' }} onClick={() => navigate('/locations')}>
                Danh sách địa điểm
              </span>
              <span>/</span>
              <span style={{ color: '#1e293b', fontWeight: '700' }}>{locationData.name}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              <h2 style={{ fontSize: '32px', fontWeight: '800', color: '#1e293b' }}>{locationData.name}</h2>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '4px 12px',
                  background: locationData.statusColor + '10',
                  borderRadius: '8px',
                  color: locationData.statusColor,
                  fontSize: '12px',
                  fontWeight: '700',
                }}>
                <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: locationData.statusColor }}></div>
                {locationData.status}
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ fontSize: '14px', fontWeight: 'bold', color: '#64748b' }}>
              Trạng thái: <span style={{ color: '#3b82f6' }}>{isActive ? 'Đang hoạt động' : 'Tạm ngưng'}</span>
            </span>
            <div
              onClick={() => setIsActive(!isActive)}
              style={{
                width: '44px',
                height: '22px',
                background: isActive ? '#3b82f6' : '#E2E8F0',
                borderRadius: '12px',
                position: 'relative',
                cursor: 'pointer',
                transition: '0.2s',
              }}>
              <div
                style={{
                  position: 'absolute',
                  left: isActive ? '24px' : '4px',
                  top: '3px',
                  width: '16px',
                  height: '16px',
                  background: 'white',
                  borderRadius: '50%',
                  transition: '0.2s',
                }}></div>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '32px', marginBottom: '32px', borderBottom: '1px solid #F1F5F9' }}>
          {['Thông tin chung', 'Đánh giá', 'Dịch vụ'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              style={{
                padding: '12px 0',
                fontSize: '14px',
                fontWeight: activeTab === tab ? '700' : '600',
                color: activeTab === tab ? '#3b82f6' : '#64748b',
                background: 'transparent',
                border: 'none',
                borderBottom: activeTab === tab ? '2px solid #3b82f6' : '2px solid transparent',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                marginBottom: '-1px',
              }}>
              {tab}
            </button>
          ))}
        </div>

        {activeTab === 'Dịch vụ' ? renderServicesMenu() : activeTab === 'Đánh giá' ? renderReviews() : renderGeneralInfo()}
      </div>
      )}
    </>
  );
};

export default LocationEditPage;
