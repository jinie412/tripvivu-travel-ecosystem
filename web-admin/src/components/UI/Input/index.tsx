import React from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement | HTMLTextAreaElement> {
  label?: string;
  icon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  multiline?: boolean;
}

export const Input: React.FC<InputProps> = ({ 
  label, 
  icon, 
  rightIcon, 
  multiline = false, 
  style, 
  ...props 
}) => {
  const containerStyle: React.CSSProperties = {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
    marginBottom: '24px',
    width: '100%'
  };

  const labelStyle: React.CSSProperties = {
    fontSize: '14px',
    fontWeight: '600',
    color: '#0f172a'
  };

  const inputWrapperStyle: React.CSSProperties = {
    position: 'relative',
    display: 'flex',
    alignItems: 'center',
    background: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '12px',
    transition: 'all 0.2s ease',
    overflow: 'hidden'
  };

  const inputStyle: React.CSSProperties = {
    width: '100%',
    padding: '14px 16px',
    paddingLeft: icon ? '48px' : '16px',
    paddingRight: rightIcon ? '48px' : '16px',
    border: 'none',
    background: 'transparent',
    outline: 'none',
    fontSize: '15px',
    color: '#1e293b',
    ...style
  };

  const iconStyle: React.CSSProperties = {
    position: 'absolute',
    left: '16px',
    color: '#94a3b8',
    display: 'flex',
    alignItems: 'center'
  };

  const rightIconStyle: React.CSSProperties = {
    position: 'absolute',
    right: '16px',
    color: '#94a3b8',
    display: 'flex',
    alignItems: 'center'
  };

  return (
    <div style={containerStyle}>
      {label && <label style={labelStyle}>{label}</label>}
      <div style={inputWrapperStyle}>
        {icon && <div style={iconStyle}>{icon}</div>}
        {multiline ? (
          <textarea style={{ ...inputStyle, minHeight: '100px' }} {...(props as React.TextareaHTMLAttributes<HTMLTextAreaElement>)} />
        ) : (
          <input style={inputStyle} {...(props as React.InputHTMLAttributes<HTMLInputElement>)} />
        )}
        {rightIcon && <div style={rightIconStyle}>{rightIcon}</div>}
      </div>
    </div>
  );
};

export default Input;
