# ADR-002: Hybrid curated-first content engine

**Status:** Accepted  
**Date:** 2026-06-27

## Context

Cần balance giữa demo reliability và tính tổng quát (chụp gì cũng ra). Live AI thuần: chậm + hên xui. Curated thuần: mất wow factor "chụp gì cũng được".

## Decision

**Hybrid curated-first:**
- Hero objects (~8 vật): nội dung + audio đóng gói sẵn trong app (offline, < 2s)
- Vật lạ: gọi OpenAI Vision + TTS live qua proxy

## Reasons

- Demo không phụ thuộc wifi (hero offline)
- Vẫn có "magic" với vật bất kỳ (AI live fallback)
- Kiểm soát chất lượng content cho hero (kid-safe, khoa học đúng)
- Tốc độ hero < 2s → wow-factor đảm bảo

## Consequences

- Phải soạn + kiểm chứng content 8 vật hero
- Phải pre-generate audio TTS cho hero
- `app/assets/` sẽ tương đối lớn (audio files)
- AI live = cần mạng + có thể chậm → UI phải handle loading state
