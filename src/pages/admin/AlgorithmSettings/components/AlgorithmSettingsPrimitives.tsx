import React from 'react';
import { ChevronDown, Info, RotateCcw } from 'lucide-react';

export const Tip: React.FC<{ text: string }> = ({ text }) => (
  <span className="as-tooltip">
    <Info size={13} className="as-tooltip__icon" />
    <span className="as-tooltip__bubble">{text}</span>
  </span>
);

interface CardProps {
  title: string;
  badge?: string;
  open: boolean;
  onToggle: () => void;
  onSave: () => void;
  onReset: () => void;
  saveDisabled?: boolean;
  saveLabel?: string;
  resetDisabled?: boolean;
  children: React.ReactNode;
}

export const AccordionCard: React.FC<CardProps> = ({
  title,
  badge,
  open,
  onToggle,
  onSave,
  onReset,
  saveDisabled = false,
  saveLabel = 'Lưu thay đổi',
  resetDisabled = false,
  children,
}) => (
  <div className={`as-card${open ? ' as-card--open' : ''}`}>
    <button className="as-card__header" type="button" onClick={onToggle}>
      <span className="as-card__title">
        {title}
        {badge && <span className="as-card__badge">{badge}</span>}
      </span>
      <ChevronDown size={16} className={`as-card__chevron${open ? ' as-card__chevron--open' : ''}`} />
    </button>
    {open && (
      <div className="as-card__body">
        {children}
        <div className="as-card__footer">
          <button className="as-btn-ghost" type="button" onClick={onReset} disabled={resetDisabled}>
            <RotateCcw size={13} />
            Khôi phục mặc định
          </button>
          <button className="as-btn-primary" type="button" onClick={onSave} disabled={saveDisabled}>
            {saveLabel}
          </button>
        </div>
      </div>
    )}
  </div>
);

export const AlgoGroup: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
  <div className="as-group">
    <div className="as-group__header">
      <span className="as-group__title">{title}</span>
    </div>
    <div className="as-group__body">{children}</div>
  </div>
);
