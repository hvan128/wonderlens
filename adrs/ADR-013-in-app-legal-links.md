# ADR-013: Link Chính sách/Điều khoản trong app + dependency url_launcher

**Status:** Accepted
**Date:** 2026-07-08
**Ref:** yêu cầu owner "build lại bản mới, thêm link Terms/Privacy vào" (phiên nộp store 2026-07-08). App đã nộp App Store (1.0) và có mặt Internal testing Play; bổ sung link pháp lý trong app cho bản 1.0.1.

## Bối cảnh

- Store bắt buộc **privacy URL ở cấp store** (đã có). Link trong app không bắt
  buộc với app không tài khoản/không mua hàng, nhưng là thông lệ tốt và tăng độ
  tin khi reviewer soi.
- App chưa có cách mở URL ngoài. `url_launcher` chưa phải dependency trực tiếp
  (chỉ có `url_launcher_platform_interface`/`_linux` kéo theo gián tiếp), nên
  không import thẳng được.
- AGENTS/CLAUDE.md: thêm dependency mới phải có ADR.

## Quyết định

1. Thêm dependency trực tiếp **`url_launcher: ^6.3.1`** (Flutter Favorite,
   first-party) để mở trang pháp lý trong trình duyệt hệ thống.
2. Trang Terms mới `proxy/public/terms.html` (VN+EN) song song `privacy.html`,
   phục vụ tại `https://wonderlens-proxy.vercel.app/terms` (+ `/privacy`).
3. Widget `lib/widgets/legal_links.dart` (`LegalLinks`) — hai link "Chính sách
   quyền riêng tư · Điều khoản" mở bằng `launchUrl(mode: externalApplication)`.
   Đặt ở chân màn Hồ sơ, dưới dòng "phiên bản demo".
4. Lỗi mở link → nuốt im lặng (điều hướng phụ, không chặn UI).

## Hệ quả

- Không cần khai `LSApplicationQueriesSchemes` (iOS) vì gọi `launchUrl` trực
  tiếp với https, không dùng `canLaunchUrl` + custom scheme.
- Android: `url_launcher_android` tự khai intent; không thêm quyền.
- Bump `version` 1.0.0+1 → 1.0.1+2. Nội dung trang pháp lý sửa được không cần
  build app (chỉ deploy proxy).

## Phương án đã cân nhắc

- **Hiện URL dạng text copy được:** không cần dependency nhưng UX kém, không
  phải "link" đúng nghĩa → loại.
- **WebView nhúng:** nặng, thêm dependency lớn hơn, thừa cho việc mở 1 trang tĩnh → loại.
