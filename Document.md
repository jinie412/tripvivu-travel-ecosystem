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

# 🏗️ Chi tiết cấu trúc một Feature (Feature Layers)

Mỗi tính năng (Feature) trong dự án phải được phân tách rạch ròi thành 3 lớp chính để đảm bảo UI không bao giờ can thiệp trực tiếp vào dữ liệu thô.

---

## 📂 1. Presentation Layer (Tầng hiển thị)
*Đây là nơi duy nhất chứa code Flutter (Widget).*

- **`screens/`**: Chứa các trang chính của feature (ví dụ: `home_screen.dart`).
- **`widgets/`**: Chứa các thành phần giao diện nhỏ chỉ dùng riêng cho feature này (ví dụ: `hotel_card.dart`).
- **`cubit/`**: Nơi quản lý State (Trạng thái). 
    - `*_cubit.dart`: Xử lý logic và phát ra (emit) trạng thái.
    - `*_state.dart`: Định nghĩa các trạng thái của màn hình (Initial, Loading, Success, Error).



---

## 📂 2. Domain Layer (Tầng nghiệp vụ)
*Đây là "não bộ" của dự án, chỉ chứa code Dart thuần túy (Pure Dart), không phụ thuộc vào Flutter hay API.*

- **`entities/`**: Định nghĩa các đối tượng dữ liệu mà UI cần hiển thị (ví dụ: `Hotel`, `User`).
- **`repositories/`**: Định nghĩa các **Interface** (Abstract class). Nó chỉ nói "Tôi cần lấy dữ liệu khách sạn", còn lấy ở đâu thì nó không quan tâm.
- **`usecases/`**: Mỗi hành động của người dùng là một UseCase (ví dụ: `GetTopHotels`, `SearchDestinations`).

---

## 📂 3. Data Layer (Tầng dữ liệu)
*Nơi trực tiếp làm việc với môi trường bên ngoài (API, Database).*

- **`models/`**: Chứa các class kế thừa từ Entity nhưng có thêm phương thức `fromJson` và `toJson`.
- **`datasources/`**: 
    - `remote_data_source.dart`: Gọi API qua Dio.
    - `local_data_source.dart`: Lấy dữ liệu từ SharedPreferences hoặc SQLite.
- **`repositories/`**: Bản thực thi (Implementation) của Interface bên Domain. Nó sẽ điều phối việc lấy dữ liệu từ DataSource nào và chuyển đổi (map) từ **Model** sang **Entity**.

---

## 🔄 Mối quan hệ giữa các thành phần

| Từ (Source) | Gọi đến (Target) | Phương thức |
| :--- | :--- | :--- |
| **UI** | **Cubit** | `context.read<MyCubit>().doSomething()` |
| **Cubit** | **UseCase** | `useCase.execute()` |
| **UseCase** | **Repository (Interface)** | `repository.getData()` |
| **Repository (Impl)** | **DataSource** | `remoteDataSource.fetchRawData()` |

---

## 💡 Ví dụ về quy tắc đặt tên (Naming Convention)

Giả sử làm feature **Auth**:
- **Entity**: `UserEntity`
- **Model**: `UserModel`
- **Repository Interface**: `AuthRepository`
- **Repository Implementation**: `AuthRepositoryImpl`
- **Cubit**: `AuthCubit`