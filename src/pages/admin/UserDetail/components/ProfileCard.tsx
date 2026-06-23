import React from 'react';
import { Badge } from '../../../../components/Badge';
import { Mail } from 'lucide-react';
import { User } from '../../../../types/user';

interface ProfileCardProps {
  user: User;
  onUpdate: (updateData: Partial<User>) => Promise<void>;
  isUpdating: boolean;
}

export const ProfileCard: React.FC<ProfileCardProps> = ({ user, onUpdate, isUpdating }) => {
  // Dịch mã Role từ Backend sang Tiếng Việt hiển thị
  const formatRoleLabel = (role: string) => {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'BUSINESS':
        return 'Nhà cung cấp';
      case 'TOURIST':
        return 'Khách du lịch';
      default:
        return role;
    }
  };

  const getRoleBadgeType = (role: string) => {
    switch (role) {
      case 'ADMIN':
        return 'admin';
      case 'BUSINESS':
        return 'provider';
      case 'TOURIST':
        return 'tourist';
      default:
        return 'default';
    }
  };

  // Logic lấy chữ cái đầu của Tên
  const getInitials = (name?: string) => {
    if (!name) return 'U';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  };

  // Hỗ trợ cả 2 chuẩn camelCase và snake_case
  const userAvatar = (user as any).avatarUrl || (user as any).avatar_url;
  const initials = getInitials(user.fullName);

  return (
    <div className="card profile-card">
      <div className="profile-card-left">
        {/* XỬ LÝ AVATAR TẠI ĐÂY */}
        <div className="avatar-large" style={{ position: 'relative', overflow: 'hidden', borderRadius: '50%' }}>
          {userAvatar ? (
            <img src={userAvatar} alt={user.fullName} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          ) : (
            <div
              style={{
                fontSize: '36px',
                fontWeight: 'bold',
                color: 'var(--primary-blue)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: '100%',
                height: '100%',
                backgroundColor: '#eff6ff',
              }}>
              {initials}
            </div>
          )}
        </div>

        <div className="profile-info">
          <div className="profile-header">
            <h2 className="profile-name">{user.fullName}</h2>
            <Badge label={formatRoleLabel(user.role)} type={getRoleBadgeType(user.role)} />
          </div>
          <div className="profile-email-row">
            <Mail size={16} />
            <span>{user.email}</span>
          </div>
        </div>
      </div>
    </div>
  );
};
