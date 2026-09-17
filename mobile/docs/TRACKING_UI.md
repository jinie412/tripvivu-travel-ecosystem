# Tracking UI — Theo dõi lịch trình

## Tổng quan

Tính năng theo dõi lịch trình cho phép tự động đánh dấu "Đã ghé" khi người dùng
đến đủ thời gian tại từng địa điểm (dùng native geofence + dwell timer chạy nền).

---

## Kiến trúc

```
ItineraryDetailScreen
└── BlocProvider<TrackingCubit>          ← provide ở đây (dùng chung cho cả màn hình)
    ├── BlocListener<TrackingCubit>      ← nghe nearbyRestaurant → show popup đặt món
    └── _ItineraryDetailView
        └── _buildContentCard(...)
            ├── TrackingSection          ← compact bar Bắt đầu / Đang theo dõi X/Y
            └── Builder (watch TrackingCubit)
                └── [TimelineActivityCard]  ← mỗi card nhận trackingStatus
```

---

## Nút "Bắt đầu lịch trình"

### Màn hình danh sách (`itinerary_screen.dart`)

Widget `_ItineraryCardWithStart` bọc `ItineraryCard` và hiện nút bên **ngoài** card:

```
┌─────────────────────────────────┐
│  [ảnh lịch trình]               │  ← ItineraryCard (không còn overlay toggle)
│  Tên · Ngày · Chi phí           │
└─────────────────────────────────┘
│ ▷ BẮT ĐẦU LỊCH TRÌNH    [🔘]   │  ← _StartButton (bên ngoài card)
└─────────────────────────────────┘
```

Khi đang diễn ra:
```
│ ◉ ĐANG DIỄN RA          [●━]   │
```

### Ràng buộc ngày (TODO — hiện đang bỏ qua)

```dart
// TODO(date-restriction): Bật lại khi muốn giới hạn nút chỉ hiện vào ngày lịch trình.
// bool get _dayReached {
//   if (item.startDate == null) return false;
//   final today = DateTime.now();
//   final s = item.startDate!;
//   return s.year == today.year && s.month == today.month && s.day == today.day;
// }
```

Khi bật lại: thay `_shouldShowStart` thành `_shouldShowStart && _dayReached`.

---

## Màn hình chi tiết (`itinerary_detail_screen.dart`)

### TrackingSection (compact bar)

- **Chưa bật**: nút full-width "Bắt đầu theo dõi lịch trình"
- **Đang bật**: `TrackingSection` không render UI nữa — tiến độ ngày hiển thị ở card **"Tiến độ tham quan"** (`_DayVisitProgressCard`) nằm ngay dưới box chi phí trong ngày: icon + "Đã đi x/z địa điểm trong ngày" + chip x/z + progress bar; đủ z địa điểm thì đổi màu xanh lá + "Đã ghé hết địa điểm trong ngày 🎉". Trạng thái "đã đi" gộp từ 3 nguồn (activity.status sau refresh, geofence_visits backend, tracking state RAM) nên refresh lẫn tracking realtime đều cập nhật đúng. Dòng "x/z đã đi" trong header box chi phí đã bỏ. `TrackingSection` vẫn nằm trong tree để sync activities (food proximity), dọn phiên stale theo `dbTrackingActive` và hiện snackbar message. Muốn dừng theo dõi dùng thẻ lịch trình ở trang Khám phá / Lịch trình của tôi.
- **Không còn liệt kê địa điểm riêng** — trạng thái hiện trực tiếp trong timeline

### Ràng buộc ngày trong TrackingSection

```dart
// TODO(date-restriction): Bật lại khi muốn giới hạn chỉ bắt đầu vào ngày lịch trình.
// bool get _dayReached { ... }
// canStart = _dayReached && !isCompleted
```

---

## Timeline Activities — Badge trạng thái

Khi tracking active, mỗi `TimelineActivityCard` hiện badge nhỏ bên trong card:

| Trạng thái    | Badge                          |
|---------------|-------------------------------|
| `visited`     | ✅ **Đã ghé** (chip xanh lá)  |
| `skipped`     | ⊘ **Đã bỏ qua** (chip đỏ)    |
| `notVisited`  | 📍 **Tôi đã đến** (nút xanh dương, bấm để check-in thủ công) |

Loading spinner thay nút khi đang xử lý check-in (`isCheckingIn == true`).

> Điều kiện "đã ghé" được gộp từ **cả 3 nguồn** (`_isVisited`): tracking state
> trong RAM, `activity.status == daDi` (chi tiết lịch trình sau refresh) và
> `backendIsVisited` (geofence_visits). Địa điểm đã check-in thì sau refresh
> luôn hiện badge "Đã đến nơi", không hiện lại nút "Tôi đã đến" kể cả khi
> tracking state chưa kịp đồng bộ.

---

## Refresh tự động — 60 giây

`TrackingCubit` chạy `Timer.periodic(60s)` gọi `refreshStatus()` khi tracking active.
Timer bị hủy khi `stop()` hoặc `close()` được gọi.

---

## Phát hiện quán ăn gần đây

### Cấu hình

```dart
// tracking_cubit.dart
static const double kFoodProximityKm = 5.0;  // đổi giá trị này để config
```

### Luồng

1. Khi `start()` được gọi, lọc các activity có `category` là food/restaurant.
2. Subscribe vào `Geolocator.getPositionStream(distanceFilter: 200m)`.
3. Mỗi khi GPS cập nhật, tính khoảng cách Haversine đến từng quán ăn.
4. Nếu `distance <= kFoodProximityKm` → emit `nearbyRestaurantName` vào state.
5. `BlocListener<TrackingCubit>` trong `ItineraryDetailScreen` bắt event → show `PreOrderPopup`.
6. Đóng popup → gọi `dismissNearbyRestaurant()` để tránh hiện lại ngay.

### Category keywords nhận diện

```dart
static const _foodKeywords = [
  'nhà hàng', 'restaurant', 'cafe', 'cà phê', 'ăn uống',
  'quán ăn', 'buffet', 'fastfood', 'fast food', 'food', 'ẩm thực',
];
```

### Mở rộng tương lai

Để show popup từ bất kỳ màn hình nào (trang chủ, lịch trình list):
- Cần đưa `TrackingCubit` lên `MainShell` level (hoặc dùng global service với `NavigatorKey`).
- Hiện tại popup chỉ hiện khi user đang ở màn hình chi tiết lịch trình.

---

## File liên quan

| File | Vai trò |
|------|---------|
| `tracking_cubit.dart` | State management, timer, location stream |
| `tracking_state.dart` | State model (thêm nearbyRestaurant fields) |
| `tracking_section.dart` | Compact bar UI (consume TrackingCubit từ cha) |
| `timeline_activity_card.dart` | Badge Đã ghé / nút Tôi đã đến |
| `itinerary_detail_screen.dart` | Hoist BlocProvider, food popup listener |
| `itinerary_screen.dart` | Nút Bắt đầu bên ngoài card |
| `itinerary_card.dart` | Bỏ overlay toggle trên ảnh |
