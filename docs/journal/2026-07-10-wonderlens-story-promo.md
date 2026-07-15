---
date: 2026-07-10
session: wonderlens-story-promo
---

# Journal — WonderLens Story Promo 61 giây

## Bối cảnh

Mở rộng promo dọc bằng Remotion thành câu chuyện 61 giây: từ lúc bé soi một chiếc cốc giấy, lần theo bốn chặng biến đổi vật liệu, nhận huy hiệu rồi tiếp tục khám phá thế giới quanh mình. Chiếc cốc là nhân vật chính xuyên suốt; mỗi chương vừa giải thích khoa học vừa đẩy câu chuyện tiến về hình dạng quen thuộc cuối cùng.

## Đã làm

- Cập nhật composition `WonderLensStoryPromo` 1080×1920, 30 fps thành hook → soi/chụp → nhận diện cốc giấy → bốn chương → huy hiệu → montage vật quanh bé → logo và tagline.
- Viết lại bốn chương theo mạch biến đổi rõ ràng:
  1. **Từ một thân cây:** thân gỗ tới nhà máy, được tách vỏ và băm thành mảnh gỗ sạch.
  2. **Hóa thành bột giấy:** nhiệt và dung dịch trong bồn kín làm mềm mảnh gỗ, giải phóng các sợi cellulose.
  3. **Thành cuộn giấy lớn:** bột giấy trải trên lưới, được ép nước, sấy nóng và cán thành cuộn giấy chắc.
  4. **Chiếc cốc ra đời:** giấy được phủ chống thấm, cắt thân và đáy, sau đó cuộn và ép mép thành cốc.
- Đồng bộ hình, chữ và lời kể theo các mốc 12,85–44,99 giây; mỗi chương có tiêu đề, mô tả, phép biến đổi vật liệu và màu nhấn riêng.
- Chuyển toàn bộ lời đọc sang Eco88Labs **Tuyết Trâm** (voice ID `151688`, speed `0.9`); Node tạo nhạc nền cùng shutter/chime SFX, còn `ffmpeg` căn delay, mix, chuẩn hóa loudness và mux vào MP4.
- Làm pipeline bền vững hơn: retry lỗi mạng tạm thời, cache từng câu theo fingerprint của endpoint/giọng/tốc độ/nội dung, kiểm tra file cache bằng `ffprobe`, ghi qua file tạm rồi rename và dừng nếu dịch vụ dùng giọng fallback.

## Quyết định

Giữ mỗi chương khoảng tám giây để có đủ không gian cho cả giải thích và nhịp kể, thay vì lướt nhanh qua sơ đồ sản xuất. Render hình và build audio vẫn tách được thành hai bước, đồng thời có lệnh `render:story:final` để tái tạo master hoàn chỉnh. Cache thoại chỉ được tái sử dụng khi đúng giọng, tốc độ và nội dung, giúp render lại nhanh nhưng không âm thầm dùng dữ liệu cũ.

## Output & kiểm chứng

- Video hoàn chỉnh: `promo/out/wonderlens-story-promo.mp4` — 61,0 giây, H.264 1080×1920/30 fps, AAC mono 48 kHz.
- Bản hình: `promo/out/wonderlens-story-promo-silent.mp4`; poster: `promo/out/wonderlens-story-promo-poster.jpg` (1080×1920).
- Pipeline xác nhận bản hình mới hơn source và đúng 61 giây trước khi ghép; kiểm tra từng câu thoại không chồng mốc kế tiếp; voice catalog phải ánh xạ duy nhất Tuyết Trâm tới ID `151688`.
- `npm exec tsc -- --noEmit` pass; `ffprobe` xác nhận duration, codec, kích thước, frame rate và audio; các chương cùng chuyển cảnh đã được kiểm tra trực quan.

## Tiếp theo

- Xem lại trên loa điện thoại thật và cân voice/bed nếu cần trước khi phát hành.
