import React from 'react';
import './AuthLayout.css';
import { Compass } from 'lucide-react';

interface AuthLayoutProps {
  children: React.ReactNode;
}

export const AuthLayout: React.FC<AuthLayoutProps> = ({ children }) => {
  return (
    <div className="auth-container">
      {/* Sidebar - Left Side */}
      <div className="auth-sidebar">
        {/* Background Image Overlay */}
        <div 
          className="auth-sidebar-bg" 
          style={{ backgroundImage: `url('/src/assets/images/login-bg.png')` }}
        />
        
        {/* Logo */}
        <div className="auth-logo">
          <Compass size={24} />
          <span>Travel Service Provider</span>
        </div>

        {/* Sidebar Content */}
        <div className="auth-sidebar-content">
          <h1 className="auth-sidebar-title">Mở rộng mạng lưới du lịch của bạn</h1>
          <p className="auth-sidebar-desc">
            Kết nối với hàng triệu khách du lịch và quản lý dịch vụ của bạn một cách chuyên nghiệp nhất.
          </p>
        </div>

        {/* Sidebar Footer */}
        <div className="auth-sidebar-footer">
          © 2024 Travel Portal Inc. • <span>Privacy Policy</span> • <span>Terms of Service</span>
        </div>
      </div>

      {/* Main Content Area - Right Side */}
      <div className="auth-content-wrapper">
        <div className="auth-content">
          {children}
        </div>
      </div>
    </div>
  );
};
