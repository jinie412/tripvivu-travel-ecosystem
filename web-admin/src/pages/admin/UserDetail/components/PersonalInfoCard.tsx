import React from 'react';
import { User as UserIcon, Calendar } from 'lucide-react';
import { User } from '../../../../types/user';

interface PersonalInfoCardProps {
  user: User;
  onUpdate: (updateData: Partial<User>) => Promise<void>;
  isUpdating: boolean;
}

export const PersonalInfoCard: React.FC<PersonalInfoCardProps> = ({ user, onUpdate, isUpdating }) => {
  // Convert Ngày sinh (VD: 1990-01-01 -> 01/01/1990)
  const displayDate = user.dateOfBirth
    ? new Date(user.dateOfBirth).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
    : '';

  return (
    <div className="card form-card">
      <div className="card-header">
        <UserIcon size={18} className="icon-muted" />
        <h3 className="card-title">Thông tin cá nhân</h3>
      </div>

      <div className="form-grid">
        <div className="form-group full-width">
          <label>Họ và tên</label>
          <input type="text" className="input-field" defaultValue={user.fullName || ''} readOnly style={{ backgroundColor: '#f8fafc' }} />
        </div>

        <div className="form-group">
          <label>Email</label>

          <input type="email" className="input-field" defaultValue={user.email || ''} readOnly style={{ backgroundColor: '#f8fafc' }} />
        </div>

        <div className="form-group">
          <label>Số điện thoại</label>
          {/* Đã map SĐT từ DB */}
          <input type="tel" className="input-field" defaultValue={user.phoneNumber || ''} readOnly style={{ backgroundColor: '#f8fafc' }} />
        </div>

        <div className="form-group half-width">
          <label>Ngày sinh</label>
          <div className="date-input-wrapper">
            {/* Đã map Ngày sinh */}
            <input
              type="text"
              className="input-field"
              defaultValue={displayDate}
              placeholder="DD/MM/YYYY"
              readOnly
              style={{ backgroundColor: '#f8fafc' }}
            />
            <Calendar size={16} className="calendar-icon" />
          </div>
        </div>

        <div className="form-group full-width">
          <label>Địa chỉ</label>
          {/* Đã map Address */}
          <textarea
            className="input-field textarea"
            rows={3}
            defaultValue={user.address || ''}
            readOnly
            style={{ backgroundColor: '#f8fafc' }}
          />
        </div>
      </div>
    </div>
  );
};
