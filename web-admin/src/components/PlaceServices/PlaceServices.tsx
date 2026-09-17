import React, { useState, useEffect } from 'react';
import { Plus, AlertCircle, BadgeCheck, CircleDollarSign } from 'lucide-react';
import { getPlaceServicesByType, type PlaceServiceItemResponse } from '../../services/order.service';

interface Service {
  id: string;
  name: string;
  description: string;
  price: number | null;
  quantity?: number | null;
}

interface PlaceServicesProps {
  placeId: string;
}

const toService = (item: PlaceServiceItemResponse): Service => {
  const rawPrice = item.price ?? item.service_price ?? item.amount;
  const numericPrice = typeof rawPrice === 'number'
    ? rawPrice
    : rawPrice === null || rawPrice === undefined || rawPrice === ''
      ? null
      : Number(String(rawPrice).replace(/[^\d.-]/g, ''));

  return {
    id: String(item.id ?? item.service_id ?? item.serviceId ?? `${Date.now()}`),
    name: item.name ?? item.service_name ?? item.title ?? 'Dịch vụ',
    description: item.description ?? item.service_description ?? '',
    price: Number.isFinite(numericPrice as number) ? (numericPrice as number) : null,
    quantity: item.quantity == null ? null : Number(item.quantity),
  };
};

export const PlaceServices: React.FC<PlaceServicesProps> = ({ placeId }) => {
  const [freeServices, setFreeServices] = useState<Service[]>([]);
  const [paidServices, setPaidServices] = useState<Service[]>([]);
  const [rooms, setRooms] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchServices = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await getPlaceServicesByType(placeId);
        const freeList = data.freeServices || data.data?.freeServices || [];
        const paidList = data.paidServices || data.data?.paidServices || [];
        const roomList = data.rooms || data.data?.rooms || [];
        setFreeServices(freeList.map(toService));
        setPaidServices(paidList.map(toService));
        setRooms(roomList.map(toService));
      } catch (err) {
        console.error('Error loading services:', err);
        setError('Không thể tải dữ liệu dịch vụ');
      } finally {
        setLoading(false);
      }
    };

    if (placeId) {
      fetchServices();
    }
  }, [placeId]);

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '32px' }}>
        <p style={{ color: '#94a3b8', fontSize: '14px' }}>Đang tải dịch vụ...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ background: '#fee2e2', borderRadius: '20px', padding: '24px', display: 'flex', gap: '12px', alignItems: 'center' }}>
        <AlertCircle size={20} style={{ color: '#dc2626' }} />
        <span style={{ color: '#991b1b', fontSize: '14px', fontWeight: '600' }}>{error}</span>
      </div>
    );
  }

  return (
    <div style={{ marginBottom: '48px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h5 style={{ fontSize: '18px', fontWeight: '800', color: '#000000', fontFamily: "'Times New Roman', Times, serif" }}>
          Dịch vụ của địa điểm
        </h5>
      </div>

      {/* Free Services Section */}
      {freeServices.length > 0 && (
        <div style={{ marginBottom: '32px' }}>
          <h6 style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b', marginBottom: '16px' }}>
            <BadgeCheck size={18} /> Dịch vụ miễn phí ({freeServices.length})
          </h6>
          <div style={{ background: 'white', borderRadius: '20px', border: '1px solid #F1F5F9', padding: '24px', display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
            {freeServices.map((service) => (
              <div
                key={service.id}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '4px',
                  padding: '12px 16px',
                  background: '#F0FDF4',
                  color: '#166534',
                  borderRadius: '12px',
                  fontSize: '13px',
                  fontWeight: '600',
                  border: '1px solid #BBEF63',
                  minWidth: '180px'
                }}
              >
                <span>{service.name}</span>
                {service.description && <span style={{ fontSize: '12px', color: '#4b7c0f', fontWeight: '400' }}>{service.description}</span>}
              </div>
            ))}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: '12px 16px',
                border: '1px solid #E2E8F0',
                borderStyle: 'dashed',
                color: '#94a3b8',
                borderRadius: '12px',
                fontSize: '13px',
                fontWeight: '600',
                cursor: 'pointer'
              }}
            >
              <Plus size={16} /> <span>Thêm dịch vụ miễn phí</span>
            </div>
          </div>
        </div>
      )}

      {rooms.length > 0 && (
        <div style={{ marginBottom: '32px' }}>
          <h6 style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b', marginBottom: '16px' }}>
            <CircleDollarSign size={18} /> Phong luu tru ({rooms.length})
          </h6>
          <div style={{ background: 'white', borderRadius: '20px', border: '1px solid #F1F5F9', padding: '24px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '16px' }}>
            {rooms.map((room) => (
              <div
                key={room.id}
                style={{
                  padding: '16px',
                  background: '#EFF6FF',
                  border: '1px solid #BFDBFE',
                  borderRadius: '12px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
                  <span style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b', flex: 1 }}>{room.name}</span>
                  <span style={{ fontSize: '14px', fontWeight: '800', color: '#2563eb', whiteSpace: 'nowrap' }}>
                    {typeof room.price === 'number' ? room.price.toLocaleString('vi-VN') : '0'}d
                  </span>
                </div>
                <p style={{ fontSize: '12px', color: '#1d4ed8', fontWeight: '500', marginBottom: '0' }}>
                  Suc chua: {room.quantity || 1} khach
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Paid Services Section */}
      {paidServices.length > 0 && (
        <div>
          <h6 style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b', marginBottom: '16px' }}>
            <CircleDollarSign size={18} /> Dịch vụ có phí ({paidServices.length})
          </h6>
          <div style={{ background: 'white', borderRadius: '20px', border: '1px solid #F1F5F9', padding: '24px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '16px' }}>
            {paidServices.map((service) => (
              <div
                key={service.id}
                style={{
                  padding: '16px',
                  background: '#FEF3C7',
                  border: '1px solid #FCD34D',
                  borderRadius: '12px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
                  <span style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b', flex: 1 }}>{service.name}</span>
                  <span style={{ fontSize: '14px', fontWeight: '800', color: '#d97706', whiteSpace: 'nowrap' }}>
                    {typeof service.price === 'number' ? service.price.toLocaleString('vi-VN') : '0'}đ
                  </span>
                </div>
                {service.description && (
                  <p style={{ fontSize: '12px', color: '#92400e', fontWeight: '400', marginBottom: '0' }}>{service.description}</p>
                )}
              </div>
            ))}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '10px',
                padding: '16px',
                border: '1px solid #E2E8F0',
                borderStyle: 'dashed',
                color: '#94a3b8',
                borderRadius: '12px',
                fontSize: '13px',
                fontWeight: '600',
                cursor: 'pointer',
                minHeight: '100px'
              }}
            >
              <Plus size={16} /> <span>Thêm dịch vụ tính phí</span>
            </div>
          </div>
        </div>
      )}

      {freeServices.length === 0 && paidServices.length === 0 && rooms.length === 0 && (
        <div style={{ background: 'white', borderRadius: '20px', border: '1px solid #F1F5F9', padding: '48px 24px', textAlign: 'center' }}>
          <p style={{ color: '#94a3b8', fontSize: '14px', marginBottom: '16px' }}>Chưa có dịch vụ nào</p>
          <button
            style={{
              padding: '10px 24px',
              background: '#3b82f6',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
          >
            <Plus size={16} style={{ display: 'inline', marginRight: '6px' }} />
            Thêm dịch vụ mới
          </button>
        </div>
      )}
    </div>
  );
};

export default PlaceServices;
