import React from 'react';
import { CheckCircle, AlertTriangle } from 'lucide-react';

type ReviewStatus = 'Chờ duyệt' | 'Đã duyệt' | 'Vi phạm' | 'Đã ẩn';

interface ReviewStatusBannerProps {
  status?: ReviewStatus;
  violationReason?: string | null;
  getTranslatedReason: (reason: string) => string;
  updating?: boolean;
  onUpdateStatus?: (newStatus: ReviewStatus) => void;
}

const THEME: Record<'Đã duyệt' | 'Chờ duyệt' | 'Vi phạm', {
  background: string;
  border: string;
  color: string;
}> = {
  'Đã duyệt': { background: '#f6ffed', border: '#b7eb8f', color: '#389e0d' },
  'Chờ duyệt': { background: '#fffbe6', border: '#ffe58f', color: '#d48806' },
  'Vi phạm': { background: '#fff1f0', border: '#ffa39e', color: '#cf1322' },
};

/** Banner trạng thái đánh giá kèm khu vực đổi trạng thái (dùng chung cho đánh giá địa điểm & lịch trình) */
export const ReviewStatusBanner: React.FC<ReviewStatusBannerProps> = ({
  status,
  violationReason,
  getTranslatedReason,
  updating = false,
  onUpdateStatus,
}) => {
  if (!status || status === 'Đã ẩn') return null;

  const theme = THEME[status];

  return (
    <div
      className="rd-status-banner"
      style={{ background: theme.background, border: `1px solid ${theme.border}` }}
    >
      <p className="rd-panel-title" style={{ color: theme.color }}>Trạng thái</p>

      {onUpdateStatus && (
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
