# TASK-015: Mission onboarding + local reminders

**Owner:** Dev  
**Status:** Done  
**Branch:** current  
**Ref:** [ADR-015](../adrs/ADR-015-local-mission-reminders.md)

## Goal

Thêm luồng "nhiệm vụ khám phá" từ notification: phụ huynh bật nhắc khám phá,
local notification gợi ý một hero object, tap vào thì mở onboarding capsule của
vật đó và đi tiếp tới timeline thật.

## Acceptance Criteria

- [x] Có route `/onboarding/mission/:objectId` mở onboarding theo hero object.
- [x] Mission dùng copy parent-facing, kid-safe, không FOMO/streak.
- [x] Tap notification payload `mission:<object_id>` mở đúng mission onboarding.
- [x] Reminder mặc định tắt, bật/tắt trong Hồ sơ.
- [x] Khi bật, app schedule một reminder sau 2 ngày và reschedule khi app mở lại.
- [x] Nhấn giữ card "Nhắc khám phá" đặt notification test sau 10 giây.
- [x] Notification chỉ dùng hero object curated/offline.
- [x] Ảnh mission sinh trước bằng OpenAI qua script, không nhúng key vào app.
- [x] Mission/onboarding lấy cutout của object làm visual; không dùng emoji thay
      ảnh vật.
- [x] Thiếu ảnh/content mission không crash, fallback về cốc giấy.

## DoD

- [x] `flutter test` pass.
- [x] Android debug build pass.
- [x] Docs/spec cập nhật cho notification contract.
- [x] Không commit API key hoặc `.env`.
