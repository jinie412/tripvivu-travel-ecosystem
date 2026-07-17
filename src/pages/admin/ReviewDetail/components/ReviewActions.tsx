import React, { useEffect, useState } from 'react';
import { Review } from '../../../../types/review';
import { Clock, Calendar, Info } from 'lucide-react';

interface ReviewActionsProps {
  classification: Review['classification'];
  classificationReason?: string | null;
  predictedTimeLabel?: 'Ngắn hạn' | 'Dài hạn' | null;
  hasContent?: boolean;
  onUpdateClassification: (newType: 'Ngắn hạn' | 'Dài hạn') => Promise<void> | void;
}

/** Footer action: Chọn phân loại đánh giá (Ngắn hạn / Dài hạn) */
export const ReviewActions: React.FC<ReviewActionsProps> = ({
  classification,
  classificationReason,
  predictedTimeLabel,
  hasContent = true,
  onUpdateClassification
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
      {/* Cập nhật Phân loại */}
      {hasContent && (
        <div
          className={`rd-classification-selector ${
            selectedType === 'Dài hạn'
              ? 'rd-classification-selector--long-term'
              : selectedType === 'Ngắn hạn'
                ? 'rd-classification-selector--short-term'
                : 'rd-classification-selector--need-action'
          }`}
        >
          <p className="rd-panel-title rd-panel-title-with-tip">
            <span>Phân loại</span>
            <span className="rd-info-tip" tabIndex={0} aria-label="Định nghĩa phân loại đánh giá">
              <Info size={14} />
              <span className="rd-info-popover">
                <strong>Ngắn hạn:</strong> đánh giá mô tả trải nghiệm hoặc tình trạng tại một thời điểm cụ thể, có thể không đại diện cho địa điểm trong thời gian dài.
                <br />
                <strong>Dài hạn:</strong> đánh giá mô tả đặc điểm ổn định của địa điểm, có tính duy trì hoặc lặp lại theo thời gian.
              </span>
            </span>
          </p>
          <div className="rd-toggle-group">
            <button 
              type="button"
              className={`rd-toggle-btn rd-toggle-btn--short-term ${selectedType === 'Ngắn hạn' ? 'active' : ''}`}
              disabled={updatingType}
              onClick={() => handleTypeSelect('Ngắn hạn')}
            >
              <Clock size={15} />
              <span>Ngắn hạn</span>
            </button>
            <button 
              type="button"
              className={`rd-toggle-btn rd-toggle-btn--long-term ${selectedType === 'Dài hạn' ? 'active' : ''}`}
              disabled={updatingType}
              onClick={() => handleTypeSelect('Dài hạn')}
            >
              <Calendar size={15} />
              <span>Dài hạn</span>
            </button>
          </div>
          {classification === 'Cần xử lý' && (classificationReason || predictedTimeLabel) && (
            <div className="rd-classification-suggestion">
              {classificationReason && (
                <p><strong>Lý do:</strong> {classificationReason}</p>
              )}
              {predictedTimeLabel && (
                <p><strong>Phân loại được đề xuất:</strong> {predictedTimeLabel}</p>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
