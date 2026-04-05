import React from 'react';
import authAPI from '../../services/authService';

interface AdminHeaderProfileProps {
  showName?: boolean;
}

export const AdminHeaderProfile: React.FC<AdminHeaderProfileProps> = ({ showName = false }) => {
  const currentUser = authAPI.getCurrentUser();

  const getInitials = (name?: string, email?: string) => {
    if (name) {
      const parts = name.trim().split(' ');
      if (parts.length >= 2) return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
      return name.substring(0, 2).toUpperCase();
    }
    if (email) return email.substring(0, 2).toUpperCase();
    return 'AD';
  };

  const getAvatarColor = (char: string) => {
    const colors = [
      { bg: '#eff6ff', text: '#3b82f6' },
      { bg: '#f5f3ff', text: '#8b5cf6' },
      { bg: '#f0fdf4', text: '#22c55e' },
      { bg: '#fefce8', text: '#eab308' },
      { bg: '#fff1f2', text: '#f43f5e' },
    ];
    const index = char ? char.charCodeAt(0) % colors.length : 0;
    return colors[index];
  };

  const userInitials = getInitials(currentUser?.fullName, currentUser?.email);
  const headerAvatarStyle = getAvatarColor(userInitials);
  const headerUserAvatar = currentUser?.avatar || currentUser?.avatarUrl || currentUser?.avatar_url || currentUser?.avartar_url;

  return (
    <>
      {headerUserAvatar ? (
        <img
          src={headerUserAvatar}
          alt={currentUser?.fullName || 'Admin'}
          style={{
            width: '36px',
            height: '36px',
            borderRadius: '50%',
            objectFit: 'cover',
            padding: 0,
            border: '0.5px solid #ccc',
            backgroundColor: 'transparent',
          }}
        />
      ) : (
        <div
          className="user-avatar-small"
          style={{
            backgroundColor: headerAvatarStyle.bg,
            color: headerAvatarStyle.text,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '14px',
            width: '36px',
            height: '36px',
            borderRadius: '50%',
            border: '0.5px solid #ccc',
          }}>
          <span className="avatar-text" style={{ color: 'inherit' }}>
            {userInitials}
          </span>
        </div>
      )}
      {showName && (
        <span className="header-username" style={{ fontWeight: '600' }}>
          {currentUser?.fullName || 'Admin'}
        </span>
      )}
    </>
  );
};
