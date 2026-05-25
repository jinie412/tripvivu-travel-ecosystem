import React, { useState } from 'react';
import Input from '../../../components/UI/Input';
import Button from '../../../components/UI/Button';
import {
  Clock,
  ArrowRight,
  ArrowLeft,
  MapPin,
  Plus,
  Trash2,
  Edit2,
  Upload,
  Wifi,
  Car,
  Utensils,
  FileSpreadsheet,
  Eye,
  CheckCircle,
  Info,
  ChevronDown,
  RefreshCw,
  Loader2,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { addNewPlace, uploadPlaceImage } from '@/services/order.service';
import * as XLSX from 'xlsx';

const userInfo = localStorage.getItem('userInfo');
const parsedUser = userInfo ? JSON.parse(userInfo) : null;
const VENDOR_ID = parsedUser?.businessId || parsedUser?.id || '';

const AddLocationPage: React.FC = () => {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [fileUploaded, setFileUploaded] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [selectedImages, setSelectedImages] = useState<Array<{ file: File; previewUrl: string }>>([]);

  // Service input state
  const [serviceInput, setServiceInput] = useState({ name: '', description: '' });

  // Menu item input state
  const [menuInput, setMenuInput] = useState({ name: '', description: '', price: '', img: '' });

  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: 'Hà Nội',
    phone: '',
    latitude: 10.77,
    longitude: 106.7,
    types: [] as string[],
    // Tách openingHours thành 2 trường riêng biệt
    openTime: '08:00',
    closeTime: '22:00',
    description: '',
    amenities: [] as { id: string; name: string; description: string; icon: React.ReactNode }[],
    menu: [] as { id: string; name: string; description: string; price: string; img: string }[],
  });

  const businessTypes = [
    { id: 'stay', label: 'Khách sạn/Lưu trú' },
    { id: 'food', label: 'Nhà hàng/Ẩm thực' },
    { id: 'tour', label: 'Tour du lịch' },
    { id: 'trans', label: 'Vận chuyển' },
  ];

  const handleTypeToggle = (typeId: string) => {
    setFormData((prev) => ({
      ...prev,
      types: prev.types.includes(typeId) ? prev.types.filter((t) => t !== typeId) : [...prev.types, typeId],
    }));
  };

  const handleAddService = () => {
    if (!serviceInput.name.trim()) {
      alert('Vui lòng nhập tên dịch vụ');
      return;
    }

    const newService = {
      id: Date.now().toString(),
      name: serviceInput.name,
      description: serviceInput.description,
      icon: <Wifi size={18} />
    };

    setFormData(prev => ({
      ...prev,
      amenities: [...prev.amenities, newService]
    }));

    setServiceInput({ name: '', description: '' });
  };

  const handleRemoveService = (id: string) => {
    setFormData(prev => ({
      ...prev,
      amenities: prev.amenities.filter(a => a.id !== id)
    }));
  };

  const handleAddMenuItem = () => {
    if (!menuInput.name.trim() || !menuInput.price.trim()) {
      alert('Vui lòng nhập tên và giá của món ăn');
      return;
    }

    const newMenuItem = {
      id: Date.now().toString(),
      name: menuInput.name,
      description: menuInput.description,
      price: menuInput.price,
      img: menuInput.img || 'https://via.placeholder.com/56x56'
    };

    setFormData(prev => ({
      ...prev,
      menu: [...prev.menu, newMenuItem]
    }));

    setMenuInput({ name: '', description: '', price: '', img: '' });
  };

  const handleRemoveMenuItem = (id: string) => {
    setFormData(prev => ({
      ...prev,
      menu: prev.menu.filter(m => m.id !== id)
    }));
  };

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files) return;
    const files = Array.from(e.target.files);
    const remaining = 5 - selectedImages.length;
    const toAdd = files.slice(0, remaining).map(file => ({
      file,
      previewUrl: URL.createObjectURL(file),
    }));
    setSelectedImages(prev => [...prev, ...toAdd]);
    e.target.value = '';
  };

  const handleImageRemove = (index: number) => {
    setSelectedImages(prev => {
      URL.revokeObjectURL(prev[index].previewUrl);
      return prev.filter((_, i) => i !== index);
    });
  };

  const handleExcelFileUpload = (file: File) => {
    try {
      const reader = new FileReader();

      reader.onerror = () => {
        console.error('FileReader error:', reader.error);
        alert('Lỗi khi đọc file. Vui lòng thử lại.');
      };

      reader.onload = (e: any) => {
        try {
          const data = e.target.result;
          console.log('📄 File data loaded, size:', data.byteLength, 'bytes');

          // Read Excel workbook
          const workbook = XLSX.read(data, { type: 'array' });
          console.log('📊 Workbook sheets found:', workbook.SheetNames);

          if (!workbook.SheetNames || workbook.SheetNames.length === 0) {
            alert('File Excel không chứa bảng tính');
            return;
          }

          // Get first sheet
          const worksheet = workbook.Sheets[workbook.SheetNames[0]];
          const rows = XLSX.utils.sheet_to_json(worksheet);
          console.log('📋 Raw rows from Excel:', rows);

          if (rows.length === 0) {
            alert('Sheet không chứa dữ liệu. Vui lòng thêm dữ liệu vào file.');
            return;
          }

          // Show actual headers for debugging
          const firstRow = rows[0] as any;
          const actualHeaders = Object.keys(firstRow);
          console.log('🔑 Actual column headers in file:', actualHeaders);

          // Find columns by flexible matching
          const findColumn = (row: any, ...possibleNames: string[]) => {
            for (const name of possibleNames) {
              const key = Object.keys(row).find(
                k => k.toLowerCase().trim() === name.toLowerCase().trim() ||
                  k.toLowerCase().includes(name.toLowerCase())
              );
              if (key) return row[key];
            }
            return '';
          };

          // Parse Excel rows with flexible column matching
          const newItems = rows.map((row: any) => {
            const name = findColumn(row, 'Tên món', 'name', 'Tên', 'item', 'product');
            const priceStr = findColumn(row, 'Giá bán', 'price', 'Giá', 'Cost', 'Value');
            const description = findColumn(row, 'Mô tả', 'description', 'Description', 'Mô tả');

            return {
              id: Date.now().toString() + Math.random(),
              name: String(name).trim(),
              description: String(description).trim(),
              price: String(priceStr).trim(),
              img: 'https://via.placeholder.com/56x56'
            };
          }).filter((item: any) => {
            // Validate: name must exist and price must be a valid number
            return item.name && !isNaN(parseFloat(item.price)) && parseFloat(item.price) > 0;
          });

          console.log('✓ Parsed items:', newItems);
          console.log('📊 Items count:', newItems.length);

          if (newItems.length === 0) {
            console.warn('⚠️ No valid items found');
            console.log('Expected columns:', 'Tên món (or name), Giá bán (or price)');
            console.log('Found columns in file:', actualHeaders);
            alert(`⚠️ Không tìm thấy dữ liệu hợp lệ.\n\nCác cột trong file của bạn:\n${actualHeaders.join(', ')}\n\nFile cần có cột:\n• "Tên món" hoặc "name"\n• "Giá bán" hoặc "price"`);
            return;
          }

          // Merge with existing items
          setFormData(prev => ({
            ...prev,
            menu: [...prev.menu, ...newItems]
          }));

          console.log('✅ File processed successfully, added', newItems.length, 'items');
          alert(`✓ Đã thêm ${newItems.length} món ăn từ file!`);
          setUploadedFile(file);
          setFileUploaded(true);
        } catch (parseError) {
          console.error('❌ Parse error:', parseError);
          alert(`Lỗi khi xử lý file: ${parseError instanceof Error ? parseError.message : 'Không xác định'}`);
        }
      };

      reader.readAsArrayBuffer(file);
    } catch (error) {
      console.error('❌ Error:', error);
      alert(`Lỗi: ${error instanceof Error ? error.message : 'Không xác định'}`);
    }
  };

  const handleSubmitForm = async () => {
    try {
      setIsLoading(true);

      // 1. Kiểm tra thông tin cơ bản
      if (!formData.name || !formData.address || formData.types.length === 0) {
        alert('Vui lòng điền đầy đủ thông tin tại Bước 1');
        setStep(1);
        return;
      }

      // 2. Logic Upload ảnh (Học từ ProfilePage)
      const uploadedUrls: string[] = [];
      if (selectedImages.length > 0) {
        // Dùng for...of để đảm bảo upload xong hết mới chạy tiếp
        for (const imgItem of selectedImages) {
          try {
            const url = await uploadPlaceImage(imgItem.file);
            uploadedUrls.push(url);
          } catch (uploadErr) {
            console.error("Lỗi upload 1 file:", uploadErr);
            // Có thể chọn dừng lại hoặc tiếp tục tùy bạn
          }
        }
      }

      // 3. Chuẩn bị Payload cho DB
      const categoryMap: { [key: string]: string } = {
        stay: 'Hotel',
        food: 'Restaurant',
        tour: 'Tour',
        trans: 'Transport'
      };

      const payload = {
        p_name: formData.name,
        p_address: formData.address,
        p_city: formData.city,
        p_lat: formData.latitude,
        p_lng: formData.longitude,
        p_vendor_id: VENDOR_ID,
        p_categories: formData.types.map(t => categoryMap[t] || t),
        p_open_time: formData.openTime, // Thêm trường này
        p_close_time: formData.closeTime, // Thêm trường này
        p_description: formData.description,
        p_services: formData.amenities.map(a => ({
          name: a.name,
          description: a.description || ''
        })),
        p_menu: formData.menu.map(item => ({
          name: item.name,
          description: item.description || '',
          price: parseFloat(item.price) || 0
        })),
        p_images: uploadedUrls // Mảng 5 URL ảnh đã upload lên cloud
      };

      // 4. Gọi API lưu vào Supabase qua hàm create_full_place
      await addNewPlace(payload);

      alert('Tạo địa điểm và lưu ảnh thành công!');
      navigate('/dashboard');

    } catch (error) {
      console.error('Lỗi khi thêm địa điểm:', error);
      alert('Không thể tạo địa điểm. Vui lòng thử lại.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleNext = () => {
    if (step < 3) {
      setStep((prev) => prev + 1);
    } else if (step === 3) {
      handleSubmitForm();
    }
  };

  const handleBack = () => {
    if (fileUploaded) {
      setFileUploaded(false);
    } else if (step > 1) {
      setStep((prev) => prev - 1);
    }
  };

  const renderStep1 = () => (
    <div style={{ display: 'flex', gap: '48px' }}>
      <div style={{ flex: 1 }}>
        <Input
          label="Tên địa điểm"
          placeholder="Ví dụ: Khách sạn Marriott Hà Nội"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
        />
        <Input
          label="Địa chỉ chi tiết"
          placeholder="Số nhà, tên đường..."
          value={formData.address}
          onChange={(e) => setFormData({ ...formData, address: e.target.value })}
        />
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}>
            <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
              Tỉnh/Thành
            </label>
            <select
              style={{
                width: '100%',
                padding: '14px 16px',
                borderRadius: '12px',
                border: '1px solid var(--border-color)',
                background: '#fcfcfc',
                outline: 'none',
                fontSize: '15px',
              }}
              value={formData.city}
              onChange={(e) => setFormData({ ...formData, city: e.target.value })}>
              <option value="Hà Nội">Hà Nội</option>
              <option value="Hồ Chí Minh">TP. Hồ Chí Minh</option>
              <option value="Đà Nẵng">Đà Nẵng</option>
            </select>
          </div>
          <div style={{ flex: 1 }}>
            <Input
              label="SĐT Liên hệ"
              placeholder="09xx xxx xxx"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              style={{ marginBottom: 0 }}
            />
          </div>
        </div>
        {/* --- THÀNH PHẦN MỚI: TEXTBOX MÔ TẢ --- */}
        <div style={{ marginBottom: '24px' }}>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '8px' }}>
            Mô tả địa điểm
          </label>
          <textarea
            placeholder="Nhập giới thiệu ngắn gọn về địa điểm của bạn (ví dụ: không gian, phong cách, đặc sản...)"
            style={{
              width: '100%',
              minHeight: '120px',
              padding: '16px',
              borderRadius: '12px',
              border: '1px solid #E2E8F0',
              background: '#fcfcfc',
              outline: 'none',
              fontSize: '15px',
              color: '#1e293b',
              lineHeight: '1.6',
              resize: 'vertical', // Cho phép user kéo giãn chiều cao
            }}
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          />
        </div>
        <div>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>
            Loại hình kinh doanh
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '12px' }}>
            {businessTypes.map((type) => (
              <div
                key={type.id}
                onClick={() => handleTypeToggle(type.id)}
                style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', userSelect: 'none' }}>
                <div
                  style={{
                    width: '20px',
                    height: '20px',
                    border: '2px solid #e2e8f0',
                    borderRadius: '6px',
                    background: formData.types.includes(type.id) ? '#3b82f6' : 'white',
                    borderColor: formData.types.includes(type.id) ? '#3b82f6' : '#e2e8f0',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'white',
                    transition: 'all 0.15s ease',
                  }}>
                  {formData.types.includes(type.id) && (
                    <svg
                      width="12"
                      height="12"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="4"
                      strokeLinecap="round"
                      strokeLinejoin="round">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  )}
                </div>
                <span style={{ fontSize: '14px', color: '#64748b' }}>{type.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }}>
        <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>
          Xác vị trí trên bản đồ
        </label>
        <div
          style={{
            width: '100%',
            height: '240px',
            background: '#f8fafc',
            borderRadius: '16px',
            position: 'relative',
            overflow: 'hidden',
            border: '1px solid #F1F5F9',
            marginBottom: '24px',
          }}>
          <img
            src="https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=600&h=400&fit=crop"
            alt="Map"
            style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.8 }}
          />
          <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -100%)', color: '#ef4444' }}>
            <MapPin size={32} fill="#ef444433" />
          </div>
          <div
            style={{
              position: 'absolute',
              bottom: '12px',
              left: '12px',
              background: 'white',
              padding: '6px 12px',
              borderRadius: '8px',
              fontSize: '11px',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
              color: '#64748b',
            }}>
            Kéo thả ghim để chọn vị trí chính xác nhất.
          </div>
        </div>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}><Input label="Kinh độ (Latitude)" type="number" value={formData.latitude} onChange={(e) => setFormData({ ...formData, latitude: parseFloat(e.target.value) })} style={{ marginBottom: 0 }} /></div>
          <div style={{ flex: 1 }}><Input label="Vĩ độ (Longitude)" type="number" value={formData.longitude} onChange={(e) => setFormData({ ...formData, longitude: parseFloat(e.target.value) })} style={{ marginBottom: 0 }} /></div>
        </div>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}>
            <Input
              label="Giờ mở cửa"
              type="time" // Sử dụng type="time" để user chọn cho nhanh
              value={formData.openTime}
              onChange={(e) => setFormData({ ...formData, openTime: e.target.value })}
              icon={<Clock size={18} />}
              style={{ marginBottom: 0 }}
            />
          </div>
          <div style={{ flex: 1 }}>
            <Input
              label="Giờ đóng cửa"
              type="time"
              value={formData.closeTime}
              onChange={(e) => setFormData({ ...formData, closeTime: e.target.value })}
              icon={<Clock size={18} />}
              style={{ marginBottom: 0 }}
            />
          </div>
        </div>
        {/* Image Upload */}
        <div>
          <label style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-primary)', display: 'block', marginBottom: '12px' }}>
            Hình ảnh địa điểm <span style={{ color: '#94a3b8', fontWeight: '400' }}>(tối đa 5 ảnh)</span>
          </label>
          <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
            {selectedImages.map((img, idx) => (
              <div key={idx} style={{ position: 'relative', width: '76px', height: '76px' }}>
                <img
                  src={img.previewUrl}
                  alt=""
                  style={{ width: '76px', height: '76px', borderRadius: '10px', objectFit: 'cover', border: '1px solid #E2E8F0' }}
                />
                <button
                  onClick={() => handleImageRemove(idx)}
                  style={{ position: 'absolute', top: '-6px', right: '-6px', width: '20px', height: '20px', borderRadius: '50%', background: '#ef4444', color: 'white', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: '800', lineHeight: 1 }}
                >×</button>
              </div>
            ))}
            {selectedImages.length < 5 && (
              <>
                <input type="file" id="placeImageInput" style={{ display: 'none' }} accept="image/*" multiple onChange={handleImageSelect} />
                <div
                  onClick={() => document.getElementById('placeImageInput')?.click()}
                  style={{ width: '76px', height: '76px', border: '2px dashed #E2E8F0', borderRadius: '10px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#94a3b8', fontSize: '10px', gap: '4px', cursor: 'pointer', background: '#F8FAFC' }}
                >
                  <Upload size={20} />
                  <span>Thêm ảnh</span>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep2 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ background: '#F8FAFC80', padding: '24px', borderRadius: '24px', border: '1px solid #F1F5F9' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '24px', color: '#1e293b' }}>
          <Wifi size={20} color="#3b82f6" />
          <h4 style={{ fontSize: '16px', fontWeight: '800' }}>Dịch vụ tiện ích</h4>
        </div>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ flex: 1 }}><Input label="Tên dịch vụ" placeholder="VD: Giữ xe miễn phí" value={serviceInput.name} onChange={(e) => setServiceInput({ ...serviceInput, name: e.target.value })} style={{ marginBottom: 0 }} /></div>
          <div style={{ flex: 1.5 }}><Input label="Mô tả (không bắt buộc)" placeholder="Nhập mô tả ngắn về dịch vụ" value={serviceInput.description} onChange={(e) => setServiceInput({ ...serviceInput, description: e.target.value })} style={{ marginBottom: 0 }} /></div>
          <div style={{ display: 'flex', alignItems: 'flex-end' }}>
            <Button variant="outline" style={{ height: '50px', gap: '8px', padding: '0 24px', borderRadius: '12px', color: '#3b82f6', borderColor: '#3b82f6' }} onClick={handleAddService}>
              <Plus size={18} /> Thêm
            </Button>
          </div>
        </div>
        <div>
          <label
            style={{
              fontSize: '12px',
              fontWeight: '800',
              color: '#94a3b8',
              textTransform: 'uppercase',
              marginBottom: '12px',
              display: 'block',
              letterSpacing: '0.5px',
            }}>
            Dịch vụ đã thêm
          </label>
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            {formData.amenities.map((item) => (
              <div
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '8px 16px',
                  background: 'white',
                  border: '1px solid #E2E8F0',
                  borderRadius: '12px',
                  fontSize: '14px',
                  color: '#475569',
                }}>
                <span style={{ color: '#3b82f6' }}>{item.icon}</span>
                <span>{item.name}</span>
                <span style={{ cursor: 'pointer', color: '#94a3b8', fontSize: '16px', marginLeft: '4px' }} onClick={() => handleRemoveService(item.id)}>×</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ background: '#F8FAFC80', padding: '24px', borderRadius: '24px', border: '1px solid #F1F5F9' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#1e293b' }}>
            <Utensils size={20} color="#3b82f6" />
            <h4 style={{ fontSize: '16px', fontWeight: '800' }}>Thực đơn món ăn (Nhà hàng)</h4>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span style={{ fontSize: '13px', fontWeight: '600', color: '#3b82f6' }}>Đăng ký thực đơn</span>
            <div
              style={{
                width: '44px',
                height: '24px',
                background: '#3b82f6',
                borderRadius: '12px',
                position: 'relative',
                cursor: 'pointer',
              }}>
              <div
                style={{
                  position: 'absolute',
                  right: '4px',
                  top: '4px',
                  width: '16px',
                  height: '16px',
                  background: 'white',
                  borderRadius: '50%',
                }}></div>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '24px', marginBottom: '32px' }}>
          <div
            style={{
              width: '100px',
              height: '100px',
              background: '#f8fafc',
              borderRadius: '16px',
              border: '2px dashed #E2E8F0',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#94a3b8',
              fontSize: '10px',
              gap: '4px',
              cursor: 'pointer',
            }}>
            <Upload size={24} /> Tải lên
          </div>
          <div style={{ flex: 1 }}><Input label="Tên món ăn" placeholder="VD: Cơm Gà Hải Nam" value={menuInput.name} onChange={(e) => setMenuInput({ ...menuInput, name: e.target.value })} /></div>
          <div style={{ flex: 1 }}><Input label="Giá bán (VNĐ)" placeholder="0" value={menuInput.price} onChange={(e) => setMenuInput({ ...menuInput, price: e.target.value })} rightIcon={<span>đ</span>} /></div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '16px', marginBottom: '32px' }}>
          <Button style={{ padding: '12px 24px', borderRadius: '12px', fontSize: '14px', gap: '8px' }} onClick={handleAddMenuItem}><Plus size={18} /> Thêm vào danh sách</Button>
          <Button variant="outline" style={{ padding: '12px 24px', borderRadius: '12px', fontSize: '14px', gap: '8px', color: '#3b82f6', borderColor: '#DBEAFE', background: '#F0F9FF' }} onClick={() => setStep(3)}><Plus size={18} /> Thêm từ file</Button>
        </div>

        <div>
          <label
            style={{
              fontSize: '12px',
              fontWeight: '800',
              color: '#94a3b8',
              textTransform: 'uppercase',
              marginBottom: '16px',
              display: 'block',
              letterSpacing: '0.5px',
            }}>
            Danh sách món ăn
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px' }}>
            {formData.menu.map((item) => (
              <div
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                  padding: '12px',
                  background: 'white',
                  border: '1px solid #E2E8F0',
                  borderRadius: '16px',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.02)',
                }}>
                <img src={item.img} alt={item.name} style={{ width: '56px', height: '56px', borderRadius: '12px', objectFit: 'cover' }} />
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                  <span style={{ fontWeight: '700', color: '#1e293b', fontSize: '14px' }}>{item.name}</span>
                  <span style={{ fontSize: '13px', color: '#3b82f6', fontWeight: '600' }}>{item.price}đ</span>
                </div>
                <div style={{ display: 'flex', gap: '12px', color: '#94a3b8' }}>
                  <Trash2 size={16} style={{ cursor: 'pointer' }} onClick={() => handleRemoveMenuItem(item.id)} />
                  <Edit2 size={16} style={{ cursor: 'pointer' }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep3Initial = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '40px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', color: '#1e293b' }}>
        <h4 style={{ fontSize: '18px', fontWeight: '800' }}>Xác nhận thông tin</h4>
      </div>

      {/* Current menu items summary */}
      {formData.menu.length > 0 && (
        <div style={{ background: '#F0FDF4', border: '1px solid #DCFCE7', borderRadius: '24px', padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <CheckCircle size={20} color="#22c55e" />
            <h5 style={{ fontSize: '15px', fontWeight: '800', color: '#1e293b' }}>Món ăn đã thêm ({formData.menu.length})</h5>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '12px' }}>
            {formData.menu.map(item => (
              <div key={item.id} style={{ padding: '12px', background: 'white', borderRadius: '12px', border: '1px solid #DCFCE7' }}>
                <div style={{ fontWeight: '600', color: '#1e293b', marginBottom: '4px' }}>{item.name}</div>
                <div style={{ fontSize: '13px', color: '#22c55e', marginBottom: '4px' }}>{parseFloat(item.price).toLocaleString('vi-VN')}đ</div>
                {item.description && <div style={{ fontSize: '12px', color: '#64748b' }}>{item.description}</div>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* File upload section */}
      <div style={{ background: 'white', border: '1px solid #F1F5F9', borderRadius: '24px', padding: '40px' }}>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: '#F0F9FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
            <FileSpreadsheet size={24} />
          </div>
          <div>
            <h5 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>Thêm món ăn từ file Excel (tùy chọn)</h5>
            <p style={{ fontSize: '13px', color: '#94a3b8' }}>Tải thêm dữ liệu thực đơn bằng file Excel. File cần có các cột: "Tên món", "Giá bán", "Mô tả" (tùy chọn).</p>
          </div>
        </div>

        <input
          type="file"
          id="fileInput"
          style={{ display: 'none' }}
          accept=".xlsx,.xls,.csv"
          onChange={(e) => {
            if (e.target.files && e.target.files[0]) {
              handleExcelFileUpload(e.target.files[0]);
            }
          }}
        />

        <div onClick={() => document.getElementById('fileInput')?.click()} style={{
          height: '240px',
          border: '2px dashed #E2E8F0',
          borderRadius: '24px',
          background: '#F8FAFC40',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '16px',
          cursor: 'pointer',
          transition: 'all 0.2s ease',
        }}>
          <div
            style={{
              width: '48px',
              height: '48px',
              borderRadius: '50%',
              background: '#F0F9FF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#3b82f6',
            }}>
            <Upload size={24} />
          </div>
          <div style={{ textAlign: 'center' }}>
            <p style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>Kéo thả file đã nhập liệu vào đây</p>
            <p style={{ fontSize: '13px', color: '#94a3b8' }}>Hoặc click để chọn tệp từ máy tính</p>
          </div>
          <span style={{ fontSize: '11px', fontWeight: '800', color: '#CBD5E1', letterSpacing: '1px' }}>XLSX, XLS HOẶC CSV</span>
        </div>
      </div>

      {uploadedFile && (
        <div style={{ background: '#F0FDF4', border: '1px solid #DCFCE7', borderRadius: '16px', padding: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <CheckCircle size={20} color="#22c55e" />
            <div>
              <p style={{ fontSize: '14px', fontWeight: '600', color: '#1e293b' }}>File đã tải: {uploadedFile.name}</p>
              <p style={{ fontSize: '12px', color: '#22c55e' }}>Dữ liệu đã được thêm vào danh sách</p>
            </div>
          </div>
          <button onClick={() => setUploadedFile(null)} style={{ fontSize: '13px', color: '#3b82f6', background: 'transparent', border: 'none', cursor: 'pointer', fontWeight: '600' }}>Xóa</button>
        </div>
      )}
    </div>
  );

  const renderStep3Mapping = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '40px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', color: '#1e293b' }}>
        <button onClick={handleBack} style={{ background: 'transparent', color: '#64748b', cursor: 'pointer', border: 'none' }}>
          <ArrowLeft size={20} />
        </button>
        <h4 style={{ fontSize: '18px', fontWeight: '800' }}>Mapping Dữ liệu Thủ công</h4>
      </div>

      {/* Guide Section */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div
          style={{
            padding: '20px',
            background: '#F0F9FF',
            borderRadius: '16px',
            border: '1px solid #DBEAFE',
            display: 'flex',
            gap: '16px',
          }}>
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              background: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#3b82f6',
            }}>
            <Info size={18} />
          </div>
          <div>
            <h5 style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>Hướng dẫn nhập liệu</h5>
            <p style={{ fontSize: '13px', color: '#64748b' }}>
              Dữ liệu đã được tải lên thành công. Vui lòng kiểm tra lại ánh xạ các trường dữ liệu bên dưới.
            </p>
          </div>
        </div>

        <div
          style={{
            padding: '20px',
            background: '#F0FDF4',
            borderRadius: '16px',
            border: '1px solid #DCFCE7',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}>
          <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
            <div
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '10px',
                background: 'white',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#22c55e',
              }}>
              <FileSpreadsheet size={20} />
            </div>
            <div>
              <p style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{uploadedFile?.name || 'Chưa tải file'}</p>
              <p style={{ fontSize: '12px', color: uploadedFile ? '#22c55e' : '#94a3b8' }}>{uploadedFile ? 'Tải lên thành công' : 'Vui lòng tải file lên'}</p>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
            {uploadedFile && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#22c55e', fontWeight: '600' }}>
                <CheckCircle size={16} /> Hoàn thành
              </div>
            )}
            <button onClick={() => setUploadedFile(null)} style={{ color: '#3b82f6', fontSize: '13px', fontWeight: '700', background: 'transparent', border: 'none', cursor: 'pointer' }}>Thay đổi tệp</button>
          </div>
        </div>
      </div>

      {/* Mapping Section */}
      <div style={{ border: '1px solid #F1F5F9', borderRadius: '24px', overflow: 'hidden', background: 'white' }}>
        <div
          style={{
            padding: '20px 24px',
            background: '#F8FAFC',
            borderBottom: '1px solid #F1F5F9',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
          }}>
          <RefreshCw size={18} color="#3b82f6" />
          <h5 style={{ fontSize: '15px', fontWeight: '800' }}>Thiết lập ánh xạ trường dữ liệu</h5>
        </div>
        {uploadedFile ? (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', borderBottom: '1px solid #F1F5F9' }}>
                <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Trường trong dữ liệu hệ thống</th>
                <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Cột trong file của bạn</th>
                <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Trạng thái</th>
              </tr>
            </thead>
          </table>
        ) : (
          <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
            <p style={{ fontSize: '14px' }}>Vui lòng tải file lên để xem phần ánh xạ trường dữ liệu</p>
          </div>
        )}
      </div>

      {/* Preview Section */}
      <div style={{ border: '1px solid #F1F5F9', borderRadius: '24px', overflow: 'hidden', background: 'white' }}>
        <div
          style={{
            padding: '20px 24px',
            background: '#F8FAFC',
            borderBottom: '1px solid #F1F5F9',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
          }}>
          <Eye size={18} color="#3b82f6" />
          <h5 style={{ fontSize: '15px', fontWeight: '800' }}>Xem trước dữ liệu (3 dòng đầu)</h5>
        </div>
        {uploadedFile ? (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', borderBottom: '1px solid #F1F5F9', background: '#F8FAFC' }}>
                <th style={{ padding: '12px 24px', fontSize: '11px', fontWeight: '800', color: '#94a3b8' }}>DỮ LIỆU DỰA TRÊN FILE</th>
              </tr>
            </thead>
            <tbody>
              <tr style={{ borderBottom: 'none', fontSize: '13px' }}>
                <td style={{ padding: '16px 24px', color: '#64748b' }}>Sẽ hiển thị dữ liệu từ file Excel khi được xử lý</td>
              </tr>
            </tbody>
          </table>
        ) : (
          <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
            <p style={{ fontSize: '14px' }}>Vui lòng tải file lên để xem phần xem trước dữ liệu</p>
          </div>
        )}
        <div style={{ padding: '12px 24px', color: '#94a3b8', fontSize: '11px', borderTop: '1px solid #F1F5F9' }}>
          ⓘ Dữ liệu xem trước giúp bạn xác nhận ánh xạ trường đã chính xác.
        </div>
      </div>
    </div>
  );

  return (
    <>
      <div style={{ maxWidth: step === 3 ? '1200px' : '1000px', margin: '0 auto', paddingBottom: step === 3 ? '120px' : '40px' }}>
        {step !== 3 && (
          <div style={{ marginBottom: '32px' }}>
            <h2 style={{ fontSize: '28px', fontWeight: '800', color: '#1e293b', marginBottom: '8px' }}>Thêm địa điểm mới</h2>
            <p style={{ fontSize: '15px', color: '#64748b' }}>
              Vui lòng điền thông tin chi tiết về địa điểm kinh doanh của bạn để bắt đầu.
            </p>
          </div>
        )}

        <div
          style={{
            background: step === 3 ? 'transparent' : 'white',
            borderRadius: '24px',
            padding: step === 3 ? '0' : '32px',
            boxShadow: step === 3 ? 'none' : '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
            border: step === 3 ? 'none' : '1px solid #F1F5F9',
          }}>
          {step !== 3 && (
            <>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '48px', marginBottom: '40px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: step >= 1 ? '#3b82f6' : '#94a3b8' }}>
                  <span
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: step >= 1 ? '#3b82f6' : '#f1f5f9',
                      color: step >= 1 ? 'white' : '#94a3b8',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      fontWeight: '700',
                    }}>
                    1
                  </span>
                  <span style={{ fontWeight: '700', fontSize: '14px' }}>Thông tin</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: step >= 2 ? '#3b82f6' : '#94a3b8' }}>
                  <span
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: step >= 2 ? '#3b82f6' : '#f1f5f9',
                      color: step >= 2 ? 'white' : '#94a3b8',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      fontWeight: '700',
                    }}>
                    2
                  </span>
                  <span style={{ fontWeight: '700', fontSize: '14px' }}>Dịch vụ</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: step >= 3 ? '#3b82f6' : '#94a3b8' }}>
                  <span
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: step >= 3 ? '#3b82f6' : '#f1f5f9',
                      color: step >= 3 ? 'white' : '#94a3b8',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      fontWeight: '700',
                    }}>
                    3
                  </span>
                  <span style={{ fontWeight: '700', fontSize: '14px' }}>Xác nhận</span>
                </div>
              </div>

              <div style={{ marginBottom: '40px' }}>
                <div style={{ height: '6px', background: '#f1f5f9', borderRadius: '3px', overflow: 'hidden' }}>
                  <div
                    style={{
                      width: step === 1 ? '33%' : step === 2 ? '66%' : '100%',
                      height: '100%',
                      background: '#3b82f6',
                      borderRadius: '3px',
                      transition: 'width 0.3s ease',
                    }}></div>
                </div>
              </div>
            </>
          )}

          {step === 1 ? renderStep1() : step === 2 ? renderStep2() : renderStep3Initial()}

          {/* Footer Actions */}
          <div style={{
            marginTop: step === 3 ? '0' : '48px',
            paddingTop: step === 3 ? '24px' : '32px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            background: step === 3 ? 'white' : 'transparent',
            padding: step === 3 ? '24px 40px' : '32px 0 0 0',
            position: step === 3 ? 'fixed' : 'relative',
            bottom: 0,
            left: step === 3 ? '280px' : 'auto',
            right: 0,
            zIndex: 10,
            borderTop: step === 3 ? '1px solid #f1f5f9' : 'none'
          }}>
            {step === 3 ? (
              <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: '24px', width: '100%' }}>
                <button onClick={() => navigate('/dashboard')} style={{ background: 'transparent', border: 'none', color: '#ef4444', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>Hủy</button>
                {uploadedFile && (
                  <button onClick={() => {
                    setUploadedFile(null);
                    setFileUploaded(false);
                  }} style={{ background: 'transparent', border: 'none', color: '#64748b', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>Xóa file</button>
                )}
                {!uploadedFile && formData.menu.length === 0 && (
                  <button onClick={() => setStep(2)} style={{ background: 'white', border: '1px solid #E2E8F0', padding: '10px 24px', borderRadius: '12px', fontSize: '14px', fontWeight: '700', color: '#475569', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <ArrowLeft size={18} /> Quay lại
                  </button>
                )}
                {/* Ở phần Footer Actions, tìm nút Hoàn tất và sửa lại như sau: */}
                <Button
                  onClick={handleNext}
                  // Bỏ điều kiện formData.menu.length === 0
                  disabled={isLoading}
                  style={{ padding: '12px 32px', borderRadius: '12px', gap: '8px' }}
                >
                  {isLoading ? (
                    <>
                      <Loader2 size={18} className="animate-spin" /> Đang xử lý...
                    </>
                  ) : (
                    <>
                      Hoàn tất <CheckCircle size={18} />
                    </>
                  )}
                </Button>
              </div>
            ) : (
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '24px', width: '100%' }}>
                {step === 1 ? (
                  <button
                    onClick={() => navigate('/dashboard')}
                    style={{
                      background: 'transparent',
                      color: '#64748b',
                      fontSize: '14px',
                      fontWeight: '700',
                      padding: '12px 24px',
                      cursor: 'pointer',
                    }}>
                    Hủy bỏ
                  </button>
                ) : (
                  <button
                    onClick={handleBack}
                    style={{
                      background: '#F1F5F9',
                      color: '#475569',
                      fontSize: '14px',
                      fontWeight: '700',
                      padding: '12px 24px',
                      borderRadius: '12px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      cursor: 'pointer',
                    }}>
                    <ArrowLeft size={18} /> Quay lại
                  </button>
                )}

                {step === 2 && (
                  <button style={{ background: 'transparent', color: '#94a3b8', fontSize: '14px', fontWeight: '700', cursor: 'pointer' }}>
                    Lưu tạm
                  </button>
                )}

                <Button onClick={handleNext} style={{ gap: '8px', padding: '12px 32px', borderRadius: '12px' }}>
                  {step === 1 ? 'Tiếp theo' : 'Tiếp tục'}
                  <ArrowRight size={18} />
                </Button>
              </div>
            )}
          </div>
        </div>

        {step !== 3 && (
          <p style={{ textAlign: 'center', marginTop: '32px', fontSize: '13px', color: '#94a3b8' }}>
            Bằng cách nhấn tiếp tục, bạn đồng ý với{' '}
            <a href="#" style={{ textDecoration: 'underline' }}>
              Điều khoản & Chính sách
            </a>{' '}
            của Travel Portal.
          </p>
        )}
      </div>
    </>
  );
};

export default AddLocationPage;
