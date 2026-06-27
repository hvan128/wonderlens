# ADR-006: Tách nền vật trên máy (object cutout) làm ảnh sản phẩm

**Status:** Accepted
**Date:** 2026-06-27

## Context

Khi trẻ chụp một đồ vật, ta muốn lưu lại **ảnh thật của vật đó** (đã tách nền,
dạng "sticker") làm hình ảnh đại diện thay cho emoji — để bộ sưu tập mang tính
"vật MÀ BẠN tìm thấy". Cần phát hiện chủ thể + tách nền.

Yêu cầu: offline-first (demo không phụ thuộc wifi), không tốn tiền mỗi lần quét,
không làm vỡ luồng khám phá, và **giữ build iOS sạch** (máy demo là iPhone; xem
note "iOS dùng SPM, Podfile.lock chỉ 2 pod").

Các lựa chọn engine:
- **ML Kit Subject Segmentation (Flutter package)**: chất lượng tốt nhưng package
  `google_mlkit_subject_segmentation` **chỉ hỗ trợ Android**; dependency nền
  `google_mlkit_commons` lại kéo pod **MLKit** (MLImage/MLKitCommon/MLKitVision)
  vào iOS — phình ~35MB, không có lát arm64 cho simulator Apple Silicon, và phá
  vỡ invariant "iOS chỉ 2 pod".
- **Apple Vision** `VNGenerateForegroundInstanceMaskRequest` (iOS 17+): đúng công
  nghệ "lấy chủ thể" như app Ảnh, chất lượng cao, offline, miễn phí, **chỉ dùng
  framework hệ thống** (không thêm pod).
- **Pure-Dart flood-fill**: nhẹ nhưng chất lượng thấp với nền lộn xộn.
- **Proxy/server**: chất lượng cao nhưng cần mạng + tốn tiền → ngược offline-first.

## Decision

Tách nền **on-device theo từng nền tảng** qua một MethodChannel chung
`wonderlens/segmentation` (method `cutout(path) -> PNG?`):

- **iOS 17+**: Apple **Vision** trong `ios/Runner/AppDelegate.swift` (không pod).
- **Android (minSdk 24+)**: ML Kit Subject Segmentation gọi **native trong
  `MainActivity.kt`** qua Gradle dependency
  `com.google.android.gms:play-services-mlkit-subject-segmentation:16.0.0-beta1`
  (KHÔNG dùng Flutter package, để iOS không bị kéo pod MLKit).
- **iOS < 17 / nền tảng khác / không có chủ thể / lỗi**: trả null → app rớt về
  emoji (fallback luôn an toàn).

Dart cắt sát chủ thể (`tightCropTransparentPng`, chỉ `dart:ui`) thành khung vuông;
lưu PNG vào `getApplicationDocumentsDirectory()/captures/{objectId}.png`
(`CaptureStore`). Hiển thị qua `ObjectAvatar` ở thẻ khám phá, header hành trình,
và lưới bộ sưu tập.

## Reasons

- Offline, miễn phí, không gửi ảnh trẻ ra mạng (kid-safe + privacy).
- Native channel mirror 2 phía → **iOS giữ đúng 2 pod** (Flutter + flutter_tts),
  không phình app vì framework không dùng.
- Chất lượng cutout cao trên cả hai nền tảng (đúng lựa chọn "Apple Vision + ML Kit
  Android").
- Tính năng "nice-to-have": mọi lỗi → null → emoji, không bao giờ làm vỡ demo.

## Consequences

- Thêm code native: 1 file Swift (đã gộp trong `AppDelegate.swift`, không sửa
  Xcode project) + `MainActivity.kt`.
- Android: minSdk nâng lên **24**; thêm meta-data tải model `subject_segment`.
- iOS < 17 không có cutout (rất hiếm với máy đời mới — máy demo iOS 27).
- Ảnh lưu local theo `objectId`; vật AI-live lưu nhưng không vào lưới bộ sưu tập.
- `play-services-mlkit-subject-segmentation` còn ở **beta**.
