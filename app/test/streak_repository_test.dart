// Test "Chuỗi ngày khám phá" (D2 / TASK-020): logic tính chuỗi thuần + persist Hive.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wonderlens/data/streak_repository.dart';

void main() {
  DateTime d(int y, int m, int day) => DateTime(y, m, day, 10, 0);

  group('computeUpdate (thuần, không Hive/không now())', () {
    test('lần đầu (lastDay null) → chuỗi 1, advanced', () {
      final u = StreakRepository.computeUpdate(
          lastDay: null, currentStreak: 0, now: d(2026, 7, 1));
      expect(u.streak, 1);
      expect(u.advanced, isTrue);
      expect(u.today, '2026-07-01');
    });

    test('cùng ngày → giữ nguyên, không advanced (dedup)', () {
      final u = StreakRepository.computeUpdate(
          lastDay: '2026-07-01', currentStreak: 3, now: d(2026, 7, 1));
      expect(u.streak, 3);
      expect(u.advanced, isFalse);
    });

    test('ngày liền kề → +1', () {
      final u = StreakRepository.computeUpdate(
          lastDay: '2026-07-01', currentStreak: 3, now: d(2026, 7, 2));
      expect(u.streak, 4);
      expect(u.advanced, isTrue);
    });

    test('đứt quãng (cách ≥2 ngày) → khởi động lại 1 (không phạt)', () {
      final u = StreakRepository.computeUpdate(
          lastDay: '2026-07-01', currentStreak: 5, now: d(2026, 7, 3));
      expect(u.streak, 1);
      expect(u.advanced, isTrue);
    });

    test('qua ranh giới tháng: 30/6 → 1/7 vẫn liền kề', () {
      final u = StreakRepository.computeUpdate(
          lastDay: '2026-06-30', currentStreak: 2, now: d(2026, 7, 1));
      expect(u.streak, 3);
      expect(u.advanced, isTrue);
    });
  });

  group('recordVisit (persist Hive + best + dedup)', () {
    setUpAll(() {
      Hive.init(Directory.systemTemp.createTempSync('wl_streak_test').path);
    });

    test('tăng qua ngày liên tiếp, best giữ đỉnh, persist qua mở lại box',
        () async {
      final box = await Hive.openBox('wl_streak_box');
      StreakRepository.debugBox = box;
      final repo = StreakRepository();

      expect(repo.recordVisit(d(2026, 7, 1)).current, 1);
      // Cùng ngày lần 2 → không tăng.
      final same = repo.recordVisit(d(2026, 7, 1));
      expect(same.current, 1);
      expect(same.advancedToday, isFalse);

      expect(repo.recordVisit(d(2026, 7, 2)).current, 2);
      final r3 = repo.recordVisit(d(2026, 7, 3));
      expect(r3.current, 3);
      expect(r3.isMilestone, isTrue); // mốc 3 ngày

      // Đứt quãng → chuỗi về 1 nhưng best vẫn 3.
      final r4 = repo.recordVisit(d(2026, 7, 6));
      expect(r4.current, 1);
      expect(r4.best, 3);

      // Persist: đóng + mở lại box.
      await box.close();
      final box2 = await Hive.openBox('wl_streak_box');
      StreakRepository.debugBox = box2;
      expect(StreakRepository().current, 1);
      expect(StreakRepository().best, 3);
    });
  });
}
