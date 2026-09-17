# GPTravelAdvisor — Mobile Flutter CLAUDE.md

## 🏗️ Architecture: Clean Architecture + Cubit (BLoC)

## 📂 Folder Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/     # AppColors, Spacing, Strings
│   ├── di/            # GetIt - injection_container.dart
│   ├── errors/        # Failure, Exceptions
│   ├── network/       # Dio client, ApiConfig (đọc từ .env)
│   ├── theme/         # AppTheme
│   └── utils/         # Extensions, helpers
├── features/
│   ├── auth/
│   ├── home/
│   └── [feature_moi]/ # Tạo tại đây
└── assets/            # Chỉ dùng .svg cho icon
```

## 🔄 Data Flow (bắt buộc tuân theo)

UI → Cubit → UseCase → Repository → DataSource → API
API → Model → Entity → Repository → Cubit State → UI

## 🚀 Thêm Feature mới (8 bước theo thứ tự)

1. Entity → `domain/entities/`
2. Model → `data/models/` (dùng `freezed`)
3. DataSource → `data/datasources/`
4. Repository Impl → `data/repositories/`
5. UseCase → `domain/usecases/`
6. Cubit → `presentation/cubit/` (các state: Loading, Loaded, Error)
7. UI → `presentation/screens/` hoặc `presentation/widgets/`
8. DI → đăng ký trong `core/di/injection_container.dart`

## ⚠️ Coding Standards (bắt buộc)

- **UI Widget**: KHÔNG chứa logic if/else, tính toán — tất cả để trong Cubit
- **DI**: Luôn dùng `sl<T>()` từ GetIt
- **Icons**: Chỉ dùng file `.svg`, không vẽ icon bằng code
- **Colors**: Không dùng màu hex trực tiếp — dùng `AppColors.primary`, `AppColors.background`
- **Naming**:
  - File/Folder: `snake_case` → `hotel_card_widget.dart`
  - Class: `PascalCase` → `HotelCardWidget`
- **Null safety**: Luôn handle, không dùng `!` bừa bãi
- **Mock → Real API**: Chỉ sửa DataSource trong `injection_container.dart`, không đụng UI

## 🛠️ Commands hay dùng

```bash
# Generate code (freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode
flutter pub run build_runner watch --delete-conflicting-outputs

# Run app
flutter run

# Analyze
flutter analyze
```

## 🌍 Environment

- Dùng `flutter_dotenv`
- Copy `.env.example` → `.env`, điền `BASE_URL` và các key
- KHÔNG commit `.env`
- Mọi config mạng đọc qua `ApiConfig` trong `core/network/`

## 🔐 Auth

- JWT token — lưu trong secure storage
- Refresh token tự động khi expired (xử lý trong Dio interceptor)

---

> **Note:** Nếu bạn cần thay đổi từ dữ liệu ảo (Mock) sang dữ liệu thật (API), bạn chỉ cần sửa trong `injection_container.dart` bằng cách đổi DataSource, toàn bộ UI sẽ không bị ảnh hưởng.
