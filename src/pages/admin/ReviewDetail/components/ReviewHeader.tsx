import React from 'react';
import { Link } from 'react-router-dom';
import { Star, MapPin } from 'lucide-react';
import { ReviewDetailInfo } from '../../../../types/review';

interface ReviewHeaderProps {
  review: ReviewDetailInfo;
}

/** Header hiển thị thông tin người đánh giá + địa điểm + rating */
export const ReviewHeader: React.FC<ReviewHeaderProps> = ({ review }) => {
  return (
    <div className="rd-header">
      <div style={{ fontSize: '14px', fontWeight: 800, color: '#1e293b', marginBottom: '16px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
        Thông tin chung
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '24px' }}>
        {/* Thông tin người đánh giá */}
        <div className="rd-user-info" style={{ marginBottom: 0, flex: 1 }}>
          <div className="rd-user-avatar">{review.userAvatar}</div>
          <div className="rd-user-details">
            <h3 className="rd-user-name">{review.userName}</h3>
          </div>
        </div>

        {/* Thông tin địa điểm */}
        <Link 
          to={`/admin/locations/${review.locationId}`} 
          style={{ textDecoration: 'none', flex: 1, display: 'block' }}
        >
          <div className="rd-location-info" style={{ marginBottom: 0, flex: 1, padding: 0, background: 'transparent', border: 'none', display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div className="rd-location-icon" style={{ background: '#f8fafc', width: '44px', height: '44px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <MapPin size={20} color="#ef4444" />
            </div>
            <div className="rd-location-details">
              <h4 className="rd-location-name" style={{ margin: 0, fontSize: '15px', color: '#1e293b' }}>{review.locationName}</h4>
              <span className="rd-location-address" style={{ marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px', fontSize: '13px', color: '#94a3b8' }}>
                <MapPin size={12} />
                <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical' }}>
                  {review.locationAddress}
                </span>
              </span>
            </div>
          </div>
        </Link>
      </div>
    </div>
  );
};
