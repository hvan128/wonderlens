# TASK-016: Settings polish + production release attempt

**Owner:** Dev  
**Status:** UI Done — production deploy blocked by local execution limit  
**Branch:** local  
**Ref:** TASK-014, TASK-015

## Goal

Đưa WonderLens Plus và Nhắc khám phá vào màn Cài đặt/Hồ sơ theo layout đơn giản
như màn tham chiếu: một danh sách trắng bo góc, icon rõ, trạng thái ngắn ở bên
phải, dễ quét cho phụ huynh. Sau khi UI build được, thử phát hành production qua
lane hiện có cho App Store và Google Play.

## Acceptance Criteria

- [x] Màn Cài đặt có dòng `WonderLens Plus` mở paywall.
- [x] Màn Cài đặt có dòng `Nhắc khám phá` bật/tắt local reminder.
- [x] UI gọn, nền nhẹ, một khối setting list, icon/trạng thái giống tinh thần
      màn tham chiếu nhưng dùng token WonderLens.
- [x] Trạng thái Plus hiển thị rõ: `Đang bật`, `Chưa bật`, hoặc `Store`.
- [x] Trạng thái nhắc khám phá hiển thị rõ: `Bật` / `Tắt`.
- [x] Không làm mất parental safety: subscription vẫn mở trong khu phụ huynh,
      reminder vẫn local notification parent-facing.
- [x] Build release iOS/Android được hoặc ghi rõ blocker từ store/signing.

## DoD

- [x] Scoped `flutter analyze` pass cho file liên quan.
- [x] `flutter test` phần subscription/settings/reminder pass.
- [x] Android release APK build pass.
- [x] iOS release no-codesign build pass.
- [ ] Production deploy attempt chạy bằng lane repo, kết quả được ghi rõ.

## Verification — 2026-07-09

- `flutter test test/profile_settings_test.dart test/subscription_test.dart test/mission_notification_service_test.dart` pass.
- `flutter analyze lib/screens/profile_screen.dart test/profile_settings_test.dart lib/data/app_settings.dart lib/data/subscription_repository.dart lib/services/mission_notification_service.dart` pass.
- `flutter build apk --release` pass → `build/app/outputs/flutter-apk/app-release.apk`.
- `flutter build ios --release --no-codesign` pass → `build/ios/iphoneos/Runner.app`.

## Release blocker

Chưa chạy được production artifact/upload trong phiên Codex này vì môi trường từ
chối quyền chạy lệnh cần escalation do hạn mức sử dụng. Lệnh bị chặn đầu tiên:
`./scripts/build-appbundle.sh`. Không dùng đường vòng sau khi escalation bị từ
chối.
