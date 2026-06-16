import React from 'react';
import { Location } from '../../../../types/location';
import { Pencil, Check, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import defaultLocationImage from '../../../../assets/images/location-default.svg';

interface LocationTableProps {
  locations: Location[];
  loading: boolean;
  selectedRows: string[];
  onSelectRow: (id: string, checked: boolean) => void;
  onSelectAll: (checked: boolean) => void;
  currentPage: number;
  totalItems: number;
  itemsPerPage: number;
  onPageChange: (page: number) => void;
  onApprove: (id: string) => Promise<void>;
  onReject: (id: string, reason?: string) => Promise<void>;
}

export const LocationTable: React.FC<LocationTableProps> = ({
  locations,
  loading,
  selectedRows,
  onSelectRow,
  onSelectAll,
  currentPage,
  totalItems,
  itemsPerPage,
  onPageChange,
  onApprove,
  onReject,
}) => {
  const navigate = useNavigate();
  const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;
  const visiblePages = Array.from(new Set([1, currentPage - 1, currentPage, currentPage + 1, totalPages])).filter(
    (page) => page >= 1 && page <= totalPages,
  );

  // Adjust wait status UI to be more orange as per design, we can use an inline style override or just active/locked
  const renderBadge = (status: string) => {
    let type: 'active' | 'locked' | 'admin' | 'provider' | 'default' = 'default';
    let customStyle = {};
    if (status === 'Đã duyệt') {
      type = 'active';
      customStyle = { backgroundColor: '#ccfbf1', color: '#0f766e' };
    } else if (status === 'Chờ duyệt') {
      type = 'provider'; // yellow/orange
      customStyle = { backgroundColor: '#fef3c7', color: '#b45309' };
    } else if (status === 'Từ chối') {
      type = 'locked'; // red
    }
    return (
      <div style={{ display: 'inline-flex' }}>
        <span
          style={{
            padding: '4px 12px',
            borderRadius: '100px',
            fontSize: '0.75rem',
            fontWeight: 600,
            ...customStyle,
          }}
          className={`badge badge-${type}`}>
          {status}
        </span>
      </div>
    );
  };

  return (
    <div className="table-container">
      <table className="location-table">
        <thead>
          <tr>
            <th className="th-checkbox">
              <input
                type="checkbox"
                className="checkbox"
                checked={selectedRows.length === locations.length && locations.length > 0}
                onChange={(e) => onSelectAll(e.target.checked)}
              />
            </th>
            <th className="th-image">HÌNH ẢNH</th>
            <th className="th-name">TÊN ĐỊA ĐIỂM</th>
            <th className="th-category">PHÂN LOẠI</th>
            <th className="th-author">NGƯỜI ĐĂNG</th>
            <th className="th-date">NGÀY ĐĂNG</th>
            <th className="th-status">TRẠNG THÁI</th>
            <th className="th-actions">THAO TÁC</th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <tr>
              <td colSpan={8} className="text-center py-4 text-muted">
                Đang tải dữ liệu...
              </td>
            </tr>
          ) : (
            locations.map((loc) => (
              <tr
                key={loc.id}
                className="table-row-hover"
                style={{ cursor: 'pointer' }}
                onClick={() => navigate(`/admin/locations/${loc.id}`)}>
                <td className="td-checkbox" data-label="" onClick={(e) => e.stopPropagation()}>
                  <input
                    type="checkbox"
                    className="checkbox"
                    checked={selectedRows.includes(loc.id)}
                    onChange={(e) => {
                      e.stopPropagation();
                      onSelectRow(loc.id, e.target.checked);
                    }}
                  />
                </td>
                <td className="td-image" data-label="Hình ảnh">
                  <div className="location-image-wrapper bg-placeholder">
                    <img
                      src={loc.image || defaultLocationImage}
                      alt={loc.name}
                      loading="lazy"
                      decoding="async"
                      onError={(event) => {
                        event.currentTarget.onerror = null;
                        event.currentTarget.src = defaultLocationImage;
                      }}
                    />
                  </div>
                </td>
                <td className="td-name" data-label="Tên địa điểm">
                  <div className="location-info">
                    <span className="location-name">{loc.name}</span>
                    <span className="location-address">{loc.address}</span>
                  </div>
                </td>
                <td className="td-category" data-label="Phân loại">
                  <span className="category-text">{loc.category}</span>
                </td>
                <td className="td-author" data-label="Người đăng">
                  <div className="author-profile">
                    <div className="author-avatar">{loc.userAvatar}</div>
                    <span className="author-name">{loc.userName}</span>
                  </div>
                </td>
                <td className="td-date" data-label="Ngày đăng">
                  <span className="date-text">{loc.publishDate}</span>
                </td>
                <td className="td-status" data-label="Trạng thái">
                  {renderBadge(loc.status)}
                </td>
                <td className="td-actions" data-label="Thao tác" onClick={(e) => e.stopPropagation()}>
                  <div className="action-buttons">
                    {loc.status === 'Chờ duyệt' && (
                      <>
                        <button
                          className="action-btn btn-approve"
                          title="Duyệt"
                          onClick={() => {
                            void onApprove(loc.id);
                          }}>
                          <Check size={16} />
                        </button>
                        <button
                          className="action-btn btn-reject"
                          title="Từ chối"
                          onClick={() => {
                            const reason = window.prompt('Nhập lý do từ chối địa điểm (không bắt buộc):') || undefined;
                            void onReject(loc.id, reason);
                          }}>
                          <X size={16} />
                        </button>
                      </>
                    )}
                    <button className="action-btn btn-edit" title="Chỉnh sửa" onClick={() => navigate(`/admin/locations/${loc.id}`)}>
                      <Pencil size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))
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
          trong <b>{totalItems.toLocaleString()}</b> kết quả
        </span>
        <div className="pagination">
          <button className="page-nav" disabled={currentPage === 1} onClick={() => onPageChange(currentPage - 1)}>
            &lt;
          </button>

          {visiblePages.map((pageNumber, index) => (
            <React.Fragment key={pageNumber}>
              {index > 0 && pageNumber - visiblePages[index - 1] > 1 && <span className="page-dots">...</span>}
              <button className={`page-item ${currentPage === pageNumber ? 'active' : ''}`} onClick={() => onPageChange(pageNumber)}>
                {pageNumber}
              </button>
            </React.Fragment>
          ))}

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
};
