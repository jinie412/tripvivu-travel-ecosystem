import React, { useEffect, useState, useCallback } from 'react';
import { User, UserStatsInfo } from '../../../types/user';
import { userAPI } from '../../../services/userAPI';
import { UserStats } from './components/UserStats';
import { UserFilter } from './components/UserFilter';
import { UserTable } from './components/UserTable';
import { Bell, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import apiClient from '../../../utils/apiClient';
import Swal from 'sweetalert2';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import './UserManagement.css';

export const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [stats, setStats] = useState<UserStatsInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedRows, setSelectedRows] = useState<string[]>([]);

  // --- PAGINATION STATE ---
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalItems, setTotalItems] = useState<number>(0);
  const itemsPerPage = 10;

  // --- FILTER STATE ---
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [activeStatusFilter, setActiveStatusFilter] = useState<string>('');
  const [deleteStatusFilter, setDeleteStatusFilter] = useState<string>('');

  // Thêm State này để kích hoạt load lại bảng
  const [refreshKey, setRefreshKey] = useState(0);

  // --- HANDLERS ---
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedRows(users.map((u) => u.id));
    } else {
      setSelectedRows([]);
    }
  };

  const handleSelectRow = (id: string, checked: boolean) => {
    if (checked) {
      setSelectedRows((prev) => [...prev, id]);
    } else {
      setSelectedRows((prev) => prev.filter((r) => r !== id));
    }
  };

  const handleSearch = useCallback((term: string) => {
    setSearchTerm(term);
    setCurrentPage(1);
  }, []);

  const handleRoleChange = (role: string) => {
    setRoleFilter(role);
    setCurrentPage(1);
  };

  const handleActiveStatusChange = (status: string) => {
    setActiveStatusFilter(status);
    setCurrentPage(1);
  };

  const handleDeleteStatusChange = (status: string) => {
    setDeleteStatusFilter(status);
    setCurrentPage(1);
  };

  // 2. Hàm xử lý Khóa/Mở khóa tài khoản (Truyền hàm này xuống UserTable)
  const handleToggleLock = async (id: string, name: string, currentStatus: string) => {
    const isLocking = currentStatus === 'ACTIVE';
    const actionText = isLocking ? 'khóa' : 'mở khóa';
    const newStatus = isLocking ? 'LOCKED' : 'ACTIVE';

    const result = await Swal.fire({
      title: `${isLocking ? 'Khóa' : 'Mở khóa'} tài khoản?`,
      text: `Bạn có chắc chắn muốn ${actionText} tài khoản "${name}"?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: isLocking ? '#ef4444' : '#22c55e',
      cancelButtonColor: '#94a3b8',
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
    });

    if (!result.isConfirmed) return;

    try {
      await apiClient.patch(`/admin/users/${id}/status`, { status: newStatus });

      await Swal.fire({
        title: 'Thành công!',
        text: `Đã ${actionText} tài khoản thành công.`,
        icon: 'success',
        confirmButtonColor: '#3b82f6',
      });
      setRefreshKey((old) => old + 1); // Kích hoạt load lại bảng
    } catch (error) {
      console.error(`Lỗi khi ${actionText} tài khoản:`, error);
      await Swal.fire({
        title: 'Lỗi!',
        text: `Có lỗi xảy ra khi ${actionText} tài khoản.`,
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    }
  };
  const handleBulkDelete = async () => {
    if (selectedRows.length === 0) return;

    const result = await Swal.fire({
      title: 'Xóa hàng loạt?',
      text: `Bạn có chắc chắn muốn xóa ${selectedRows.length} tài khoản đã chọn?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#94a3b8',
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
    });

    if (!result.isConfirmed) return;

    try {
      // Lưu ý: Với Axios, truyền body cho method DELETE phải bọc trong config "data"
      await apiClient.delete('/admin/users/bulk', {
        data: { userIds: selectedRows },
      });

      await Swal.fire({
        title: 'Thành công!',
        text: `Đã xóa thành công ${selectedRows.length} tài khoản.`,
        icon: 'success',
        confirmButtonColor: '#3b82f6',
      });

      setSelectedRows([]);
      setRefreshKey((old) => old + 1);
    } catch (error) {
      console.error('Lỗi khi xóa hàng loạt:', error);
      await Swal.fire({
        title: 'Lỗi!',
        text: 'Có lỗi xảy ra khi xóa dữ liệu.',
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    }
  };

  // --- API CALL ---
  useEffect(() => {
    const fetchUserPageData = async () => {
      setLoading(true);
      try {
        const [statsResponse, usersResponse] = await Promise.all([
          // Sửa chỗ này: Thay userAPI.getUserStats() bằng apiClient
          apiClient.get('/admin/users/stats'),
          apiClient.get('/admin/users', {
            params: {
              page: currentPage,
              limit: itemsPerPage,
              ...(searchTerm && { search: searchTerm }),
              ...(roleFilter && { role: roleFilter }),
              ...(activeStatusFilter && { activeStatus: activeStatusFilter }),
              ...(deleteStatusFilter && { deleteStatus: deleteStatusFilter }),
            },
          }),
        ]);

        // Xử lý việc Backend có thể bọc response trong .data hay không
        const statsData = statsResponse.data?.data || statsResponse.data;
        setStats(statsData); // Gán data vào state stats
        setUsers(usersResponse.data.data);
        setTotalItems(usersResponse.data.meta.totalItems);
      } catch (error) {
        console.error('Lỗi khi tải dữ liệu:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchUserPageData();
  }, [currentPage, searchTerm, roleFilter, activeStatusFilter, deleteStatusFilter, refreshKey]);

  return (
    <div className="page-container">
      <header className="page-header">
        <div className="header-titles">
          <h1 className="page-title">Quản lý người dùng</h1>
          <div className="breadcrumb">
            <span className="text-muted">Quản lý</span> /{' '}
            <Link to="/admin/users" className="active-bread">
              Người dùng
            </Link>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn">
            <Bell size={20} />
          </button>

          <AdminHeaderProfile />

          <Link to="/admin/users/add" className="btn-primary">
            <Plus size={18} />
            <span>Thêm người dùng</span>
          </Link>
        </div>
      </header>

      <div className="page-content">
        <UserStats stats={stats} loading={loading} />

        <div className="card tab-container">
          {/* TRUYỀN CÁC HÀM VÀ STATE XUỐNG USERFILTER */}
          <UserFilter
            selectedCount={selectedRows.length}
            onBulkDelete={handleBulkDelete}
            onSearch={handleSearch}
            onRoleChange={handleRoleChange}
            onActiveStatusChange={handleActiveStatusChange}
            onDeleteStatusChange={handleDeleteStatusChange}
            currentRole={roleFilter}
            currentActiveStatus={activeStatusFilter}
            currentDeleteStatus={deleteStatusFilter}
          />

          <UserTable
            users={users}
            loading={loading}
            selectedRows={selectedRows}
            onToggleLock={handleToggleLock}
            onSelectRow={handleSelectRow}
            onSelectAll={handleSelectAll}
            currentPage={currentPage}
            totalItems={totalItems}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
          />
        </div>
      </div>
    </div>
  );
};
