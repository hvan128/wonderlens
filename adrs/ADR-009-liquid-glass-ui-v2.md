# ADR-009: Design system v2 — Liquid Glass thống nhất + hệ motion spring

**Status:** Accepted
**Date:** 2026-07-02
**Ref:** TASK-012

## Bối cảnh

Design system v1 (`app/lib/ui/`) đã có recipe liquid glass hand-rolled và bộ
component dùng chung, nhưng: (1) animation dùng duration/curve rời rạc, không
có cảm giác vật lý liền mạch; (2) TextStyle hardcode lặp khắp nơi; (3) chưa có
component tương tác nâng cao (panel nổi kéo/resize, sheet kính) mà các màn
sáng tạo/demo sắp tới cần. Người dùng đã cân nhắc viết lại native iOS (SwiftUI
`.glassEffect`) và **quyết định giữ Flutter** (giữ ADR-001, giữ Android, không
viết lại tính năng) — Flutter mô phỏng ~95% cảm giác Liquid Glass.

## Quyết định

1. **Motion = spring vật lý, tham số kiểu Apple.** `app/lib/ui/motion.dart`
   định nghĩa spring theo cặp `(response, dampingFraction)` như SwiftUI, quy đổi
   `stiffness = (2π/response)²`, `damping = 4π·ζ/response` (mass = 1, dùng
   `SpringDescription` của Flutter SDK — **không dependency mới**). Bốn preset:
   `smooth` (0.42/1.0), `snappy` (0.32/0.85), `bouncy` (0.42/0.65),
   `interactive` (0.24/0.86). Mọi tương tác kéo/thả bàn giao velocity thật vào
   simulation — không animate bằng Tween cứng.
2. **Recipe kính v2 giữ ràng buộc v1:** blur thuần trên `BackdropFilter`
   (KHÔNG ColorFilter bão hoà — artifact premultiplied alpha, đã kiểm chứng),
   thêm rim specular bằng gradient stroke vẽ foreground và sheen đỉnh mềm.
   Một `BackdropFilter` cho mỗi surface — không lồng kính trong kính.
3. **Panel nổi theo mô hình host + controller.** `GlassPanelArea` (Stack host,
   quản z-order) + `GlassPanelController` (`ChangeNotifier` giữ position/size)
   + `GlassPanel` (view). Logic hình học (clamp, snap, resize anchor) nằm trong
   controller — test được không cần render, đúng luật "business logic không ở
   widget".
4. **Chữ qua thang `WonderType`** (display/title/body/label/caption), KHÔNG set
   fontFamily → kế thừa font hệ thống mỗi nền tảng (SF trên iOS, Roboto trên
   Android) — thoả offline-first, không font tải mạng.
5. **API v1 giữ tương thích.** Rebuild bên trong; chữ ký public của component
   hiện có không đổi để call-site và test hiện hành không phải sửa.

## Hệ quả

- ✅ Một ngôn ngữ chuyển động/vật liệu duy nhất; thêm màn mới không phát minh style.
- ✅ Panel/sheet mới mở đường cho khu sáng tạo + demo tương tác.
- ⚠️ BackdropFilter nhiều panel cùng lúc tốn GPU — quy ước ≤ 3 panel kính
  đồng thời; panel nền tĩnh dùng tint đặc `GlassTone` thay blur khi cần.
- ⚠️ Spring không có duration cố định — test dùng `pumpAndSettle` có timeout
  hoặc drive controller trực tiếp.

## Quy ước bổ sung sau vòng review đối kháng (2026-07-02)

1. **Tolerance theo đơn vị trục.** `WonderSpring.simulation` mặc định
   `pixelTolerance`; trục 0..1 (scale, fraction) PHẢI truyền
   `WonderSpring.unitTolerance`, và khi simulation `isDone` phải ĐẶT giá trị
   về đúng đích (không dừng ở `x(t)` — lệch vĩnh viễn theo tolerance).
2. **Rubber-band tính trên vị trí thô.** Lực cản là hàm của TỔNG vượt biên
   tích lũy trong gesture (`beginDrag`/`dragBy`/`endDrag`), không áp đệ quy
   lên giá trị đã cản.
3. **Thoát blur cho bề mặt đè video/camera:** `GlassSurface(blur: 0)` bỏ hẳn
   `BackdropFilter` (không saveLayer). Camera hiện còn 4 backdrop mặc định —
   việc chuyển các nút camera sang `blur: 0` là quyết định thị giác, để ngỏ.
4. **Nền blob không dùng `ImageFiltered.blur`** — đĩa mờ vẽ bằng
   `RadialGradient` tĩnh; hiệu ứng lặp vô hạn chỉ được là transform thuần.
5. **Vòng quét raster một lần:** gradient đối xứng tròn xoay bằng
   `RotationTransition` + `RepaintBoundary`, không repaint painter mỗi frame.
6. **Mở (không sửa) sau review:** contrast chữ trắng trên `WonderGradients.cta`
   ~1.8–2.1:1 dưới chuẩn WCAG — đổi gradient là quyết định thương hiệu của
   user, chưa tự ý sửa.
