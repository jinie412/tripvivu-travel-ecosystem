import React, { useState, useCallback, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient, keepPreviousData } from '@tanstack/react-query';
import { User, UserStatsInfo } from '../../../types/user';
import { UserStats } from './components/UserStats';
import { UserFilter } from './components/UserFilter';
import { UserTable } from './components/UserTable';
import { Bell, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import apiClient from '../../../utils/apiClient';
import Swal from 'sweetalert2';
import { AdminHeaderProfile } from '../../../components/AdminHeaderProfile';
import { NotificationBell } from '../../../components/NotificationBell';
import './UserManagement.css';

const ITEMS_PER_PAGE = 10;

const fetchUserStats = (): Promise<UserStatsInfo> =>
  apiClient.get('/admin/users/stats').then((r) => r.data?.data ?? r.data);

const fetchUsers = (params: {
  page: number;
  search: string;
  role: string;
  activeStatus: string;
}) =>
  apiClient
    .get('/admin/users', {
      params: {
        page: params.page,
        limit: ITEMS_PER_PAGE,
        ...(params.search && { search: params.search }),
        ...(params.role && { role: params.role }),
        ...(params.activeStatus && { activeStatus: params.activeStatus }),
      },
    })
    .then((r) => r.data);

export const UserManagement: React.FC = () => {
  const queryClient = useQueryClient();
  const [selectedRows, setSelectedRows] = useState<string[]>([]);

  // --- PAGINATION STATE ---
  const [currentPage, setCurrentPage] = useState<number>(1);

  // --- FILTER STATE ---
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [activeStatusFilter, setActiveStatusFilter] = useState<string>('');

  // Set<string> cho O(1) lookup trong UserTable thay vì O(n) Array.includes
  const selectedSet = useMemo(() => new Set(selectedRows), [selectedRows]);

  // --- QUERIES ---

  // Stats: cache 5 phút, ít thay đổi
  const { data: stats, isLoading: statsLoading } = useQuery<UserStatsInfo>({
    queryKey: ['admin', 'user-stats'],
    queryFn: fetchUserStats,
    staleTime: 5 * 60 * 1000,
  });

  // User list: cache 2 phút, giữ data cũ khi đổi trang/filter (placeholderData)
  const { data: usersData, isLoading: usersLoading, isFetching: usersFetching } = useQuery({
    queryKey: ['admin', 'users', { page: currentPage, searchTerm, roleFilter, activeStatusFilter }],
    queryFn: () =>
      fetchUsers({ page: currentPage, search: searchTerm, role: roleFilter, activeStatus: activeStatusFilter }),
    staleTime: 2 * 60 * 1000,
    placeholderData: keepPreviousData,
  });

  const users: User[] = usersData?.data ?? [];
  const totalItems: number = usersData?.meta?.totalItems ?? 0;
  const totalPages: number = usersData?.meta?.totalPages ?? 1;

  // --- MUTATIONS ---

  const toggleLockMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      apiClient.patch(`/admin/users/${id}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'user-stats'] });
    },
  });

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

  const handleToggleLock = useCallback(
    async (id: string, name: string, currentStatus: string) => {
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
        await toggleLockMutation.mutateAsync({ id, status: newStatus });
        await Swal.fire({
          title: 'Thành công!',
          text: `Đã ${actionText} tài khoản thành công.`,
          icon: 'success',
          confirmButtonColor: '#3b82f6',
        });
      } catch {
        await Swal.fire({
          title: 'Lỗi!',
          text: `Có lỗi xảy ra khi ${actionText} tài khoản.`,
          icon: 'error',
          confirmButtonColor: '#3b82f6',
        });
      }
    },
    [toggleLockMutation],
  );

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
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'user-stats'] });
    } catch (error) {
      console.error('Lỗi khi xóa hàng loạt:', error);
      await Swal.fire({
        title: 'Lỗi!',
        text: 'Có lỗi xảy ra khi xóa dữ liệu.',
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    }
  }, [selectedRows, queryClient]);

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
          <NotificationBell />

          <AdminHeaderProfile />

          <Link to="/admin/users/add" className="btn-primary">
            <Plus size={18} />
            <span>Thêm người dùng</span>
          </Link>
        </div>
      </header>

      <div className="page-content">
        <UserStats stats={stats ?? null} loading={statsLoading} />

        <div className="card tab-container">
          <UserFilter
            selectedCount={selectedRows.length}
            onBulkDelete={handleBulkDelete}
            onSearch={handleSearch}
            onRoleChange={handleRoleChange}
            onActiveStatusChange={handleActiveStatusChange}
            currentRole={roleFilter}
            currentActiveStatus={activeStatusFilter}
          />

          <UserTable
            users={users}
            loading={usersLoading}
            isFetching={usersFetching}
            selectedSet={selectedSet}
            onToggleLock={handleToggleLock}
            onSelectRow={handleSelectRow}
            onSelectAll={handleSelectAll}
            currentPage={currentPage}
            totalItems={totalItems}
            totalPages={totalPages}
            itemsPerPage={ITEMS_PER_PAGE}
            onPageChange={setCurrentPage}
          />
        </div>
      </div>
    </div>
  );
};
