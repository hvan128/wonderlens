import 'package:hive/hive.dart';

/// Kết quả sau khi ghi nhận hoạt động khám phá của một ngày.
class StreakResult {
  final int current; // số ngày liên tiếp hiện tại
  final int best; // chuỗi dài nhất từng đạt
  final bool advancedToday; // hôm nay lần đầu ghi nhận (chuỗi vừa khởi động/tăng)

  const StreakResult({
    required this.current,
    required this.best,
    required this.advancedToday,
  });

  /// Mốc đáng ăn mừng đậm hơn (chỉ khi vừa tăng trong ngày).
  bool get isMilestone =>
      advancedToday &&
      (current == 3 || current == 7 || current == 14 || current == 30);
}

/// "Chuỗi ngày khám phá" (D2 / TASK-020 — mới). Streak nhẹ nhàng, **không áp lực**:
/// chỉ cần khám phá ≥1 vật/ngày để giữ chuỗi. Không cấp huy hiệu, không phạt khi
/// đứt (tự khởi động lại từ 1). Lưu local Hive box `wonderlens_streak`
/// (key-value đơn giản — không TypeAdapter/build_runner). Xem `ADR-015`.
///
/// Business logic (tính chuỗi) là hàm **thuần** [computeUpdate] — không đọc Hive,
/// không `DateTime.now()` — để test tất định (AGENTS.md).
class StreakRepository {
  static const _boxName = 'wonderlens_streak';
  static const _lastDayKey = 'last_day'; // yyyy-mm-dd lần khám phá gần nhất
  static const _countKey = 'streak_count';
  static const _bestKey = 'best_streak';

  static Box? _box;

  /// Gọi lúc khởi động (sau khi Hive đã init bởi CollectionRepository).
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Hook cho test — gán box mà không cần Hive.initFlutter.
  static set debugBox(Box box) => _box = box;

  int get current => (_box?.get(_countKey) as int?) ?? 0;
  int get best => (_box?.get(_bestKey) as int?) ?? 0;
  String? get lastDay => _box?.get(_lastDayKey) as String?;

  /// yyyy-mm-dd theo lịch địa phương (khoá ngày ổn định, không phụ thuộc giờ).
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Thuần — tính chuỗi mới từ trạng thái cũ + thời điểm hiện tại.
  /// - Cùng ngày → giữ nguyên (đã tính hôm nay), `advanced=false`.
  /// - Ngày liền kề hôm qua → +1.
  /// - Đứt quãng / lần đầu → khởi động lại về 1.
  static ({int streak, String today, bool advanced}) computeUpdate({
    required String? lastDay,
    required int currentStreak,
    required DateTime now,
  }) {
    final today = dayKey(now);
    if (lastDay == today) {
      return (
        streak: currentStreak < 1 ? 1 : currentStreak,
        today: today,
        advanced: false,
      );
    }
    // Dùng ngày (nửa đêm) để trừ 1 ngày, tránh lệch do giờ/DST.
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterday = dayKey(todayDate.subtract(const Duration(days: 1)));
    final streak = (lastDay == yesterday) ? currentStreak + 1 : 1;
    return (streak: streak, today: today, advanced: true);
  }

  /// Ghi nhận một lần "khám phá hôm nay" (gọi khi mở hành trình một vật).
  /// Chỉ ghi Hive khi chuỗi thực sự đổi (ngày mới). Trả kết quả để UI ăn mừng.
  StreakResult recordVisit([DateTime? at]) {
    final now = at ?? DateTime.now();
    final u = computeUpdate(
      lastDay: lastDay,
      currentStreak: current,
      now: now,
    );
    final newBest = u.streak > best ? u.streak : best;
    if (u.advanced) {
      _box?.put(_lastDayKey, u.today);
      _box?.put(_countKey, u.streak);
      _box?.put(_bestKey, newBest);
    }
    return StreakResult(
      current: u.streak,
      best: newBest,
      advancedToday: u.advanced,
    );
  }
}
