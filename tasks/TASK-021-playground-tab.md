# TASK-021: Tab "Sân chơi" + bottom-nav shell (A1)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-021-playground-tab
**Ref ADR:** [ADR-016](../adrs/ADR-016-bottom-nav-shell.md) · ADR-006 (camera lifecycle)
**Depends:** [TASK-017](TASK-017-game-integration-foundation.md), TASK-018, TASK-019

## Bối cảnh

"Cửa vào" thứ ba (A1): thanh bottom-nav với tab **Sân chơi** gom mọi trò + tab **Bộ sưu tập**,
nút giữa 📷 mở camera. Hoàn tất bộ "cửa vào" A (A1 tab + A2 Bộ sưu tập + A3 cuối Timeline).

## Goal

- `StatefulShellRoute.indexedStack` 2 nhánh: `/playground` (Sân chơi) + `/collection`.
  `HomeShell` + `WonderBottomNav` (Sân chơi · [📷] · Bộ sưu tập).
- Camera + timeline + game giữ là **route toàn màn hình** trên root (giữ vòng đời camera —
  ADR-016/006). Nút giữa `push('/camera')`.
- Màn "Sân chơi" mới (`PlaygroundScreen`): tiles Nhiệm vụ, Thẻ vật liệu, Đố vui, Ghép ngược.
  Đố vui/Ghép ngược chọn vật đã khám phá **có** trò đó; chưa có → gợi ý nhẹ.

## Phạm vi

IN:
- `lib/ui/wonder_bottom_nav.dart`, `lib/screens/home_shell.dart`, `lib/screens/playground_screen.dart` (mới).
- `lib/router.dart`: shell + nhánh; điều hướng: Onboarding `go('/camera')`, Camera 🏠→`pop`/`go('/playground')`,
  🗂️→`go('/collection')`; Collection bỏ back (là tab).
- Widget test Sân chơi + WonderBottomNav.
- Docs: ADR-016, `specs/features.md` (F-17).

OUT:
- Camera **không** là tab (ADR-016) — tránh rò session; không viết lại logic camera.
- So sánh 2 vật (F-11 / `/compare`) — feature C, chưa yêu cầu.
- Đổi Onboarding thành tab — giữ ngoài shell (intro một lần).

## Acceptance Criteria

- [x] `flutter analyze` sạch.
- [x] `flutter test` pass — thêm test Sân chơi + WonderBottomNav, không hồi quy (65 pass).
- [x] Bottom-nav 2 tab + nút giữa mở camera; camera/timeline/game full-screen phủ nav.
- [x] Sân chơi mở Nhiệm vụ/Thẻ trực tiếp; Đố vui/Ghép ngược chọn vật phù hợp / gợi ý nếu chưa có.
- [x] Vòng đời camera giữ nguyên (route push/pop trên root — RouteObserver không đổi).
- [ ] Verify app thật: chuyển tab mượt, mở camera từ nút giữa, back-stack đúng, camera không đen khi quay lại.

## DoD

- [x] Code đúng phạm vi + AC; shell là lớp điều hướng (không business logic).
- [x] `flutter analyze` sạch · `flutter test` pass · build pass; ADR-016 + features cập nhật.
- [ ] Verify trên app thật (đặc biệt vòng đời camera + back-stack).
- [ ] PR reviewed & merged.
