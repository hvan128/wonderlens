# TASK-012: Design system v2 — Liquid Glass đồng nhất + panel kéo/resize

**Owner:** Dev
**Status:** Code done + verified trên simulator — chờ commit/PR
**Branch:** feature/TASK-011-effort-gated-discovery (làm chồng — commit tách riêng)
**Ref:** [ADR-009](../adrs/ADR-009-liquid-glass-ui-v2.md)

**Đã xong (2026-07-02):**
- `motion.dart` (4 preset spring Apple + projectMomentum + spring 2D), `WonderType`
  + token panel/paper trong `wonder_tokens.dart`
- `glass_surface.dart` v2 (rim specular, API/default giữ từng số),
  `glass_panel.dart` (controller hình học + area z-order + panel kéo/resize),
  `glass_sheet.dart` (sheet nổi iOS 26, kéo đóng theo velocity)
- Rebuild: pressable, wonder_button, wonder_chip, wonder_header,
  scan_ring_button (spring + WonderType, API nguyên vẹn); `app_theme.dart` hợp
  nhất tokens; barrel `ui.dart` thêm export mới
- Playground: `screens/playground_screen.dart` + nút trong Dev panel +
  entry `lib/main_playground.dart` (`flutter run -t lib/main_playground.dart`)
- Test mới 20 case (motion/panel/sheet); toàn suite 55/55 pass; analyze sạch
- Chạy thật trên simulator iPhone 16e — chụp màn hình xác nhận
- Điều chỉnh có bằng chứng so với dự kiến: GIỮ shared-axis wonderPage, KHÔNG
  thêm swipe-back Cupertino cho route go_router (tranh gesture trực tiếp với
  `onHorizontalDragUpdate` của StageActionGate); Cupertino transition chỉ áp
  cho MaterialPageRoute qua pageTransitionsTheme
- Vòng review đối kháng (4 lăng kính × verifier phản biện, 34 agent): 20
  finding confirmed → đã sửa hết trong cùng ngày (sheet snap đúng đích +
  tolerance đơn vị fraction, guard double-pop, rubber-band theo raw, resizeBy
  hết crash clamp đảo cận, Tooltip nhánh !floating, haptic disabled, semantics
  sheet/scan-ring, GlassSurface blur:0 thoát BackdropFilter, blob nền
  RadialGradient thay ImageFiltered, vòng quét raster-once). 10 finding bị
  verifier bác bỏ có bằng chứng. Sau fix: analyze sạch, 55/55 test pass.

**Mở (chờ quyết định của user):**
- Contrast chữ trắng trên `WonderGradients.cta` ~1.8–2.1:1 (dưới WCAG) —
  phương án: (a) scrim tối nhẹ sau label, (b) đổi gradient đậm hơn (đụng
  thương hiệu). Xem ADR-009 §Quy ước bổ sung.
- Chuyển 4 nút kính trên camera sang `blur: 0` (perf máy yếu) — đổi thị giác,
  cần duyệt.

## Goal

Rebuild bộ component dùng chung `app/lib/ui/` thành **một ngôn ngữ liquid glass
kiểu iOS 26** liền mạch cho toàn app (Flutter — giữ ADR-001, KHÔNG viết lại
native), đồng thời thêm bộ **panel nổi kéo/thả + resize kiểu visionOS**:

1. **Nền tảng motion:** spring physics chuẩn Apple (response/dampingFraction),
   dùng chung cho mọi tương tác — không còn duration/curve tuỳ tiện.
2. **Nâng recipe kính:** rim sáng dạng gradient (specular), chiều sâu khối kính,
   giữ nguyên ràng buộc "không ColorFilter bão hoà trên BackdropFilter".
3. **Component mới:** `GlassPanel` (kéo bằng title bar, resize góc/cạnh, snap
   cạnh + spring, momentum, z-order, haptics) + `GlassSheet` (bottom sheet kính,
   kéo để đóng theo velocity).
4. **Rebuild đồng nhất:** Pressable, WonderButton, WonderChip, WonderHeader,
   WonderScaffold, WonderBackground, ScanRingButton, transitions — cùng thang
   chữ (`WonderType`), token, spring; API cũ giữ tương thích (call-site không
   phải sửa, trừ khi dọn style hardcode).
5. **Cảm giác native iOS:** font hệ thống SF trên iOS (không tải mạng),
   haptics có chủ đích, chuyển màn kiểu Cupertino cho push ngang.

## Ràng buộc

- KHÔNG dependency mới (physics nằm trong Flutter SDK).
- KHÔNG emoji làm icon — icon qua shim `phosphor_compat.dart`.
- KHÔNG phá tính năng TASK-010/011 đang chờ PR (share, journey video, effort gate).
- Offline-first: không font/asset tải mạng.
- Business logic không nằm trong widget — panel dùng controller.

## Acceptance Criteria

- [ ] `app/lib/ui/motion.dart`: preset spring (smooth/snappy/bouncy/interactive)
      quy đổi đúng công thức Apple `stiffness = (2π/response)²`,
      `damping = 4π·ζ/response`; helper chạy simulation với velocity bàn giao.
- [ ] `GlassPanel` trong `GlassPanelArea`: kéo được bằng title bar; thả có
      momentum + snap về trong vùng an toàn bằng spring; resize từ góc/cạnh với
      min/max; panel được chạm nổi lên trên cùng (z-order); haptic khi snap.
- [ ] `GlassSheet.show()`: sheet kính trượt lên bằng spring, có grabber, kéo
      xuống quá ngưỡng hoặc fling nhanh → đóng; nhẹ hơn ngưỡng → nảy về.
- [ ] Mọi component cũ giữ nguyên API public (call-site hiện tại compile
      không sửa gì); style hardcode trong `ui/` được thay bằng token/`WonderType`.
- [ ] Không còn `TextStyle` lặp fontSize/weight tay trong `app/lib/ui/` —
      tất cả qua `WonderType`.
- [ ] Widget test mới: panel (kéo/clamp/resize-min/z-order), sheet
      (mở/kéo-đóng), motion (preset hợp lệ). Test cũ pass nguyên vẹn.
- [ ] Playground trong Dev Panel để thử panel/sheet (không lộ ra flow chính
      của bé).

## DoD

- [ ] `flutter analyze` sạch
- [ ] `flutter test` pass (trừ `share_test.dart` fail sẵn trên HEAD — ngoài phạm vi)
- [ ] ADR-009 ghi quyết định + specs không đổi contract (UI thuần, không đụng schema)
- [ ] Demo được trên simulator/máy thật
