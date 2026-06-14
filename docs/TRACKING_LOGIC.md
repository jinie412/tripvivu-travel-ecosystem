# Tracking Logic — Logic theo dõi lịch trình (geofence + dwell)

> Tài liệu này mô tả **luồng chạy bên trong** của tính năng theo dõi lịch trình
> trên mobile: cách phát hiện người dùng đến địa điểm, cách đánh dấu "Đã ghé",
> thời gian phản hồi và cách tối ưu pin. Phần giao diện xem ở [TRACKING_UI.md](./TRACKING_UI.md).

---

## 1. Bức tranh tổng thể

Mục tiêu: khi người dùng **đến và ở lại đủ lâu** tại một địa điểm trong lịch
trình → tự động đánh dấu "Đã ghé" + bắn thông báo "Đã đến nơi 🎉".

Có **hai cơ chế phát hiện song song**, bù trừ cho nhau:

| Cơ chế | Khi nào hoạt động | Tốc độ | Nguồn |
|--------|-------------------|--------|-------|
| **Foreground chủ động** | App đang mở (màn tracking) | Nhanh (~20-130s) | `TrackingCubit` tự poll GPS |
| **Native geofence (nền)** | App bị kill / chạy nền | Chậm (vài phút) | Google Play Services |

> **Vì sao cần cả hai?** Native geofence của Android là **passive** — để tiết
> kiệm pin nó gom location theo lô (batching), có thể trễ 2–5 phút và bỏ qua
> `notificationResponsiveness` khi màn hình tắt. Đây là giới hạn hệ điều hành,
> không sửa được bằng cấu hình. Nên khi app đang mở, ta **tự** tính khoảng cách
> để phản hồi nhanh; khi app đóng thì đành dựa vào native.

---

## 2. Các khái niệm

- **Geofence**: vùng tròn quanh một địa điểm (tâm = lat/lng, bán kính =
  `radiusM`, mặc định **200m**).
- **ENTER**: sự kiện khi người dùng **vào** vùng. Chỉ ghi mốc, *chưa* tính "Đã ghé".
- **DWELL**: sự kiện khi người dùng **ở lại đủ lâu** trong vùng → đánh dấu "Đã ghé".
- **EXIT**: sự kiện khi người dùng **ra khỏi** vùng.
- **`dwell_threshold_seconds`**: ngưỡng (giây) cần ở lại để tính "Đã ghé".
  Backend tính lúc `/start`, lưu trong DB.
- **`dwellSeconds`**: giá trị mobile **gửi lên** trong sự kiện DWELL. Hiện mobile
  gửi lại chính `dwell_threshold_seconds` đã cache (xem mục 7), nên backend check
  `dwellSeconds >= threshold` luôn đúng khi DWELL fire.

---

## 3. Luồng "Bắt đầu theo dõi" (`TrackingCubit.start`)

```
Người dùng bấm "BẮT ĐẦU LỊCH TRÌNH"
        │
        ▼
1. Gọi API  POST /itinerary/tracking/start
        → backend trả danh sách geofence (lat/lng/radius/dwellThreshold)
        │
        ▼
2. Lưu TrackingContext vào SharedPreferences
        (baseUrl, touristId, itineraryId, date, tên + dwell từng điểm)
        → để background isolate đọc được khi app bị kill
        │
        ▼
3. removeAll() geofence cũ   ← tránh "lây" sự kiện từ session/lịch trình trước
        │
        ▼
4. registerAll() geofence mới với native (loiteringDelay = dwell.clamp(30,120))
        → nếu registered == 0 → báo lỗi quyền vị trí "Luôn cho phép"
        │
        ▼
5. Đặt AlarmManager 23:00 để kết thúc ngày (remove geofence + mark skipped)
        │
        ▼
6. Nạp _geofences cho phát hiện chủ động foreground + reset detection state
        │
        ▼
7. Bật refresh timer (30s) + location stream (mục 5)
```

**Vì sao `removeAll()` trước khi `registerAll()`?** Hai lịch trình khác nhau có
thể trỏ tới cùng một địa điểm vật lý. Geofence cũ còn sót lại trong Android OS sẽ
kích hoạt và ghi nhận nhầm cho lịch trình đang theo dõi. Xoá sạch trước là cách
chống "nhiễm chéo".

---

## 4. Phát hiện chủ động foreground (`_evaluateGeofences`)

Đây là phần làm DWELL **về nhanh** khi app đang mở.

### Trạng thái lưu trong cubit

```dart
List<TrackingGeofence> _geofences;   // geofence của ngày (lat/lng/dwell)
Position? _lastPosition;             // vị trí GPS mới nhất
Set<String> _insideIds;              // các điểm đang ở TRONG vùng
Map<String,DateTime> _enteredAt;     // mốc thời gian vào từng vùng
Set<String> _dwellSentIds;           // đã gửi DWELL thành công (chống lặp)
Set<String> _visitedIds;             // đã "Đã ghé" → bỏ qua, không gửi lại
```

### Vòng đánh giá (chạy mỗi khi có vị trí mới HOẶC mỗi 5s khi đang trong vùng)

```
Với mỗi geofence g (bỏ qua nếu đã visited):
    khoảng_cách = haversine(viTriHienTai, tâm g)  [mét]
    inside = khoảng_cách <= g.radiusM

    NẾU inside:
        • Lần đầu vào vùng (chưa có trong _insideIds):
              → thêm _insideIds, ghi _enteredAt = now
              → bật dwell timer (mục 6)
              → GỬI ENTER
        • Đã ở trong, chưa gửi DWELL:
              elapsed = now - _enteredAt
              NẾU elapsed >= dwellForeground(threshold):
                    → đánh dấu _dwellSentIds
                    → GỬI DWELL  (nếu lỗi mạng → bỏ cờ để thử lại sau)
    NGƯỢC LẠI (ra khỏi vùng):
        NẾU đang trong _insideIds:
              → xoá khỏi _insideIds/_enteredAt/_dwellSentIds
              → GỬI EXIT

Cuối vòng: nếu _insideIds rỗng → tắt dwell timer (tiết kiệm pin)
```

### Khi DWELL được backend xác nhận "visited"

```dart
_visitedIds.add(detailId);   // không gửi lại nữa
await refreshStatus();       // cập nhật màu/icon trên bản đồ + "Đã đi X/Y"
_showArrivalNotification();  // thông báo cục bộ "Đã đến nơi 🎉"
```

### `dwellForeground` — ngưỡng chờ thực tế

```dart
static int _foregroundDwell(int threshold) => threshold.clamp(15, 120);
```

Dù backend trả threshold lớn (vd 780s = 13 phút), foreground **chỉ chờ tối đa
120s**. Sàn 15s để test nhanh. Lưu ý: giá trị `dwellSeconds` *gửi lên* vẫn là
threshold gốc (780), nên backend check `780 >= 780` vẫn đúng.

---

## 5. Location stream + độ chính xác thích ứng (tối ưu pin)

GPS độ chính xác cao là thứ **tốn pin nhất**. Nên chỉ bật khi thực sự cần.

### `_subscribeLocationStream({highAccuracy})`

```dart
accuracy:       highAccuracy ? high   : medium
distanceFilter: highAccuracy ? 10m    : 100m
```

### `_maybeSwitchAccuracy(pos)` — đổi chế độ theo khoảng cách

```
nearest = khoảng cách tới điểm CHƯA ghé gần nhất
NẾU nearest <= 500m  → bật high  (sắp tới nơi → cần chính xác bắt ENTER/DWELL)
NẾU nearest >  500m  → hạ medium (đang di chuyển/đứng xa → nhẹ pin)
Chỉ resubscribe khi chế độ thực sự đổi (tránh hủy/tạo stream liên tục).
```

→ Kết quả: GPS chính xác cao **chỉ chạy lúc đang ở gần địa điểm**; lúc đi đường
giữa các điểm hoặc đứng xa thì dùng medium.

### Stream này phục vụ 3 việc cùng lúc (`_onPosition`)

1. `_evaluateGeofences()` — phát hiện geofence chủ động (mục 4)
2. `_checkFoodProximity()` — gợi ý quán ăn gần (≤ 5km)
3. `_maybeSwitchAccuracy()` — điều chỉnh độ chính xác GPS

---

## 6. Dwell timer — chỉ chạy khi cần

Vấn đề: khi người dùng **đứng yên** trong vùng, location stream không emit thêm
(do `distanceFilter`), nên không có gì kích hoạt việc kiểm tra "đã đủ dwell chưa".

Giải pháp: một `Timer.periodic(5s)` gọi lại `_evaluateGeofences()`.

**Tối ưu pin:** timer **chỉ bật khi `_insideIds` không rỗng** (đang chờ dwell ở
ít nhất một vùng) và **tự tắt khi ra khỏi mọi vùng**:

```dart
_ensureDwellTimer()      // gọi khi VÀO một vùng
_stopDwellTimerIfIdle()  // gọi cuối mỗi vòng; tắt nếu _insideIds rỗng
```

→ Lúc đang di chuyển ngoài mọi vùng (phần lớn thời gian), timer **không chạy**.

---

## 7. Cache & background isolate

`TrackingContext` (SharedPreferences) là cầu nối giữa **main isolate** (app) và
**background isolate** (native geofence callback chạy khi app bị kill).

- Background isolate **không** có DI, không đọc được `flutter_dotenv`, không chia
  sẻ bộ nhớ với app → mọi thứ cần thiết (baseUrl, touristId, tên + dwell từng
  điểm) phải được **persist lúc `/start`**.
- Callback nền (`geofence_callback.dart`) đọc context từ SharedPreferences rồi tự
  gọi `POST /itinerary/tracking/event`.

> ⚠️ **Hệ quả quan trọng:** geofence native dùng `dwellThresholdSeconds` đã cache
> lúc bấm Bắt đầu. Nếu sửa `dwell_threshold_seconds` trong DB **sau đó**, mobile
> đang chạy **không** thấy thay đổi (cả `loiteringDelay` đã đăng ký lẫn giá trị
> gửi lên đều là bản cache cũ). Muốn áp dụng giá trị mới → **Dừng rồi Bắt đầu lại**
> theo dõi để mobile nạp lại.

---

## 8. Thời gian DWELL về thực tế

### Foreground (app đang mở)

```
≈ clamp(threshold, 15, 120)  +  ~5s (timer)  +  ~1-5s (phát hiện GPS lần đầu)
```

| threshold (cache) | chờ dwell | tổng |
|-------------------|-----------|------|
| ≤ 15s | 15s | ~20–25s |
| 60s | 60s | ~65–70s |
| 780s (13 phút) | 120s (trần) | ~125–130s |

### Background (app bị kill)

```
≈ clamp(threshold, 30, 120)  +  độ trễ passive của Android (vài phút, không kiểm soát)
```

---

## 9. Khôi phục sau khi app khởi động lại (`restoreIfActive`)

```
Đọc TrackingContext từ SharedPreferences
        │  (nếu không có / hết ngày → thôi)
        ▼
Emit trạng thái active + gọi /status để lấy bản đồ
        │
        ▼
_rebuildGeofencesFromStatus(status)
        → dựng lại _geofences từ lat/lng trong /status
          (context chỉ lưu tên + dwell, KHÔNG lưu lat/lng)
        → đánh dấu _visitedIds cho điểm đã ghé/đã bỏ qua
        │
        ▼
Bật refresh timer + location stream  → phát hiện chủ động hoạt động trở lại
```

---

## 10. Dừng theo dõi & dọn dẹp

Cả `stop()` (người dùng bấm Dừng) và `clearStaleCache()` (DB báo không còn active)
đều dọn sạch:

```dart
_refreshTimer / _geofenceTimer        → cancel
_locationSub                          → cancel
_resetDetectionState()                → xoá _geofences + các Set/Map detection
_geofenceSvc.removeAll()              → gỡ geofence khỏi Android OS
_alarmSvc.cancelAll()                 → huỷ alarm 23:00
TrackingContextStore.clear()          → xoá cache SharedPreferences
```

> Việc gỡ geofence khỏi Android OS rất quan trọng: nếu không, callback nền vẫn có
> thể fire khi người dùng đi ngang khu vực đã từng theo dõi → ghi nhận giả.

---

## 11. Đồng bộ chống gửi trùng

`_visitedIds` được nạp từ `/status` ở **3 chỗ**: `start`, `refreshStatus`,
`_rebuildGeofencesFromStatus`. Nhờ vậy nếu một điểm đã được đánh dấu "Đã ghé"
qua *native callback* hoặc *check-in thủ công*, foreground sẽ **không** gửi lại
sự kiện cho điểm đó.

---

## 12. Bản đồ các file

| File | Vai trò |
|------|---------|
| `tracking_cubit.dart` | Điều phối chính: start/stop, phát hiện chủ động, location stream, độ chính xác thích ứng |
| `geofence_tracking_service.dart` | Đăng ký/gỡ geofence với native (Google Play Services) |
| `geofence_callback.dart` | Callback chạy ở **background isolate** khi app bị kill |
| `tracking_context.dart` | Cache `TrackingContext` qua SharedPreferences (cầu nối 2 isolate) |
| `tracking_alarm_service.dart` | AlarmManager kết thúc ngày 23:00 |
| `tracking_remote_datasource.dart` | 6 endpoint backend `/itinerary/tracking/*` |
| `tracking_models.dart` | Model: `TrackingGeofence`, `TrackingPlaceStatus`, `GeofenceEventResult`… |
| `tracking_config.dart` | Hằng số: `radiusM=200`, `dwellSeconds=120`, `foodProximityKm=5` |

### Vị trí ngoài trang Khám phá (liên quan)

| File | Vai trò |
|------|---------|
| `location_service.dart` | Lấy GPS + reverse-geocode (Nominatim) + `positionStream` (medium) |
| `location_cubit.dart` | Header "VỊ TRÍ CỦA BẠN": lấy lần đầu + tự cập nhật khi di chuyển ≥ 150m |

---

## 13. Các hằng số chỉnh nhanh

| Hằng số | Giá trị | Ý nghĩa | File |
|---------|---------|---------|------|
| `radiusM` | 200m | Bán kính geofence | `tracking_config.dart` |
| `_foregroundDwell` clamp | 15–120s | Khoảng chờ DWELL foreground | `tracking_cubit.dart` |
| `loiteringDelay` clamp | 30–120s | Khoảng chờ DWELL native nền | `geofence_tracking_service.dart` |
| `_highAccuracyRangeM` | 500m | Ngưỡng bật GPS chính xác cao | `tracking_cubit.dart` |
| dwell timer | 5s | Chu kỳ kiểm tra khi đứng yên trong vùng | `tracking_cubit.dart` |
| food stream distanceFilter | 100m (medium) / 10m (high) | Tần suất cập nhật vị trí | `tracking_cubit.dart` |
| explore distanceFilter | 100m (medium) | Cập nhật tên khu vực | `location_service.dart` |
| `_refreshDistanceM` | 150m | Đi bao xa thì geocode lại tên khu vực | `location_cubit.dart` |
| `MIN_DWELL_SECONDS` | 30 | Sàn ngưỡng dwell (backend) | `itinerary-tracking.constants.ts` |
| `DWELL_FRACTION` | 0.05 | Tỉ lệ thời lượng → ngưỡng dwell (backend) | `itinerary-tracking.constants.ts` |
