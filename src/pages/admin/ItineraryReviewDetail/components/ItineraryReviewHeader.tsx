import React from 'react';
import { Star, CalendarRange, CalendarDays } from 'lucide-react';
import { ItineraryReviewDetailInfo } from '../../../../types/review';

interface ItineraryReviewHeaderProps {
  review: ItineraryReviewDetailInfo;
}

export const ItineraryReviewHeader: React.FC<ItineraryReviewHeaderProps> = ({ review }) => {
  const renderStars = (rating: number) => (
    <div className="rd-stars">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          size={18}
          fill={i < rating ? '#facc15' : 'none'}
          color={i < rating ? '#facc15' : '#d1d5db'}
        />
      ))}
    </div>
  );

  const dateRange =
    review.itineraryStartDate && review.itineraryEndDate
      ? `${review.itineraryStartDate} – ${review.itineraryEndDate}`
      : review.itineraryStartDate
        ? `Từ ${review.itineraryStartDate}`
        : null;

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

      {/* Thông tin lịch trình */}
      <div className="rd-location-info ird-itinerary-info">
        <div className="rd-location-icon">
          <CalendarRange size={18} color="#2563eb" />
        </div>
        <div className="rd-location-details">
          <h4 className="rd-location-name">{review.itineraryName}</h4>
          {dateRange && (
            <span className="rd-location-address">
              <CalendarDays size={12} /> {dateRange}
            </span>
          )}
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
