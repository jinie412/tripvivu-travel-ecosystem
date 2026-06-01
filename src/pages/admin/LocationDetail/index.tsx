import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { ArrowLeft, Check, X } from 'lucide-react';
import { locationAPI } from '../../../services/locationAPI';
import { LocationDetailInfo } from '../../../types/location';
import { PhotoGallery } from './components/PhotoGallery';
import { SenderInfo } from './components/SenderInfo';
import { GeneralInfo } from './components/GeneralInfo';
import { LocationMap } from './components/LocationMap';
import './LocationDetail.css';

export const LocationDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [location, setLocation] = useState<LocationDetailInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [rejectReason, setRejectReason] = useState('');

  useEffect(() => {
    const fetchDetail = async () => {
      if (!id) return;
      setLoading(true);
      try {
        const data = await locationAPI.getLocationById(id);
        setLocation(data);
      } catch (error) {
        console.error('Failed to load location details', error);
      } finally {
        setLoading(false);
      }
    };
    fetchDetail();
  }, [id]);

  if (loading) {
    return <div className="page-container py-8 text-center">Đang tải chi tiết địa điểm...</div>;
  }

  if (!location) {
    return <div className="page-container py-8 text-center text-red">Không tìm thấy địa điểm.</div>;
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Đã duyệt':
        return { bg: '#ccfbf1', text: '#0f766e' };
      case 'Chờ duyệt':
        return { bg: '#fef3c7', text: '#b45309' };
      case 'Từ chối':
        return { bg: '#fef2f2', text: '#ef4444' };
      default:
        return { bg: '#f1f5f9', text: '#64748b' };
    }
  };

  const statusColor = getStatusColor(location.status);

  const handleApprove = async () => {
    if (!id) {
      return;
    }
    try {
      await locationAPI.approveLocation(id);
      const refreshed = await locationAPI.getLocationById(id);
      setLocation(refreshed);
    } catch (error) {
      console.error('Failed to approve location', error);
      window.alert('Không thể duyệt địa điểm. Vui lòng thử lại.');
    }
  };

  const handleReject = async () => {
    if (!id) {
      return;
    }
    try {
      await locationAPI.rejectLocation(id, rejectReason);
      const refreshed = await locationAPI.getLocationById(id);
      setLocation(refreshed);
    } catch (error) {
      console.error('Failed to reject location', error);
      window.alert('Không thể từ chối địa điểm. Vui lòng thử lại.');
    }
  };

  return (
    <div className="location-detail-page">
      <div className="location-detail-header-wrapper">
        <div className="ld-breadcrumb">
          <span>Quản lý</span> / <Link to="/admin/locations">Địa điểm</Link> / <span className="active-bread">Chi tiết</span>
        </div>

        <div className="ld-header-main">
          <div className="ld-title-area">
            <h1 className="ld-title">Chi tiết địa điểm: {location.name}</h1>
            <span
              className="badge"
              style={{
                backgroundColor: statusColor.bg,
                color: statusColor.text,
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '4px 12px',
                borderRadius: '100px',
                fontSize: '0.75rem',
                fontWeight: 600,
              }}>
              <span style={{ width: 6, height: 6, borderRadius: '50%', backgroundColor: statusColor.text }}></span>
              {location.status}
            </span>
          </div>

          <button className="btn-outline-secondary" onClick={() => navigate('/admin/locations')}>
            <ArrowLeft size={16} />
            <span>Quay lại</span>
          </button>
        </div>
      </div>

      {location.status === 'Từ chối' && (
        <div className="ld-rejection-alert">
          <div className="ld-rejection-title">
            <X size={18} />
            <span>Địa điểm đã bị từ chối</span>
          </div>
          <div className="ld-rejection-content">
            <strong>Lý do:</strong> {location.rejectionReason || 'Chưa cung cấp lý do cụ thể.'}
          </div>
        </div>
      )}

      <div className="ld-content-wrapper">
        <div className="ld-grid">
          {/* Left Column */}
          <div className="ld-col-left">
            <PhotoGallery photos={location.photos} />
            <SenderInfo
              userName={location.userName}
              userAvatar={location.userAvatar}
              email={location.email || ''}
              stats={location.senderStats}
            />
          </div>

          {/* Right Column */}
          <div className="ld-col-right">
            <GeneralInfo location={location} />
            <LocationMap location={location} />
          </div>
        </div>
      </div>

      {location.status === 'Chờ duyệt' && (
        <div className="ld-footer-action">
          <div className="ld-footer-container">
            <div className="ld-reject-input">
              <input
                type="text"
                placeholder="Nhập lý do từ chối (bắt buộc nếu từ chối)..."
                value={rejectReason}
                onChange={(event) => setRejectReason(event.target.value)}
              />
            </div>
            <div className="ld-action-buttons">
              <button className="btn-reject-action" onClick={() => void handleReject()}>
                <X size={16} />
                <span>Từ chối</span>
              </button>
              <button className="btn-approve-action" onClick={() => void handleApprove()}>
                <Check size={16} />
                <span>Duyệt địa điểm</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
