import 'object_content.dart';

/// Tiện ích biến một [Stage] thành "cảnh phim" cho màn Generating & Video Player.
///
/// Tiêu đề chặng trong nội dung hero thường kết thúc bằng một emoji chủ đề
/// (vd "Bắt đầu từ dầu mỏ 🛢️"). Ta tách emoji đó làm hình minh hoạ cảnh, và lấy
/// phần chữ còn lại làm nhãn chương ngắn gọn.

/// Emoji "cảnh" cho một chặng — emoji cuối tiêu đề, hoặc [fallback] (emoji vật).
String sceneEmoji(Stage stage, String fallback) {
  final e = _trailingEmoji(stage.title);
  return (e != null && e.isNotEmpty) ? e : fallback;
}

/// Nhãn chương ngắn = tiêu đề đã bỏ emoji đuôi.
String sceneLabel(Stage stage) {
  final e = _trailingEmoji(stage.title);
  var label = stage.title;
  if (e != null) label = label.substring(0, label.length - e.length);
  return label.trim();
}

/// Lấy chuỗi emoji ở cuối [s] (gồm cả variation-selector/ZWJ), hoặc null.
String? _trailingEmoji(String s) {
  final runes = s.runes.toList();
  var i = runes.length - 1;
  // Bỏ khoảng trắng & bộ chọn biến thể ở đuôi.
  while (i >= 0 && (runes[i] == 0x20 || runes[i] == 0xFE0F || runes[i] == 0x200D)) {
    i--;
  }
  if (i < 0 || !_isEmoji(runes[i])) return null;
  // Gom ngược cụm emoji liền nhau (kèm ZWJ / VS).
  while (i >= 0 &&
      (_isEmoji(runes[i]) || runes[i] == 0xFE0F || runes[i] == 0x200D)) {
    i--;
  }
  return String.fromCharCodes(runes.sublist(i + 1)).trim();
}

/// Rune nằm trong vùng emoji/biểu tượng (≥ U+2190), bỏ qua VS16/ZWJ.
bool _isEmoji(int r) => r >= 0x2190 && r != 0xFE0F && r != 0x200D;
