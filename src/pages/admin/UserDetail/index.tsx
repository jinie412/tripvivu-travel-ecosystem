import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { DetailHeader } from './components/DetailHeader';
import { ProfileCard } from './components/ProfileCard';
import { PersonalInfoCard } from './components/PersonalInfoCard';
import { DetailFooter } from './components/DetailFooter';
import { Lock, Unlock } from 'lucide-react';
import { User } from '../../../types/user';
import apiClient from '../../../utils/apiClient';
import Swal from 'sweetalert2';
import './UserDetail.css';

export const UserDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const queryClient = useQueryClient();
  const [isUpdating, setIsUpdating] = useState(false);

  // --- QUERY ---
  const { data: user, isLoading: loading } = useQuery<User>({
    queryKey: ['admin', 'user-detail', id],
    queryFn: () => apiClient.get(`/admin/users/${id}`).then((r) => r.data),
    staleTime: 2 * 60 * 1000,
    enabled: !!id,
    // Seed ngay từ cache của trang danh sách — render tức thì khi click
    placeholderData: () => {
      const cached = queryClient.getQueriesData<{ data: User[] }>({
        queryKey: ['admin', 'users'],
      });
      for (const [, queryData] of cached) {
        const found = queryData?.data?.find((u) => u.id === id);
        if (found) return found;
      }
      return undefined;
    },
  });

  // --- MUTATION: toggle lock/unlock ---
  const toggleStatusMutation = useMutation({
    mutationFn: (newStatus: 'ACTIVE' | 'LOCKED') =>
      apiClient.patch(`/admin/users/${id}/status`, { status: newStatus }),
    onSuccess: (_data, newStatus) => {
      // Cập nhật cache detail ngay, không cần refetch
      queryClient.setQueryData<User>(['admin', 'user-detail', id], (old) =>
        old ? { ...old, activeStatus: newStatus } : old,
      );
      // Invalidate list để đồng bộ trạng thái khi quay lại
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
    },
  });

  // --- HANDLERS ---

  const handleUpdateUser = async (updateData: Partial<User>) => {
    if (!id) return;
    setIsUpdating(true);
    try {
      await apiClient.patch(`/admin/users/${id}`, updateData);
      // Cập nhật cache thay vì setState
      queryClient.setQueryData<User>(['admin', 'user-detail', id], (old) =>
        old ? { ...old, ...updateData } : old,
      );
      Swal.fire({
        title: 'Thành công!',
        text: 'Cập nhật thông tin thành công!',
        icon: 'success',
        confirmButtonColor: '#3b82f6',
      });
    } catch (error: any) {
      console.error('Lỗi khi cập nhật:', error);
      const errorMessage = error.response?.data?.message || 'Có lỗi xảy ra khi lưu thông tin.';
      Swal.fire({
        title: 'Cập nhật thất bại',
        text: Array.isArray(errorMessage) ? errorMessage[0] : errorMessage,
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    } finally {
      setIsUpdating(false);
    }
  };

  const handleToggleStatus = async (newStatus: 'ACTIVE' | 'LOCKED') => {
    if (!id) return;
    const result = await Swal.fire({
      title: newStatus === 'LOCKED' ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?',
      text:
        newStatus === 'LOCKED'
          ? 'Bạn có chắc chắn muốn KHÓA tài khoản này? Người dùng sẽ không thể đăng nhập.'
          : 'Bạn có chắc chắn muốn MỞ KHÓA tài khoản này?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: newStatus === 'LOCKED' ? '#ef4444' : '#3b82f6',
      cancelButtonColor: '#94a3b8',
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
    });

    if (!result.isConfirmed) return;

    try {
      await toggleStatusMutation.mutateAsync(newStatus);
      Swal.fire({
        title: 'Thành công!',
        text: `Đã ${newStatus === 'LOCKED' ? 'khóa' : 'mở khóa'} tài khoản thành công!`,
        icon: 'success',
        confirmButtonColor: '#3b82f6',
      });
    } catch {
      Swal.fire({
        title: 'Lỗi!',
        text: 'Có lỗi xảy ra, không thể thay đổi trạng thái.',
        icon: 'error',
        confirmButtonColor: '#3b82f6',
      });
    }
  };

  if (loading) {
    return (
      <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-muted)' }}>
        Đang tải dữ liệu người dùng...
      </div>
    );
  }

  if (!user) {
    return (
      <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-muted)' }}>
        Không tìm thấy người dùng.
      </div>
    );
  }

  const isMutating = isUpdating || toggleStatusMutation.isPending;

  return (
    <div className="detail-page-container">
      <DetailHeader />

      <div className="detail-content-wrapper">
        <h1 className="detail-page-title">Thông tin người dùng</h1>

        <div className="profile-section">
          <ProfileCard user={user} onUpdate={handleUpdateUser} isUpdating={isMutating} />
        </div>

        <div>
          <PersonalInfoCard user={user} onUpdate={handleUpdateUser} isUpdating={isMutating} />
        </div>

        <div style={{ marginTop: '24px', display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: '8px' }}>
          <button
            className={`btn ${user.activeStatus === 'ACTIVE' ? 'btn-danger' : 'btn-primary'}`}
            onClick={() => handleToggleStatus(user.activeStatus === 'ACTIVE' ? 'LOCKED' : 'ACTIVE')}
            disabled={isMutating}
            style={{ width: 'fit-content', display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '12px 24px', borderRadius: '8px', fontWeight: 600, border: 'none', cursor: 'pointer', color: 'white', backgroundColor: user.activeStatus === 'ACTIVE' ? '#ef4444' : '#3b82f6' }}>
            {user.activeStatus === 'ACTIVE' ? <Lock size={18} /> : <Unlock size={18} />}
            {user.activeStatus === 'ACTIVE' ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
          </button>
          <p style={{ fontSize: '0.875rem', color: '#64748b', fontStyle: 'italic', margin: 0 }}>
            {user.activeStatus === 'ACTIVE'
              ? 'Người dùng sẽ không thể đăng nhập cho đến khi được mở khoá.'
              : 'Người dùng có thể đăng nhập lại bình thường sau khi mở khóa.'}
          </p>
        </div>
      </div>

      <DetailFooter />
    </div>
  );
};
