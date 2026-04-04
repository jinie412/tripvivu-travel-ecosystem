import React from 'react';
import { Settings, Lock, Unlock } from 'lucide-react';
import { Badge } from '../../../../components/Badge';
import { User } from '../../../../types/user';

interface AccountSettingsCardProps {
  user: User;
  onUpdate: (updateData: Partial<User>) => Promise<void>;
  onToggleStatus: (newStatus: 'ACTIVE' | 'LOCKED') => Promise<void>; // Khai báo
  isUpdating: boolean;
}

export const AccountSettingsCard: React.FC<AccountSettingsCardProps> = ({
  user,
  onUpdate,
  onToggleStatus, // Lấy ra dùng
  isUpdating,
}) => {
  const getStatusBadgeType = (status: string) => {
    return status === 'ACTIVE' ? 'active' : 'locked';
  };

  const formatStatusLabel = (status: string) => {
    return status === 'ACTIVE' ? 'HOẠT ĐỘNG' : 'ĐÃ KHÓA';
  };
  const handleStatusClick = () => {
    // Nếu đang Active thì ném lệnh Khóa, và ngược lại
    const targetStatus = user.activeStatus === 'ACTIVE' ? 'LOCKED' : 'ACTIVE';
    onToggleStatus(targetStatus);
  };

  return (
    <div className="card form-card account-card">
      <div className="card-header">
        <Settings size={18} className="icon-muted" />
        <h3 className="card-title">Cài đặt tài khoản</h3>
      </div>

      {/* Vai trò */}
      <div className="settings-section">
        <label className="section-label">Vai trò hệ thống</label>
        <div className="role-options">
          {/* Đổi thành chữ IN HOA để khớp với DB */}
          <label className={`role-radio-btn ${user.role === 'ADMIN' ? 'active' : ''}`}>
            <input type="radio" name="role" defaultChecked={user.role === 'ADMIN'} />
            <span className="radio-circle">
              <span className="radio-dot"></span>
            </span>
            <span>Admin</span>
          </label>
          <label className={`role-radio-btn ${user.role === 'BUSINESS' ? 'active' : ''}`}>
            <input type="radio" name="role" defaultChecked={user.role === 'BUSINESS'} />
            <span className="radio-circle">
              <span className="radio-dot"></span>
            </span>
            <span>Nhà cung cấp (Partner)</span>
          </label>
          <label className={`role-radio-btn ${user.role === 'TOURIST' ? 'active' : ''}`}>
            <input type="radio" name="role" defaultChecked={user.role === 'TOURIST'} />
            <span className="radio-circle">
              <span className="radio-dot"></span>
            </span>
            <span>Khách du lịch (Traveler)</span>
          </label>
        </div>
      </div>

      <div className="divider" />

      {/* Trạng thái tài khoản */}
      <div className="settings-section">
        <label className="section-label text-uppercase">TRẠNG THÁI TÀI KHOẢN</label>
        <div className="status-container">
          <Badge label={formatStatusLabel(user.activeStatus)} type={getStatusBadgeType(user.activeStatus)} showDot={true} />

          {/* Gắn sự kiện onClick và chặn nút khi đang loading */}
          <button
            className={`w-full mt-4 ${user.activeStatus === 'ACTIVE' ? 'btn-danger' : 'btn-primary'}`}
            onClick={handleStatusClick}
            disabled={isUpdating}>
            {user.activeStatus === 'ACTIVE' ? (
              <>
                <Lock size={16} style={{ display: 'inline', marginRight: '8px', position: 'relative', top: '-2px ' }} /> Khóa tài khoản
              </>
            ) : (
              <>
                <Unlock size={16} style={{ display: 'inline', marginRight: '8px', position: 'relative', top: '-2px' }} /> Mở khóa tài khoản
              </>
            )}
          </button>

          <p className="danger-helper-text">
            {user.activeStatus === 'ACTIVE'
              ? 'Người dùng sẽ không thể đăng nhập cho đến khi được mở khoá.'
              : 'Người dùng có thể đăng nhập lại bình thường sau khi mở khóa.'}
          </p>
        </div>
      </div>
    </div>
  );
};
