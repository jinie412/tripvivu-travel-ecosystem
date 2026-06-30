import React, { useState, useEffect, useRef } from 'react';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { Upload, Eye, EyeOff, Loader2 } from 'lucide-react';
import apiClient from '../../../utils/apiClient';
import Swal from 'sweetalert2';
import axios from 'axios';

const AdminProfilePage: React.FC = () => {
  const [isPasswordChangeEnabled, setIsPasswordChangeEnabled] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [formErrors, setFormErrors] = useState<string[]>([]);
  const [passwords, setPasswords] = useState({
    oldPassword: '',
    newPassword: '',
    confirmNewPassword: '',
  });

  const [showOldPassword, setShowOldPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [profileData, setProfileData] = useState({
    fullName: '',
    email: '',
    phone: '',

    dateOfBirth: '',

    avatarUrl: '',
  });

  const defaultAvatar =
    'https://media.istockphoto.com/id/1477583639/vector/user-profile-icon-vector-avatar-or-person-icon-profile-picture-portrait-symbol-vector.jpg?s=612x612&w=0&k=20&c=OWGIPPkZIWLPvnQS14ZSyHMoGtVTn1zS8cAgLy1Uh24=';
  const bodyFont = '"Plus Jakarta Sans", "Outfit", sans-serif';
  const headingFont = '"Outfit", "Plus Jakarta Sans", sans-serif';

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const response = await apiClient.get('/admin/users/profile/me');
        const data = response.data;

        setProfileData({
          fullName: data.fullName || '',
          email: data.email || '',
          phone: data.phone || data.phoneNumber || '',
          dateOfBirth: data.dateOfBirth ? data.dateOfBirth.slice(0, 10) : '',

          avatarUrl: data.avatarUrl || data.avatar_url || '',
        });
      } catch (error) {
        console.error('Lỗi khi lấy thông tin hồ sơ Admin:', error);
        Swal.fire({
          icon: 'error',
          title: 'Lỗi',
          text: 'Không thể tải thông tin hồ sơ. Phiên đăng nhập có thể đã hết hạn.',
        });
      } finally {
        setIsLoading(false);
      }
    };

    fetchProfile();
  }, []);

  const updateStoredUser = (updates: Record<string, unknown>) => {
    const storage = localStorage.getItem('userInfo') ? localStorage : sessionStorage;
    const storedUser = storage.getItem('userInfo');
    if (!storedUser) return;

    const parsedUser = JSON.parse(storedUser);
    storage.setItem('userInfo', JSON.stringify({ ...parsedUser, ...updates }));
    window.dispatchEvent(new Event('userUpdated'));
  };

  const extractAvatarUrl = (data: any) =>
    data?.url ||
    data?.avatarUrl ||
    data?.avatar_url ||
    data?.data?.url ||
    data?.data?.avatarUrl ||
    data?.data?.avatar_url ||
    (typeof data === 'string' ? data : '');

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      Swal.fire({
        icon: 'warning',
        title: 'File không hợp lệ',
        text: 'Vui lòng chọn đúng file hình ảnh.',
      });
      event.target.value = '';
      return;
    }

    if (file.size > 2 * 1024 * 1024) {
      Swal.fire({
        icon: 'warning',
        title: 'Ảnh quá lớn',
        text: 'Vui lòng chọn ảnh có dung lượng tối đa 2MB.',
      });
      event.target.value = '';
      return;
    }

    const previousAvatarUrl = profileData.avatarUrl;
    const previewUrl = URL.createObjectURL(file);
    setProfileData((prev) => ({ ...prev, avatarUrl: previewUrl }));

    setIsUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await apiClient.post('/upload/avatar-draft', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      const newAvatarUrl = extractAvatarUrl(response.data);
      if (!newAvatarUrl) {
        throw new Error('Upload thành công nhưng server không trả về URL ảnh.');
      }

      setProfileData((prev) => ({ ...prev, avatarUrl: newAvatarUrl }));
      URL.revokeObjectURL(previewUrl);

      Swal.fire({
        icon: 'success',
        title: 'Ảnh đã sẵn sàng',
        text: 'Nhấn "Lưu thay đổi" để cập nhật ảnh đại diện.',
        timer: 1500,
        showConfirmButton: false,
      });
    } catch (error) {
      URL.revokeObjectURL(previewUrl);
      setProfileData((prev) => ({ ...prev, avatarUrl: previousAvatarUrl }));

      const errorMessage = axios.isAxiosError(error)
        ? error.response?.data?.message || error.response?.data?.error || error.message
        : error instanceof Error
          ? error.message
          : 'Không xác định được nguyên nhân.';

      console.error('Chi tiết lỗi upload avatar:', errorMessage);
      console.error('Lỗi khi tải ảnh:', error);

      Swal.fire({
        icon: 'error',
        title: 'Lỗi',
        text: 'Có lỗi xảy ra khi tải ảnh lên. Khôi phục lại ảnh cũ.',
      });
    } finally {
      setIsUploading(false);
      event.target.value = '';
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setProfileData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  if (isLoading) {
    return <div style={{ textAlign: 'center', padding: '50px' }}>Đang tải dữ liệu hồ sơ...</div>;
  }

  const handleSaveProfile = async () => {
    setIsSaving(true);
    setFormErrors([]);

    const localErrors: string[] = [];

    if (isPasswordChangeEnabled && (passwords.newPassword || passwords.confirmNewPassword)) {
      if (!passwords.oldPassword) {
        localErrors.push('Vui lòng nhập mật khẩu hiện tại.');
      }
      if (passwords.newPassword !== passwords.confirmNewPassword) {
        localErrors.push('Mật khẩu mới và Xác nhận mật khẩu không khớp!');
      }
      if (passwords.oldPassword && passwords.oldPassword === passwords.newPassword) {
        localErrors.push('Mật khẩu mới không được trùng với mật khẩu hiện tại!');
      }
      if (passwords.newPassword.length < 6) {
        localErrors.push('Mật khẩu mới phải có ít nhất 6 ký tự.');
      }
    }

    if (localErrors.length > 0) {
      setFormErrors(localErrors);
      setIsSaving(false);
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }

    try {
      // 1. Cập nhật thông tin profile
      const updatePayload = {
        fullName: profileData.fullName,
        phone: profileData.phone,
        dateOfBirth: profileData.dateOfBirth || null,
        avatarUrl: profileData.avatarUrl,
      };

      await apiClient.patch('/admin/users/profile/me', updatePayload);

      updateStoredUser({
        fullName: updatePayload.fullName,
        phone: updatePayload.phone,
        dateOfBirth: updatePayload.dateOfBirth,
        avatarUrl: updatePayload.avatarUrl,
        avatar_url: updatePayload.avatarUrl,
      });

      // update password
      if (isPasswordChangeEnabled && passwords.oldPassword && passwords.newPassword) {
        await apiClient.put('/auth/change-password', {
          currentPassword: passwords.oldPassword,
          newPassword: passwords.newPassword,
        });

        Swal.fire({
          icon: 'success',
          title: 'Thành công',
          text: 'Cập nhật hồ sơ và đổi mật khẩu thành công! Vui lòng đăng nhập lại.',
          confirmButtonColor: '#3b82f6',
        }).then(() => {
          localStorage.removeItem('token');
          localStorage.removeItem('accessToken');
          localStorage.removeItem('userInfo');
          window.location.href = '/login';
        });
      } else {
        Swal.fire({
          icon: 'success',
          title: 'Thành công',
          text: 'Cập nhật hồ sơ thành công!',
          confirmButtonColor: '#3b82f6',
        });
      }
    } catch (error: any) {
      console.error('Lỗi khi cập nhật hồ sơ:', error);
      if (error.response?.data?.message) {
        const backendMessages = error.response.data.message;
        setFormErrors(Array.isArray(backendMessages) ? backendMessages : [backendMessages]);
        window.scrollTo({ top: 0, behavior: 'smooth' });
      } else {
        setFormErrors(['Có lỗi xảy ra khi kết nối. Vui lòng kiểm tra lại.']);
      }
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <>
      <div style={{ maxWidth: '1000px', margin: '0 auto', fontFamily: bodyFont }}>
        <h2 style={{ fontSize: '24px', fontWeight: '700', color: '#1e293b', marginBottom: '32px', fontFamily: headingFont }}>
          Hồ sơ Admin
        </h2>

        <div
          style={{
            background: 'white',
            borderRadius: '24px',
            overflow: 'hidden',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
            border: '1px solid #F1F5F9',
          }}>
          <div style={{ padding: '32px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '24px', marginBottom: '48px' }}>
              <div style={{ width: '120px', height: '120px', borderRadius: '50%', overflow: 'hidden', border: '4px solid #F8FAFC' }}>
                <img
                  src={profileData.avatarUrl || defaultAvatar}
                  alt="Avatar cá nhân"
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
              <div>
                <h4 style={{ fontSize: '18px', fontWeight: '700', color: '#1e293b', marginBottom: '8px', fontFamily: headingFont }}>
                  Ảnh đại diện
                </h4>
                <p style={{ fontSize: '14px', color: '#64748b', marginBottom: '16px' }}>
                  Tải lên ảnh mới để thay đổi diện mạo hồ sơ của bạn.
                </p>
                <input type="file" ref={fileInputRef} onChange={handleFileChange} accept="image/*" style={{ display: 'none' }} />
                <Button
                  variant="outline"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={isUploading}
                  style={{ padding: '8px 16px', fontSize: '13px', borderRadius: '10px', gap: '8px' }}>
                  {isUploading ? <Loader2 size={16} className="animate-spin" /> : <Upload size={16} />}
                  {isUploading ? 'Đang tải lên...' : 'Thay đổi ảnh'}
                </Button>
              </div>
            </div>

            {formErrors.length > 0 && (
              <div
                style={{
                  background: '#FEE2E2',
                  border: '1px solid #F87171',
                  color: '#B91C1C',
                  padding: '16px',
                  borderRadius: '12px',
                  marginBottom: '24px',
                }}>
                <h4 style={{ margin: '0 0 8px 0', fontSize: '14px', fontWeight: '700', fontFamily: headingFont }}>
                  Vui lòng kiểm tra lại các thông tin sau:
                </h4>
                <ul style={{ margin: 0, paddingLeft: '20px', fontSize: '14px' }}>
                  {formErrors.map((err, index) => (
                    <li key={index}>{err}</li>
                  ))}
                </ul>
              </div>
            )}

            <div style={{ marginBottom: '48px' }}>
              <h4 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '24px', fontFamily: headingFont }}>
                Thông tin cơ bản
              </h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '24px' }}>
                <Input label="Họ và tên" value={profileData.fullName} onChange={(e) => handleInputChange('fullName', e.target.value)} />
                <div style={{ opacity: 0.7 }}>
                  <Input label="Email" value={profileData.email} disabled style={{ background: '#F8FAFC' }} />
                </div>
                <Input label="Số điện thoại" value={profileData.phone} onChange={(e) => handleInputChange('phone', e.target.value)} />
                <Input
                  label="Ngày sinh"
                  type="date"
                  value={profileData.dateOfBirth}
                  onChange={(e) => handleInputChange('dateOfBirth', e.target.value)}
                />
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
                <h4 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', fontFamily: headingFont }}>Đổi mật khẩu</h4>
                <div
                  onClick={() => setIsPasswordChangeEnabled(!isPasswordChangeEnabled)}
                  style={{
                    width: '44px',
                    height: '24px',
                    background: isPasswordChangeEnabled ? '#3b82f6' : '#E2E8F0',
                    borderRadius: '12px',
                    position: 'relative',
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                  }}>
                  <div
                    style={{
                      position: 'absolute',
                      left: isPasswordChangeEnabled ? '24px' : '4px',
                      top: '4px',
                      width: '16px',
                      height: '16px',
                      background: 'white',
                      borderRadius: '50%',
                      transition: 'all 0.2s ease',
                    }}></div>
                </div>
              </div>

              {isPasswordChangeEnabled && (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '24px' }}>
                  <Input
                    label="Mật khẩu hiện tại"
                    placeholder="********"
                    type={showOldPassword ? 'text' : 'password'}
                    value={passwords.oldPassword}
                    onChange={(e) => setPasswords({ ...passwords, oldPassword: e.target.value })}
                    rightIcon={
                      <div style={{ cursor: 'pointer', display: 'flex' }} onClick={() => setShowOldPassword(!showOldPassword)}>
                        {showOldPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                      </div>
                    }
                  />
                  <Input
                    label="Mật khẩu mới"
                    placeholder="Nhập mật khẩu mới"
                    type={showNewPassword ? 'text' : 'password'}
                    value={passwords.newPassword}
                    onChange={(e) => setPasswords({ ...passwords, newPassword: e.target.value })}
                    rightIcon={
                      <div style={{ cursor: 'pointer', display: 'flex' }} onClick={() => setShowNewPassword(!showNewPassword)}>
                        {showNewPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                      </div>
                    }
                  />
                  <Input
                    label="Xác nhận mật khẩu mới"
                    placeholder="Nhập mật khẩu mới"
                    type={showConfirmPassword ? 'text' : 'password'}
                    value={passwords.confirmNewPassword}
                    onChange={(e) => setPasswords({ ...passwords, confirmNewPassword: e.target.value })}
                    rightIcon={
                      <div style={{ cursor: 'pointer', display: 'flex' }} onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                        {showConfirmPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                      </div>
                    }
                  />
                </div>
              )}
            </div>
          </div>

          <div
            style={{
              background: '#F8FAFC',
              padding: '20px 32px',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '16px',
              borderTop: '1px solid #F1F5F9',
            }}>
            <Button
              variant="outline"
              style={{ background: 'white', borderColor: '#E2E8F0', color: '#64748b' }}
              onClick={() => window.history.back()}>
              Hủy bỏ
            </Button>
            <Button style={{ padding: '12px 32px' }} onClick={handleSaveProfile} disabled={isSaving}>
              {isSaving ? 'Đang lưu...' : 'Lưu thay đổi'}
            </Button>
          </div>
        </div>
      </div>
    </>
  );
};

export default AdminProfilePage;
