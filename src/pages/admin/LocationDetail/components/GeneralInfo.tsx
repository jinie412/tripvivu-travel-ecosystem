import React from 'react';
import { Info, ChevronDown } from 'lucide-react';
import { LocationDetailInfo } from '../../../../types/location';

interface GeneralInfoProps {
  location: LocationDetailInfo;
}

const splitDescriptionSentences = (description: string): string[] => {
  return description
    .match(/[^.!?。！？]+[.!?。！？]+|[^.!?。！？]+$/g)
    ?.map((sentence) => sentence.trim())
    .filter(Boolean) ?? [];
};

export const GeneralInfo: React.FC<GeneralInfoProps> = ({ location }) => {
  const [isDescriptionExpanded, setIsDescriptionExpanded] = React.useState(false);
  const description = (location.description || '').trim();
  const hasDescription = Boolean(description) && description !== 'Không có mô tả.';
  const sentences = hasDescription ? splitDescriptionSentences(description) : [];
  const shouldShowMore = hasDescription && (sentences.length > 3 || description.length > 360);
  const visibleDescription = shouldShowMore && !isDescriptionExpanded
    ? sentences.slice(0, 3).join(' ')
    : description;

  React.useEffect(() => {
    setIsDescriptionExpanded(false);
  }, [location.id, description]);

  return (
    <div className="ld-card mb-24">
      <div className="ld-card-header">
        <div className="ld-card-title-group">
          <Info size={18} className="ld-icon-primary" />
          <h3 className="ld-card-title">Thông tin chung</h3>
        </div>
      </div>

      <div className="ld-form-grid">
        <div className="ld-form-group">
          <label className="ld-label">Tên địa điểm</label>
          <input type="text" className="ld-input" value={location.name} readOnly />
        </div>

        <div className="ld-form-group">
          <label className="ld-label">Danh mục</label>
          <div className="ld-select-wrapper">
            <select className="ld-select" value={location.category || ''} disabled>
              <option value={location.category || ''}>{location.category || 'Chưa có danh mục'}</option>
            </select>
            <ChevronDown size={16} className="ld-select-icon" />
          </div>
        </div>

        <div className="ld-form-group full-width">
          <div className="ld-description-header">
            <label className="ld-label">Mô tả giới thiệu</label>
            {shouldShowMore && (
              <button
                type="button"
                className="ld-description-toggle"
                onClick={() => setIsDescriptionExpanded((current) => !current)}>
                <span>{isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm'}</span>
                <ChevronDown className={`ld-description-icon ${isDescriptionExpanded ? 'is-open' : ''}`} size={14} />
              </button>
            )}
          </div>
          <div className="ld-textarea-read ld-textarea-expanded">
            {hasDescription ? visibleDescription : 'Không có mô tả.'}
          </div>
        </div>

        <div className="ld-form-group">
          <label className="ld-label">Số điện thoại</label>
          <div className="ld-input-icon-wrapper">
            <span className="ld-input-icon">📞</span>
            <input type="text" className="ld-input pl-32" value={location.phone || ''} readOnly />
          </div>
        </div>

        <div className="ld-form-group">
          <label className="ld-label">Email liên hệ</label>
          <div className="ld-input-icon-wrapper">
            <span className="ld-input-icon">✉️</span>
            <input type="email" className="ld-input pl-32" value={location.email || ''} readOnly />
          </div>
        </div>
      </div>
    </div>
  );
};
