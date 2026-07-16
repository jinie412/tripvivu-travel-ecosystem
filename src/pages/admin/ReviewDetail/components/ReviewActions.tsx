import React, { useEffect, useState } from 'react';
import { Review } from '../../../../types/review';
import { Clock, Calendar, Info } from 'lucide-react';

interface ReviewActionsProps {
  classification: Review['classification'];
  hasContent?: boolean;
  onUpdateClassification: (newType: 'Ngắn hạn' | 'Dài hạn') => Promise<void> | void;
}

/** Footer action: Chọn phân loại đánh giá (Ngắn hạn / Dài hạn) */
export const ReviewActions: React.FC<ReviewActionsProps> = ({
  classification,
  hasContent = true,
  onUpdateClassification,
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

  const disabled = updatingType || !hasContent;

  return (
    <div className="rd-classification-selector">
      <p className="rd-panel-title rd-panel-title-with-tip" style={{ color: '#0369a1' }}>
        <span>Phân loại</span>
        <span className="rd-info-tip" tabIndex={0} aria-label="Định nghĩa phân loại đánh giá">
          <Info size={14} />
          <span className="rd-info-popover">
            <strong>Ngắn hạn:</strong> đánh giá mô tả trải nghiệm một lần cụ thể, có thể là trường hợp ngoại lệ, không đại diện cho mọi lần.
            <br />
            <strong>Dài hạn:</strong> đánh giá mô tả đặc điểm thường trực của địa điểm.
          </span>
        </span>
      </p>
      <div className="rd-toggle-group">
        <button
          className={`rd-toggle-btn rd-toggle-btn--info ${updatingType ? 'rd-toggle-btn--updating' : ''} ${selectedType === 'Ngắn hạn' ? 'active' : ''}`}
          disabled={disabled}
          onClick={() => handleTypeSelect('Ngắn hạn')}
        >
          <Clock size={15} />
          <span>Ngắn hạn</span>
        </button>
        <button
          className={`rd-toggle-btn rd-toggle-btn--info ${updatingType ? 'rd-toggle-btn--updating' : ''} ${selectedType === 'Dài hạn' ? 'active' : ''}`}
          disabled={disabled}
          onClick={() => handleTypeSelect('Dài hạn')}
        >
          <Calendar size={15} />
          <span>Dài hạn</span>
        </button>
      </div>
    </div>
  );
};
