import React from 'react';
import { Mail, CheckCircle } from 'lucide-react';
import { Link } from 'react-router-dom';
import { LocationDetailInfo } from '../../../../types/location';

interface SenderInfoProps {
  userName: string;
  userAvatar: string;
  email: string;
  vendorId?: string;
  stats?: LocationDetailInfo['senderStats'];
}

export const SenderInfo: React.FC<SenderInfoProps> = ({ userName, userAvatar, email, vendorId, stats }) => {
  return (
    <div className="ld-card">
      <div className="ld-card-header">
        <h3 className="ld-card-title">Thông tin người gửi</h3>
      </div>
      
      <div className="ld-sender-profile">
        <div className="ld-sender-avatar">
          <div className="avatar-text-lg bg-blue-light text-blue flex-center justify-center" style={{ width: 56, height: 56, borderRadius: '50%', fontSize: '1.25rem' }}>
            {userAvatar}
          </div>
          <div className="ld-verified-badge">
            <CheckCircle size={12} fill="white" color="var(--success-green)" />
          </div>
        </div>
        
        <div className="ld-sender-details">
          <h4 className="ld-sender-name">{userName}</h4>
          <div className="ld-sender-email">
            <Mail size={14} />
            <span>{email || 'contact@example.com'}</span>
          </div>
          
          <div className="ld-sender-meta">
            <span className="badge badge-provider" style={{ padding: '2px 8px', fontSize: '10px' }}>
              {stats?.role || 'Nhà cung cấp'}
            </span>
            <span className="ld-sender-joined">Tham gia: {stats?.joinedDate || 'N/A'}</span>
          </div>
        </div>
      </div>
      
      <div className="ld-sender-footer">
        <span className="ld-sender-stat-text">Đã đăng {stats?.totalLocations || 1} địa điểm</span>
        {vendorId ? (
          <Link to={`/admin/locations?vendorId=${vendorId}`} className="ld-link-btn">Xem hồ sơ</Link>
        ) : (
          <span className="ld-link-btn">Xem hồ sơ</span>
        )}
      </div>
    </div>
  );
};
