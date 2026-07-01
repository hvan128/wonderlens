# TASK-020: Chuỗi ngày khám phá (D2 — daily streak, mới)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-020-discovery-streak
**Ref ADR:** [ADR-015](../adrs/ADR-015-discovery-streak.md) · ADR-005 (Hive)
**Depends:** [TASK-017](TASK-017-game-integration-foundation.md)

## Bối cảnh

Cho trẻ lý do quay lại mỗi ngày (ý tưởng D2). Streak **nhẹ nhàng, không áp lực**:
chỉ cần khám phá ≥1 vật/ngày để giữ ngọn lửa. Feature **mới hoàn toàn** — không có trên
`integration/truc-c-d`. Quyết định sản phẩm: **chỉ đếm + màn chúc mừng**, KHÔNG cấp huy
hiệu (giữ nguyên logic badge/level của ADR-011).

## Goal

- `StreakRepository` (Hive box `wonderlens_streak`): `last_day`/`streak_count`/`best_streak`.
  Logic tính chuỗi là hàm **thuần** `computeUpdate` (không Hive, không `now()`).
- Ghi nhận `recordVisit()` khi mở hành trình một vật (Timeline `initState`).
- Chuỗi sang ngày mới (`advancedToday` && `current ≥ 2`) → màn "Chuỗi N ngày! 🔥"
  (dialog nền magic, tắt được ngay, ≤1 lần/ngày).
- Bộ sưu tập: chip "🔥 N ngày" trên thẻ cấp độ.

## Phạm vi

IN:
- `lib/data/streak_repository.dart` (mới) + `StreakRepository.init()` trong `main.dart`.
- `lib/widgets/streak_celebration.dart` (mới) — `showStreakCelebration` + dialog.
- Hook Timeline `initState` (record + mừng); chip streak trong `collection_screen.dart` (`_StreakChip`).
- Docs: `ADR-015`, `specs/features.md` (F-18), `specs/api-contracts.md` (box `wonderlens_streak`).
- Test `test/streak_repository_test.dart` (logic thuần + persist) + widget test màn chúc mừng.

OUT:
- Không cấp huy hiệu/không đụng cấp độ (ADR-011 giữ nguyên). Không phạt khi đứt.
- Thông báo đẩy/nhắc nhở — chưa làm (chỉ hiển thị + ăn mừng in-app).
- Tab Sân chơi (A1) → TASK-021.

## Acceptance Criteria

- [x] `flutter analyze` sạch.
- [x] `flutter test` pass — thêm test logic streak (liền kề/đứt/qua tháng/persist) + widget màn chúc mừng (63 pass).
- [x] Ngày liền kề → +1; cùng ngày → không đổi; đứt quãng → về 1; persist qua restart.
- [x] Màn "Chuỗi N ngày" hiện khi chuỗi sang ngày mới (≥2), tắt được; ≤1 lần/ngày.
- [x] Bộ sưu tập hiện chip streak; streak **không** ảnh hưởng huy hiệu/cấp độ.
- [x] Thiếu box/khoá → streak = 0, không crash.

## DoD

- [x] Code đúng phạm vi + AC; logic ở repository (không trong widget).
- [x] `flutter analyze` sạch · `flutter test` pass · build pass; ADR-015 + specs cập nhật.
- [ ] Verify trên app thật (khám phá 2 ngày liên tiếp → thấy màn chuỗi + chip 🔥).
- [ ] PR reviewed & merged.
