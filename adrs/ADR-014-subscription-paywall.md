# ADR-014: WonderLens Plus paywall + Store subscription bridge

**Status:** Accepted
**Date:** 2026-07-09
**Ref:** TASK-014

## Context

Owner cung cấp các màn tham chiếu subscription kiểu paywall mobile: gói trial,
lợi ích, social proof, restore/legal và trạng thái mua thành công. Repo hiện
chưa có domain monetisation; PRD v1 cũ ghi "không subscription / monetisation".
App nhắm trẻ 6-10 nên mọi cơ hội mua hàng phải minh bạch với phụ huynh, không
ẩn trong luồng của bé.

Tích hợp thanh toán thật cần product IDs, subscription group/base plans, giá
từng store, cấu hình sandbox và quy tắc entitlement. Có thể code bridge Store
trước bằng product IDs cấu hình qua dart-define; giao dịch thật chỉ chạy khi App
Store Connect / Play Console trả về sản phẩm hợp lệ.

## Decision

1. Thêm dependency chính thức **`in_app_purchase: ^3.3.0`** (Flutter team) để
   dùng StoreKit / Google Play Billing qua API thống nhất.
2. `SubscriptionRepository.init()` mở Hive, hydrate entitlement local, bắt đầu
   nghe `InAppPurchase.instance.purchaseStream` sớm khi app khởi động, rồi query
   product details.
3. Product IDs lấy qua dart-define:
   - `WONDERLENS_PLUS_YEARLY_ID` (default `wonderlens_plus_yearly`)
   - `WONDERLENS_PLUS_MONTHLY_ID` (default `wonderlens_plus_monthly`)
4. Paywall ưu tiên Store products: hiển thị giá Store, gọi
   `buyNonConsumable()` cho subscription, restore bằng `restorePurchases()`, và
   `completePurchase()` sau khi deliver entitlement.
5. Khi Store chưa có product IDs (dev/internal), CTA bật **mock local rõ ràng**
   để test UX nhưng UI ghi rằng chưa thu tiền thật.
6. Thêm script `app/scripts/create_store_subscriptions.rb` để tạo/cập nhật
   metadata subscription bằng API chính thức:
   - App Store Connect API qua JWT/Fastlane key.
   - Google Android Publisher API qua Play service account.
   Script đọc secrets từ biến môi trường, không tự load file secret.

Paywall hiện tại:

- Nằm ở khu phụ huynh (Hồ sơ) thay vì chen vào camera/timeline của bé.
- Có parental gate trước khi mở cơ hội mua/bật Plus.
- Dùng copy tiếng Việt và visual WonderLens; không dùng claim/brand của màn tham
  chiếu như Apple Design Award, Editor's Choice, CapWords hay Mobbin.
- Hiện Privacy/Terms và Restore Purchase.

## Consequences

- Có thể build app với Store bridge ngay; product IDs thật quyết định Store có
  hiện sheet mua hàng hay rơi về fallback mock.
- Entitlement Store hiện vẫn ghi local sau purchase/restored; trước production
  lớn hơn cần cân nhắc backend receipt validation để chống giả mạo.
- App Store Connect đã tạo được product IDs, localization, availability Việt Nam,
  giá VND, free trial 3 ngày cho gói năm và review screenshots qua API. Apple vẫn
  báo `MISSING_METADATA`, nên cần kiểm tra/submit trong App Store Connect trước
  khi StoreKit sandbox/production trả product ổn định.
- Google Play chưa tạo được subscription vì tài khoản developer chưa có payments
  profile; sau khi bật payments profile có thể chạy lại script idempotent.
