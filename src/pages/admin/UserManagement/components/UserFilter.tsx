import React, { memo, useState, useEffect } from 'react';
import { Search, Trash2 } from 'lucide-react';

interface UserFilterProps {
  selectedCount: number;
  onBulkDelete: () => void;
  onSearch: (term: string) => void;
  onRoleChange: (role: string) => void;
  onActiveStatusChange: (status: string) => void;
  currentRole: string;
  currentActiveStatus: string;
}

export const UserFilter = memo<UserFilterProps>(function UserFilter({
  selectedCount,
  onBulkDelete,
  onSearch,
  onRoleChange,
  onActiveStatusChange,
  currentRole,
  currentActiveStatus,
}) {
  const [localSearch, setLocalSearch] = useState('');

  useEffect(() => {
    const timer = setTimeout(() => {
      onSearch(localSearch);
    }, 500);
    return () => clearTimeout(timer);
  }, [localSearch, onSearch]);

  return (
    <div className="filter-container" style={{ display: 'flex', flexWrap: 'wrap', gap: '16px', marginBottom: '20px' }}>
      <div className="search-box" style={{ flex: '1 1 200px', minWidth: '200px', position: 'relative' }}>
        <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
        <input
          type="text"
          placeholder="Tìm kiếm theo tên, email..."
          value={localSearch}
          onChange={(e) => setLocalSearch(e.target.value)}
          style={{ width: '100%', padding: '8px 12px 8px 36px', borderRadius: '8px', border: '0px solid #e2e8f0' }}
        />
      </div>

      <button
        onClick={onBulkDelete}
        disabled={selectedCount === 0}
        style={{
          padding: '8px 16px',
          borderRadius: '8px',
          border: '1px solid #e2e8f0',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          opacity: selectedCount === 0 ? 0.5 : 1,
        }}>
        <Trash2 size={16} /> Xóa tất cả ({selectedCount})
      </button>

      <select
        value={currentRole}
        onChange={(e) => onRoleChange(e.target.value)}
        style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
        <option value="">Tất cả vai trò</option>
        <option value="ADMIN">Quản trị</option>
        <option value="BUSINESS">Nhà cung cấp</option>
        <option value="TOURIST">Khách du lịch</option>
      </select>

      <select
        value={currentActiveStatus}
        onChange={(e) => onActiveStatusChange(e.target.value)}
        style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
        <option value="">Tất cả trạng thái HĐ</option>
        <option value="ACTIVE">Hoạt động</option>
        <option value="LOCKED">Đã khóa</option>
      </select>
    </div>
  );
});
