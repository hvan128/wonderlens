---
phase: 7
title: Video Journey
status: planned
priority: P1
dependencies:
  - 3
effort: D5
---

# Phase 7: Video Journey

## Overview
Sau khi trẻ chụp đồ vật và xem Origin Timeline bằng text + audio, app mở thêm nhánh "Xem cách tạo ra": một video ngắn 30–60s giải thích quy trình tạo ra đồ vật bằng ngôn ngữ trẻ em. Với hero objects, video là asset curated/bundled để chạy offline và kiểm soát kid-safe. Với vật AI-live, chưa sinh video tự động; app chỉ hiển thị timeline text + audio và gợi ý "Video đang được chuẩn bị".

## Complete User Flow
1. Trẻ mở Camera và chụp một đồ vật.
2. App gửi ảnh qua `/api/recognize`.
3. Nếu nhận diện là hero object, app load `HeroContent` bundled.
4. Timeline hiện ngay: tên vật, các chặng lịch sử/cách hình thành bằng text, fun fact, giọng đọc `flutter_tts`.
5. Trên timeline có CTA "Xem cách tạo ra".
6. Khi bấm CTA, app mở `VideoJourneyScreen`.
7. Video tự hiện poster, nút play lớn, caption ngắn; không autoplay âm thanh để trẻ/phụ huynh chủ động.
8. Khi trẻ bấm play, video phát fullscreen hoặc inline, có play/pause, replay, phụ đề/caption ngắn theo stage nếu asset có.
9. Kết thúc video, app hiện "Con đã khám phá xong!" và nút "Nhận huy hiệu".
10. App mở confetti, ghi nhận object vào Collection/Hive, mở huy hiệu vật liệu như flow hiện tại.
11. Nếu video asset thiếu hoặc lỗi, app hiện poster + thông báo "Video đang được chuẩn bị" và vẫn cho hoàn thành khám phá bằng timeline text + audio.
12. Nếu object là AI-live/unknown, app không gọi endpoint sinh video; chỉ render timeline AI + audio on-device, gắn nhãn "Khám phá vui (AI)".

## Requirements
- Functional: mỗi hero object có optional `video` metadata trong bundled content; `VideoJourneyScreen` phát được asset video; timeline có CTA vào video; collection/badge không phụ thuộc tuyệt đối vào video.
- Non-functional: hero video chạy offline; nội dung đúng khoa học, kid-safe, tiếng Việt cho trẻ 6–10; video 30–60s; app không crash khi thiếu/lỗi video.
- Content quality: video phải giải thích theo trình tự đơn giản "nguyên liệu → xử lý → tạo hình → kiểm tra/đóng gói → đến tay chúng ta"; tránh cảnh nguy hiểm, bạo lực, máy móc đáng sợ, hướng dẫn tự làm hóa chất/nhiệt/cắt sắc nhọn.

## Architecture
- `HeroContent.video`: metadata optional gồm `asset`, `poster`, `duration_seconds`, `caption`.
- `VideoJourneyScreen`: nhận `ObjectContent`, kiểm tra `video.asset`, phát bằng `video_player` hoặc package hiện có nếu đã có trong app.
- `VideoJourneyController`: quản lý play/pause/replay, lifecycle pause khi app background, dispose đúng controller.
- `ContentRepository`: parse optional video metadata; không làm hỏng hero content cũ nếu chưa có video.
- Assets: `app/assets/videos/{object_id}_making.mp4`, poster ở `app/assets/images/{object_id}_video_poster.png`.

## Related Code Files
- Modify: `app/lib/models/object_content.dart` (thêm `VideoContent? video`)
- Modify: `app/lib/data/content_repository.dart` (parse video optional)
- Modify: `app/lib/screens/timeline_screen.dart` (CTA "Xem cách tạo ra")
- Create: `app/lib/screens/video_journey_screen.dart`
- Create: `app/lib/services/video_journey_controller.dart` nếu logic controller đủ lớn
- Modify: `app/pubspec.yaml` (khai báo video/poster assets, dependency nếu cần)
- Add assets: `app/assets/videos/*_making.mp4`, `app/assets/images/*_video_poster.png`

## Implementation Steps
1. Chốt content contract trong `specs/api-contracts.md` và cập nhật model `HeroContent`.
2. Chọn package phát video theo Flutter best practice; nếu thêm dependency mới, tạo ADR hoặc cập nhật ADR liên quan trước.
3. Dựng `VideoJourneyScreen` với trạng thái: ready, playing, ended, missing asset, error.
4. Gắn CTA từ `TimelineScreen`; hero có video thì CTA nổi bật, hero chưa có video thì CTA vẫn mở fallback poster.
5. Thêm metadata video cho 1–2 hero trước để kiểm chứng flow, sau đó mở rộng đủ 8 hero.
6. Kiểm tra lifecycle: rời màn hình, khóa máy, background/resume không rò controller.
7. Viết test cho parse schema và widget fallback khi thiếu video.
8. QA nội dung video: đúng khoa học, kid-safe, dễ hiểu, không hướng dẫn hành vi nguy hiểm.

## Acceptance Criteria
- [ ] Chụp hero object → timeline text + audio vẫn hiện <5s.
- [ ] Timeline có CTA "Xem cách tạo ra".
- [ ] Hero có `video.asset` → mở video, play/pause/replay hoạt động.
- [ ] Hero thiếu/lỗi video → hiện poster/fallback, không crash, vẫn cho nhận huy hiệu.
- [ ] AI-live/unknown không cố sinh video, chỉ hiện timeline + audio với nhãn AI.
- [ ] Ít nhất 2 hero có video end-to-end; sau đó mở rộng đủ 8 hero trước release.
- [ ] Widget/unit test phủ parse `VideoContent` và fallback missing asset.

## Definition of Done
- [ ] Code đúng spec + AC.
- [ ] `flutter test` pass.
- [ ] `flutter analyze` pass.
- [ ] Video assets không chứa secret/license không rõ ràng.
- [ ] Docs/contracts cập nhật nếu schema đổi.
- [ ] PR reviewed & merged.

## Risk Assessment
- Video asset làm app nặng → nén 720p, 30–60s, cân nhắc tải theo gói ở bản sau.
- Nội dung video sai hoặc không kid-safe → checklist review thủ công trước khi bundle.
- Dependency video mới gây lỗi lifecycle → test pause/resume, dispose controller, không autoplay khi vào màn.
- AI-generated video live tốn kém/khó kiểm duyệt → không làm trong phase này; chỉ curated hero video.
