import { Bell } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { AdminHeaderProfile } from '../../../../components/AdminHeaderProfile';

export const DetailHeader: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="detail-header-container">
      <div className="breadcrumb">
        <span 
          className="breadcrumb-link" 
          onClick={() => navigate('/admin/users')}
        >
          Quản lý người dùng
        </span>
        <span className="separator">&gt;</span>
        <span className="current">Thông tin người dùng</span>
      </div>
      
      <div className="header-actions">
        <button className="icon-btn">
          <Bell size={20} />
        </button>
        <AdminHeaderProfile showName />
      </div>
    </div>
  );
};
