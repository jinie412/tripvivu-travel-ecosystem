import React from 'react';
import { Search, CheckSquare } from 'lucide-react';

interface SelectOption {
  value: string;
  label: string;
}

interface LocationFilterProps {
  selectedCount: number;
  search: string;
  status: string;
  categoryName: string;
  statusOptions: SelectOption[];
  categoryOptions: SelectOption[];
  onSearchChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onCategoryChange: (value: string) => void;
}

export const LocationFilter: React.FC<LocationFilterProps> = ({
  selectedCount,
  search,
  status,
  categoryName,
  statusOptions,
  categoryOptions,
  onSearchChange,
  onStatusChange,
  onCategoryChange,
}) => {
  return (
    <div className="location-filter-bar">
      <div className="filter-left">
        <div className="search-box">
          <Search size={18} className="search-icon" />
          <input
            type="text"
            placeholder="Tìm kiếm địa điểm, người đăng"
            className="search-input"
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
          />
        </div>
      </div>

      <div className="filter-right">
        <button 
          className={`btn-bulk-approve ${selectedCount > 0 ? 'active' : ''}`}
          disabled={selectedCount === 0}
        >
          <CheckSquare size={16} />
          <span>Duyệt tất cả ({selectedCount})</span>
        </button>
        <div className="dropdown">
          <select
            value={status}
            onChange={(event) => onStatusChange(event.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', cursor: 'pointer' }}
          >
            {statusOptions.map((option) => (
              <option key={option.value} value={option.value}>
                Trạng thái ({option.label})
              </option>
            ))}
          </select>
        </div>

        <div className="dropdown">
          <select
            value={categoryName}
            onChange={(event) => onCategoryChange(event.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', cursor: 'pointer' }}
          >
            <option value="">Phân loại (Tất cả)</option>
            {categoryOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
};
