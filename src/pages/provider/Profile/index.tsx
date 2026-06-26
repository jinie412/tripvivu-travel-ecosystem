import React, { useState, useEffect, useRef } from 'react';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import { Upload, Eye, EyeOff, Loader2 } from 'lucide-react';
import apiClient from '../../../utils/apiClient';
import Swal from 'sweetalert2';

const ProfilePage: React.FC = () => {
  const [isPasswordChangeEnabled, setIsPasswordChangeEnabled] = useState(true);
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

  // 1. Khởi tạo State chứa dữ liệu người dùng
  const [profileData, setProfileData] = useState({
    fullName: '',
    email: '',
    phone: '',
    identityCard: '',
    dob: '',
    address: '',
    avatarUrl: '',
  });
  const defaultAvatar =
    'https://media.istockphoto.com/id/1477583639/vector/user-profile-icon-vector-avatar-or-person-icon-profile-picture-portrait-symbol-vector.jpg?s=612x612&w=0&k=20&c=OWGIPPkZIWLPvnQS14ZSyHMoGtVTn1zS8cAgLy1Uh24=';

  // 2. Gọi API khi trang vừa render
  useEffect(() => {
    const fetchProfile = async () => {
      try {
        // apiClient sẽ tự động gắn Token vào header
        const response = await apiClient.get('/business/profile/me');
        const data = response.data;

        // Làm sạch dữ liệu: Nếu giá trị là null hoặc undefined, ép thành chuỗi rỗng ''
        setProfileData({
          fullName: data.fullName || '',
          email: data.email || '',
          phone: data.phone || '',
          identityCard: data.identityCard || '',
          dob: data.dob || '',
          address: data.address || '',
          avatarUrl: data.avatarUrl || '',
        });
      } catch (error) {
        console.error('Lỗi khi lấy thông tin hồ sơ:', error);
        Swal.fire({
          icon: 'error',
          title: 'Lỗi',
          text: 'Không thể tải thông tin. Phiên đăng nhập có thể đã hết hạn.',
        });
      } finally {
        setIsLoading(false);
      }
    };

    fetchProfile();
  }, []);

  // Xử lý khi người dùng chọn file ảnh mới
  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Tính năng Preview: Hiển thị ngay ảnh vừa chọn
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

      // Gửi FormData lên NestJS, trình duyệt tự sinh boundary multipart/form-data
      const response = await apiClient.post('/upload/avatar', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      // Nhận URL trả về và cập nhật lại Avatar (để đảm bảo lấy URL xịn từ Cloudflare)
      const newAvatarUrl = response.data.url || response.data;
      setProfileData((prev) => ({ ...prev, avatarUrl: newAvatarUrl }));

      // Update localStorage (tuỳ chọn) để Header cũng được cập nhật ngay ảnh mới
      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        parsedUser.avatarUrl = newAvatarUrl;
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
      // Nếu muốn bạn có thể khôi phục lại previewUrl về avatar mặc định ở đây
    } finally {
      setIsUploading(false);
    }
  };

  // Hàm xử lý khi người dùng gõ vào ô Input
  const handleInputChange = (field: string, value: string) => {
    setProfileData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  // Hiển thị màn hình chờ trong lúc gọi API
  if (isLoading) {
    return <div style={{ textAlign: 'center', padding: '50px' }}>Đang tải dữ liệu hồ sơ...</div>;
  }

  const handleSaveProfile = async () => {
    setIsSaving(true);
    setFormErrors([]); // Xóa các lỗi cũ trên màn hình mỗi khi bắt đầu gửi request mới

    const localErrors: string[] = [];

    // Kiểm tra khớp mật khẩu
    if (isPasswordChangeEnabled && (passwords.newPassword || passwords.confirmNewPassword)) {
      if (passwords.newPassword !== passwords.confirmNewPassword) {
        localErrors.push('Mật khẩu mới và Xác nhận mật khẩu không khớp!');
      }
      if (passwords.oldPassword && passwords.oldPassword === passwords.newPassword) {
        localErrors.push('Mật khẩu mới không được trùng với mật khẩu hiện tại!');
      }
      // Bạn có thể thêm validation độ dài mật khẩu ở đây nếu muốn
      if (passwords.newPassword.length < 6) {
        localErrors.push('Mật khẩu mới phải có ít nhất 6 ký tự.');
      }
    }

    // Nếu có lỗi ở Frontend thì dừng lại và hiển thị
    if (localErrors.length > 0) {
      setFormErrors(localErrors);
      setIsSaving(false);
      // Scroll lên đầu trang để người dùng thấy lỗi
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }

    try {
      const updatePayload: any = {
        fullName: profileData.fullName,
        phone: profileData.phone,
        identityCard: profileData.identityCard,
        dob: profileData.dob,
        address: profileData.address,
      };

      if (isPasswordChangeEnabled && passwords.oldPassword && passwords.newPassword) {
        updatePayload.oldPassword = passwords.oldPassword;
        updatePayload.newPassword = passwords.newPassword;
      }

      const response = await apiClient.patch('/business/profile/me', updatePayload);

      // Xử lý lưu localStorage cho profile (giữ nguyên của bạn)
      const storedUser = localStorage.getItem('userInfo');
      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        const updatedUser = { ...parsedUser, ...updatePayload };
        // Xóa thuộc tính password trước khi lưu vào localStorage cho an toàn
        delete updatedUser.oldPassword;
        delete updatedUser.newPassword;
        localStorage.setItem('userInfo', JSON.stringify(updatedUser));
      }

      if (updatePayload.newPassword) {
        Swal.fire({
          icon: 'success',
          title: 'Thành công',
          text: 'Cập nhật hồ sơ và đổi mật khẩu thành công! Vui lòng đăng nhập lại.',
          confirmButtonColor: '#3b82f6',
        }).then(() => {
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
        <h2 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '32px', fontFamily: '"Outfit", sans-serif' }}>Thông tin cá nhân</h2>

        <div
          style={{
            background: 'white',
            borderRadius: '24px',
            overflow: 'hidden',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
            border: '1px solid #F1F5F9',
          }}>
          <div style={{ padding: '32px' }}>
            {/* 2. PHẦN AVATAR ĐÃ ĐƯỢC CẬP NHẬT */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '24px', marginBottom: '48px' }}>
              <div style={{ width: '120px', height: '120px', borderRadius: '50%', overflow: 'hidden', border: '4px solid #F8FAFC' }}>
                {/* Gắn link ảnh từ State, nếu rỗng thì xài ảnh mặc định */}
                <img
                  src={profileData.avatarUrl || defaultAvatar}
                  alt="Avatar cá nhân"
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
              <div>
                <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '8px', fontFamily: '"Outfit", sans-serif' }}>Ảnh đại diện</h4>
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
            {/* HIỂN THỊ KHUNG LỖI NẾU CÓ */}
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

            {/* 3. Đổ dữ liệu State vào các Input */}
            <div style={{ marginBottom: '48px' }}>
              <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '24px', fontFamily: '"Outfit", sans-serif' }}>Thông tin cơ bản</h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '24px' }}>
                <Input label="Họ và tên" value={profileData.fullName} onChange={(e) => handleInputChange('fullName', e.target.value)} />
                <div style={{ opacity: 0.7 }}>
                  <Input label="Email" value={profileData.email} disabled style={{ background: '#F8FAFC' }} />
                </div>
                <Input label="Số điện thoại" value={profileData.phone} onChange={(e) => handleInputChange('phone', e.target.value)} />
                <Input
                  label="Căn cước công dân"
                  value={profileData.identityCard}
                  onChange={(e) => handleInputChange('identityCard', e.target.value)}
                />
                <Input type="date" label="Ngày sinh" value={profileData.dob} onChange={(e) => handleInputChange('dob', e.target.value)} />
                <Input label="Địa chỉ" value={profileData.address} onChange={(e) => handleInputChange('address', e.target.value)} />
              </div>
            </div>

            {/* Change Password Section */}
            <div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
                <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--text-primary)', fontFamily: '"Outfit", sans-serif' }}>Đổi mật khẩu</h4>
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

          {/* Footer Actions */}
          <div
            style={{
              background: '#F8FAFC',
              padding: '20px 32px',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '16px',
              borderTop: '1px solid #F1F5F9',
            }}>
            <Button variant="outline" style={{ background: 'white', borderColor: '#E2E8F0', color: '#64748b' }}>
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

export default ProfilePage;
