# Tổng kết thay đổi Mobile

Tài liệu này tổng hợp các thay đổi giao diện và tích hợp dữ liệu đã thực hiện trên ứng dụng `GP-Travel-Advisor-Mobile` trong đợt đồng bộ UI hiện tại.

## 1. Ngôn ngữ thiết kế chung

- Đồng bộ giao diện theo palette premium: navy, blue, teal, nền xám sáng và surface trắng.
- Card chủ đạo sử dụng bo góc khoảng `18–20px`, viền xanh-xám và bóng navy nhẹ.
- Tab/chip active dùng gradient blue–teal; trạng thái inactive dùng nền trắng và viền `premiumBorder`.
- Chuẩn hóa màu tiêu đề, metadata, app bar, nút quay lại và trạng thái rỗng.
- Cân lại padding, khoảng cách carousel–dots và kích thước card trên màn hình mobile.

## 2. Đăng nhập và quản lý phiên

- Đồng bộ màn Đăng nhập theo nhận diện premium.
- Đổi nền, logo gradient, màu tiêu đề, liên kết và nút đăng nhập.
- Cache HTTP trong bộ nhớ được gắn với `userId` hiện tại.
- Khi đăng xuất hoặc chuyển sang tài khoản khác, cache cũ được xóa và Explore được revalidate.
- Đảm bảo dữ liệu cá nhân hóa của tài khoản trước không bị tái sử dụng cho tài khoản sau.

## 3. Trang Khám phá

- Đồng bộ section header, carousel, card địa điểm, nhà hàng, khách sạn và lịch trình.
- Lịch trình nổi bật sử dụng dữ liệu backend đã sắp xếp theo số lượt yêu thích.
- Điểm đến nổi bật không còn bị client tải lại rồi tự thay đổi thứ tự, giúp kết quả ổn định hơn.
- Card điểm đến giữ tên ở cỡ chữ `15`, rating hiển thị một chữ số thập phân.
- Card địa điểm dùng chung giảm cỡ tên và cho phép nhiều dòng để hạn chế mất tên.
- Card khách sạn:
  - Rating hiển thị một chữ số thập phân.
  - Hiển thị giá thấp nhất theo dạng `Từ xđ/ngày`.
  - Giá rỗng hoặc bằng `0đ` được chuyển thành `Liên hệ giá`.
- Cache dữ liệu Explore được làm mới khi người dùng thay đổi.

## 4. Lịch trình của tôi

- Đồng bộ màu filter với tab trong Chi tiết tỉnh/thành phố.
- Filter active dùng gradient blue–teal và chữ trắng.
- Filter được chuyển sang danh sách cuộn ngang để responsive tốt hơn.
- Đồng bộ card lịch trình theo palette premium và cân lại khoảng cách nội dung.
- Không thay đổi nghiệp vụ của màn Tóm tắt lịch trình và Chi tiết lịch trình.

## 5. Chi tiết tỉnh/thành phố

- Đồng bộ app bar, tab pill, section, card carousel và danh sách “Xem tất cả”.
- Rút gọn nhãn `Hoạt động tham quan & giải trí` thành `Tham quan & giải trí`.
- Card lịch trình trong “Gợi ý từ cộng đồng” được thu gọn chiều cao phần nội dung và bỏ icon lượt xem.
- Gợi ý từ cộng đồng sử dụng thứ tự theo số lượt yêu thích từ backend.
- Các section hoạt động, nhà hàng và khách sạn sử dụng dữ liệu đã xếp hạng theo rating kết hợp số lượt đánh giá.
- Rating trên các card được chuẩn hóa một chữ số thập phân.
- Giá khách sạn bằng `0` không còn hiển thị `0đ`, mà chuyển thành `Liên hệ giá`.
- Danh sách “Xem tất cả” hoạt động nhận toàn bộ dữ liệu backend thay vì chỉ phần dữ liệu đầu tiên bị giới hạn bởi Supabase.

## 6. Chi tiết địa điểm

- Đồng bộ title, rating box, gallery, mô tả, liên hệ, review và địa điểm liên quan thành các surface premium.
- Nếu địa điểm là khách sạn và có dữ liệu phòng, hiển thị giá thấp nhất theo dạng `Từ xđ/đêm`.
- Section “Có thể bạn sẽ thích” được sửa responsive:
  - Card tự điều chỉnh chiều rộng theo viewport.
  - Tăng chiều cao hợp lý và bỏ lỗi `BOTTOM OVERFLOWED`.
  - Tên tối đa hai dòng.
  - Rating hiển thị một chữ số thập phân.
  - Bổ sung số lượt đánh giá, ví dụ `4.8 (126)`.
- Model địa điểm liên quan được bổ sung `reviewCount`.
- Model chi tiết địa điểm được bổ sung `minimumHotelPrice`.

## 7. Bộ sưu tập/Đã lưu

- Sửa rating của địa điểm và lịch trình đã lưu để lấy đúng dữ liệu backend.
- Card lịch trình đã lưu hiển thị rating bằng icon sao.
- Bỏ số lượt đánh giá của lịch trình vì dữ liệu hiện tại thường tự động là `1` và không mang nhiều giá trị.
- Sửa hàng metadata responsive: tên địa điểm có thể ellipsis mà không đẩy ngày và rating ra khỏi card.

## 8. Các card dùng chung

- `DetailedPlaceCard` giữ cỡ chữ tên `15`.
- Card địa điểm dạng danh sách sử dụng tên nhỏ hơn và nhiều dòng để giảm dấu `...`.
- Card hoạt động, nhà hàng và khách sạn dạng dọc được đồng bộ màu, rating, review count và trạng thái giá.
- Các card carousel sử dụng viền, bóng và khoảng cách nhất quán.

## 9. Thay đổi contract dữ liệu mobile

Mobile hiện đọc thêm các trường sau từ API:

| Trường | Mục đích |
| --- | --- |
| `min_price` | Giá phòng thấp nhất trong chi tiết khách sạn |
| `review_count` của related place | Hiển thị độ tin cậy của rating ở “Có thể bạn sẽ thích” |
| Rating/review count của favorite itinerary | Hiển thị đúng thông tin lịch trình trong Đã lưu |

Giá khách sạn được chuẩn hóa ở datasource: giá `null`, rỗng hoặc nhỏ hơn hay bằng `0` được coi là chưa có giá.

## 10. Backend liên quan cần được deploy

Một số thay đổi mobile chỉ hoạt động đầy đủ sau khi deploy/restart backend:

- Trả giá phòng thấp nhất cho chi tiết địa điểm khách sạn.
- Chia batch truy vấn `hotel_rooms` để tránh toàn bộ giá thành `0` ở thành phố lớn.
- Sắp xếp lịch trình nổi bật và gợi ý cộng đồng theo lượt yêu thích.
- Trả đầy đủ địa điểm theo từng batch, tránh giới hạn 1.000 dòng của Supabase ở “Xem tất cả”.
- Xếp hạng địa điểm bằng rating kết hợp review count.

## 11. Các file mobile chính đã thay đổi

- `lib/core/network/dio_client.dart`
- `lib/features/auth/`
- `lib/features/home/`
- `lib/features/itinerary/presentation/widgets/itinerary_card.dart`
- `lib/features/itinerary/presentation/widgets/itinerary_filter_chips.dart`
- `lib/features/city_detail/`
- `lib/features/place/`
- `lib/features/saved/`

## 12. Trạng thái kiểm tra

- Backend liên quan đã chạy `nest build` thành công.
- Mobile và backend đã chạy `git diff --check` không có lỗi whitespace.
- Công cụ Dart analyzer trong môi trường hiện tại có tình trạng bị treo; các model generated liên quan đã được cập nhật và đối chiếu thủ công.
- Cần kiểm tra lại trên thiết bị ở các chiều rộng màn hình khác nhau sau khi deploy backend, đặc biệt là Chi tiết địa điểm và danh sách “Xem tất cả”.

