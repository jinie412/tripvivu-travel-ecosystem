
# ✈️ GPTravelAdvisor - Flutter Architecture Guide

![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-green?style=for-the-badge)
![State Management](https://img.shields.io/badge/State%20Management-BLoC%2FCubit-red?style=for-the-badge)

Tài liệu này hướng dẫn cách tổ chức code và quy trình phát triển tính năng mới. Chúng ta sử dụng **Clean Architecture** kết hợp với **Cubit (BLoC)** để đảm bảo dự án dễ bảo trì và mở rộng.

---

## 📂 1. Cấu trúc thư mục (Folder Structure)

Khi mở dự án, bạn sẽ thấy cấu trúc phân cấp như sau:

```text
lib/
├── main.dart               # Điểm khởi đầu của ứng dụng
├── core/                   # Những thứ dùng chung cho toàn bộ dự án
│   ├── constants/          # Màu sắc (AppColors), Spacing, Strings
│   ├── di/                 # Dependency Injection (injection_container.dart)
│   ├── errors/             # Xử lý lỗi (Failure, Exceptions)
│   ├── network/            # Cấu hình API Client (Dio)
│   ├── theme/              # Cấu hình giao diện (AppTheme)
│   └── utils/              # Tiện ích, Extensions
├── features/               # Nơi chứa các tính năng (Mỗi folder là 1 feature)
│   ├── auth/               # Feature Đăng nhập/Đăng ký
│   ├── home/               # Feature Trang chủ/Khám phá
│   └── ...                 # Feature mới sẽ tạo tại đây
└── assets/                 # Hình ảnh, Icons (SVG), Fonts

```

---

## 🏗️ 2. Cấu trúc bên trong một Feature

Mỗi folder trong `features/` được chia làm 3 lớp (layers):

### 🔹 Presentation (Tầng giao diện)

* **Screens:** Các trang lớn của ứng dụng.
* **Widgets:** Các thành phần nhỏ có thể tái sử dụng.
* **Cubit:** Quản lý trạng thái (State) của UI.

### 🔹 Domain (Tầng Logic nghiệp vụ)

* **Entities:** Các đối tượng dữ liệu thuần Dart (không chứa logic JSON).
* **Repositories (Interface):** Các bản thiết kế quy định tính năng cần làm gì.
* **UseCases:** Các hành động cụ thể (VD: `GetHotelsUseCase`).

### 🔹 Data (Tầng Dữ liệu)

* **Models:** Đối tượng có chứa logic `fromJson` và `toJson`.
* **DataSources:** Nơi gọi API trực tiếp (Remote) hoặc lấy từ Cache (Local).
* **Repositories (Impl):** Thực thi các Interface từ tầng Domain.

---

## 🔄 3. Luồng dữ liệu (Data Flow)

Để phát triển tính năng, chúng ta tuân thủ luồng:
**UI** ➔ **Cubit** ➔ **UseCase** ➔ **Repository** ➔ **DataSource** ➔ **API**

Khi dữ liệu trả về:
**API (JSON)** ➔ **Model** ➔ **Entity** ➔ **Repository** ➔ **Cubit (State)** ➔ **UI (Rebuild)**

---

## 🚀 4. Quy trình thêm Feature mới

Thực hiện theo 8 bước để tránh sai sót:

1. **Entity:** Tạo tại `domain/entities/`.
2. **Model:** Tạo tại `data/models/` (Dùng `freezed` để generate).
3. **DataSource:** Viết hàm gọi API/Mock tại `data/datasources/`.
4. **Repository Impl:** Triển khai logic tại `data/repositories/`.
5. **UseCase:** Viết hàm thực thi logic cho UI tại `domain/usecases/`.
6. **Cubit:** Quản lý trạng thái `Loading`, `Loaded`, `Error` tại `presentation/cubit/`.
7. **UI:** Vẽ màn hình và dùng `BlocBuilder` để hiển thị dữ liệu.
8. **DI:** Đăng ký các lớp vào `core/di/injection_container.dart`.

---

## 🛠️ 5. Lệnh thực thi (Commands)

Chúng ta sử dụng `build_runner` để tự động tạo code cho Model & Entity.

* **Chạy một lần:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs

```

* **Chạy chế độ "Watch" (Tự động cập nhật khi lưu file):**

```bash
flutter pub run build_runner watch --delete-conflicting-outputs

```

---

## ⚠️ 6. Quy tắc bắt buộc (Coding Standards)

* **UI:** Không viết logic xử lý dữ liệu (if/else, tính toán) trong Widget. Tất cả phải nằm trong Cubit.
* **Dependency Injection:** Luôn sử dụng `sl<T>()` từ GetIt để khởi tạo đối tượng.
* **Assets:** Chỉ sử dụng định dạng `.svg` cho icon. Không vẽ icon bằng code.
* **Naming:**
* Folder/File: `snake_case` (ví dụ: `hotel_card_widget.dart`).
* Class: `PascalCase` (ví dụ: `HotelCardWidget`).


* **Colors:** Không dùng màu trực tiếp. Dùng `AppColors.primary`, `AppColors.background`.

---

## 🌍 7. Môi trường và Bảo mật (Environment Variables)

Dự án sử dụng `flutter_dotenv` để quản lý các biến môi trường và ẩn đi các thông tin nhạy cảm (như API Url, API Keys).

**Quy trình cho thành viên mới (Khi clone dự án về):**
1. Copy file `.env.example` và đổi tên thành `.env` tại thư mục gốc rễ (root) của dự án.
2. Mở file `.env` vừa tạo và điền các giá trị thực tế (Ví dụ: `BASE_URL=https://api.gptraveladvisor.com/v1`).
3. **Tuyệt đối không** commit file `.env` lên Git (file này đã được chặn trong `.gitignore`).

Mọi logic mạng đều tự động đọc biến môi trường thông qua cầu nối `ApiConfig` trong thư mục `core/network`.

---

> **Note:** Nếu bạn cần thay đổi từ dữ liệu ảo (Mock) sang dữ liệu thật (API), bạn chỉ cần sửa trong `injection_container.dart` bằng cách đổi DataSource, toàn bộ UI sẽ không bị ảnh hưởng.
