# TASK-008: Detect object + tách nền → ảnh sản phẩm

**Owner:** Dev
**Status:** In review
**Branch:** feature/TASK-008-object-cutout
**Ref:** [ADR-006](../adrs/ADR-006-on-device-object-cutout.md)

## Goal

Khi trẻ chụp một vật → phát hiện chủ thể + tách nền **trên máy** (offline) → lưu
ảnh cutout làm "hình ảnh của sản phẩm", thay emoji ở thẻ khám phá, header hành
trình và lưới bộ sưu tập.

## Acceptance Criteria

- [x] Chụp → tách nền chạy song song nhận diện, không chặn luồng
- [x] iOS 17+ dùng Apple Vision; Android dùng ML Kit Subject Segmentation
- [x] Cắt sát chủ thể, khung vuông, nền trong suốt
- [x] Lưu PNG local theo `objectId` (`captures/{id}.png`), bền qua restart cho vật hero
- [x] Hiển thị ảnh ở 3 nơi (overlay / timeline / bộ sưu tập), emoji là fallback
- [x] Không tách được (iOS<17 / lỗi / nền tảng khác) → rớt về emoji, không vỡ
- [x] iOS giữ đúng 2 pod (không kéo pod MLKit)

## DoD

- [x] `flutter analyze` sạch
- [x] `flutter test` pass (thêm test crop + fallback)
- [x] Build iOS (simulator) pass
- [x] Build Android APK debug pass
- [x] ADR-006 + contracts/domains cập nhật
- [ ] PR reviewed & merged
