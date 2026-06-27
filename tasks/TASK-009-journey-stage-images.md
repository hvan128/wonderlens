# TASK-009: Ảnh GenAI cho từng chặng (đồng nhất bối cảnh)

**Owner:** Dev
**Status:** In progress
**Branch:** feature/TASK-008-object-cutout
**Ref:** [ADR-007](../adrs/ADR-007-journey-stage-images.md)

## Goal

Mỗi chặng "hành trình tạo ra vật" có một ảnh minh hoạ. Các ảnh của cùng một vật
**đồng nhất bối cảnh** (cùng style + bảng màu + nền). Hero objects dùng ảnh
pre-gen bundle (offline); vật AI-live sinh runtime qua proxy bằng `gpt-image-1`.

## Acceptance Criteria

- [x] Mỗi chặng dùng chung "world bible" → ảnh cùng tông (đồng nhất bối cảnh)
- [x] Proxy `POST /api/journey-images` sinh ảnh song song, có moderation gate + auth
- [x] App render ảnh trong từng tile chặng; đang sinh → shimmer; lỗi/thiếu → không-ảnh, không crash
- [x] `stages[].illustration` (asset/URL) ưu tiên hơn ảnh AI-live; vật lạ cache file local theo objectId
- [x] Script `pregen:images` sinh sẵn ảnh hero + điền `illustration` vào content JSON
- [x] Hero objects KHÔNG gọi proxy (offline-first); chỉ vật `source: live` mới sinh runtime

## DoD

- [x] `flutter analyze` sạch
- [x] `flutter test` pass cho phần mới (thêm test `resolveStageImage`)
- [x] proxy `tsc --noEmit` sạch
- [x] `specs/api-contracts.md` + ADR-007 cập nhật
- [ ] Chạy `npm run pregen:images` (cần OPENAI_API_KEY) để bundle ảnh hero
- [ ] PR reviewed & merged

## Ghi chú

- Pre-existing: `test/share_test.dart` ("🏅 Giấy") fail sẵn trên HEAD do thay đổi
  avatar ảnh thật trước đó — ngoài phạm vi task này.
