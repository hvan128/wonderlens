import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/util/vn_time.dart';

void main() {
  group('vnNow', () {
    test('luôn bằng UTC+7 (độc lập múi giờ thiết bị)', () {
      // Kẹp thời điểm gọi vnNow() giữa hai mốc UTC để so khớp chính xác,
      // tránh flake ở ranh giới giây/phút.
      final before = DateTime.now().toUtc();
      final v = vnNow();
      final after = DateTime.now().toUtc();

      // v là giờ tường VN (non-UTC). Đọc lại các trường như một instant UTC để
      // so với `mốc + 7h` — chính là định nghĩa UTC+7.
      final vInstant = DateTime.utc(
        v.year,
        v.month,
        v.day,
        v.hour,
        v.minute,
        v.second,
        v.millisecond,
        v.microsecond,
      );
      final lo = before.add(const Duration(hours: 7, seconds: -1));
      final hi = after.add(const Duration(hours: 7, seconds: 1));

      expect(vInstant.isAfter(lo), isTrue, reason: 'vnNow sớm hơn UTC+7');
      expect(vInstant.isBefore(hi), isTrue, reason: 'vnNow trễ hơn UTC+7');
    });

    test('không gắn cờ UTC và ISO không có hậu tố Z', () {
      final v = vnNow();
      expect(v.isUtc, isFalse);
      expect(v.toIso8601String().endsWith('Z'), isFalse);
    });

    test('round-trip ISO giữ đúng ngày và vẫn là giờ địa phương', () {
      final v = vnNow();
      final back = DateTime.parse(v.toIso8601String());
      expect(back.year, v.year);
      expect(back.month, v.month);
      expect(back.day, v.day);
      expect(back.isUtc, isFalse);
    });
  });
}
