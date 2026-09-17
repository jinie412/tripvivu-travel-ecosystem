import React from 'react';
import './Badge.css';

interface BadgeProps {
  label: string;
  type?: 'admin' | 'provider' | 'tourist' | 'active' | 'locked' | 'default';
  showDot?: boolean;
}

export const Badge: React.FC<BadgeProps> = ({ label, type = 'default', showDot = false }) => {
  return (
    <span className={`badge badge-${type}`}>
      {showDot && <span className="badge-dot"></span>}
      {label}
    </span>
  );
};
