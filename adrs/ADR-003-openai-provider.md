# ADR-003: OpenAI làm AI provider duy nhất

**Status:** Accepted  
**Date:** 2026-06-27

## Context

Cần AI cho nhận diện vật (Vision) và giọng đọc (TTS). Nhiều lựa chọn: OpenAI, Google Vision + Cloud TTS, Azure, local model.

## Decision

Dùng **OpenAI** cho cả hai: `gpt-4o` (Vision) + OpenAI TTS.

## Reasons

- 1 nhà cung cấp = 1 API key, 1 billing, pipeline đơn giản
- `gpt-4o` Vision: chất lượng nhận diện tốt nhất hiện tại
- OpenAI TTS: tiếng Việt đủ dùng, latency thấp
- Không cần setup thêm service

## Consequences

- Phụ thuộc 1 provider (single point of failure) — chấp nhận cho hackathon
- Cần API key quản lý qua Vercel env vars
- Chi phí gọi API live: chấp nhận cho scale demo
