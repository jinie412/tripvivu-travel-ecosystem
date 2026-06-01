import React, { useEffect, useState, useCallback, useMemo } from 'react';
import { User, UserStatsInfo } from '../../../types/user';
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
  const [usersLoading, setUsersLoading] = useState<boolean>(true);
  const [statsLoading, setStatsLoading] = useState<boolean>(true);
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

  const [refreshKey, setRefreshKey] = useState(0);

  // Set<string> cho O(1) lookup trong UserTable thay vì O(n) Array.includes
  const selectedSet = useMemo(() => new Set(selectedRows), [selectedRows]);

  // --- HANDLERS ---
  const handleSelectAll = useCallback(
    (checked: boolean) => {
      setSelectedRows(checked ? users.map((u) => u.id) : []);
    },
    [users],
  );

  const handleSelectRow = useCallback((id: string, checked: boolean) => {
    setSelectedRows((prev) => (checked ? [...prev, id] : prev.filter((r) => r !== id)));
  }, []);

  const handleSearch = useCallback((term: string) => {
    setSearchTerm(term);
    setCurrentPage(1);
  }, []);

  const handleRoleChange = useCallback((role: string) => {
    setRoleFilter(role);
    setCurrentPage(1);
  }, []);

  const handleActiveStatusChange = useCallback((status: string) => {
    setActiveStatusFilter(status);
    setCurrentPage(1);
  }, []);

  const handleDeleteStatusChange = useCallback((status: string) => {
    setDeleteStatusFilter(status);
    setCurrentPage(1);
  }, []);

  const handleToggleLock = useCallback(async (id: string, name: string, currentStatus: string) => {
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
      setRefreshKey((old) => old + 1);
    } catch (error) {
      console.error(`Lỗi khi ${actionText} tài khoản:`, error);
      await Swal.fire({
        title: 'Lỗi!',
        text: `Có lỗi xảy ra khi ${actionText} tài khoản.`,
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    }
  }, []);

  const handleBulkDelete = useCallback(async () => {
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
  }, [selectedRows]);

  // Stats chỉ fetch lại khi có mutation (refreshKey), không phụ thuộc filter/page
  useEffect(() => {
    setStatsLoading(true);
    apiClient
      .get('/admin/users/stats')
      .then((res) => setStats(res.data?.data || res.data))
      .catch((err) => console.error('Lỗi khi tải thống kê:', err))
      .finally(() => setStatsLoading(false));
  }, [refreshKey]);

  // User list fetch lại mỗi khi filter/page thay đổi
  useEffect(() => {
    setUsersLoading(true);
    apiClient
      .get('/admin/users', {
        params: {
          page: currentPage,
          limit: itemsPerPage,
          ...(searchTerm && { search: searchTerm }),
          ...(roleFilter && { role: roleFilter }),
          ...(activeStatusFilter && { activeStatus: activeStatusFilter }),
          ...(deleteStatusFilter && { deleteStatus: deleteStatusFilter }),
        },
      })
      .then((res) => {
        setUsers(res.data.data);
        setTotalItems(res.data.meta.totalItems);
      })
      .catch((err) => console.error('Lỗi khi tải danh sách người dùng:', err))
      .finally(() => setUsersLoading(false));
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
        <UserStats stats={stats} loading={statsLoading} />

        <div className="card tab-container">
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
            loading={usersLoading}
            selectedSet={selectedSet}
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
