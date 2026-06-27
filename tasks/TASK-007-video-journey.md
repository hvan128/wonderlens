# TASK-007: Research Summary + Video Journey

**Owner:** Dev  
**Status:** Planned  
**Branch:** feature/TASK-007-research-video-journey  
**Ref:** [phase-07-video-journey.md](../plans/2026-06-27-wonderlens/phase-07-video-journey.md)

## Goal

Sau khi chụp ảnh, app hiển thị **thông tin + lịch sử** của vật (lấy từ Wikipedia/trang chính thống, tóm tắt kid-safe qua proxy), kèm timeline text + audio. Sau đó dùng **system prompt** sinh kịch bản video "cách làm / cách tạo ra" cho trẻ em.

## Luồng (tóm tắt)

```
Chụp ảnh → Nhận diện → Research (wiki/official) → Summary → Hiển thị info + lịch sử + timeline + audio
                                                                              ↓
                                                              System prompt → Kịch bản video "cách làm"
                                                                              ↓
                                                              Phát video (bundled hoặc sinh sau)
```

## Acceptance Criteria

### Bước 1 — Research & Summary
- [ ] Sau chụp ảnh, proxy gọi `/api/research-summary` với `object_id` hoặc `display_name` (+ optional ảnh)
- [ ] Proxy fetch snippet từ Wikipedia (vi) và/hoặc URL chính thống đã whitelist
- [ ] OpenAI tóm tắt thành `object_info`, `history_summary`, `fun_facts`, `sources[]`, `confidence`
- [ ] App hiển thị block "Vật này là gì?" + "Lịch sử" + nguồn tham khảo trước/song song timeline stages
- [ ] Hero object: bundled content vẫn hiện <5s; research summary load nền hoặc cache, không chặn wow-factor
- [ ] Offline: fallback bundled hero content; không crash

### Bước 2 — Timeline text + audio
- [ ] Stages hiển thị hành trình tạo ra (bundled hero hoặc AI live như hiện tại)
- [ ] `flutter_tts` đọc `object_info`, `history_summary`, và từng stage

### Bước 3 — System prompt video "cách làm"
- [ ] Proxy `/api/generate-video-script` nhận research summary + stages → trả `VideoMakingScript` (4-6 scene, 30-60s)
- [ ] System prompt nằm tại `proxy/lib/video-making-prompt.ts`, kid-safe, không bịa quy trình
- [ ] App có CTA "Xem cách tạo ra" dùng `caption` + script từ response
- [ ] Giai đoạn 1: hiển thị script/scene preview + poster; giai đoạn 2: ghép video thật (bundled hoặc gen API)

### Fallback & safety
- [ ] Research thất bại → chỉ hiện timeline bundled/AI, toast "Chưa tìm thêm được thông tin"
- [ ] `confidence = low` → gắn nhãn "Thông tin tham khảo"
- [ ] Video script rỗng → poster + timeline, không crash
- [ ] Không gọi OpenAI trực tiếp từ app

## DoD

- Code theo ADR-002, ADR-004 và contract `specs/api-contracts.md`
- System prompts: `proxy/lib/research-summary-prompt.ts`, `proxy/lib/video-making-prompt.ts`
- `flutter test` pass · `flutter analyze` pass · proxy `tsc --noEmit` pass
- Ít nhất 1 hero end-to-end: chụp → summary wiki → timeline → video script
- Docs/contracts cập nhật
- PR reviewed & merged
