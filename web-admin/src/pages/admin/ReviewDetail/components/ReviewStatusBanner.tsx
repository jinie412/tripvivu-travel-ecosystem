import React from 'react';
import { CheckCircle, AlertTriangle, Clock3, Eye, EyeOff, Info } from 'lucide-react';

type ReviewStatus = 'Chờ duyệt' | 'Đã duyệt' | 'Vi phạm' | 'Đã ẩn';

interface ReviewStatusBannerProps {
  status?: ReviewStatus;
  violationReason?: string | null;
  hiddenReason?: string | null;
  hiddenAt?: string | null;
  getTranslatedReason: (reason: string) => string;
  updating?: boolean;
  onUpdateStatus?: (newStatus: ReviewStatus) => void;
  onVisibilityChange?: (hidden: boolean) => void;
}

const THEME: Record<ReviewStatus, {
  background: string;
  border: string;
  color: string;
}> = {
  'Đã duyệt': { background: '#f6ffed', border: '#b7eb8f', color: '#389e0d' },
  'Chờ duyệt': { background: '#fffbe6', border: '#ffe58f', color: '#d48806' },
  'Vi phạm': { background: '#fff1f0', border: '#ffa39e', color: '#cf1322' },
  'Đã ẩn': { background: '#f8fafc', border: '#cbd5e1', color: '#475569' },
};

/** Banner trạng thái đánh giá kèm khu vực đổi trạng thái (dùng chung cho đánh giá địa điểm & lịch trình) */
export const ReviewStatusBanner: React.FC<ReviewStatusBannerProps> = ({
  status,
  violationReason,
  hiddenReason,
  hiddenAt,
  getTranslatedReason,
  updating = false,
  onUpdateStatus,
  onVisibilityChange,
}) => {
  if (!status) return null;

  const theme = THEME[status];

  return (
    <div
      className="rd-status-banner"
      style={{ background: theme.background, border: `1px solid ${theme.border}` }}
    >
      <p className="rd-panel-title rd-panel-title-with-tip" style={{ color: theme.color }}>
        <span>Trạng thái</span>
        <span
          className="rd-info-tip"
          style={{ color: theme.color }}
          tabIndex={0}
          aria-label="Giải thích trạng thái đánh giá"
        >
          <Info size={14} />
          <span className="rd-info-popover">
            <strong>Đã duyệt / Vi phạm:</strong> kết quả kiểm duyệt nội dung đánh giá.
            <br />
            <strong>Đã ẩn:</strong> đánh giá không còn hiển thị với người dùng, nhưng vẫn được lưu trong hệ thống.
          </span>
        </span>
      </p>

      {status === 'Đã ẩn' ? (
        <>
          <div className="rd-hidden-summary">
            <p className="rd-hidden-message">Đánh giá đã được ẩn.</p>
            <p><strong>Lý do:</strong> {hiddenReason || 'Không có thông tin lý do.'}</p>
            {hiddenAt && (
              <p className="rd-hidden-time">
                <Clock3 size={14} />
                <span><strong>Đã ẩn lúc:</strong> {hiddenAt}</span>
              </p>
            )}
          </div>
          {onVisibilityChange && (
            <button
              type="button"
              className={`rd-toggle-btn rd-toggle-btn--show ${updating ? 'rd-toggle-btn--updating' : ''}`}
              disabled={updating}
              onClick={() => onVisibilityChange(false)}
            >
              <Eye size={15} />
              <span>Hiển thị lại đánh giá</span>
            </button>
          )}
        </>
      ) : onUpdateStatus && (
        <div className="rd-toggle-group">
          <button
            type="button"
            className={`rd-toggle-btn rd-toggle-btn--approve ${updating ? 'rd-toggle-btn--updating' : ''} ${status === 'Đã duyệt' ? 'active' : ''}`}
            disabled={updating}
            onClick={() => onUpdateStatus('Đã duyệt')}
          >
            <CheckCircle size={15} />
            <span>Đã duyệt</span>
          </button>
          <button
            type="button"
            className={`rd-toggle-btn rd-toggle-btn--violation ${updating ? 'rd-toggle-btn--updating' : ''} ${status === 'Vi phạm' ? 'active' : ''}`}
            disabled={updating}
            onClick={() => onUpdateStatus('Vi phạm')}
          >
            <AlertTriangle size={15} />
            <span>Vi phạm</span>
          </button>
          {onVisibilityChange && (
            <button
              type="button"
              className={`rd-toggle-btn rd-toggle-btn--hide ${updating ? 'rd-toggle-btn--updating' : ''}`}
              disabled={updating}
              onClick={() => onVisibilityChange(true)}
            >
              <EyeOff size={15} />
              <span>Ẩn</span>
            </button>
          )}
        </div>
      )}

      {status === 'Vi phạm' && violationReason && (
        <div className="rd-status-banner-reasons">
          <span>Lý do phát hiện:</span>
          {getTranslatedReason(violationReason).split(',').map((reasonPart, idx) => {
            const cleanReason = reasonPart.trim().replace('Nội dung vi phạm: ', '');
            if (!cleanReason) return null;
            return (
              <span key={idx} className="rd-status-banner-reason-pill">
                {cleanReason}
              </span>
            );
          })}
        </div>
      )}
    </div>
  );
};
