// Phải khớp CHÍNH XÁC với vocab model AI đã train
const kTripIntents = [
  'Khám phá tổng hợp',
  'Ẩm thực & Bản địa',
  'Văn hóa & Lịch sử',
  'Khám phá & Sinh thái',
  'Nghỉ dưỡng & Biển',
  'Đô thị & Vui chơi',
];

// Option exclusive: không trộn với intent cụ thể
const kGeneralTripIntent = 'Khám phá tổng hợp';

const kMaxTripIntents = 3;
