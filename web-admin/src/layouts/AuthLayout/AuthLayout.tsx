import React from 'react';

interface AuthLayoutProps {
  children: React.ReactNode;
  bgImage?: string;
  slogan?: string;
  subSlogan?: string;
}

const AuthLayout: React.FC<AuthLayoutProps> = ({ 
  children, 
  bgImage = '/assets/background.png',
  slogan = "Mở rộng mạng lưới du lịch của bạn",
  subSlogan = "Kết nối với hàng triệu khách du lịch và quản lý dịch vụ của bạn một cách chuyên nghiệp nhất."
}) => {
  return (
    <div style={{ display: 'flex', minHeight: '100vh', width: '100vw', overflowX: 'hidden' }}>
      {/* Left Decoration / Slogan Section */}
      <div style={{ 
        flex: 1.1, 
        position: 'relative', 
        display: 'flex', 
        flexDirection: 'column',
        alignItems: 'flex-start',
        justifyContent: 'center',
        padding: '60px',
        color: 'white',
        overflow: 'hidden',
        background: `linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0.2)), url(${bgImage}) center center / cover no-repeat`,
        borderRadius: '0 32px 32px 0',
        margin: '12px'
      }}>
        {/* Logo and Brand */}
        <div style={{ position: 'absolute', top: '40px', left: '40px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{ width: '40px', height: '40px', background: 'rgba(255, 255, 255, 0.2)', backdropFilter: 'blur(8px)', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-compass"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>
          </div>
          <span style={{ fontSize: '18px', fontWeight: '700', letterSpacing: '0.5px' }}>Travel Service Provider</span>
        </div>

        {/* Content Section */}
        <div style={{ maxWidth: '85%', marginTop: 'auto', marginBottom: '80px', zIndex: 1 }}>
          <h1 style={{ fontSize: '48px', fontWeight: '800', lineHeight: '1.2', marginBottom: '24px' }}>
            {slogan}
          </h1>
          <p style={{ fontSize: '18px', opacity: 0.9, lineHeight: '1.6', fontWeight: '400' }}>
            {subSlogan}
          </p>
        </div>

        {/* Footer Section */}
        <div style={{ position: 'absolute', bottom: '40px', left: '40px', display: 'flex', gap: '20px', fontSize: '13px', opacity: 0.8 }}>
          <span>© 2024 Travel Portal Inc.</span>
          <span>•</span>
          <a href="#" style={{ color: 'white' }}>Privacy Policy</a>
          <span>•</span>
          <a href="#" style={{ color: 'white' }}>Terms of Service</a>
        </div>
      </div>

      {/* Right Form Section */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '40px' }}>
        <div style={{ maxWidth: '440px', width: '100%', display: 'flex', flexDirection: 'column' }}>
          {children}
        </div>
      </div>
    </div>
  );
};

export default AuthLayout;
