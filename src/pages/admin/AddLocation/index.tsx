import React, { useState } from "react";

import Input from "../../../components/UI/Input";
import Button from "../../../components/UI/Button";
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
} from "lucide-react";
import { useNavigate } from "react-router-dom";

export const AddLocation: React.FC = () => {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [fileUploaded, setFileUploaded] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    address: "",
    city: "Hà Nội",
    phone: "",
    types: [] as string[],
    openingHours: "",
    amenities: [
      { id: "1", name: "Giữ xe miễn phí", icon: <Car size={16} /> },
      { id: "2", name: "Wifi tốc độ cao", icon: <Wifi size={16} /> },
    ],
    menu: [
      {
        id: "1",
        name: "Cơm gà Hải Nam",
        price: "45.000đ",
        img: "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=100&h=100&fit=crop",
      },
      {
        id: "2",
        name: "Mì quảng đặc biệt",
        price: "35.000đ",
        img: "https://images.unsplash.com/photo-1595147353130-9759e663da5e?w=100&h=100&fit=crop",
      },
    ],
  });

  const businessTypes = [
    { id: "stay", label: "Khách sạn/Lưu trú" },
    { id: "food", label: "Nhà hàng/Ẩm thực" },
    { id: "tour", label: "Tour du lịch" },
    { id: "trans", label: "Vận chuyển" },
  ];

  const handleTypeToggle = (typeId: string) => {
    setFormData((prev) => ({
      ...prev,
      types: prev.types.includes(typeId) ? prev.types.filter((t) => t !== typeId) : [...prev.types, typeId],
    }));
  };

  const handleNext = () => {
    if (step < 3) {
      setStep((prev) => prev + 1);
    } else if (fileUploaded) {
      navigate("/admin/locations");
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
    <div style={{ display: "flex", gap: "48px" }}>
      <div style={{ flex: 1 }}>
        <Input
          label="Tên địa điểm"
          placeholder="Ví dụ: Khách sạn Marriott Hà Nội"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: (e.target as HTMLInputElement).value })}
        />
        <Input
          label="Địa chỉ chi tiết"
          placeholder="Số nhà, tên đường..."
          value={formData.address}
          onChange={(e) => setFormData({ ...formData, address: (e.target as HTMLInputElement).value })}
        />
        <div style={{ display: "flex", gap: "16px", marginBottom: "24px" }}>
          <div style={{ flex: 1 }}>
            <label style={{ fontSize: "14px", fontWeight: "600", color: "var(--text-primary)", display: "block", marginBottom: "8px" }}>
              Tỉnh/Thành
            </label>
            <select
              style={{
                width: "100%",
                padding: "14px 16px",
                borderRadius: "12px",
                border: "1px solid var(--border-color)",
                background: "#fcfcfc",
                outline: "none",
                fontSize: "15px",
              }}
              value={formData.city}
              onChange={(e) => setFormData({ ...formData, city: e.target.value })}
            >
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
              onChange={(e) => setFormData({ ...formData, phone: (e.target as HTMLInputElement).value })}
              style={{ marginBottom: 0 }}
            />
          </div>
        </div>
        <div>
          <label style={{ fontSize: "14px", fontWeight: "600", color: "var(--text-primary)", display: "block", marginBottom: "12px" }}>
            Loại hình kinh doanh
          </label>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: "12px" }}>
            {businessTypes.map((type) => (
              <div
                key={type.id}
                onClick={() => handleTypeToggle(type.id)}
                style={{ display: "flex", alignItems: "center", gap: "10px", cursor: "pointer", userSelect: "none" }}
              >
                <div
                  style={{
                    width: "20px",
                    height: "20px",
                    border: "2px solid #e2e8f0",
                    borderRadius: "6px",
                    background: formData.types.includes(type.id) ? "#3b82f6" : "white",
                    borderColor: formData.types.includes(type.id) ? "#3b82f6" : "#e2e8f0",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: "white",
                    transition: "all 0.15s ease",
                  }}
                >
                  {formData.types.includes(type.id) && (
                    <svg
                      width="12"
                      height="12"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="4"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  )}
                </div>
                <span style={{ fontSize: "14px", color: "#64748b" }}>{type.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }}>
        <label style={{ fontSize: "14px", fontWeight: "600", color: "var(--text-primary)", display: "block", marginBottom: "12px" }}>
          Xác vị trí trên bản đồ
        </label>
        <div
          style={{
            width: "100%",
            height: "240px",
            background: "#f8fafc",
            borderRadius: "16px",
            position: "relative",
            overflow: "hidden",
            border: "1px solid #F1F5F9",
            marginBottom: "24px",
          }}
        >
          <img
            src="https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=600&h=400&fit=crop"
            alt="Map"
            style={{ width: "100%", height: "100%", objectFit: "cover", opacity: 0.8 }}
          />
          <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%, -100%)", color: "#ef4444" }}>
            <MapPin size={32} fill="#ef444433" />
          </div>
          <div
            style={{
              position: "absolute",
              bottom: "12px",
              left: "12px",
              background: "white",
              padding: "6px 12px",
              borderRadius: "8px",
              fontSize: "11px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
              color: "#64748b",
            }}
          >
            Kéo thả ghim để chọn vị trí chính xác nhất.
          </div>
        </div>
        <Input
          label="Giờ mở cửa"
          placeholder="Ví dụ: 08:00 - 22:00"
          icon={<Clock size={18} />}
          value={formData.openingHours}
          onChange={(e) => setFormData({ ...formData, openingHours: (e.target as HTMLInputElement).value })}
        />
      </div>
    </div>
  );

  const renderStep2 = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div style={{ background: "#F8FAFC80", padding: "24px", borderRadius: "24px", border: "1px solid #F1F5F9" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "24px", color: "#1e293b" }}>
          <Wifi size={20} color="#3b82f6" />
          <h4 style={{ fontSize: "16px", fontWeight: "800" }}>Dịch vụ tiện ích</h4>
        </div>
        <div style={{ display: "flex", gap: "16px", marginBottom: "24px" }}>
          <div style={{ flex: 1 }}>
            <Input label="Tên dịch vụ" placeholder="VD: Giữ xe miễn phí" style={{ marginBottom: 0 }} />
          </div>
          <div style={{ flex: 1.5 }}>
            <Input label="Mô tả (không bắt buộc)" placeholder="Nhập mô tả ngắn về dịch vụ" style={{ marginBottom: 0 }} />
          </div>
          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <Button
              variant="outline"
              style={{ height: "52px", gap: "8px", padding: "0 24px", borderRadius: "12px", color: "#3b82f6", borderColor: "#3b82f6" }}
            >
              <Plus size={18} /> Thêm
            </Button>
          </div>
        </div>
        <div>
          <label
            style={{
              fontSize: "12px",
              fontWeight: "800",
              color: "#94a3b8",
              textTransform: "uppercase",
              marginBottom: "12px",
              display: "block",
              letterSpacing: "0.5px",
            }}
          >
            Dịch vụ đã thêm
          </label>
          <div style={{ display: "flex", gap: "12px", flexWrap: "wrap" }}>
            {formData.amenities.map((item) => (
              <div
                key={item.id}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  padding: "8px 16px",
                  background: "white",
                  border: "1px solid #E2E8F0",
                  borderRadius: "12px",
                  fontSize: "14px",
                  color: "#475569",
                }}
              >
                <span style={{ color: "#3b82f6" }}>{item.icon}</span>
                <span>{item.name}</span>
                <span style={{ cursor: "pointer", color: "#94a3b8", fontSize: "16px", marginLeft: "4px" }}>×</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ background: "#F8FAFC80", padding: "24px", borderRadius: "24px", border: "1px solid #F1F5F9" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "24px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", color: "#1e293b" }}>
            <Utensils size={20} color="#3b82f6" />
            <h4 style={{ fontSize: "16px", fontWeight: "800" }}>Thực đơn món ăn (Nhà hàng)</h4>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <span style={{ fontSize: "13px", fontWeight: "600", color: "#3b82f6" }}>Đăng ký thực đơn</span>
            <div
              style={{
                width: "44px",
                height: "24px",
                background: "#3b82f6",
                borderRadius: "12px",
                position: "relative",
                cursor: "pointer",
              }}
            >
              <div
                style={{
                  position: "absolute",
                  right: "4px",
                  top: "4px",
                  width: "16px",
                  height: "16px",
                  background: "white",
                  borderRadius: "50%",
                }}
              ></div>
            </div>
          </div>
        </div>

        <div style={{ display: "flex", gap: "24px", marginBottom: "32px" }}>
          <div
            style={{
              width: "100px",
              height: "100px",
              background: "#f8fafc",
              borderRadius: "16px",
              border: "2px dashed #E2E8F0",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              color: "#94a3b8",
              fontSize: "10px",
              gap: "4px",
              cursor: "pointer",
            }}
          >
            <Upload size={24} /> Tải lên
          </div>
          <div style={{ flex: 1 }}>
            <Input label="Tên món ăn" placeholder="VD: Cơm Gà Hải Nam" style={{ marginBottom: 0 }} />
          </div>
          <div style={{ flex: 1 }}>
            <Input label="Giá bán (VNĐ)" placeholder="0" rightIcon={<span>đ</span>} style={{ marginBottom: 0 }} />
          </div>
        </div>

        <div style={{ display: "flex", justifyContent: "flex-end", gap: "16px", marginBottom: "32px" }}>
          <Button style={{ padding: "12px 24px", borderRadius: "12px", fontSize: "14px", gap: "8px" }}>
            <Plus size={18} /> Thêm vào danh sách
          </Button>
          <Button
            variant="outline"
            style={{
              padding: "12px 24px",
              borderRadius: "12px",
              fontSize: "14px",
              gap: "8px",
              color: "#3b82f6",
              borderColor: "#DBEAFE",
              background: "#F0F9FF",
            }}
            onClick={() => setStep(3)}
          >
            <Plus size={18} /> Thêm từ file
          </Button>
        </div>

        <div>
          <label
            style={{
              fontSize: "12px",
              fontWeight: "800",
              color: "#94a3b8",
              textTransform: "uppercase",
              marginBottom: "16px",
              display: "block",
              letterSpacing: "0.5px",
            }}
          >
            Danh sách món ăn
          </label>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: "16px" }}>
            {formData.menu.map((item) => (
              <div
                key={item.id}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "16px",
                  padding: "12px",
                  background: "white",
                  border: "1px solid #E2E8F0",
                  borderRadius: "16px",
                  boxShadow: "0 2px 4px rgba(0,0,0,0.02)",
                }}
              >
                <img src={item.img} alt={item.name} style={{ width: "56px", height: "56px", borderRadius: "12px", objectFit: "cover" }} />
                <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
                  <span style={{ fontWeight: "700", color: "#1e293b", fontSize: "14px" }}>{item.name}</span>
                  <span style={{ fontSize: "13px", color: "#3b82f6", fontWeight: "600" }}>{item.price}</span>
                </div>
                <div style={{ display: "flex", gap: "12px", color: "#94a3b8" }}>
                  <Trash2 size={16} style={{ cursor: "pointer" }} />
                  <Edit2 size={16} style={{ cursor: "pointer" }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep3Initial = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "40px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: "12px", color: "#1e293b" }}>
        <button onClick={handleBack} style={{ background: "transparent", color: "#64748b", cursor: "pointer", border: "none" }}>
          <ArrowLeft size={20} />
        </button>
        <h4 style={{ fontSize: "18px", fontWeight: "800" }}>Thêm món ăn từ file</h4>
      </div>

      <div style={{ background: "white", border: "1px solid #F1F5F9", borderRadius: "24px", padding: "40px" }}>
        <div style={{ display: "flex", gap: "16px", marginBottom: "24px" }}>
          <div
            style={{
              width: "48px",
              height: "48px",
              borderRadius: "12px",
              background: "#F0F9FF",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#3b82f6",
            }}
          >
            <FileSpreadsheet size={24} />
          </div>
          <div>
            <h5 style={{ fontSize: "15px", fontWeight: "700", marginBottom: "4px" }}>Tải lên dữ liệu thực đơn</h5>
            <p style={{ fontSize: "13px", color: "#94a3b8" }}>Kéo thả tệp đã nhập liệu theo đúng định dạng file mẫu.</p>
          </div>
        </div>

        <div
          onClick={() => setFileUploaded(true)}
          style={{
            height: "240px",
            border: "2px dashed #E2E8F0",
            borderRadius: "24px",
            background: "#F8FAFC40",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: "16px",
            cursor: "pointer",
            transition: "all 0.2s ease",
          }}
        >
          <div
            style={{
              width: "48px",
              height: "48px",
              borderRadius: "50%",
              background: "#F0F9FF",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#3b82f6",
            }}
          >
            <Upload size={24} />
          </div>
          <div style={{ textAlign: "center" }}>
            <p style={{ fontSize: "15px", fontWeight: "700", color: "#1e293b", marginBottom: "4px" }}>Kéo thả file đã nhập liệu vào đây</p>
            <p style={{ fontSize: "13px", color: "#94a3b8" }}>Hoặc click để chọn tệp từ máy tính</p>
          </div>
          <span style={{ fontSize: "11px", fontWeight: "800", color: "#CBD5E1", letterSpacing: "1px" }}>XLSX, XLS HOẶC CSV</span>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "10px", color: "#1e293b" }}>
          <Eye size={20} color="#3b82f6" />
          <span style={{ fontSize: "15px", fontWeight: "800" }}>Xem trước dữ liệu (3 dòng đầu)</span>
        </div>
        <div
          style={{
            height: "240px",
            background: "#F8FAFC40",
            border: "1px solid #F1F5F9",
            borderRadius: "24px",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: "16px",
            color: "#94a3b8",
          }}
        >
          <div
            style={{
              width: "56px",
              height: "56px",
              borderRadius: "50%",
              background: "white",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              border: "1px solid #F1F5F9",
            }}
          >
            <FileSpreadsheet size={24} color="#E2E8F0" />
          </div>
          <div style={{ textAlign: "center", maxWidth: "400px" }}>
            <p style={{ fontSize: "15px", fontWeight: "700", color: "#1e293b", marginBottom: "8px" }}>Chưa có dữ liệu để hiển thị</p>
            <p style={{ fontSize: "13px", lineHeight: "1.6" }}>
              Vui lòng tải tệp Excel lên và thực hiện ánh xạ các cột dữ liệu để xem bản xem trước tại đây.
            </p>
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep3Mapping = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "40px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: "12px", color: "#1e293b" }}>
        <button onClick={handleBack} style={{ background: "transparent", color: "#64748b", cursor: "pointer", border: "none" }}>
          <ArrowLeft size={20} />
        </button>
        <h4 style={{ fontSize: "18px", fontWeight: "800" }}>Mapping Dữ liệu Thủ công</h4>
      </div>

      {/* Guide Section */}
      <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
        <div
          style={{
            padding: "20px",
            background: "#F0F9FF",
            borderRadius: "16px",
            border: "1px solid #DBEAFE",
            display: "flex",
            gap: "16px",
          }}
        >
          <div
            style={{
              width: "32px",
              height: "32px",
              borderRadius: "50%",
              background: "white",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#3b82f6",
            }}
          >
            <Info size={18} />
          </div>
          <div>
            <h5 style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b", marginBottom: "4px" }}>Hướng dẫn nhập liệu</h5>
            <p style={{ fontSize: "13px", color: "#64748b" }}>
              Dữ liệu đã được tải lên thành công. Vui lòng kiểm tra lại ánh xạ các trường dữ liệu bên dưới.
            </p>
          </div>
        </div>

        <div
          style={{
            padding: "20px",
            background: "#F0FDF4",
            borderRadius: "16px",
            border: "1px solid #DCFCE7",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <div style={{ display: "flex", gap: "16px", alignItems: "center" }}>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                background: "white",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#22c55e",
              }}
            >
              <FileSpreadsheet size={20} />
            </div>
            <div>
              <p style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b" }}>Thuc_don_nha_hang.xlsx</p>
              <p style={{ fontSize: "12px", color: "#22c55e" }}>Tải lên thành công • 1.2 MB</p>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "20px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "13px", color: "#22c55e", fontWeight: "600" }}>
              <CheckCircle size={16} /> Hoàn thành
            </div>
            <button
              style={{
                color: "#3b82f6",
                fontSize: "13px",
                fontWeight: "700",
                background: "transparent",
                border: "none",
                cursor: "pointer",
              }}
            >
              Thay đổi tệp
            </button>
          </div>
        </div>
      </div>

      {/* Mapping Section */}
      <div style={{ border: "1px solid #F1F5F9", borderRadius: "24px", overflow: "hidden", background: "white" }}>
        <div
          style={{
            padding: "20px 24px",
            background: "#F8FAFC",
            borderBottom: "1px solid #F1F5F9",
            display: "flex",
            alignItems: "center",
            gap: "10px",
          }}
        >
          <RefreshCw size={18} color="#3b82f6" />
          <h5 style={{ fontSize: "15px", fontWeight: "800" }}>Thiết lập ánh xạ trường dữ liệu</h5>
        </div>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ textAlign: "left", borderBottom: "1px solid #F1F5F9" }}>
              <th style={{ padding: "16px 24px", fontSize: "11px", fontWeight: "800", color: "#94a3b8", textTransform: "uppercase" }}>
                Trường trong dữ liệu hệ thống
              </th>
              <th style={{ padding: "16px 24px", fontSize: "11px", fontWeight: "800", color: "#94a3b8", textTransform: "uppercase" }}>
                Cột trong file của bạn
              </th>
              <th style={{ padding: "16px 24px", fontSize: "11px", fontWeight: "800", color: "#94a3b8", textTransform: "uppercase" }}>
                Trạng thái
              </th>
            </tr>
          </thead>
          <tbody>
            {[
              { label: "Tên món", icon: <Edit2 size={16} />, mapping: "Tên món", status: "Bắt buộc", statusColor: "#ef4444" },
              { label: "Giá bán", icon: <Plus size={16} />, mapping: "Giá bán", status: "Bắt buộc", statusColor: "#ef4444" },
              { label: "Mô tả món ăn", icon: <Utensils size={16} />, mapping: "Mô tả món ăn", status: "Tùy chọn", statusColor: "#94a3b8" },
            ].map((row, idx) => (
              <tr key={idx} style={{ borderBottom: idx < 2 ? "1px solid #F1F5F9" : "none" }}>
                <td style={{ padding: "20px 24px" }}>
                  <div
                    style={{ display: "flex", alignItems: "center", gap: "12px", fontSize: "14px", fontWeight: "700", color: "#1e293b" }}
                  >
                    <span style={{ color: "#94a3b8" }}>{row.icon}</span>
                    {row.label}
                  </div>
                </td>
                <td style={{ padding: "20px 24px" }}>
                  <div style={{ position: "relative", width: "280px" }}>
                    <select
                      style={{
                        width: "100%",
                        padding: "10px 16px",
                        borderRadius: "10px",
                        border: "1px solid #E2E8F0",
                        background: "#F8FAFC",
                        outline: "none",
                        appearance: "none",
                        fontSize: "14px",
                      }}
                    >
                      <option>{row.mapping}</option>
                    </select>
                    <ChevronDown
                      size={16}
                      style={{ position: "absolute", right: "12px", top: "50%", transform: "translateY(-50%)", color: "#94a3b8" }}
                    />
                  </div>
                </td>
                <td style={{ padding: "20px 24px" }}>
                  <span
                    style={{
                      padding: "4px 12px",
                      borderRadius: "6px",
                      background: row.statusColor + "10",
                      color: row.statusColor,
                      fontSize: "11px",
                      fontWeight: "700",
                    }}
                  >
                    {row.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Preview Section */}
      <div style={{ border: "1px solid #F1F5F9", borderRadius: "24px", overflow: "hidden", background: "white" }}>
        <div
          style={{
            padding: "20px 24px",
            background: "#F8FAFC",
            borderBottom: "1px solid #F1F5F9",
            display: "flex",
            alignItems: "center",
            gap: "10px",
          }}
        >
          <Eye size={18} color="#3b82f6" />
          <h5 style={{ fontSize: "15px", fontWeight: "800" }}>Xem trước dữ liệu (3 dòng đầu)</h5>
        </div>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ textAlign: "left", borderBottom: "1px solid #F1F5F9", background: "#F8FAFC" }}>
              <th style={{ padding: "12px 24px", fontSize: "11px", fontWeight: "800", color: "#94a3b8" }}>TÊN MÓN</th>
              <th style={{ padding: "12px 24px", fontSize: "11px", fontWeight: "800", color: "#94a3b8" }}>GIÁ BÁN</th>
              <th style={{ padding: "12px 24px", fontSize: "11px", fontWeight: "800", color: "#94a3b8" }}>MÔ TẢ</th>
            </tr>
          </thead>
          <tbody>
            {[
              { name: "Cơm gà Hải Nam", price: "45.000đ", desc: "Cơm dẻo kèm thịt gà luộc chín tới" },
              { name: "Mì Quảng", price: "35.000đ", desc: "Mì sợi vàng với tôm, thịt heo và bánh đa" },
              { name: "Phở bò", price: "50.000đ", desc: "Nước dùng đậm đà, thịt bò tươi tái chín" },
            ].map((row, idx) => (
              <tr key={idx} style={{ borderBottom: idx < 2 ? "1px solid #F1F5F9" : "none", fontSize: "13px" }}>
                <td style={{ padding: "16px 24px", fontWeight: "700", color: "#1e293b" }}>{row.name}</td>
                <td style={{ padding: "16px 24px", fontWeight: "700", color: "#3b82f6" }}>{row.price}</td>
                <td style={{ padding: "16px 24px", color: "#64748b" }}>{row.desc}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div style={{ padding: "12px 24px", color: "#94a3b8", fontSize: "11px", borderTop: "1px solid #F1F5F9" }}>
          ⓘ Dữ liệu xem trước giúp bạn xác nhận ánh xạ trường đã chính xác.
        </div>
      </div>
    </div>
  );

  return (
    <>
      <div
        style={{
          maxWidth: step === 3 ? "1200px" : "1000px",
          margin: "0 auto",
          paddingBottom: step === 3 ? "120px" : "80px",
          paddingTop: "40px",
        }}
      >
        {step !== 3 && (
          <div style={{ marginBottom: "32px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "800",
                color: "#000000",
                marginBottom: "8px",
                fontFamily: "'Times New Roman', Times, serif",
              }}
            >
              Thêm địa điểm mới
            </h2>
            <p style={{ fontSize: "15px", color: "#64748b" }}>
              Vui lòng điền thông tin chi tiết về địa điểm kinh doanh của bạn để bắt đầu.
            </p>
          </div>
        )}

        <div
          style={{
            background: step === 3 ? "transparent" : "white",
            borderRadius: "24px",
            padding: step === 3 ? "0" : "32px",
            boxShadow: step === 3 ? "none" : "0 4px 6px -1px rgba(0, 0, 0, 0.05)",
            border: step === 3 ? "none" : "1px solid #F1F5F9",
          }}
        >
          {step === 1 ? renderStep1() : step === 2 ? renderStep2() : fileUploaded ? renderStep3Mapping() : renderStep3Initial()}

          {/* Footer Actions */}
          <div
            style={{
              marginTop: step === 3 ? "0" : "48px",
              paddingTop: step === 3 ? "24px" : "32px",
              borderTop: step === 3 ? "none" : "1px solid #f1f5f9",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              background: step === 3 ? "white" : "transparent",
              padding: step === 3 ? "24px 40px" : "32px 0 0 0",
              position: step === 3 ? "fixed" : "relative",
              bottom: 0,
              left: step === 3 ? "var(--sidebar-width)" : "auto",
              right: 0,
              zIndex: 10,
              borderTopColor: "#f1f5f9",
              borderTopWidth: step === 3 ? "1px" : "0",
            }}
          >
            {step === 3 ? (
              <div style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", gap: "24px", width: "100%" }}>
                <button
                  onClick={() => navigate("/admin/locations")}
                  style={{
                    background: "transparent",
                    border: "none",
                    color: "#ef4444",
                    fontSize: "14px",
                    fontWeight: "700",
                    cursor: "pointer",
                  }}
                >
                  Hủy
                </button>
                {fileUploaded && (
                  <button
                    onClick={() => setFileUploaded(false)}
                    style={{
                      background: "transparent",
                      border: "none",
                      color: "#64748b",
                      fontSize: "14px",
                      fontWeight: "700",
                      cursor: "pointer",
                    }}
                  >
                    Tải lại file khác
                  </button>
                )}
                {!fileUploaded && (
                  <button
                    onClick={() => setStep(2)}
                    style={{
                      background: "white",
                      border: "1px solid #E2E8F0",
                      padding: "10px 24px",
                      borderRadius: "12px",
                      fontSize: "14px",
                      fontWeight: "700",
                      color: "#475569",
                      cursor: "pointer",
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                    }}
                  >
                    <ArrowLeft size={18} /> Quay lại
                  </button>
                )}
                <Button onClick={handleNext} disabled={!fileUploaded} style={{ padding: "12px 32px", borderRadius: "12px", gap: "8px" }}>
                  Hoàn tất nhập dữ liệu <CheckCircle size={18} />
                </Button>
              </div>
            ) : (
              <div style={{ display: "flex", justifyContent: "flex-end", gap: "24px", width: "100%" }}>
                {step === 1 ? (
                  <button
                    onClick={() => navigate("/admin/locations")}
                    style={{
                      background: "transparent",
                      color: "#64748b",
                      fontSize: "14px",
                      fontWeight: "700",
                      padding: "12px 24px",
                      cursor: "pointer",
                    }}
                  >
                    Hủy bỏ
                  </button>
                ) : (
                  <button
                    onClick={handleBack}
                    style={{
                      background: "#F1F5F9",
                      color: "#475569",
                      fontSize: "14px",
                      fontWeight: "700",
                      padding: "12px 24px",
                      borderRadius: "12px",
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                      cursor: "pointer",
                    }}
                  >
                    <ArrowLeft size={18} /> Quay lại
                  </button>
                )}

                {step === 2 && (
                  <button style={{ background: "transparent", color: "#94a3b8", fontSize: "14px", fontWeight: "700", cursor: "pointer" }}>
                    Lưu tạm
                  </button>
                )}

                <Button onClick={handleNext} style={{ gap: "8px", padding: "12px 32px", borderRadius: "12px" }}>
                  {step === 1 ? "Tiếp theo" : "Tiếp tục"}
                  <ArrowRight size={18} />
                </Button>
              </div>
            )}
          </div>
        </div>

        {step !== 3 && (
          <p style={{ textAlign: "center", marginTop: "32px", fontSize: "13px", color: "#94a3b8" }}>
            Bằng cách nhấn tiếp tục, bạn đồng ý với{" "}
            <a href="#" style={{ textDecoration: "underline" }}>
              Điều khoản & Chính sách
            </a>{" "}
            của Travel Portal.
          </p>
        )}
      </div>
    </>
  );
};
