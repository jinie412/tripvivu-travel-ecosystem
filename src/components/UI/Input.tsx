import React, { forwardRef } from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  icon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  readOnly?: boolean;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, icon, rightIcon, fullWidth = true, className, style, ...props }, ref) => {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px', width: '100%' }}>
        {label && <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)' }}>{label}</label>}
        <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
          {icon && (
            <div style={{ position: 'absolute', left: '12px', color: 'var(--text-secondary)', display: 'flex' }}>
              {icon}
            </div>
          )}
          <input
            ref={ref}
            {...props}
            style={{
              width: '100%',
              padding: '14px 16px',
              paddingLeft: icon ? '40px' : '16px',
              paddingRight: rightIcon ? '40px' : '16px',
              borderRadius: '12px',
              border: `1px solid ${error ? '#ef4444' : 'var(--border-color)'}`,
              background: '#fcfcfc',
              fontSize: '15px',
              outline: 'none',
              transition: 'border-color 0.2s, box-shadow 0.2s',
              color: 'var(--text-primary)',
              ...style
            }}
            className={className}
          />
          {rightIcon && (
            <div style={{ position: 'absolute', right: '12px', color: 'var(--text-secondary)', display: 'flex', cursor: 'pointer' }}>
              {rightIcon}
            </div>
          )}
        </div>
        {error && <span style={{ fontSize: '12px', color: '#ef4444', marginTop: '4px' }}>{error}</span>}
      </div>
    );
  }
);

Input.displayName = 'Input';

export default Input;
