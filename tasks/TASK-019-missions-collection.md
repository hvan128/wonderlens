# TASK-019: Nhiệm vụ khám phá (D1) + khu "Thử thách" trong Bộ sưu tập (A2)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-019-missions-collection
**Ref ADR:** [ADR-014](../adrs/ADR-014-missions-and-teacher-parent.md) · [ADR-012](../adrs/ADR-012-material-graph-model.md)
**Depends:** [TASK-017](TASK-017-game-integration-foundation.md)

## Bối cảnh

"Cửa vào" thứ hai (A2): gắn game với thứ trẻ đã có — Bộ sưu tập. Thêm khu "Thử thách"
mở **Nhiệm vụ khám phá** (D1) và **Thẻ vật liệu** ngay trong màn Bộ sưu tập. Nhiệm vụ +
mạng lưới thẻ đã dựng ở `integration/truc-c-d` (Domain 3), tiến độ suy trực tiếp từ
`discoveredIds` (không lưu thêm — ADR-012/014).

## Goal

- Port màn **MissionsScreen** (`/missions`) + **MaterialCardsScreen** (`/material-cards`),
  khớp design system hiện tại.
- **A2:** thêm section "Thử thách" vào `collection_screen.dart` (sau thẻ cấp độ) gồm 2 ô
  `Pressable`: "Nhiệm vụ khám phá" (X/Y hoàn thành) → `/missions`, "Thẻ vật liệu"
  (đã mở X/Y) → `/material-cards`.
- Tiến độ nhiệm vụ tính live từ `MissionRepository.progressOf` + `MaterialCatalog.unlockedCards`;
  hoàn thành → confetti + ghi nhận (dedup, persist Hive `wonderlens_progress`).

## Phạm vi

IN:
- `lib/screens/missions_screen.dart`, `lib/screens/material_cards_screen.dart` (port + reskin).
- Route `/missions`, `/material-cards` trong `lib/router.dart` (`wonderPage`).
- `_ChallengeTile` + `_challengeSummary(discovered)` trong `collection_screen.dart` (A2);
  section ẩn an toàn nếu `MaterialCatalog` chưa nạp (`isReady=false`).
- Smoke test MissionsScreen (render + tiến độ) trong `test/game_screens_test.dart`.

OUT (task sau):
- Streak (D2) → TASK-020. Tab Sân chơi (A1) → TASK-021.
- So sánh 2 vật (F-11) — feature C, chưa yêu cầu (route/screen không port trong task này).
- Ghi `RewardEarned` từ quiz/assembly vào track huy hiệu — giữ tách (ADR-011 không đổi).

## Acceptance Criteria

- [x] `flutter analyze` sạch.
- [x] `flutter test` pass — thêm smoke test MissionsScreen, không hồi quy (56 pass).
- [x] Bộ sưu tập hiện khu "Thử thách" với tiến độ nhiệm vụ + số thẻ vật liệu đã mở, tap mở đúng màn.
- [x] Tiến độ nhiệm vụ đúng theo `discoveredIds` (material_count/discover_set/collect_card); AI-live không tính (hero-only).
- [x] `/missions` khi mở: nhiệm vụ đủ điều kiện → confetti + persist dedup; mở lại không trao lại.
- [x] Thiếu catalog/nhiệm vụ → section ẩn / màn rỗng, không crash.

## DoD

- [x] Code đúng phạm vi + AC; logic tiến độ ở `MissionRepository`/`MaterialCatalog` (không trong widget).
- [x] `flutter analyze` sạch · `flutter test` pass · build pass.
- [ ] Verify trên app thật (Bộ sưu tập → Thử thách → Nhiệm vụ, tiến độ khớp số vật đã khám phá).
- [ ] PR reviewed & merged.
