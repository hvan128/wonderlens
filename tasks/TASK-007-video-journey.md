# TASK-007: Video Journey

**Owner:** Dev  
**Status:** Planned  
**Branch:** feature/TASK-007-video-journey  
**Ref:** [phase-07-video-journey.md](../plans/2026-06-27-wonderlens/phase-07-video-journey.md)

## Goal

Sau khi chụp đồ vật và xem lịch sử/hành trình bằng text + audio, trẻ có thể xem video ngắn giải thích cách đồ vật đó được tạo ra. Hero objects dùng video curated/bundled để chạy offline và kiểm soát kid-safe; AI-live chưa sinh video tự động.

## Acceptance Criteria

- [ ] Chụp hero object → timeline text + audio vẫn hiện <5s
- [ ] Timeline có CTA "Xem cách tạo ra"
- [ ] Hero có video asset → mở màn video, play/pause/replay hoạt động
- [ ] Hero thiếu hoặc lỗi video → hiện poster/fallback "Video đang được chuẩn bị", không crash
- [ ] Kết thúc video hoặc fallback → vẫn có thể nhận huy hiệu và lưu Collection
- [ ] AI-live/unknown không gọi endpoint sinh video, chỉ hiển thị timeline + audio với nhãn "Khám phá vui (AI)"
- [ ] Ít nhất 2 hero objects có video end-to-end trong task đầu; backlog mở rộng đủ 8 hero trước release

## DoD

- Code theo ADR-002, ADR-004 và contract `specs/api-contracts.md`
- `flutter test` pass
- `flutter analyze` pass
- Test parse `VideoContent` optional và widget fallback missing video
- Video/poster assets có nguồn rõ ràng, kid-safe, không vi phạm license
- Docs/contracts cập nhật nếu schema đổi
- PR reviewed & merged
