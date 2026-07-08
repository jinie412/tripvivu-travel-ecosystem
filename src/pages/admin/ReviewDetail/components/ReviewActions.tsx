import React, { useEffect, useState } from 'react';
import { Review } from '../../../../types/review';
import { Clock, Calendar, CheckCircle, AlertTriangle, Info } from 'lucide-react';

interface ReviewActionsProps {
  status: Review['status'];
  classification: Review['classification'];
  hasContent?: boolean;
  onUpdateClassification: (newType: 'Ngắn hạn' | 'Dài hạn') => Promise<void> | void;
  onUpdateStatus: (newStatus: Review['status']) => void;
}

/** Footer actions: Chọn phân loại & Trạng thái */
export const ReviewActions: React.FC<ReviewActionsProps> = ({ 
  status,
  classification, 
  hasContent = true,
  onUpdateClassification,
  onUpdateStatus
}) => {
  const [selectedType, setSelectedType] = useState<'Ngắn hạn' | 'Dài hạn' | null>(
    (classification === 'Ngắn hạn' || classification === 'Dài hạn') ? classification : null
  );
  const [updatingType, setUpdatingType] = useState(false);

  useEffect(() => {
    setSelectedType((classification === 'Ngắn hạn' || classification === 'Dài hạn') ? classification : null);
  }, [classification]);

  const handleTypeSelect = async (type: 'Ngắn hạn' | 'Dài hạn') => {
    if (updatingType || selectedType === type) return;
    const previousType = selectedType;
    setSelectedType(type);
    setUpdatingType(true);
    try {
      await onUpdateClassification(type);
    } catch {
      setSelectedType(previousType);
    } finally {
      setUpdatingType(false);
    }
  };

  return (
    <div className="rd-actions-container">
      {/* Cập nhật Trạng thái */}
      {status !== 'Đã ẩn' && (
        <div className="rd-classification-selector" style={{ background: '#f8fafc', borderStyle: 'solid', borderColor: 'var(--border-color)' }}>
          <p className="rd-selector-label" style={{ color: 'var(--text-secondary)' }}>Thay đổi trạng thái:</p>
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
              style={status === 'Vi phạm' ? { background: 'linear-gradient(135deg, #ef4444, #dc2626)', boxShadow: '0 4px 12px rgba(220, 38, 38, 0.25)' } : {}}
            >
              <AlertTriangle size={16} />
              <span>Vi phạm</span>
            </button>
          </div>
        </div>
      )}

      {/* Cập nhật Phân loại */}
      {hasContent && (
        <div className="rd-classification-selector">
          <p className="rd-selector-label rd-selector-label-with-tip">
            <span>Phân loại đánh giá:</span>
            <span className="rd-info-tip" tabIndex={0} aria-label="Định nghĩa phân loại đánh giá">
              <Info size={14} />
              <span className="rd-info-popover">
                <strong>Ngắn hạn:</strong> đánh giá mô tả trải nghiệm một lần cụ thể, có thể là trường hợp ngoại lệ, không đại diện cho mọi lần.
                <br />
                <strong>Dài hạn:</strong> đánh giá mô tả đặc điểm thường trực của địa điểm.
              </span>
            </span>
          </p>
          <div className="rd-selector-options">
            <button 
              className={`rd-opt-btn ${selectedType === 'Ngắn hạn' ? 'active' : ''}`}
              disabled={updatingType}
              onClick={() => handleTypeSelect('Ngắn hạn')}
            >
              <Clock size={16} />
              <span>Ngắn hạn</span>
            </button>
            <button 
              className={`rd-opt-btn ${selectedType === 'Dài hạn' ? 'active' : ''}`}
              disabled={updatingType}
              onClick={() => handleTypeSelect('Dài hạn')}
            >
              <Calendar size={16} />
              <span>Dài hạn</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
