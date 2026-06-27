---
phase: 5
title: AI Live Fallback
status: completed
priority: P2
dependencies:
  - 2
  - 3
effort: D5
---

# Phase 5: AI Live Fallback

## Overview
"Chụp gì cũng ra": vật ngoài bộ hero → proxy gọi OpenAI sinh hành trình JSON kid-safe + TTS live, render bằng đúng `TimelineScreen`. Kèm guardrail an toàn cho trẻ.

## Requirements
- Functional: object_id = `unknown` (hoặc confidence thấp đã xác nhận) → proxy `generate` trả `ObjectContent` đúng schema + audio (TTS live hoặc TTS theo từng stage). Render lại bằng timeline hiện có.
- Non-functional: kid-safe (không nội dung độc hại/nguy hiểm); độ trễ chấp nhận được + có loading vui; chi phí kiểm soát.

## Architecture
- Proxy `generate.ts`: input `{display_name hoặc image}`; OpenAI sinh JSON stages (temperature thấp, ép schema), prompt ràng buộc: "chỉ sự thật đơn giản, không chắc thì nói tổng quát, ngôn ngữ trẻ 6–10, gắn nhãn khám phá vui". Sinh TTS cho từng stage.
- App: cùng `ContentRepository` interface — nguồn `live` thay vì `asset`.
- Bỏ sinh ảnh live (chậm/đắt) → dùng icon/placeholder theo material; chỉ text + audio.

## Related Code Files
- Create: `proxy/api/generate.ts`, `proxy/lib/kid-safe-prompt.ts`
- Modify: `app/lib/data/content_repository.dart` (thêm nguồn live), `app/lib/services/recognition_service.dart` (route unknown → generate)
- Modify: `app/lib/screens/timeline_screen.dart` (hỗ trợ audio remote/stream + nhãn "khám phá vui")

## Implementation Steps
1. Viết kid-safe system prompt + JSON schema cho stages.
2. `generate.ts`: gọi OpenAI (chat + structured output) → validate schema → gọi TTS từng stage → trả JSON + audio URL/base64.
3. App: unknown → màn loading vui → gọi generate → render timeline (nguồn live).
4. Guardrail: lọc chủ đề nhạy cảm/nguy hiểm; nếu fail validate → thông báo thân thiện "Mình chưa biết món này, thử vật khác nhé!".
5. Gắn nhãn "khám phá vui" cho nội dung live (phân biệt với hero đã kiểm chứng).

## Success Criteria
- [ ] Chụp 1 vật ngoài hero (có mạng) → sinh hành trình + đọc to, render đúng timeline.
- [ ] Nội dung không vi phạm an toàn trẻ em; lỗi → thông báo thân thiện, không crash.

## Điều chỉnh khi triển khai (ghi nhận)
- **Bỏ TTS server:** vì narration dùng flutter_tts on-device (Phase 3), proxy `generate` chỉ trả JSON nội dung; giọng đọc do app tự đọc → đơn giản hơn, không cần stream audio.
- **AI-live không vào bộ sưu tập:** `CollectionRepository.record` chỉ tính vật trong `heroCatalog`; vật AI-live chỉ hiện timeline + nhãn "✨ Khám phá vui (AI)", không tính huy hiệu/cấp độ (tránh phồng số liệu + phân biệt nội dung chưa kiểm chứng).
- **Cần để test thật:** OpenAI key + deploy proxy + chạy app với `--dart-define=PROXY_BASE_URL=...`. Khi proxy rỗng, vật lạ → thông báo thân thiện (không crash).

## Risk Assessment
- AI bịa sai → temperature thấp + ràng buộc "không chắc nói tổng quát" + nhãn khám phá vui (không khẳng định chắc như hero).
- Độ trễ TTS từng stage → có thể stream stage đầu trước, phần sau nền; hoặc 1 file gộp.
- Đây là **nice-to-have**: không để chặn demo hero (P1–P3 đã đủ wow).
