import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'outline' | 'ghost';
}

export const Button: React.FC<ButtonProps> = ({ 
  children, 
  variant = 'primary', 
  style, 
  ...props 
}) => {
  const getStyles = (): React.CSSProperties => {
    const base: React.CSSProperties = {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '12px 24px',
      borderRadius: '12px',
      fontSize: '14px',
      fontWeight: '700',
      cursor: 'pointer',
      transition: 'all 0.2s ease',
      border: 'none',
      ...style
    };

    if (variant === 'primary') {
      return {
        ...base,
        background: '#3b82f6',
        color: 'white',
        boxShadow: '0 4px 6px -1px rgba(59, 130, 246, 0.2)'
      };
    }

    if (variant === 'outline') {
      return {
        ...base,
        background: 'transparent',
        border: '1px solid #e2e8f0',
        color: '#475569'
      };
    }

    if (variant === 'ghost') {
      return {
        ...base,
        background: 'transparent',
        color: '#64748b'
      };
    }

    return base;
  };

  return (
    <button style={getStyles()} {...props}>
      {children}
    </button>
  );
};

export default Button;
