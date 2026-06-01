import React, { memo } from 'react';
import { User } from '../../../../types/user';
import { Badge } from '../../../../components/Badge';
import { Eye, Lock, Unlock } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// --- Utility functions hoisted ngoài component, không tạo lại mỗi render ---

const DATE_FORMATTER = new Intl.DateTimeFormat('vi-VN', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
});

const formatDate = (dateString: string) => {
  if (!dateString) return '--/--/----';
  return DATE_FORMATTER.format(new Date(dateString));
};

const ROLE_LABELS: Record<string, string> = {
  ADMIN: 'Quản trị',
  BUSINESS: 'Nhà cung cấp',
  TOURIST: 'Khách du lịch',
};

const ROLE_BADGE_TYPES: Record<string, string> = {
  ADMIN: 'admin',
  BUSINESS: 'provider',
  TOURIST: 'tourist',
};

const formatRoleLabel = (role: string) => ROLE_LABELS[role] ?? role;
const getRoleBadgeType = (role: string) => ROLE_BADGE_TYPES[role] ?? 'default';

const formatStatusLabel = (status: string) => {
  if (status === 'ACTIVE') return 'Hoạt động';
  if (status === 'LOCKED') return 'Đã khóa';
  return status;
};

const getStatusBadgeType = (status: string) => (status === 'ACTIVE' ? 'active' : 'locked');

const AVATAR_COLORS = [
  { bg: '#eff6ff', text: '#3b82f6' },
  { bg: '#f5f3ff', text: '#8b5cf6' },
  { bg: '#f0fdf4', text: '#22c55e' },
  { bg: '#fefce8', text: '#eab308' },
  { bg: '#fff1f2', text: '#f43f5e' },
];

const getAvatarColor = (char: string) =>
  AVATAR_COLORS[char ? char.charCodeAt(0) % AVATAR_COLORS.length : 0];

const getInitials = (name?: string, email?: string) => {
  if (name) {
    const parts = name.trim().split(' ');
    if (parts.length >= 2) return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }
  if (email) return email.substring(0, 2).toUpperCase();
  return 'U';
};

// Windowed pagination: tối đa 7 nút, dùng '...' thay vì render tất cả
const getPageNumbers = (current: number, total: number): (number | '...')[] => {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  if (current <= 4) return [1, 2, 3, 4, 5, '...', total];
  if (current >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
  return [1, '...', current - 1, current, current + 1, '...', total];
};

// --- Props ---

interface UserTableProps {
  users: User[];
  loading: boolean;
  selectedSet: Set<string>;
  onSelectRow: (id: string, checked: boolean) => void;
  onSelectAll: (checked: boolean) => void;
  currentPage: number;
  totalItems: number;
  itemsPerPage: number;
  onPageChange: (page: number) => void;
  onToggleLock: (id: string, name: string, currentStatus: string) => void;
}

export const UserTable = memo<UserTableProps>(function UserTable({
  users,
  loading,
  selectedSet,
  onSelectRow,
  onSelectAll,
  currentPage,
  totalItems,
  itemsPerPage,
  onPageChange,
  onToggleLock,
}) {
  const navigate = useNavigate();
  const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;
  // Kiểm tra chính xác: tất cả user trên trang hiện tại có trong selectedSet không
  const allSelected = users.length > 0 && users.every((u) => selectedSet.has(u.id));

  return (
    <div className="table-container">
      <table className="user-table">
        <thead>
          <tr>
            <th className="th-checkbox">
              <input
                type="checkbox"
                className="checkbox"
                checked={allSelected}
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
              const userAvatar = (user as any).avatarUrl || (user as any).avatar_url;

              return (
                <tr
                  key={user.id}
                  onClick={() => navigate(`/admin/users/${user.id}`)}
                  className="table-row-hover table-row-clickable">
                  <td className="td-checkbox" data-label="" onClick={(e) => e.stopPropagation()}>
                    <input
                      type="checkbox"
                      className="checkbox"
                      checked={selectedSet.has(user.id)}
                      onChange={(e) => {
                        e.stopPropagation();
                        onSelectRow(user.id, e.target.checked);
                      }}
                    />
                  </td>
                  <td className="td-user" data-label="Người dùng">
                    <div className="user-profile">
                      {userAvatar ? (
                        <img
                          src={userAvatar}
                          alt={displayName}
                          loading="lazy"
                          className="avatar avatar-img"
                        />
                      ) : (
                        <div
                          className="avatar avatar-initials"
                          style={{ backgroundColor: avatarStyle.bg, color: avatarStyle.text }}>
                          {initials}
                        </div>
                      )}
                      <div className="user-info">
                        <span className="user-name">{displayName}</span>
                        <span className="user-email">{user.email}</span>
                      </div>
                    </div>
                  </td>
                  <td className="td-role" data-label="Vai trò">
                    <Badge label={formatRoleLabel(user.role)} type={getRoleBadgeType(user.role)} />
                  </td>
                  <td className="td-status" data-label="Trạng thái">
                    <Badge
                      label={formatStatusLabel(user.activeStatus)}
                      type={getStatusBadgeType(user.activeStatus)}
                      showDot={true}
                    />
                  </td>
                  <td className="td-date" data-label="Ngày tham gia">
                    <span className="date-text">{formatDate(user.joinedDate)}</span>
                  </td>
                  <td
                    className="td-actions"
                    data-label="Thao tác"
                    onClick={(e) => e.stopPropagation()}>
                    <button
                      className="action-btn text-blue action-btn-view"
                      title="Xem chi tiết"
                      onClick={() => navigate(`/admin/users/${user.id}`)}>
                      <Eye size={18} />
                    </button>
                    <button
                      className={`action-btn ${user.activeStatus === 'ACTIVE' ? 'text-red' : 'text-green'}`}
                      title={user.activeStatus === 'ACTIVE' ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
                      onClick={() =>
                        onToggleLock(user.id, user.fullName || user.email, user.activeStatus)
                      }>
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
            {totalItems === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1}–
            {Math.min(currentPage * itemsPerPage, totalItems)}
          </b>{' '}
          trong <b>{totalItems}</b> kết quả
        </span>
        <div className="pagination">
          <button
            className="page-nav"
            disabled={currentPage === 1}
            onClick={() => onPageChange(currentPage - 1)}>
            &lt;
          </button>

          {getPageNumbers(currentPage, totalPages).map((page, index) =>
            page === '...' ? (
              <span key={`ellipsis-${index}`} className="page-dots">
                ...
              </span>
            ) : (
              <button
                key={page}
                className={`page-item ${currentPage === page ? 'active' : ''}`}
                onClick={() => onPageChange(page as number)}>
                {page}
              </button>
            ),
          )}

          <button
            className="page-nav"
            disabled={currentPage === totalPages || totalItems === 0}
            onClick={() => onPageChange(currentPage + 1)}>
            &gt;
          </button>
        </div>
      </div>
    </div>
  );
});
