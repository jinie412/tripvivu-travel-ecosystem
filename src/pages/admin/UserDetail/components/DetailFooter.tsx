import React from 'react';

import { useNavigate } from 'react-router-dom';

interface DetailFooterProps {
  onSave?: () => void;
  isSaving?: boolean;
}

export const DetailFooter: React.FC<DetailFooterProps> = ({ onSave, isSaving = false }) => {
  const navigate = useNavigate();

  return (
    <div className="fixed-footer">
      <div className="footer-actions">
        <button className="btn-ghost" onClick={() => navigate('/admin/users')}>
          Huỷ bỏ
        </button>
        <button className="btn-primary" onClick={onSave} disabled={isSaving}>
          {isSaving ? 'Đang lưu...' : 'Lưu thay đổi'}
        </button>
      </div>
    </div>
  );
};
