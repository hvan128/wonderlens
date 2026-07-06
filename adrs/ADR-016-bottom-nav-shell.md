# ADR-016: Điều hướng bottom-nav (Sân chơi + Bộ sưu tập), camera là route toàn màn hình

**Status:** Accepted
**Date:** 2026-07-01
**Liên quan:** `specs/features.md` (F-17), `lib/router.dart`, ADR-006 (camera lifecycle), ADR-013 (Learn & Play)

## Context

Luồng cũ là **push tuyến tính** (Onboarding → Camera → Timeline → Collection), không có
"cửa vào" cho game (TASK-018/019). Ý tưởng A1 (`wonderlens-ui-brainstorm.html`) muốn một
**tab "Sân chơi"** trên thanh dưới gom mọi trò, cùng tab Bộ sưu tập.

Ràng buộc then chốt: **màn Camera quản lý vòng đời AVCaptureSession qua `RouteObserver`**
(`app_route_observer.dart`, `didPushNext`/`didPopNext`) — chỉ kích hoạt khi có route
**push/pop** đè lên. Nếu đặt camera vào một `StatefulShellRoute.indexedStack` (giữ sống mọi
nhánh), việc chuyển tab **không** phát sự kiện observer → camera bị giữ chạy nền (rò tài
nguyên, xung đột với video player). Đây là rủi ro cho tính năng lõi.

## Decision

Dùng **`StatefulShellRoute.indexedStack`** với **2 nhánh**: `/playground` (Sân chơi) và
`/collection` (Bộ sưu tập), bọc bởi `HomeShell` + `WonderBottomNav` (3 ô: Sân chơi ·
[📷 quét] · Bộ sưu tập). **Camera KHÔNG nằm trong shell** — là **route toàn màn hình** ở
root navigator; nút giữa 📷 `push('/camera')` phủ cả bottom-nav. Timeline + các màn game
(`/quiz /assembly /missions /material-cards`) cũng là route root → phủ nav, full-screen.

Điều hướng:
- Onboarding → `go('/camera')` (quét ngay, camera-first như cũ).
- Camera 🏠 → `canPop ? pop : go('/playground')`; 🗂️ → `go('/collection')`.
- Sân chơi: Nhiệm vụ/Thẻ mở thẳng; Đố vui/Ghép ngược chọn vật đã khám phá **có** trò đó,
  chưa có → gợi ý (không mở màn "đang chuẩn bị").

## Reasons

- **Giữ nguyên vòng đời camera** (ADR-006): camera vẫn là route push/pop trên root →
  `RouteObserver` hoạt động y hệt; không rò session, không phải viết lại logic camera.
- **Đắm chìm khi quét**: camera full-screen (không nav) đúng trải nghiệm "lens", nav xuất
  hiện ở các màn duyệt (Sân chơi/Bộ sưu tập) — pattern quen thuộc (capture full-screen).
- **Ít rủi ro hồi quy**: chỉ thêm shell + đổi vài đích điều hướng (`push`→`go`), không đụng
  logic nghiệp vụ; các màn game/timeline giữ nguyên là route root.

## Consequences

- `main.dart`/router thêm shell; Collection bỏ nút back (là tab). Onboarding vẫn ngoài shell.
- Chuyển tab dùng `IndexedStack` (giữ sống 2 nhánh nhẹ: Sân chơi + Bộ sưu tập) — chấp nhận
  được (không có camera trong đó).
- Nếu sau này muốn camera là tab thật, phải bổ sung cơ chế pause/resume camera theo hiển thị
  nhánh — ngoài phạm vi hiện tại.
