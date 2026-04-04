import React from 'react';
import { MessageSquare, AlertTriangle, Clock } from 'lucide-react';
import { ReviewStatsInfo } from '../../../../types/review';

interface ReviewStatsProps {
  stats: ReviewStatsInfo | null;
  loading: boolean;
}

export const ReviewStats: React.FC<ReviewStatsProps> = ({ stats, loading }) => {
  if (loading || !stats) {
    return (
      <div className="stats-grid">
        {[1, 2, 3].map(i => (
          <div key={i} className="stat-card">
            <div className="stat-info"><span className="stat-label">Đang tải...</span></div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="stats-grid">
      <div className="stat-card">
        <div className="stat-icon bg-blue-light">
          <MessageSquare size={24} className="text-blue" />
        </div>
        <div className="stat-info">
          <span className="stat-label">TỔNG ĐÁNH GIÁ</span>
          <span className="stat-value">{stats.totalReviews.toLocaleString()}</span>
        </div>
      </div>

      <div className="stat-card">
        <div className="stat-icon bg-orange-light">
          <Clock size={24} className="text-orange" />
        </div>
        <div className="stat-info">
          <span className="stat-label">CHỜ DUYỆT</span>
          <span className="stat-value">{stats.pendingReviews}</span>
        </div>
      </div>

      <div className="stat-card">
        <div className="stat-icon" style={{ backgroundColor: '#fef2f2' }}>
          <AlertTriangle size={24} style={{ color: '#ef4444' }} />
        </div>
        <div className="stat-info">
          <span className="stat-label">VI PHẠM</span>
          <span className="stat-value" style={{ color: '#ef4444' }}>{stats.violationReviews}</span>
        </div>
      </div>
    </div>
  );
};
