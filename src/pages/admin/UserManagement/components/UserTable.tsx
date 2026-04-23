import React from 'react';
import { User } from '../../../../types/user';
import { Badge } from '../../../../components/Badge';
import { Eye, Lock, Unlock } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface UserTableProps {
  users: User[];
  loading: boolean;
  selectedRows: string[];
  onSelectRow: (id: string, checked: boolean) => void;
  onSelectAll: (checked: boolean) => void;
  currentPage: number;
  totalItems: number;
  itemsPerPage: number;
  onPageChange: (page: number) => void;
  onToggleLock: (id: string, name: string, currentStatus: string) => void;
}

export const UserTable: React.FC<UserTableProps> = ({
  users,
  loading,
  selectedRows,
  onSelectRow,
  onSelectAll,
  currentPage,
  totalItems,
  itemsPerPage,
  onPageChange,
  onToggleLock,
}) => {
  const navigate = useNavigate();

  const formatRoleLabel = (role: string) => {
    switch (role) {
      case 'ADMIN':
        return 'Quản trị';
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

  const formatStatusLabel = (status: string) => {
    switch (status) {
      case 'ACTIVE':
        return 'Hoạt động';
      case 'LOCKED':
        return 'Đã khóa';
      default:
        return status;
    }
  };

  const getStatusBadgeType = (status: string) => {
    return status === 'ACTIVE' ? 'active' : 'locked';
  };

  const getInitials = (name?: string, email?: string) => {
    if (name) {
      const parts = name.trim().split(' ');
      if (parts.length >= 2) return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
      return name.substring(0, 2).toUpperCase();
    }
    if (email) return email.substring(0, 2).toUpperCase();
    return 'U';
  };

  const getAvatarColor = (char: string) => {
    const colors = [
      { bg: '#eff6ff', text: '#3b82f6' }, // Blue
      { bg: '#f5f3ff', text: '#8b5cf6' }, // Purple
      { bg: '#f0fdf4', text: '#22c55e' }, // Green
      { bg: '#fefce8', text: '#eab308' }, // Yellow
      { bg: '#fff1f2', text: '#f43f5e' }, // Red
    ];
    const index = char ? char.charCodeAt(0) % colors.length : 0;
    return colors[index];
  };

  // 4. Hàm format Ngày tháng
  const formatDate = (dateString: string) => {
    if (!dateString) return '--/--/----';
    const date = new Date(dateString);
    return date.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  return (
    <div className="table-container">
      <table className="user-table">
        <thead>
          <tr>
            <th className="th-checkbox">
              <input
                type="checkbox"
                className="checkbox"
                checked={selectedRows.length === users.length && users.length > 0}
                onChange={(e) => onSelectAll(e.target.checked)}
              />
            </th>
            <th className="th-user">NGƯỜI DÙNG</th>
            <th className="th-role">VAI TRÒ</th>
            <th className="th-status">TRẠNG THÁI</th>
            <th className="th-date">NGÀY THAM GIA</th>
            <th className="th-actions">THAO TÁC</th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <tr>
              <td colSpan={6} className="text-center py-4 text-muted">
                Đang tải dữ liệu...
              </td>
            </tr>
          ) : users.length === 0 ? (
            <tr>
              <td colSpan={6} className="text-center py-4 text-muted">
                Không tìm thấy người dùng nào.
              </td>
            </tr>
          ) : (
            users.map((user) => {
              const initials = getInitials(user.fullName, user.email);
              const avatarStyle = getAvatarColor(initials);
              const displayName = user.fullName || user.email.split('@')[0];

              // Hỗ trợ cả 2 chuẩn đặt tên biến từ Backend (avatarUrl hoặc avatar_url)
              const userAvatar = (user as any).avatarUrl || (user as any).avatar_url;

              return (
                <tr
                  key={user.id}
                  onClick={() => navigate(`/admin/users/${user.id}`)}
                  style={{ cursor: 'pointer' }}
                  className="table-row-hover">
                  <td className="td-checkbox" data-label="" onClick={(e) => e.stopPropagation()}>
                    <input
                      type="checkbox"
                      className="checkbox"
                      checked={selectedRows.includes(user.id)}
                      onChange={(e) => {
                        e.stopPropagation();
                        onSelectRow(user.id, e.target.checked);
                      }}
                    />
                  </td>
                  <td className="td-user" data-label="Người dùng">
                    <div className="user-profile">
                      {/* XỬ LÝ ĐIỀU KIỆN AVATAR Ở ĐÂY */}
                      {userAvatar ? (
                        <img
                          src={userAvatar}
                          alt={displayName}
                          className="avatar"
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '50%',
                            objectFit: 'cover', // Đảm bảo hình không bị méo
                          }}
                        />
                      ) : (
                        <div
                          className="avatar"
                          style={{
                            backgroundColor: avatarStyle.bg,
                            color: avatarStyle.text,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: 'bold',
                            fontSize: '14px',
                            width: '40px',
                            height: '40px',
                            borderRadius: '50%',
                          }}>
                          {initials}
                        </div>
                      )}

                      <div className="user-info">
                        <span className="user-name" style={{ fontWeight: '600' }}>
                          {displayName}
                        </span>
                        <span className="user-email" style={{ color: '#94a3b8' }}>
                          {user.email}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td className="td-role" data-label="Vai trò">
                    <Badge label={formatRoleLabel(user.role)} type={getRoleBadgeType(user.role)} />
                  </td>
                  <td className="td-status" data-label="Trạng thái">
                    <Badge label={formatStatusLabel(user.activeStatus)} type={getStatusBadgeType(user.activeStatus)} showDot={true} />
                  </td>
                  <td className="td-date" data-label="Ngày tham gia">
                    <span className="date-text">{formatDate(user.joinedDate)}</span>
                  </td>
                  <td className="td-actions" data-label="Thao tác" onClick={(e) => e.stopPropagation()}>
                    <button
                      className="action-btn text-blue"
                      title="Xem chi tiết"
                      onClick={() => navigate(`/admin/users/${user.id}`)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', marginRight: '8px' }}>
                      <Eye size={18} />
                    </button>
                    <button
                      className={`action-btn ${user.activeStatus === 'ACTIVE' ? 'text-red' : 'text-green'}`}
                      title={user.activeStatus === 'ACTIVE' ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
                      onClick={() => onToggleLock(user.id, user.fullName || user.email, user.activeStatus)}
                      style={{
                        background: 'none',
                        border: 'none',
                        cursor: 'pointer',
                        color: user.activeStatus === 'ACTIVE' ? '#ef4444' : '#22c55e',
                      }}>
                      {user.activeStatus === 'ACTIVE' ? <Lock size={18} /> : <Unlock size={18} />}
                    </button>
                  </td>
                </tr>
              );
            })
          )}
        </tbody>
      </table>

      {/* Pagination */}
      <div className="pagination-wrapper">
        <span className="pagination-info">
          Hiển thị{' '}
          <b>
            {totalItems === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1}-{Math.min(currentPage * itemsPerPage, totalItems)}
          </b>{' '}
          trong <b>{totalItems}</b> kết quả
        </span>
        <div className="pagination">
          <button className="page-nav" disabled={currentPage === 1} onClick={() => onPageChange(currentPage - 1)}>
            &lt;
          </button>

          {Array.from({ length: Math.ceil(totalItems / itemsPerPage) || 1 }).map((_, index) => {
            const pageNumber = index + 1;
            return (
              <button
                key={pageNumber}
                className={`page-item ${currentPage === pageNumber ? 'active' : ''}`}
                onClick={() => onPageChange(pageNumber)}>
                {pageNumber}
              </button>
            );
          })}

          <button
            className="page-nav"
            disabled={currentPage === Math.ceil(totalItems / itemsPerPage) || totalItems === 0}
            onClick={() => onPageChange(currentPage + 1)}>
            &gt;
          </button>
        </div>
      </div>
    </div>
  );
};
