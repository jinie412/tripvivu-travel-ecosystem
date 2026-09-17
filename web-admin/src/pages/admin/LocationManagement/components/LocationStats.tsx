import React from 'react';
import { LocationStatsInfo } from '../../../../types/location';
import { MapPin, CheckCircle, PlusCircle } from 'lucide-react';

interface LocationStatsProps {
  stats: LocationStatsInfo | null;
  loading: boolean;
}

export const LocationStats: React.FC<LocationStatsProps> = ({ stats, loading }) => {
  if (loading || !stats) {
    return (
      <div className="stats-grid">
        <div className="stat-card">Đang tải...</div>
        <div className="stat-card">Đang tải...</div>
        <div className="stat-card">Đang tải...</div>
      </div>
    );
  }

  return (
    <div className="stats-grid">
      <div className="stat-card">
        <div className="stat-icon bg-blue-light text-blue">
          <MapPin size={24} />
        </div>
        <div className="stat-info">
          <span className="stat-label">Tổng địa điểm</span>
          <div className="stat-value">
            {stats.totalLocations.toLocaleString()}
          </div>
        </div>
      </div>

      <div className="stat-card">
        <div className="stat-icon bg-orange-light text-orange">
          <CheckCircle size={24} />
        </div>
        <div className="stat-info">
          <span className="stat-label">Chờ duyệt</span>
          <div className="stat-value text-orange">
            {stats.pendingApproval}
          </div>
        </div>
      </div>

      <div className="stat-card">
        <div className="stat-icon bg-green-light text-green">
          <PlusCircle size={24} />
        </div>
        <div className="stat-info">
          <span className="stat-label">Địa điểm mới (tháng)</span>
          <div className="stat-value text-green">
            +{stats.newThisMonth}
          </div>
        </div>
      </div>
    </div>
  );
};
