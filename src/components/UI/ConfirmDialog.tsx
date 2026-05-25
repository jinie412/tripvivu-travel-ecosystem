import React from 'react';
import ReactDOM from 'react-dom';
import Button from './Button';

interface ConfirmDialogProps {
  message: string;
  confirmLabel?: string;
  confirmColor?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  message,
  confirmLabel = 'Xác nhận',
  confirmColor,
  onConfirm,
  onCancel,
}) => {
  return ReactDOM.createPortal(
    <div
      style={{
        position: 'fixed', inset: 0,
        background: 'rgba(0,0,0,0.45)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 9999,
      }}
      onClick={onCancel}
    >
      <div
        style={{
          background: 'white', borderRadius: '20px',
          padding: '32px', width: '380px',
          boxShadow: '0 24px 48px rgba(0,0,0,0.18)',
        }}
        onClick={e => e.stopPropagation()}
      >
        <h4 style={{ fontSize: '18px', fontWeight: '800', color: '#1e293b', marginBottom: '10px' }}>
          Xác nhận thao tác
        </h4>
        <p style={{ fontSize: '14px', color: '#64748b', marginBottom: '28px', lineHeight: '1.6' }}>
          {message}
        </p>
        <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
          <Button variant="outline" onClick={onCancel} style={{ borderRadius: '10px', padding: '10px 20px' }}>
            Hủy
          </Button>
          <Button
            onClick={onConfirm}
            style={{ borderRadius: '10px', padding: '10px 24px', ...(confirmColor ? { background: confirmColor } : {}) }}
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  );
};

export default ConfirmDialog;
