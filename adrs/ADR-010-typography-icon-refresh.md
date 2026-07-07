# ADR-010: Font bundle Baloo 2 + Nunito và icon Material Symbols hai tầng

**Status:** Accepted
**Date:** 2026-07-06
**Ref:** yêu cầu owner "làm lại các màn, dùng bộ icon và font đẹp hơn" (phiên 2026-07-06, có vòng phản biện Codex)

## Bối cảnh

1. App dùng font hệ thống (SF/Roboto) — trung tính, không có cá tính thương
   hiệu; DESIGN.md cũ cấm custom font vì lo demo offline phụ thuộc mạng.
2. Icon thực chất đã là Material Symbols dưới shim tên Phosphor
   (`phosphor_compat.dart`) vì `phosphor_flutter`/`lucide_icons` không biên
   dịch được trên Flutter hiện tại (`IconData` đã thành final class). Shim ép
   `fill: 1, weight: 600` cho MỌI icon → hai tier Bold/Fill render y hệt,
   mất phân cấp thị giác.

## Quyết định

1. **Bundle font làm asset** (không tải mạng — vẫn offline-first):
   - `Baloo 2` (600/700/800, subset Latin+Vietnamese): CHỈ cho
     display / title / wordmark. Không dùng ở cỡ ≤17px hoặc chữ dài — dấu
     tiếng Việt chồng tầng dễ dính nét ở weight nặng cỡ nhỏ (phản biện Codex).
   - `Nunito` (400/700/800/900, subset Latin+Vietnamese): heading, body,
     button, label, caption — x-height cao, đọc tốt cho trẻ 6-10.
   - Gắn `ThemeData(fontFamily: 'Nunito')` → mọi `TextStyle` thô kế thừa qua
     `DefaultTextStyle`; `WonderType` set family tường minh. Body nâng 15→16.
   - Tổng dung lượng 7 file TTF ≈ 330KB.
2. **Đổi bộ icon sang Iconsax** (`iconsax_plus`) — bộ tròn thân thiện hợp app
   trẻ em, có sẵn cặp Linear (nét) / Bold (đặc) khớp đúng hệ hai tầng.
   `iconsax_plus` dùng `static const IconData` (KHÔNG `extends IconData`) nên
   biên dịch được — khác `phosphor_flutter`/`lucide_icons` (đã đóng vì
   `IconData` là final class). Kiểm bằng `flutter test` (compile thật), không
   chỉ `flutter analyze`.
   - Ánh xạ trong shim `phosphor_compat.dart` (điểm đổi bộ icon DUY NHẤT):
     `PhosphorIconsBold.*` → `IconsaxPlusLinear.*` (nét — điều hướng/công cụ);
     `PhosphorIconsFill/Duotone.*` → `IconsaxPlusBold.*` (đặc — trạng thái).
     Phân tier nay đến từ VARIANT (Linear vs Bold), không phải trục fill của
     variable font → `PhosphorIcon` render `Icon` thuần, bỏ set codePoint cũ.
   - Giữ API Phosphor-compat để không sửa ~40 call-site (phản biện Codex).
   - `material_symbols_icons` giữ lại CHỈ cho dấu check trơn (Iconsax không có
     glyph check độc lập) + Dev panel (không phải mặt trẻ thấy); mọi icon
     thương hiệu/nội dung — gồm thẻ share — đều là Iconsax.

## Hệ quả

- ✅ Cá tính thương hiệu rõ (wordmark/tựa tròn mập, thân thiện) mà thân bài vẫn
  tối ưu độ đọc; không phụ thuộc mạng.
- ✅ Icon có phân cấp: chrome nhẹ mắt, trạng thái chắc nịch.
- ⚠️ DESIGN.md §3/§7 phải cập nhật cùng ADR này (đã làm).
- ⚠️ Font mới rộng hơn hệ thống ~3-5% — text một dòng (tên vật, chip) phải giữ
  ellipsis; đã có sẵn từ đợt audit trước.
- ⚠️ Thêm weight mới phải qua gwfh (subset vietnamese) — không copy TTF full
  từ Google Fonts (nặng gấp ~4 lần).
