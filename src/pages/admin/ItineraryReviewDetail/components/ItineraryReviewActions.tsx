import React from 'react';
import { CheckCircle, AlertTriangle } from 'lucide-react';
import { ItineraryReview } from '../../../../types/review';

interface ItineraryReviewActionsProps {
  status: ItineraryReview['status'];
  onUpdateStatus: (newStatus: ItineraryReview['status']) => void;
}

export const ItineraryReviewActions: React.FC<ItineraryReviewActionsProps> = ({
  status,
  onUpdateStatus,
}) => {
  return (
    <div className="rd-actions-container">
      <div
        className="rd-classification-selector"
        style={{ background: '#f8fafc', borderStyle: 'solid', borderColor: 'var(--border-color)' }}
      >
        <p className="rd-selector-label" style={{ color: 'var(--text-secondary)' }}>
          Thay đổi trạng thái:
        </p>
        <div className="rd-selector-options">
          <button
            className={`rd-opt-btn ${status === 'Đã duyệt' ? 'active' : ''}`}
            onClick={() => onUpdateStatus('Đã duyệt')}
          >
            <CheckCircle size={16} />
            <span>Đã duyệt</span>
          </button>
          <button
            className={`rd-opt-btn ${status === 'Vi phạm' ? 'active' : ''}`}
            onClick={() => onUpdateStatus('Vi phạm')}
            style={
              status === 'Vi phạm'
                ? {
                    background: 'linear-gradient(135deg, #ef4444, #dc2626)',
                    boxShadow: '0 4px 12px rgba(220, 38, 38, 0.25)',
                  }
                : {}
            }
          >
            <AlertTriangle size={16} />
            <span>Vi phạm</span>
          </button>
        </div>
      </div>
    </div>
  );
};
