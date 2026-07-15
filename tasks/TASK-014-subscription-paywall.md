# TASK-014: Subscription paywall WonderLens Plus

**Owner:** Dev
**Status:** Code Done — iOS Store API objects created; Google Play blocked by payments profile
**Branch:** local

## Goal

Thêm nền tảng subscription cho WonderLens Plus theo tinh thần các màn tham
chiếu: paywall rõ lợi ích, gói dùng thử, CTA nổi bật, khôi phục mua hàng, link
pháp lý và trạng thái Plus trong app. Luồng ưu tiên App Store / Google Play qua
`in_app_purchase`, fallback mock chỉ dùng khi Store chưa có product IDs.

## Acceptance Criteria

- [x] Hồ sơ có lối vào WonderLens Plus và hiển thị trạng thái đã bật.
- [x] Màn paywall dùng visual WonderLens, tiếng Việt, không copy brand/claim của
      app tham chiếu.
- [x] Có gói năm dùng thử 3 ngày và gói tháng để mô phỏng lựa chọn.
- [x] CTA mua/dùng thử đi qua parental gate trước khi bật Plus.
- [x] Query product details từ Store khi Store sẵn sàng.
- [x] Bật Plus qua Store purchase stream khi mua/restore thành công.
- [x] Fallback mock local khi Store chưa có product IDs để kiểm thử UX.
- [x] Bật Plus lưu local qua Hive và persist qua restart.
- [x] "Khôi phục mua hàng" gọi Store restore và phản hồi rõ.
- [x] Có Privacy/Terms trên màn paywall.
- [x] Script Store API tạo/cập nhật product metadata idempotent.

## DoD

- `flutter test test/subscription_test.dart` pass.
- Scoped `flutter analyze` pass.
- Dependency mới có ADR: `in_app_purchase`.
- Không hardcode secret; product IDs cấu hình qua dart-define.

## Store API run — 2026-07-09

Script: `app/scripts/create_store_subscriptions.rb`

- App Store Connect:
  - Product IDs đã tạo: `wonderlens_plus_yearly`, `wonderlens_plus_monthly`.
  - Subscription group: `WonderLens Plus`.
  - Localizations: `vi`, `en-US`.
  - Territory: `VNM`.
  - Giá: `499000 VND / năm`, `89000 VND / tháng`.
  - Intro offer: gói năm có free trial `THREE_DAYS`.
  - App Store review screenshot: upload `COMPLETE` cho cả hai gói.
  - API vẫn trả state `MISSING_METADATA`; cần kiểm tra/submit trong App Store
    Connect trước khi sản phẩm xuất hiện ổn định cho StoreKit.
- Google Play:
  - Android Publisher API bị chặn bởi cấu hình tài khoản:
    `Cannot create a subscription without first registering a payments profile
    for the developer account.`
  - Sau khi bật payments profile, chạy lại script để tạo subscription/base plans.
