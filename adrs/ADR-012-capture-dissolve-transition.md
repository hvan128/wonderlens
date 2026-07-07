# ADR-012: Màn camera tối giản (CapWords) + hiệu ứng tan biến vẽ viền bằng fragment shader

**Status:** Accepted
**Date:** 2026-07-07
**Ref:** yêu cầu owner "làm màn camera capture đơn giản như CapWords; chụp xong có hiệu ứng tan biến để biến mất background và hiệu ứng đang vẽ viền" (phiên 2026-07-07). Chốt hướng: dựng lại tối giản + fragment shader (GLSL).

## Bối cảnh

1. Màn `camera_screen.dart` cũ nhiều chi tiết (`WonderHeader`, hint pill, đèn pin,
   rương, nhãn "Hành trình") — owner muốn gọn kiểu CapWords: 4 góc ngắm, một dòng
   gợi ý, nút quét cầu vồng, nút thư viện.
2. App **đã có** `SegmentationService` tách nền offline (iOS Vision / Android ML
   Kit) trả foreground trong suốt. Đây đúng là dữ liệu (mask chủ thể) mà hiệu ứng
   "tan biến nền + vẽ viền" cần → tái dùng, không thêm hạ tầng mới.

## Quyết định

1. **Dựng lại `camera_screen.dart` tối giản.** Giữ NGUYÊN toàn bộ logic camera
   (permission, `_setup`, vòng đời, `takePicture`) và luồng AI `GenerateService`.
   Bỏ header/hint-pill/đèn pin; thêm `_FramingCorners` (CustomPaint 4 góc), `_TopBar`
   (ngày + nút về phòng khám phá; nhấn giữ ngày = Dev panel — thay chỗ long-press cũ),
   `_BottomBar` (gợi ý + `ScanRingButton` canh giữa + nút rương bên phải).
2. **Hiệu ứng chụp = fragment shader `shaders/dissolve.frag`.** Nền ảnh vỡ thành
   hạt theo ngưỡng noise (`bgVisible = smoothstep(progress±edge, n)`), chủ thể (alpha
   mask) giữ nguyên; viền chủ thể (gradient alpha) được **vẽ dần theo vòng quét góc**
   (`drawn = step(angN, uBorder)`) kèm điểm sáng dẫn đầu. Đầu ra premultiplied alpha.
   - Đăng ký trong `pubspec.yaml` mục `flutter: shaders:` — **không thêm package mới**
     (dùng `dart:ui` `FragmentProgram.fromAsset` + `CustomPainter` thuần).
   - `DissolveShader.ensureLoaded()` nạp một lần trong `main()` → tạo shader tức thì.
3. **Cover-fit trong shader** khớp preview camera (đang cover) để chủ thể không
   "nhảy" lúc freeze → dissolve. Chớp trắng 260ms che nhịp chuyển.
3b. **Canh khung mask↔frame — nền tảng của tính đúng đắn (fix sau bug thực tế):**
    - **iOS full-frame:** `generateMaskedImage(croppedToInstancesExtent: false)` —
      **true** cắt sát bbox chủ thể → shader kéo giãn mask ra cả khung → xoá nền
      sai. Xác nhận qua Apple docs/WWDC 2023 (session 10176). **Đây là fix gốc thật.**
    - **KHÔNG tự nướng EXIF ở Dart.** Từng thử `decodeOriented()` (nghiên cứu web bảo
      Flutter không áp EXIF) → **sai với thực tế**: `ui.instantiateImageCodec` **CÓ**
      tự áp EXIF orientation trên máy thật; nướng thêm → **xoay chồng 90° → ảnh nằm
      ngang** + lệch mask. Đã gỡ. Frame (Flutter decode, đã đứng) + mask native (đã
      đứng) khớp nhau sẵn. Bài học: **bằng chứng trên máy thắng nghiên cứu trừu tượng.**
    - **Guard tỉ lệ (`_aspectClose`, lưới an toàn):** chỉ dùng mask native khi cùng
      tỉ lệ khung với frame (±4%); lệch (còn sót ẩn số xoay/cắt) → mask 1x1 trong
      suốt → **tan biến cả khung** thay vì xoá sai. Không bao giờ hiện cảnh sai.
4. **`SegmentationService.foreground()` (mới, public):** trả foreground **toàn khung**
   (chưa cắt), để mask khớp toạ độ ảnh gốc. Gọi viên tự `tightCropTransparentPng`
   khi cần sticker bộ sưu tập. `cutout()` cũ (cắt sát + vuông) đã gỡ (dead code).
   Một lần chụp gọi native **một lần**, dùng cho cả hiệu ứng lẫn ảnh lưu.
5. **Sở hữu ảnh rõ ràng:** `CaptureDissolve` nhận & tự `dispose()` `frame`/`mask`
   (`ui.Image`) — đặt trong `AnimatedSwitcher` nên dispose chạy sau crossfade, an toàn.
   Không tách được chủ thể (simulator/lỗi) → mask 1x1 trong suốt: cả khung tan biến
   (fallback vẫn đẹp). Shader nạp lỗi → rớt về crossfade ảnh đơn giản.
6. **minShow 1500ms** đảm bảo hiệu ứng chạy trọn dù AI trả nhanh; Reduce Motion rút
   thời lượng còn 420ms.
7. **Kết quả hiện NGAY trên màn tách-nền — bỏ modal, không quay về camera.**
   Nền **lưới chấm + glow ấm** (kiểu CapWords). `CaptureDissolve` 3 pha trên cùng
   một widget (giữ nguyên State/subject):
   - **Intro:** tan biến + vẽ viền (shader).
   - **Đang dựng** (`title == null`, sau intro): **halftone cầu vồng toả** quanh chủ
     thể (`_HalftoneBurst` CustomPainter, vòng sáng chạy ra + hue theo góc) + chú
     thích + "Huỷ".
   - **Xong** (`title != null`): chủ thể **đẩy lên** (`AnimatedSlide -0.11`), RỒI hiện
     so le **tên (sticker chữ viền trắng ôm nét chữ, không phải hộp bo góc)** + loa
     + **3 nút tròn** (↺ soi lại · ✓ mở hành trình, to hơn, dấu tím · ✕ huỷ) + link
     "Không đúng vật? Chạm để soi lại".
   Bỏ hẳn modal `_DiscoveryOverlay`. "Mở hành trình" → **thẳng `/timeline`**. Guard
   `_dissolveFrame == null` chặn bung kết quả nếu bé đã huỷ lúc đang dựng.
   `/reveal` (`DiscoveryRevealScreen`) giữ lại vì `main_reveal_preview.dart` (harness
   dev) vẫn dùng — không phải dead code.

## Phương án đã cân nhắc

- **Particle thuần Dart (CustomPainter lưới ô).** Không cần cấu hình build, chạy mọi
  nơi; nhưng hạt "khối", kém mịn/điện ảnh so với noise dissolve của ảnh mẫu. Loại.
- **Trích contour (marching squares) để vẽ viền bằng PathMetric.** Chính xác nhưng
  nặng CPU + phức tạp cho mask runtime; edge-detect trong shader + vòng quét góc cho
  cảm giác "đang vẽ" tương đương, rẻ hơn nhiều. Loại.
- **Giữ màn cũ, chỉ thêm góc ngắm.** Owner muốn tối giản đúng CapWords → dựng lại.

## Hệ quả

- Bỏ đèn pin (torch) khỏi màn camera. Điều hướng về onboarding chuyển sang nút nhà
  ở `_TopBar`; mở Dev panel chuyển sang nhấn giữ ngày.
- Sửa file native `AppDelegate.swift` (crop → false) → **phải build lại đầy đủ**
  (hot reload không áp dụng thay đổi Swift).
- `SegmentationService.cutout()` (cắt sát + vuông) đã gỡ (dead code sau khi camera
  chuyển sang `foreground()` + `tightCropTransparentPng`).
- Còn cần **verify trực quan trên máy thật**: chất lượng dissolve + alpha
  premultiplied. Canh mask↔frame đã xử nền tảng (full-frame + nướng EXIF + guard);
  orientation hiếm (mirror/transpose 2,4,5,7) gần như không xảy ra với camera sau.
