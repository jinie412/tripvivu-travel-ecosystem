# Backup — UI filter mock của City Detail (trước khi rework 2026-07-04)

Đây là bản gốc của phần filter city detail khi còn dựa trên **mock data**
(khoảng giá, danh sách quận/huyện mẫu của TP.HCM, món ăn, mức giá nhà hàng,
tiện ích, loại hình lưu trú, khoảng giá khách sạn...). Các option này không có
dữ liệu thật từ backend `/explore/cities/:id/overview` nên filter không hoạt
động — đã được thay bằng bộ filter mới chỉ dùng field có dữ liệu thật.

| File backup | Vị trí gốc |
|---|---|
| `filter_bottom_sheet.dart.bak` | `lib/features/city_detail/presentation/widgets/filter_bottom_sheet.dart` |
| `filter_enums.dart.bak` | `lib/features/city_detail/domain/entities/filter_enums.dart` |

Khi backend bổ sung dữ liệu thật (giá phòng, loại lưu trú, tiện ích, món ăn...),
có thể lấy lại UI ở đây để khôi phục các section filter tương ứng.

Chi tiết thay đổi: xem `GP-Travel-Advisor-Backend/api-service/docs/city-detail-filter-rework.md`.
