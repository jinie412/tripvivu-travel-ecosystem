// Tags theo category_id từ bảng travel.categories
const Map<String, List<String>> kTagsByCategory = {
  // Ẩm thực
  '97029cfb-069b-4dba-a152-dfb3d36634d3': [
    'Đồ ăn ngon',
    'Phục vụ tốt',
    'Không gian đẹp',
    'Giá cả hợp lý',
    'Đặc sản địa phương',
    'Sạch sẽ',
    'Thực đơn đa dạng',
  ],
  // Văn hóa & Di sản
  'e57f20dc-3466-424d-9017-5a12bb644485': [
    'Giá trị lịch sử',
    'Hướng dẫn viên tốt',
    'Cảnh đẹp',
    'Đáng tham quan',
    'Thông tin phong phú',
    'Không gian trang nghiêm',
  ],
  // Tham quan & Khám phá
  'f11adf24-9112-4888-b190-3374c419f6a6': [
    'Cảnh đẹp',
    'Đáng khám phá',
    'Trải nghiệm địa phương',
    'Chụp ảnh đẹp',
    'Không khí thoải mái',
    'Dễ di chuyển',
  ],
  // Giải trí & Vui chơi
  '0383e57c-8a64-4ca5-9dbd-6a246e601827': [
    'Sôi động',
    'Vui nhộn',
    'Phù hợp gia đình',
    'Giá vé hợp lý',
    'Không gian rộng rãi',
    'Thích hợp nhóm bạn',
  ],
  // Thư giãn & Thể thao
  'e0601e9b-2622-4c48-b975-caaa4ee5e1c2': [
    'Yên bình',
    'Không khí trong lành',
    'Sạch sẽ',
    'Tiện nghi',
    'Phù hợp gia đình',
    'Nhân viên thân thiện',
  ],
  // Lưu trú
  'ea6f098f-3c84-4818-a346-f67bd99fb9d1': [
    'Sạch sẽ',
    'Nhân viên thân thiện',
    'Vị trí thuận tiện',
    'Tiện nghi đầy đủ',
    'Yên tĩnh',
    'Giá tốt',
  ],
  // Mua sắm & Dịch vụ
  'f59deeb6-6eed-4045-8583-1dd67c6327f4': [
    'Hàng hóa đa dạng',
    'Giá cả hợp lý',
    'Chất lượng tốt',
    'Nhân viên tư vấn tốt',
    'Mua sắm tiện lợi',
    'Không gian thoải mái',
  ],
};

// Tags cho đánh giá tổng thể lịch trình
const List<String> kItineraryReviewTags = [
  'Lịch trình hợp lý',
  'Đa dạng địa điểm',
  'Đúng tiến độ',
  'Phù hợp gia đình',
  'Đáng tiền',
  'Trải nghiệm địa phương',
  'Dễ di chuyển',
];

// Fallback khi địa điểm không có category
const List<String> kDefaultReviewTags = [
  'Cảnh đẹp',
  'Đáng tiền',
  'Trải nghiệm địa phương',
  'Sạch sẽ',
  'Dễ di chuyển',
  'Nhân viên thân thiện',
];

List<String> getTagsForCategory(String? categoryId) {
  if (categoryId == null) return kDefaultReviewTags;
  return kTagsByCategory[categoryId] ?? kDefaultReviewTags;
}

const List<String> kMissedLocationReasons = [
  'Thời gian quá gấp',
  'Địa điểm không như mong đợi',
  'Thời tiết không thuận lợi',
  'Sức khỏe không đảm bảo',
  'Tìm thấy địa điểm khác thú vị hơn',
];
