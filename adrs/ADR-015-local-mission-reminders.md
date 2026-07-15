# ADR-015: Local mission reminders cho object onboarding

**Status:** Accepted  
**Date:** 2026-07-09  
**Ref:** TASK-015

## Bối cảnh

WonderLens đã có onboarding lần đầu kiểu "chụp thử" với cốc giấy. Owner muốn
mở rộng thành luồng nhắc khám phá: notification gợi ý phụ huynh cùng bé thử xem
một vật quen thuộc được tạo ra như thế nào, tap vào notification thì vào thẳng
onboarding theo vật đó.

Ứng dụng phục vụ trẻ 6-10 tuổi nên notification không được tạo cảm giác ép buộc,
streak, FOMO, hoặc nói trực tiếp như app đang gọi trẻ quay lại. Persona phụ
huynh trong `specs/user-roles.md` cũng yêu cầu "không push notification spam".

## Quyết định

1. Pha này dùng **local notification**, không dùng remote push:
   - Không backend device token.
   - Không Firebase Messaging.
   - Không notification marketing từ server.
2. Thêm dependency `flutter_local_notifications` và `timezone`:
   - `flutter_local_notifications`: hiển thị/schedule local notification và
     nhận payload khi user tap.
   - `timezone`: hỗ trợ `zonedSchedule`, theo khuyến nghị của package.
3. Notification chỉ dẫn vào **hero object curated/offline**:
   - Payload dạng `mission:<object_id>`.
   - Tap mở `/onboarding/mission/:objectId`.
   - Nếu `objectId` không hợp lệ hoặc thiếu content, app rớt về `paper_cup`.
4. Copy notification là **parent-facing**:
   - Title: `Hôm nay soi thử: {objectName}`.
   - Body: `Cùng bé xem {objectNameLower} được tạo ra như thế nào nhé.`
   - Không dùng streak, deadline giả, "vào ngay", hoặc lời gọi trực tiếp gây áp
     lực cho trẻ.
5. Permission notification chỉ xin sau khi phụ huynh bật trong Hồ sơ:
   - Mặc định tắt.
   - Hồ sơ có card "Nhắc khám phá".
   - Có thể tắt bất cứ lúc nào.
6. Chiến lược "lâu không vào app":
   - Khi bật reminder, app schedule một notification sau 2 ngày.
   - Mỗi lần app mở lại/resume, notification cũ bị hủy và đặt lại sau 2 ngày.
   - Nhấn giữ card "Nhắc khám phá" trong Hồ sơ đặt một notification test sau
     10 giây để kiểm tra nhanh trên máy thật.
   - Nếu người dùng không mở app trong khoảng đó, local notification sẽ xuất hiện.
7. Hình mission là asset bundle sinh trước bằng OpenAI Images qua script repo:
   - API key chỉ dùng ở `proxy/.env` hoặc environment khi chạy script.
   - Không nhúng key vào Flutter app.
   - Object visual dùng cutout của chính hero object
     (`mission_<object_id>_cutout.png` hoặc `paper_cup_cutout.png`), không dùng
     emoji thay ảnh vật.
   - Ảnh thiếu thì app fallback an toàn, không crash.

## Phương án đã cân nhắc

- **Remote push thật**: mở đường growth hơn nhưng cần backend token, consent,
  unsubscribe, rate limit và review privacy rộng hơn. Quá nặng cho pha này.
- **In-app card only**: ít rủi ro nhất nhưng không xử lý được trường hợp lâu
  không mở app.
- **Local notification**: đủ cho comeback reminder, không server, phù hợp
  offline-first. Chọn.

## Hệ quả

- Cần cấu hình native tối thiểu cho plugin notification.
- Android scheduled notification có giới hạn theo OEM; nếu OS chặn background
  alarm thì reminder có thể không bắn đúng tuyệt đối. Luồng app vẫn dùng được.
- iOS có giới hạn pending notification, nhưng pha này chỉ giữ một reminder nên
  không chạm giới hạn.
- Nếu sau này dùng remote push, cần ADR mới cho backend token, consent, rate
  limit, privacy và store review.
