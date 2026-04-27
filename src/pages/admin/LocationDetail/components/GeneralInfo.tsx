import React, { useState } from 'react';
import { Info, ChevronDown } from 'lucide-react';
import { LocationDetailInfo } from '../../../../types/location';

interface GeneralInfoProps {
  location: LocationDetailInfo;
}

export const GeneralInfo: React.FC<GeneralInfoProps> = ({ location }) => {
  const [isDescriptionExpanded, setIsDescriptionExpanded] = useState(false);

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
          <label className="ld-label">TÊN ĐỊA ĐIỂM</label>
          <input 
            type="text" 
            className="ld-input" 
            value={location.name} 
            readOnly 
          />
        </div>
        
        <div className="ld-form-group">
          <label className="ld-label">DANH MỤC</label>
          <div className="ld-select-wrapper">
            <select 
              className="ld-select" 
              value={location.category} 
              disabled
            >
              <option value="Khách sạn">Khách sạn</option>
              <option value="Nhà hàng">Nhà hàng</option>
              <option value="Cafe">Cafe</option>
              <option value="Di tích">Di tích</option>
              <option value="Giải trí">Giải trí</option>
              <option value="Ẩm thực">Ẩm thực</option>
              <option value="Mua sắm">Mua sắm</option>
              <option value="Du lịch">Du lịch</option>
              <option value="Khác">Khác</option>
            </select>
            <ChevronDown size={16} className="ld-select-icon" />
          </div>
        </div>
        
        <div className="ld-form-group full-width">
          <div className="ld-description-header">
            <label className="ld-label">MÔ TẢ GIỚI THIỆU</label>
            <button
              type="button"
              className="ld-description-toggle"
              onClick={() => setIsDescriptionExpanded((value) => !value)}
              aria-expanded={isDescriptionExpanded}
            >
              <span>{isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm'}</span>
              <ChevronDown
                size={16}
                className={isDescriptionExpanded ? 'ld-description-icon is-open' : 'ld-description-icon'}
              />
            </button>
          </div>
          <div
            className={
              isDescriptionExpanded
                ? 'ld-textarea-read ld-textarea-expanded'
                : 'ld-textarea-read ld-textarea-collapsed'
            }
          >
            {location.description}
          </div>
        </div>
        
        <div className="ld-form-group">
          <label className="ld-label">SỐ ĐIỆN THOẠI</label>
          <div className="ld-input-icon-wrapper">
            <span className="ld-input-icon">📞</span>
            <input 
              type="text" 
              className="ld-input pl-32" 
              value={location.phone || ''} 
              readOnly 
            />
          </div>
        </div>
        
        <div className="ld-form-group">
          <label className="ld-label">EMAIL LIÊN HỆ</label>
          <div className="ld-input-icon-wrapper">
            <span className="ld-input-icon">✉️</span>
            <input 
              type="email" 
              className="ld-input pl-32" 
              value={location.email || ''} 
              readOnly 
            />
          </div>
        </div>
      </div>
    </div>
  );
};
