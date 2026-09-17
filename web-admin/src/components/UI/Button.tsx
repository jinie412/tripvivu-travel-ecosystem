import React from 'react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Helper for tailwind class merging (if using tailwind)
// Note: User doesn't want tailwind by default, but I'll use it for logic if needed.
// However, I'll stick to CSS classes or CSS modules if preferred.
// For now, I'll use simple class merging.

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  fullWidth?: boolean;
}

const Button: React.FC<ButtonProps> = ({ 
  children, 
  variant = 'primary', 
  fullWidth = false, 
  className, 
  ...props 
}) => {
  const getVariantStyles = () => {
    switch (variant) {
      case 'primary':
        return {
          background: 'var(--secondary-blue)',
          color: 'white',
          boxShadow: '0 4px 6px -1px rgb(37 99 235 / 0.1), 0 2px 4px -2px rgb(37 99 235 / 0.1)'
        };
      case 'outline':
        return {
          background: 'transparent',
          border: '1px solid var(--border-color)',
          color: 'var(--text-primary)'
        };
      case 'ghost':
        return {
          background: 'transparent',
          color: 'var(--text-secondary)'
        };
      case 'secondary':
        return {
          background: 'var(--light-gray)',
          color: 'var(--text-primary)',
          border: '1px solid var(--medium-gray)'
        };
      default:
        return {};
    }
  };

  return (
    <button
      {...props}
      style={{
        padding: '12px 24px',
        borderRadius: '8px',
        fontWeight: '600',
        fontSize: '15px',
        transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '8px',
        width: fullWidth ? '100%' : 'auto',
        cursor: props.disabled ? 'not-allowed' : 'pointer',
        opacity: props.disabled ? 0.6 : 1,
        ...getVariantStyles(),
        ...(props.style as React.CSSProperties)
      }}
      className={className}
    >
      {children}
    </button>
  );
};

export default Button;
