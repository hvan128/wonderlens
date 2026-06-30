# TASK-015: Re-skin UI v2 (tông tím + mascot Tia + typography)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-015-ui-reskin-purple-tia
**Bối cảnh:** Bản redesign "mockup v2" (PR #1) từng được merge rồi revert (`76215be`) vì
xung đột với code member (Trục C/D Learn & Play) + đụng số hiệu ADR. Task này áp **lại
phần visual** của redesign lên `main` hiện tại theo phạm vi đã chốt — KHÔNG gộp Learn &
Play, KHÔNG thêm luồng phim AI (`/generating /video /share /badge`), giữ nguyên luồng
`timeline_screen` + `journey_video` của main.

## Goal

Đưa bản sắc thị giác "mockup v2" lên app: **tông tím kỳ diệu** (`#6B4EE6`), **mascot Tia**,
**typography Fredoka + Nunito** — mà KHÔNG đổi luồng điều hướng, KHÔNG đè feature member,
KHÔNG vỡ build/test.

## Phạm vi (đã chốt với owner)

IN:
- Re-skin palette/tokens/app_theme sang tím (giữ nguyên TÊN biến để tương thích call-site).
- Thêm `wonder_typography.dart` (Fredoka/Nunito qua `google_fonts`).
- Thêm `tia_mascot.dart` (CustomPaint) + dùng ở Onboarding (và modal nhận diện Camera).
- Cập nhật `wonder_button`, `wonder_background`, `ui.dart` (barrel), `phosphor_compat` (icon bổ sung).
- Thêm dependency `google_fonts` + ADR typography (đánh số lại tránh đụng ADR-006).

OUT (không làm trong task này):
- 4 màn mới `/generating /video /share /badge` và route tương ứng.
- `journey_args.dart`, `scene_emoji.dart`, field `Stage.chapter`.
- Gộp track Learn & Play (`integration/truc-c-d`).
- Đổi luồng video/share của main.

## Acceptance Criteria

- [ ] App đổi sang tông tím `#6B4EE6` ở tất cả màn hiện có (onboarding/camera/timeline/collection).
- [ ] Mascot Tia xuất hiện ở màn Onboarding; chữ tiêu đề dùng Fredoka, nội dung Nunito.
- [ ] KHÔNG thêm route mới; luồng camera → timeline → collection giữ nguyên hành vi.
- [ ] KHÔNG đổi schema `object_content.dart`; KHÔNG đụng file/route của member.
- [ ] Offline: thiếu mạng → google_fonts fallback font hệ thống, app KHÔNG crash.
- [ ] `flutter analyze` sạch, `flutter test` pass, build pass.

## DoD

- [ ] Code đúng phạm vi + AC.
- [ ] `flutter analyze` sạch · `flutter test` pass · build pass.
- [ ] ADR typography thêm mới (số hiệu không đụng ADR-006-on-device-object-cutout).
- [ ] `AGENTS.md`/dependency note cập nhật nếu cần (google_fonts).
- [ ] PR reviewed & merged (không push thẳng main).
