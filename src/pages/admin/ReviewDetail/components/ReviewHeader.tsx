import React from 'react';
import { Star, MapPin } from 'lucide-react';
import { ReviewDetailInfo } from '../../../../types/review';

interface ReviewHeaderProps {
  review: ReviewDetailInfo;
}

/** Header hiển thị thông tin người đánh giá + địa điểm + rating */
export const ReviewHeader: React.FC<ReviewHeaderProps> = ({ review }) => {
  const renderStars = (rating: number) => (
    <div className="rd-stars">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star key={i} size={18} fill={i < rating ? '#facc15' : 'none'} color={i < rating ? '#facc15' : '#d1d5db'} />
      ))}
    </div>
  );

  return (
    <div className="rd-header">
      {/* Thông tin người đánh giá */}
      <div className="rd-user-info">
        <div className="rd-user-avatar">{review.userAvatar}</div>
        <div className="rd-user-details">
          <h3 className="rd-user-name">{review.userName}</h3>
          <span className="rd-user-meta">
            {review.totalReviews} đánh giá &nbsp;·&nbsp; {review.totalReports} report
          </span>
        </div>
      </div>

      {/* Thông tin địa điểm */}
      <div className="rd-location-info">
        <div className="rd-location-icon">
          <MapPin size={18} color="#ef4444" />
        </div>
        <div className="rd-location-details">
          <h4 className="rd-location-name">{review.locationName}</h4>
          <span className="rd-location-address">
            <MapPin size={12} /> {review.locationAddress}
          </span>
        </div>
      </div>

      {/* Rating + ngày giờ */}
      <div className="rd-rating-row">
        {renderStars(review.rating)}
        <span className="rd-datetime">Đăng lúc {review.datetime}</span>
      </div>
    </div>
  );
};
