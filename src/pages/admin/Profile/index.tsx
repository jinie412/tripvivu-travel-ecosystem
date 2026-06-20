import React, { useState, useEffect, useRef } from 'react';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { Upload, Eye, EyeOff, Loader2 } from 'lucide-react';
import apiClient from '../../../utils/apiClient';
import Swal from 'sweetalert2';

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

  const [profileData, setProfileData] = useState({
    fullName: '',
    email: '',
    phone: '',
    avatarUrl: '',
  });
  
  const defaultAvatar =
    'https://media.istockphoto.com/id/1477583639/vector/user-profile-icon-vector-avatar-or-person-icon-profile-picture-portrait-symbol-vector.jpg?s=612x612&w=0&k=20&c=OWGIPPkZIWLPvnQS14ZSyHMoGtVTn1zS8cAgLy1Uh24=';

  useEffect(() => {
    // Tải thông tin từ localStorage
    const storedUser = localStorage.getItem('userInfo');
    if (storedUser) {
      const parsedUser = JSON.parse(storedUser);
      setProfileData({
        fullName: parsedUser.fullName || '',
        email: parsedUser.email || '',
        phone: parsedUser.phone || '',
        avatarUrl: parsedUser.avatar_url || '',
      });
    }
    setIsLoading(false);
  }, []);

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const previewUrl = URL.createObjectURL(file);
    setProfileData((prev) => ({ ...prev, avatarUrl: previewUrl }));

    setIsUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);

      const storedUser = localStorage.getItem('userInfo');
      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        if (parsedUser.id) formData.append('userId', parsedUser.id);
      }

      const response = await apiClient.post('/upload/avatar', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      const newAvatarUrl = response.data.url || response.data;
      setProfileData((prev) => ({ ...prev, avatarUrl: newAvatarUrl }));

      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        parsedUser.avatar_url = newAvatarUrl;
        localStorage.setItem('userInfo', JSON.stringify(parsedUser));
        window.dispatchEvent(new Event('userUpdated'));
      }

      Swal.fire({
        icon: 'success',
        title: 'Thành công',
        text: 'Tải ảnh đại diện lên thành công!',
        timer: 1000,
        showConfirmButton: false,
      });
    } catch (error) {
      console.error('Lỗi khi tải ảnh:', error);
      Swal.fire({
        icon: 'error',
        title: 'Lỗi',
        text: 'Có lỗi xảy ra khi tải ảnh lên. Khôi phục lại ảnh cũ.',
      });
    } finally {
      setIsUploading(false);
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
        avatarUrl: profileData.avatarUrl,
      };

      await apiClient.patch('/admin/users/profile/me', updatePayload);

      const storedUser = localStorage.getItem('userInfo');
      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        const updatedUser = { 
          ...parsedUser, 
          fullName: updatePayload.fullName,
          phone: updatePayload.phone,
          avatar_url: updatePayload.avatarUrl,
        };
        localStorage.setItem('userInfo', JSON.stringify(updatedUser));
        window.dispatchEvent(new Event('userUpdated'));
      }

      // 2. Cập nhật mật khẩu nếu có
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
      <div style={{ maxWidth: '1000px', margin: '0 auto' }}>
        <h2 style={{ fontSize: '24px', fontWeight: '800', color: '#1e293b', marginBottom: '32px' }}>Hồ sơ Admin</h2>

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
                <h4 style={{ fontSize: '18px', fontWeight: '800', color: '#1e293b', marginBottom: '8px' }}>Ảnh đại diện</h4>
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
                <h4 style={{ margin: '0 0 8px 0', fontSize: '14px', fontWeight: 'bold' }}>Vui lòng kiểm tra lại các thông tin sau:</h4>
                <ul style={{ margin: 0, paddingLeft: '20px', fontSize: '14px' }}>
                  {formErrors.map((err, index) => (
                    <li key={index}>{err}</li>
                  ))}
                </ul>
              </div>
            )}

            <div style={{ marginBottom: '48px' }}>
              <h4 style={{ fontSize: '16px', fontWeight: '800', color: '#1e293b', marginBottom: '24px' }}>Thông tin cơ bản</h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '24px' }}>
                <Input label="Họ và tên" value={profileData.fullName} onChange={(e) => handleInputChange('fullName', e.target.value)} />
                <div style={{ opacity: 0.7 }}>
                  <Input label="Email" value={profileData.email} disabled style={{ background: '#F8FAFC' }} />
                </div>
                <Input label="Số điện thoại" value={profileData.phone} onChange={(e) => handleInputChange('phone', e.target.value)} />
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
                <h4 style={{ fontSize: '16px', fontWeight: '800', color: '#1e293b' }}>Đổi mật khẩu</h4>
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
                    type={showNewPassword ? 'text' : 'password'}
                    value={passwords.confirmNewPassword}
                    onChange={(e) => setPasswords({ ...passwords, confirmNewPassword: e.target.value })}
                    rightIcon={
                      <div style={{ cursor: 'pointer', display: 'flex' }} onClick={() => setShowNewPassword(!showNewPassword)}>
                        {showNewPassword ? <EyeOff size={20} /> : <Eye size={20} />}
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
            <Button variant="outline" style={{ background: 'white', borderColor: '#E2E8F0', color: '#64748b' }} onClick={() => window.history.back()}>
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
