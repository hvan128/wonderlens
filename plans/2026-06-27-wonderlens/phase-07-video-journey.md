---
phase: 7
title: Research Summary + Video Journey
status: planned
priority: P1
dependencies:
  - 2
  - 3
effort: D7
---

# Phase 7: Research Summary + Video Journey

## Overview

Luồng mới sau khi chụp ảnh:

1. **Thông tin + lịch sử** — lấy từ Wikipedia / trang chính thống, tóm tắt kid-safe qua proxy.
2. **Timeline text + audio** — hành trình tạo ra vật (bundled hero hoặc AI live).
3. **System prompt video "cách làm"** — sinh kịch bản scene 30–60s từ summary + stages; sau đó phát video (bundled hoặc gen).

Khác với bản plan cũ (chỉ bundle video MP4): nội dung info/lịch sử **động từ nguồn**, video script **sinh có kiểm soát** bằng prompt riêng.

---

## Complete User Flow

```
┌─────────┐    ┌────────────┐    ┌─────────────────────┐    ┌──────────────────┐
│ Camera  │───►│ /recognize │───►│ /research-summary   │───►│ Object Info Card │
│  chụp   │    │  object_id │    │ wiki + official     │    │ + Lịch sử        │
└─────────┘    └────────────┘    │ → OpenAI summary    │    │ + Nguồn          │
                                 └─────────────────────┘    └────────┬─────────┘
                                                                      │
                    ┌─────────────────────────────────────────────────┘
                    ▼
         ┌──────────────────────┐    ┌─────────────────────┐
         │ Origin Timeline        │───►│ /generate-video-    │
         │ stages + flutter_tts   │    │ script (system      │
         └──────────────────────┘    │ prompt cách làm)    │
                    │                 └──────────┬──────────┘
                    │                            ▼
                    │                 ┌─────────────────────┐
                    └────────────────►│ Video Journey       │
                                      │ script / video play │
                                      └──────────┬──────────┘
                                                 ▼
                                      ┌─────────────────────┐
                                      │ Badge + Collection  │
                                      └─────────────────────┘
```

### Chi tiết từng bước

| # | Bước | Actor | Mô tả |
|---|------|-------|-------|
| 1 | Chụp ảnh | Trẻ | Camera → JPEG base64 |
| 2 | Nhận diện | App → Proxy | `POST /api/recognize` → `object_id`, `display_name`, `is_hero` |
| 3 | Hiển thị nhanh (hero) | App | Load bundled JSON → timeline <5s (offline-first) |
| 4 | Research | App → Proxy | `POST /api/research-summary` với `object_id`, `display_name`, `language: vi` |
| 5 | Fetch nguồn | Proxy | Wikipedia API (vi) + optional URL whitelist (official/educational) |
| 6 | Summarize | Proxy → OpenAI | System prompt `research-summary-prompt.ts` → structured JSON |
| 7 | Hiển thị info | App | Card: **Vật này là gì?** (`object_info`) + **Lịch sử** (`history_summary`) + fun facts + link nguồn |
| 8 | Timeline + audio | App | Stages bundled/AI; TTS đọc info → history → từng stage |
| 9 | Video script | App → Proxy | `POST /api/generate-video-script` với research + stages |
| 10 | System prompt | Proxy | `video-making-prompt.ts` → 4-6 scene, narration, visual_hint, 30-60s |
| 11 | Xem video | App | CTA "Xem cách tạo ra" → phase 7a: scene preview; phase 7b: MP4 bundled/gen |
| 12 | Hoàn thành | App | Confetti, badge, collection (hero only) |

### Nhánh offline / lỗi

| Tình huống | Hành vi |
|------------|---------|
| Hero + offline | Bundled timeline ngay; bỏ qua research; video script từ bundled nếu có |
| Research timeout | Timeline vẫn hiện; toast "Chưa tìm thêm được thông tin" |
| Wiki không có bài | Dùng `display_name` + AI tổng quát, `confidence: low` |
| Video script rỗng | Poster + timeline text, vẫn nhận badge |
| AI-live object | Research + summary + video script; nhãn "Khám phá vui (AI)"; không vào collection |

---

## System Prompts (đã định nghĩa)

| File | Vai trò |
|------|---------|
| `proxy/lib/research-summary-prompt.ts` | Wiki/official → `object_info`, `history_summary`, `fun_facts`, `sources` |
| `proxy/lib/video-making-prompt.ts` | Summary + stages → kịch bản video "cách làm" 30-60s |
| `proxy/lib/kid-safe-prompt.ts` | (giữ) Sinh stages journey từ ảnh cho vật lạ |

---

## Architecture

### Proxy endpoints mới

- `POST /api/research-summary` — fetch wiki/official + OpenAI summarize
- `POST /api/generate-video-script` — research + stages → video script

### App

- `ObjectInfoCard` — info + history + sources
- `TimelineScreen` — gắn info card phía trên stages
- `VideoJourneyScreen` — hiển thị script scenes hoặc phát MP4

### Cache

- Proxy cache theo `object_id` (24h) để giảm gọi wiki + OpenAI lặp

---

## Related Code Files

**Proxy (tạo/sửa):**
- `proxy/lib/research-summary-prompt.ts` ✅
- `proxy/lib/video-making-prompt.ts` ✅
- `proxy/lib/wiki-fetch.ts` (mới)
- `proxy/api/research-summary.ts` (mới)
- `proxy/api/generate-video-script.ts` (mới)

**App (sửa/tạo):**
- `app/lib/models/object_research.dart` (mới)
- `app/lib/models/video_script.dart` (mới)
- `app/lib/services/research_service.dart` (mới)
- `app/lib/widgets/object_info_card.dart` (mới)
- `app/lib/screens/timeline_screen.dart`
- `app/lib/screens/video_journey_screen.dart` (mới)

---

## Implementation Steps

1. ✅ Định nghĩa system prompts + contract trong `specs/api-contracts.md`
2. Implement `wiki-fetch.ts` (Wikipedia REST API tiếng Việt)
3. Implement `/api/research-summary` + unit test mock wiki response
4. Implement `/api/generate-video-script`
5. App: `ObjectInfoCard` + gọi research sau recognize
6. App: CTA video + hiển thị script scenes
7. (Phase 7b) Ghép video MP4 bundled hoặc tích hợp video gen API
8. QA kid-safe + kiểm chứng nguồn wiki với 8 hero

---

## Acceptance Criteria

- [ ] Chụp hero → timeline <5s; research summary hiện trong ≤15s khi có mạng
- [ ] Hiển thị `object_info` + `history_summary` + ít nhất 1 nguồn wiki/official
- [ ] Timeline + TTS đọc info, history, stages
- [ ] `/api/generate-video-script` trả 4-6 scene, 30-60s, kid-safe
- [ ] CTA "Xem cách tạo ra" mở video journey (script hoặc video)
- [ ] Offline hero: bundled timeline, không crash
- [ ] Research/script lỗi: fallback graceful

---

## Risk Assessment

| Rủi ro | Mitigation |
|--------|------------|
| Wiki không có bài tiếng Việt | Fallback en wiki hoặc AI tổng quát + `confidence: low` |
| Nội dung wiki sai/lệch | Chỉ summarize từ snippet; gắn nguồn; không khẳng định như sách giáo khoa |
| Latency research + script | Hero bundled trước; research nền; cache proxy |
| Video gen đắt/chậm | Phase 7a chỉ script; 7b mới video thật |
| Kid-safe | Prompt guardrail + nhãn tham khảo khi confidence thấp |
