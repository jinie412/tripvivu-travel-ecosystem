import React from 'react';
import { CalendarRange, CalendarDays } from 'lucide-react';
import { ItineraryReviewDetailInfo } from '../../../../types/review';

interface ItineraryReviewHeaderProps {
  review: ItineraryReviewDetailInfo;
}

export const ItineraryReviewHeader: React.FC<ItineraryReviewHeaderProps> = ({ review }) => {


  const dateRange =
    review.itineraryStartDate && review.itineraryEndDate
      ? `${review.itineraryStartDate} – ${review.itineraryEndDate}`
      : review.itineraryStartDate
        ? `Từ ${review.itineraryStartDate}`
        : null;

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

        {/* Thông tin lịch trình */}
        <div className="rd-location-info ird-itinerary-info" style={{ marginBottom: 0, flex: 1, padding: 0, background: 'transparent', border: 'none', display: 'flex', alignItems: 'center' }}>
          <div className="rd-location-icon" style={{ background: '#f8fafc', width: '44px', height: '44px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <CalendarRange size={20} color="#2563eb" />
          </div>
          <div className="rd-location-details">
            <h4 className="rd-location-name" style={{ margin: 0, fontSize: '15px' }}>{review.itineraryName}</h4>
            {dateRange && (
              <span className="rd-location-address" style={{ marginTop: '4px', display: 'inline-block' }}>
                <CalendarDays size={12} /> {dateRange}
              </span>
            )}
          </div>
        </div>
      </div>


    </div>
  );
};
