# Memory Optimization — Tối ưu RAM để app sống sót khi đa nhiệm

> Tài liệu này mô tả đợt tối ưu bộ nhớ (07/2026) nhằm khắc phục tình trạng
> **app dễ bị Android kill khi người dùng đa nhiệm / chuyển sang app khác**.
> Phần theo dõi lịch trình chạy nền xem [TRACKING_LOGIC.md](./TRACKING_LOGIC.md).

---

## 1. Vấn đề & nguyên nhân gốc

**Triệu chứng:** chuyển sang app khác một lúc rồi quay lại → app bị khởi động
lại từ đầu (bị hệ điều hành kill).

**Nguyên nhân KHÔNG phải** thiếu foreground service — tracking đã có sẵn
foreground service (xem TRACKING_LOGIC.md mục 5). Nguyên nhân là **app chiếm
quá nhiều RAM**: khi thiếu bộ nhớ, Low Memory Killer của Android kill các
process nền **ngốn RAM nhất trước**. App này nặng vì:

1. **Ảnh mạng được giải mã ở độ phân giải gốc.** Một ảnh 4000×3000px hiển thị
   trong ô thumbnail 56dp vẫn chiếm `4000 × 3000 × 4 byte ≈ 46MB` RAM sau khi
   giải mã. Không có chỗ nào trong app đặt `memCacheWidth`/`cacheWidth`.
2. **Cache ảnh trong RAM của Flutter mặc định 100MB / 1000 ảnh** — không được
   giới hạn lại, và không được xả khi app vào nền.
3. **Mapbox** (map native) vốn đã chiếm 100–200MB khi mở.
4. `IndexedStack` giữ sống đồng thời 4 tab → ảnh của mọi tab cùng nằm trong RAM.

Tối ưu tập trung vào (1) và (2) — tác động lớn nhất, không đổi UX.

---

## 2. Các thay đổi

### 2.1. Giới hạn + xả cache ảnh toàn cục — `lib/main.dart`

**Hạ trần cache ảnh giải mã trong RAM** (trong `main()`, trước `runApp`):

```dart
PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20; // 48MB (mặc định 100MB)
PaintingBinding.instance.imageCache.maximumSize = 300;           // (mặc định 1000 ảnh)
```

**Xả cache khi app vào nền** — `_TravelAdvisorAppState` mix thêm
`WidgetsBindingObserver`:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    PaintingBinding.instance.imageCache.clear();
  }
}
```

- Ảnh **đang hiển thị** không bị ảnh hưởng (widget còn giữ tham chiếu, không
  bị flash trắng khi quay lại).
- Ảnh khác nạp lại từ **disk cache** (`AppImageCacheManager`, 7 ngày / 300
  file) nên chỉ tốn giải mã lại, không tải mạng lại.
- Đây là thay đổi trực tiếp nhất: RAM chiếm giữ giảm mạnh **đúng thời điểm**
  Android cân nhắc kill process nào.

### 2.2. `NetImage` giải mã đúng kích thước hiển thị — `lib/core/widgets/net_image.dart`

`NetImage` là widget ảnh dùng chung (~19 file). Bọc `CachedNetworkImage` trong
`LayoutBuilder` và đặt `memCacheWidth = _decodeWidth(...)`:

```
_decodeWidth = max(width, height, constraints.maxWidth, constraints.maxHeight
                   — chỉ lấy giá trị hữu hạn)
               × devicePixelRatio, clamp [64, 1440]
```

- Lấy **cạnh lớn nhất** của khung để ảnh `BoxFit.cover` trong khung cao/hẹp
  không bị vỡ nét.
- Trần 1440px vật lý đủ cho ảnh mở toàn màn hình.
- Kết quả: ảnh card 160dp chiếm ~1MB thay vì hàng chục MB.

### 2.3. Thêm `memCacheWidth`/`cacheWidth` cho 21 chỗ dùng ảnh trực tiếp

Các chỗ dùng `CachedNetworkImage` / `Image.network` không qua `NetImage`,
đặt theo kích thước hiển thị thật (≈ dp × 3 cho dpr tối đa phổ biến):

| Nhóm | Giá trị | File |
|------|---------|------|
| Card dọc 100×100 (city detail) | `memCacheWidth: 300` | `restaurant_vertical_card.dart`, `itinerary_vertical_card.dart`, `hotel_vertical_card.dart`, `activity_vertical_card.dart` |
| Card hero full-width (height 180) | `memCacheWidth: 1080` | `city_detail_cards.dart` (1 chỗ) |
| Card carousel 4:3 | `memCacheWidth: 720` | `city_detail_cards.dart` (3 chỗ) |
| Thumbnail tìm kiếm 56dp | `memCacheWidth: 168` | `search_suggestion_widget.dart`, `search_result_widget.dart` |
| Avatar dùng chung | `memCacheWidth: (radius × 2 × dpr).ceil()` | `default_avatar.dart` |
| Avatar profile 60dp (provider) | `CachedNetworkImageProvider(url, maxWidth: 180)` | `profile_header.dart` |
| Avatar drawer 50dp | `memCacheWidth: 150` | `profile_drawer.dart` |
| Ảnh nền header edit profile | `memCacheWidth: 1080` | `edit_profile_screen.dart` |
| Card lịch trình full-width | `memCacheWidth: 1080` | `saved_itinerary_card.dart`, `itinerary_completed_card.dart`, `itinerary_card.dart` (2 chỗ), `home_itinerary_card.dart` |
| Ảnh review (viewer) | `cacheWidth: 1080` | `review_catalog_screen.dart` (`_CorsFriendlyImage`) |
| Thumbnail media review 52dp | `cacheWidth: 156` | `location_review_list_tile.dart` |
| Thumbnail sheet xung đột 60dp | `cacheWidth: 180` | `conflict_resolution_sheet.dart` |
| Avatar thành viên (summary) | `cacheWidth: (size × 3).ceil()` | `itinerary_summary_screen.dart` |

> **Quy ước từ nay:** thêm ảnh mạng mới → **ưu tiên dùng `NetImage`** (tự
> clamp). Nếu buộc dùng `CachedNetworkImage`/`Image.network` trực tiếp thì
> **bắt buộc** đặt `memCacheWidth`/`cacheWidth` ≈ kích thước hiển thị (dp) × 3.

---

## 3. Kiểm chứng

- `flutter analyze`: không phát sinh lỗi/cảnh báo mới từ các thay đổi
  (84 issue còn lại đều là lint có sẵn từ trước: deprecated API, `print`,
  unused element).
- Đo RAM thực tế:

```bash
# Mở app, lướt vài màn hình nhiều ảnh, rồi bấm Home, sau đó:
adb shell dumpsys meminfo <package_name>
```

So sánh **TOTAL PSS** trước/sau đợt tối ưu — phần Graphics/Dart heap thường
giảm 30–50% khi app ở nền.

---

## 4. Giới hạn còn lại & hướng tiếp theo (chưa làm)

- **OEM battery manager** (Xiaomi/Oppo/Vivo...) có thể kill app bất chấp mọi
  tối ưu. Người dùng cần bật "Không giới hạn pin" / khóa app trong recent
  apps. Tracking khi bị kill đã có native geofence + `restoreIfActive` bù
  (TRACKING_LOGIC.md mục 1, 9).
- **Mapbox**: map native trong màn chi tiết lịch trình chiếm 100–200MB và
  giữ nguyên khi app vào nền. Có thể dispose map khi màn bị che khuất lâu,
  nhưng đổi UX (map phải nạp lại khi quay lại) → cân nhắc sau.
- **`IndexedStack` 4 tab**: giữ sống mọi tab là lựa chọn UX có chủ đích
  (không mất trạng thái khi đổi tab); với ảnh đã clamp thì chi phí chấp
  nhận được.
