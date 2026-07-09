// Đồng hồ Việt Nam (UTC+7) — **độc lập với múi giờ thiết bị**.
//
// WonderLens là app offline cho trẻ ở Việt Nam: dù máy bị đặt sai múi giờ
// (hoặc tắt "đặt tự động"), ngày trong nhật ký và lời chào vẫn phải theo ngày
// ở Việt Nam. Vì thế mọi chỗ cần "hôm nay" / "bây giờ" để nhóm hoặc hiển thị
// đều dùng [vnNow] thay cho `DateTime.now()` (vốn phụ thuộc múi giờ thiết bị).

/// Việt Nam cố định UTC+7, **không có DST** (áp dụng toàn quốc từ 1975) nên chỉ
/// cần một offset tĩnh — không cần package timezone.
const Duration _vnOffset = Duration(hours: 7);

/// Giờ hiện tại theo Việt Nam, độc lập với múi giờ thiết bị.
///
/// Trả về một [DateTime] **không gắn cờ UTC** (`isUtc == false`) mà các trường
/// year/month/day/hour... chính là giờ tường (wall-clock) ở Việt Nam. Nhờ vậy
/// `toIso8601String()` cho ra chuỗi **không có hậu tố 'Z'** — khớp định dạng
/// `discovered_at` trong `specs/api-contracts.md`.
///
/// Không gọi `.toLocal()` / `.toUtc()` trên giá trị này: nó đã là giờ tường VN,
/// mọi phép quy đổi múi giờ sẽ làm sai ngày.
DateTime vnNow() {
  final vn = DateTime.now().toUtc().add(_vnOffset);
  // Bỏ cờ UTC nhưng giữ nguyên các trường giờ tường VN.
  return DateTime(
    vn.year,
    vn.month,
    vn.day,
    vn.hour,
    vn.minute,
    vn.second,
    vn.millisecond,
    vn.microsecond,
  );
}
