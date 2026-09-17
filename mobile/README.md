# 📱 Travel Advisor Mobile

Ứng dụng di động Flutter cho hệ thống gợi ý du lịch cá nhân hóa - Dành cho end-users.

---

## ⚠️ Quy định về đường dẫn cài đặt

**Lưu ý quan trọng:** Để tránh các lỗi phát sinh trong quá trình biên dịch, **tuyệt đối không đặt thư mục mã nguồn hoặc thư mục cài đặt phần mềm** tại các đường dẫn có chứa:
- ❌ Ký tự tiếng Việt có dấu
- ❌ Khoảng trắng (dấu cách)

**Ví dụ KHÔNG hợp lệ:**
- `D:\Do An\Travel App`
- `D:\Đại học\TravelApp`
- `C:\Program Files\Flutter Projects`

**Ví dụ hợp lệ:**
- ✅ `D:\Projects\TravelApp`
- ✅ `C:\src\flutter`
- ✅ `D:\DATN\Travel-Graduation-Workspace`

---

## 🛠️ Bước 1: Cài đặt Flutter SDK

### 1.1. Tải Flutter SDK
- Tải Flutter SDK dành cho Windows từ [trang chủ của Flutter](https://docs.flutter.dev/get-started/install/windows) hoặc sử dụng phiên bản ổn định [v3.38.4](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.38.4-stable.zip) (hoặc bản mới nhất trên trang chủ).

### 1.2. Giải nén Flutter
- Giải nén tập tin đã tải vào ổ đĩa hệ thống.
- **Cấu trúc thư mục khuyến nghị:** `C:\src\flutter`

### 1.3. Cấu hình biến môi trường (Environment Variables)
1. Truy cập vào mục **"Edit the system environment variables"** thông qua thanh tìm kiếm của Windows.
2. Chọn **"Environment Variables"**.
3. Tại mục **System variables**, tìm biến **Path** và chọn **Edit**.
4. Chọn **New** và thêm đường dẫn: `C:\src\flutter\bin`
5. Lưu lại toàn bộ các thay đổi.

### 1.4. Kiểm tra cài đặt
Mở **Command Prompt (CMD)** hoặc **PowerShell** và nhập lệnh:
```bash
flutter --version
```
Nếu hiển thị thông tin phiên bản Flutter, cài đặt đã thành công.

---

## 📦 Bước 2: Cài đặt Android SDK (tối ưu hóa dung lượng)

Quy trình này giúp thiết lập các công cụ cần thiết cho Android mà **không cần cài đặt toàn bộ phần mềm Android Studio**.

### 2.1. Thiết lập cấu trúc thư mục
1. Tạo thư mục gốc: `AndroidSDK` (ví dụ: `D:\AndroidSDK`)
2. Tạo thư mục con theo cấu trúc: `AndroidSDK\cmdline-tools\latest\`

### 2.2. Tải công cụ dòng lệnh (Command line tools)
1. Tải bản dành cho Windows tại mục **"Command line tools only"** trên trang [Android Developer](https://developer.android.com/studio#command-tools).
2. Giải nén và sao chép toàn bộ nội dung bên trong thư mục `cmdline-tools` (bao gồm các thư mục con như `bin`, `lib`) vào thư mục `latest` đã tạo ở bước trên.

### 2.3. Cài đặt các gói thành phần
1. Mở **CMD** với quyền quản trị (**Run as Administrator**).
2. Di chuyển đến thư mục chứa công cụ:
   ```bash
   cd /d D:\AndroidSDK\cmdline-tools\latest\bin
   ```
   *(Thay đổi ký tự ổ đĩa tuỳ theo sở thích và tương ứng với máy tính của người dùng)*

3. Thực thi lệnh cài đặt:
   ```bash
   sdkmanager.bat "platform-tools" "platforms;android-36" "build-tools;28.0.3"
   ```
4. Xác nhận các điều khoản bằng cách nhập `y` khi được yêu cầu.

### 2.4. Liên kết Android SDK với Flutter
Tại **CMD**, nhập lệnh cấu hình đường dẫn:
```bash
flutter config --android-sdk "D:\AndroidSDK"
```
*(Thay đổi đường dẫn phù hợp với vị trí bạn đã cài)*

### 2.5. Chấp nhận các giấy phép bản quyền của Android
```bash
flutter doctor --android-licenses
```
Nhập `y` cho tất cả các yêu cầu xác nhận.

---

## 💻 Bước 3: Cài đặt Visual Studio Code và Tiện ích mở rộng

1. Cài đặt trình soạn thảo mã nguồn [Visual Studio Code](https://code.visualstudio.com/).
2. Truy cập mục **Extensions** (phím tắt `Ctrl + Shift + X`) và cài đặt hai tiện ích sau:
   - **Flutter**
   - **Dart**

---

## ✅ Bước 4: Kiểm tra hệ thống và Khởi chạy ứng dụng

### 5.1. Kiểm tra tổng quát
Mở **Terminal** và nhập lệnh:
```bash
flutter doctor
```
Nếu các hạng mục chính đều hiển thị dấu **✓** (xác nhận hoàn tất) là đã cài đặt thành công.

> **Lưu ý:** Các thông báo liên quan đến trình duyệt Chrome hoặc các thành phần không liên quan có thể bỏ qua.

---

**Happy Coding! 🚀**

*Last updated: February 2026*
