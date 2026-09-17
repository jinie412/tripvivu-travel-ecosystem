import React, { memo } from 'react';
import { Users, UserPlus, ShieldAlert } from 'lucide-react';
import { UserStatsInfo } from '../../../../types/user';

interface UserStatsProps {
  stats: UserStatsInfo | null;
  loading: boolean;
}

export const UserStats = memo<UserStatsProps>(function UserStats({ stats, loading }) {
  if (loading || !stats) {
    return (
      <div className="user-stats">
        {[0, 1, 2].map((i) => (
          <div key={i} className="stat-card stat-card-skeleton">
            <div className="skeleton-icon" />
            <div className="stat-info">
              <div className="skeleton-line skeleton-label" />
              <div className="skeleton-line skeleton-value" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="user-stats">
      <div className="stat-card">
        <div className="stat-icon bg-blue-light">
          <Users size={24} className="text-blue" />
        </div>
        <div className="stat-info">
          <span className="stat-label">Tổng người dùng</span>
          <span className="stat-value">{stats.totalUsers.toLocaleString()}</span>
        </div>
      </div>

      <div className="stat-card">
        <div className="stat-icon bg-green-light">
          <UserPlus size={24} className="text-green" />
        </div>
        <div className="stat-info">
          <span className="stat-label">Mới tháng này</span>
          <span className="stat-value">+{stats.newThisMonth.toLocaleString()}</span>
        </div>
      </div>

      <div className="stat-card">
        <div className="stat-icon bg-orange-light">
          <ShieldAlert size={24} className="text-orange" />
        </div>
        <div className="stat-info">
          <span className="stat-label">Tài khoản Admin</span>
          <span className="stat-value">{stats.totalAdmins.toLocaleString()}</span>
        </div>
      </div>
    </div>
  );
});
