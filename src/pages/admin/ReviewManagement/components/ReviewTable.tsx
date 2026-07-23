import React, { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { Review } from '../../../../types/review';
import { Star, ChevronDown, CheckCircle, AlertTriangle, Eye, EyeOff, Info, Clock } from 'lucide-react';
import Swal from 'sweetalert2';

interface ReviewTableProps {
  reviews: Review[];
  loading: boolean;
  currentPage: number;
  totalItems: number;
  itemsPerPage: number;
  onPageChange: (page: number) => void;
  onStatusChange: (id: string, status: Review['status']) => Promise<void>;
  onVisibilityChange?: (id: string, hidden: boolean, reason?: string) => Promise<void>;
  showClassification?: boolean;
  targetColumnLabel?: string;
  disableRowNavigation?: boolean;
  rowNavigatePath?: string;
}

const STATUS_OPTIONS: Review['status'][] = ['Chờ duyệt', 'Đã duyệt', 'Vi phạm'];

const statusConfig: Record<Review['status'], { bg: string; text: string; dot: string; icon: React.ReactNode }> = {
  'Chờ duyệt': { bg: '#fef3c7', text: '#b45309', dot: '#b45309', icon: <Clock size={13} /> },
  'Đã duyệt': { bg: '#ccfbf1', text: '#0f766e', dot: '#0f766e', icon: <CheckCircle size={13} /> },
  'Vi phạm':  { bg: '#fef2f2', text: '#ef4444', dot: '#ef4444', icon: <AlertTriangle size={13} /> },
  'Đã ẩn': { bg: '#e2e8f0', text: '#475569', dot: '#64748b', icon: <EyeOff size={13} /> },
};

const ClassificationTooltip = () => {
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const triggerRef = useRef<HTMLSpanElement>(null);

  const showTooltip = () => {
    const rect = triggerRef.current?.getBoundingClientRect();
    if (!rect) return;
    setPosition({
      top: rect.bottom + 10,
      left: rect.left + rect.width / 2,
    });
    setOpen(true);
  };

  return (
    <>
      <span
        ref={triggerRef}
        className="rv-info-tip"
        tabIndex={0}
        aria-label="Định nghĩa phân loại đánh giá"
        onMouseEnter={showTooltip}
        onMouseLeave={() => setOpen(false)}
        onFocus={showTooltip}
        onBlur={() => setOpen(false)}
      >
        <Info size={14} />
      </span>
      {open &&
        createPortal(
          <div
            className="rv-info-popover"
            style={{ top: position.top, left: position.left }}
            role="tooltip"
          >
            <strong>Ngắn hạn:</strong> đánh giá mô tả trải nghiệm hoặc tình trạng tại một thời điểm cụ thể, có thể không đại diện cho địa điểm trong thời gian dài.
            <br />
            <strong>Dài hạn:</strong> đánh giá mô tả đặc điểm ổn định của địa điểm, có tính duy trì hoặc lặp lại theo thời gian.
          </div>,
          document.body,
        )}
    </>
  );
};

const StatusTooltip = () => {
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const triggerRef = useRef<HTMLSpanElement>(null);

  const showTooltip = () => {
    const rect = triggerRef.current?.getBoundingClientRect();
    if (!rect) return;
    setPosition({
      top: rect.bottom + 10,
      left: rect.left + rect.width / 2,
    });
    setOpen(true);
  };

  return (
    <>
      <span
        ref={triggerRef}
        className="rv-info-tip"
        tabIndex={0}
        aria-label="Giải thích trạng thái đánh giá"
        onMouseEnter={showTooltip}
        onMouseLeave={() => setOpen(false)}
        onFocus={showTooltip}
        onBlur={() => setOpen(false)}
      >
        <Info size={14} />
      </span>
      {open &&
        createPortal(
          <div
            className="rv-info-popover"
            style={{ top: position.top, left: position.left }}
            role="tooltip"
          >
            <strong>Đã duyệt / Vi phạm:</strong> kết quả kiểm duyệt nội dung đánh giá.
            <br />
            <strong>Đã ẩn:</strong> đánh giá không còn hiển thị với người dùng, nhưng vẫn được lưu trong hệ thống.
          </div>,
          document.body,
        )}
    </>
  );
};

/** Dropdown chỉnh trạng thái riêng lẻ */
const StatusDropdown: React.FC<{
  reviewId: string;
  current: Review['status'];
  onChange: (id: string, status: Review['status']) => void;
  onVisibilityChange?: (id: string, hidden: boolean) => void;
}> = ({ reviewId, current, onChange, onVisibilityChange }) => {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const cfg = statusConfig[current];

  if (current === 'Đã ẩn') {
    return (
      <div
        onClick={(event) => event.stopPropagation()}
        style={{
          display: 'inline-flex', alignItems: 'center', gap: '8px',
        }}
      >
        <span
          style={{
            display: 'inline-flex', alignItems: 'center', gap: '6px',
            padding: '4px 10px', borderRadius: '100px',
            backgroundColor: cfg.bg, color: cfg.text,
            fontWeight: 600, fontSize: '0.78rem',
          }}
        >
          <span style={{ width: 6, height: 6, borderRadius: '50%', backgroundColor: cfg.dot, flexShrink: 0 }} />
          {current}
        </span>
        {onVisibilityChange && (
          <button
            type="button"
            title="Hiển thị lại đánh giá"
            aria-label="Hiển thị lại đánh giá"
            onClick={() => onVisibilityChange(reviewId, false)}
            style={{
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              width: 30, height: 30, borderRadius: 8,
              border: '1px solid #cbd5e1', background: '#fff',
              color: '#2563eb', cursor: 'pointer',
            }}
          >
            <Eye size={15} />
          </button>
        )}
      </div>
    );
  }

  return (
    <div ref={ref} style={{ position: 'relative', display: 'inline-block' }} onClick={(e) => e.stopPropagation()}>
      <button
        onClick={() => setOpen(v => !v)}
        style={{
          display: 'inline-flex', alignItems: 'center', gap: '6px',
          padding: '4px 10px', borderRadius: '100px',
          backgroundColor: cfg.bg, color: cfg.text,
          border: 'none', cursor: 'pointer', fontWeight: 600, fontSize: '0.78rem',
          transition: 'opacity 0.15s',
        }}
      >
        <span style={{ width: 6, height: 6, borderRadius: '50%', backgroundColor: cfg.dot, flexShrink: 0 }} />
        {current}
        <ChevronDown
          size={12}
          style={{ opacity: 0.7, marginLeft: 2, transition: 'transform 0.2s', transform: open ? 'rotate(180deg)' : 'rotate(0deg)' }}
        />
      </button>

      {open && (
        <div style={{
          position: 'absolute', top: 'calc(100% + 6px)', right: 0, zIndex: 50,
          background: 'white', borderRadius: '12px', boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
          border: '1px solid var(--border-color)', overflow: 'hidden', minWidth: '160px',
        }}>
          <div style={{ padding: '6px', display: 'flex', flexDirection: 'column', gap: '2px' }}>
            {STATUS_OPTIONS.map((opt) => {
              const oCfg = statusConfig[opt];
              const isActive = opt === current;
              return (
                <button
                  key={opt}
                  onClick={() => { onChange(reviewId, opt); setOpen(false); }}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '10px',
                    padding: '9px 14px', borderRadius: '8px',
                    background: isActive ? oCfg.bg : 'transparent',
                    color: isActive ? oCfg.text : 'var(--text-secondary)',
                    border: 'none', cursor: 'pointer', fontWeight: isActive ? 700 : 500,
                    fontSize: '0.875rem', textAlign: 'left', width: '100%',
                    transition: 'background 0.15s',
                  }}
                  onMouseEnter={e => { if (!isActive) (e.currentTarget as HTMLButtonElement).style.background = '#f8fafc'; }}
                  onMouseLeave={e => { if (!isActive) (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}
                >
                  <span style={{ color: oCfg.text }}>{oCfg.icon}</span>
                  {opt}
                  {isActive && <span style={{ marginLeft: 'auto', width: 8, height: 8, borderRadius: '50%', backgroundColor: oCfg.dot }} />}
                </button>
              );
            })}
            {onVisibilityChange && (
              <>
                <div style={{ height: 1, background: '#e2e8f0', margin: '4px 6px' }} />
                <button
                  type="button"
                  onClick={() => { onVisibilityChange(reviewId, true); setOpen(false); }}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '10px',
                    padding: '9px 14px', borderRadius: '8px',
                    background: 'transparent', color: '#475569',
                    border: 'none', cursor: 'pointer', fontWeight: 600,
                    fontSize: '0.875rem', textAlign: 'left', width: '100%',
                  }}
                >
                  <EyeOff size={14} />
                  Ẩn đánh giá
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export const ReviewTable: React.FC<ReviewTableProps> = ({
  reviews: initialReviews,
  loading,
  currentPage,
  totalItems,
  itemsPerPage,
  onPageChange,
  onStatusChange,
  onVisibilityChange,
  showClassification = true,
  targetColumnLabel = 'ĐỊA ĐIỂM',
  disableRowNavigation = false,
  rowNavigatePath = '/admin/reviews',
}) => {
  const navigate = useNavigate();
  const [reviews, setReviews] = useState<Review[]>(initialReviews);

  useEffect(() => { setReviews(initialReviews); }, [initialReviews]);

  const handleStatusChange = async (id: string, newStatus: Review['status']) => {
    setReviews(prev => prev.map(r => r.id === id ? { ...r, status: newStatus } : r));
    try {
      await onStatusChange(id, newStatus);
    } catch (error) {
      setReviews(initialReviews);
      if (error instanceof Error && error.message === 'REASON_INPUT_CANCELLED') return;
      console.error('Failed to update review status', error);
      Swal.fire({ text: 'Không thể cập nhật trạng thái đánh giá. Vui lòng thử lại.', icon: 'error' });
    }
  };

  const handleVisibilityChange = async (id: string, hidden: boolean) => {
    if (!onVisibilityChange) return;

    let reason: string | undefined;
    if (hidden) {
      const result = await Swal.fire({
        title: 'Ẩn đánh giá',
        input: 'text',
        inputLabel: 'Nhập lý do ẩn đánh giá',
        inputPlaceholder: 'Lý do ẩn...',
        inputAttributes: { maxlength: '500' },
        showCancelButton: true,
        confirmButtonText: 'Ẩn đánh giá',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#64748b',
        inputValidator: (value) => value.trim() ? undefined : 'Vui lòng nhập lý do ẩn đánh giá.',
      });
      if (!result.isConfirmed) return;
      reason = typeof result.value === 'string' ? result.value.trim() : undefined;
    } else {
      const result = await Swal.fire({
        title: 'Cho hiển thị lại đánh giá?',
        text: 'Đánh giá sẽ được chuyển về trạng thái Đã duyệt và hiển thị với người dùng.',
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Hiển thị lại',
        cancelButtonText: 'Hủy',
        confirmButtonColor: '#2563eb',
      });
      if (!result.isConfirmed) return;
    }

    const previousReviews = reviews;
    setReviews((items) => items.map((review) => (
      review.id === id
        ? {
            ...review,
            status: hidden ? 'Đã ẩn' : 'Đã duyệt',
            hiddenReason: hidden ? reason : null,
            hiddenAt: hidden ? new Date().toISOString() : null,
          }
        : review
    )));

    try {
      await onVisibilityChange(id, hidden, reason);
    } catch (error) {
      setReviews(previousReviews);
      console.error('Failed to update review visibility', error);
      Swal.fire({ text: 'Không thể cập nhật khả năng hiển thị đánh giá. Vui lòng thử lại.', icon: 'error' });
    }
  };

  const renderStars = (rating: number) => (
    <div className="rv-stars">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star key={i} size={14} fill={i < rating ? '#facc15' : 'none'} color={i < rating ? '#facc15' : '#d1d5db'} />
      ))}
    </div>
  );

  const renderClassification = (classification?: Review['classification']) => {
    if (!classification) {
      return <span className="rv-muted-dash">-</span>;
    }

    let dotColor = '#64748b', bg = '#f1f5f9', text = '#64748b';
    if (classification === 'Ngắn hạn')       { dotColor = '#2563eb'; bg = '#dbeafe'; text = '#2563eb'; }
    else if (classification === 'Dài hạn')   { dotColor = '#7c3aed'; bg = '#ede9fe'; text = '#7c3aed'; }
    else if (classification === 'Cần xử lý') { dotColor = '#b45309'; bg = '#fef3c7'; text = '#b45309'; }
    return (
      <span className="rv-badge" style={{ backgroundColor: bg, color: text }}>
        <span className="rv-badge-dot" style={{ backgroundColor: dotColor }} />
        {classification}
      </span>
    );
  };

  const avatarColors = [
    { bg: '#dbeafe', text: '#2563eb' }, { bg: '#fce7f3', text: '#be185d' },
    { bg: '#d1fae5', text: '#059669' }, { bg: '#e0e7ff', text: '#4338ca' },
    { bg: '#fee2e2', text: '#dc2626' }, { bg: '#fef3c7', text: '#b45309' },
    { bg: '#ede9fe', text: '#7c3aed' }, { bg: '#ccfbf1', text: '#0d9488' },
    { bg: '#ffedd5', text: '#c2410c' }, { bg: '#f1f5f9', text: '#475569' },
  ];

  const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;

  return (
    <div className="table-container">
      <table className="rv-table">
        <thead>
          <tr>
            <th>NGƯỜI ĐÁNH GIÁ</th>
            <th>{targetColumnLabel}</th>
            <th>NỘI DUNG ĐÁNH GIÁ</th>
            <th>SỐ SAO</th>
            <th>NGÀY GỬI</th>
            {showClassification && (
              <th>
                <span className="rv-th-with-tip">
                  PHÂN LOẠI
                  <ClassificationTooltip />
                </span>
              </th>
            )}
            <th>
              <span className="rv-th-with-tip">
                TRẠNG THÁI
                <StatusTooltip />
              </span>
            </th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <tr><td colSpan={showClassification ? 7 : 6} className="text-center py-4 text-muted">Đang tải dữ liệu...</td></tr>
          ) : (
            reviews.map((review, idx) => {
              const color = avatarColors[idx % avatarColors.length];
              return (
                <tr
                  key={review.id}
                  className="table-row-hover"
                  style={{ cursor: 'pointer' }}
                  onClick={() => {
                    if (disableRowNavigation) return;
                    navigate(`${rowNavigatePath}/${review.id}`);
                  }}
                >
                  <td data-label="Người dùng">
                    <div className="rv-user-cell">
                      <div className="rv-avatar" style={{ backgroundColor: color.bg, color: color.text }}>
                        {review.userAvatar}
                      </div>
                      <span className="rv-user-name">{review.userName}</span>
                    </div>
                  </td>
                  <td data-label="Địa điểm">
                    {review.locationId ? (
                      <button
                        type="button"
                        className="rv-location-link"
                        onClick={(event) => {
                          event.preventDefault();
                          event.stopPropagation();
                          navigate(`/admin/locations/${review.locationId}`);
                        }}>
                        {review.locationName}
                      </button>
                    ) : (
                      <span className="rv-location-link rv-location-link-disabled">{review.locationName}</span>
                    )}
                  </td>
                  <td data-label="Nội dung">
                    <span className="rv-content-preview">{review.content}</span>
                  </td>
                  <td data-label="Đánh giá">{renderStars(review.rating)}</td>
                  <td data-label="Ngày gửi"><span className="rv-date">{review.date}</span></td>
                  {showClassification && (
                    <td data-label="Phân loại">{renderClassification(review.classification)}</td>
                  )}
                  <td data-label="Trạng thái" onClick={(event) => event.stopPropagation()}>
                    <StatusDropdown
                      reviewId={review.id}
                      current={review.status}
                      onChange={(id, nextStatus) => {
                        void handleStatusChange(id, nextStatus);
                      }}
                      onVisibilityChange={onVisibilityChange
                        ? (id, hidden) => { void handleVisibilityChange(id, hidden); }
                        : undefined}
                    />
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
          Hiển thị <b>{totalItems === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1}-{Math.min(currentPage * itemsPerPage, totalItems)}</b> trong <b>{totalItems.toLocaleString()}</b> kết quả
        </span>
        <div className="pagination">
          <button className="page-nav" disabled={currentPage === 1} onClick={() => onPageChange(currentPage - 1)}>&lt;</button>
          {Array.from({ length: totalPages }).map((_, index) => {
            const p = index + 1;
            if (totalPages > 7) {
              if (p === 1 || p === 2 || p === 3 || p === totalPages)
                return <button key={p} className={`page-item ${currentPage === p ? 'active' : ''}`} onClick={() => onPageChange(p)}>{p}</button>;
              if (p === 4) return <span key={p} className="page-dots">...</span>;
              return null;
            }
            return <button key={p} className={`page-item ${currentPage === p ? 'active' : ''}`} onClick={() => onPageChange(p)}>{p}</button>;
          })}
          <button className="page-nav" disabled={currentPage === totalPages || totalItems === 0} onClick={() => onPageChange(currentPage + 1)}>&gt;</button>
        </div>
      </div>
    </div>
  );
};
