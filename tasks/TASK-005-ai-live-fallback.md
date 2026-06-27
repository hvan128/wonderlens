# TASK-005: AI Live Fallback

**Owner:** Dev  
**Status:** Done  
**Branch:** main  
**Ref:** [phase-05-ai-live-fallback.md](../plans/2026-06-27-wonderlens/phase-05-ai-live-fallback.md)

## Goal

Vật lạ (không phải hero) → AI sinh hành trình kid-safe + TTS live.

## Acceptance Criteria

- [ ] Unknown object → gọi `/api/generate-journey` → nhận stages JSON
- [ ] Stages hiện trên Timeline screen (same UI)
- [ ] Audio TTS tự chạy qua `/api/tts`
- [ ] Loading state khi đang sinh (spinner + "Đang khám phá...")
- [ ] Offline + unknown → hiện "Khám phá sau nhé!" gracefully
- [ ] AI content: temperature thấp, prompt guardrail kid-safe

## DoD

- ≥ 1 live object thành công end-to-end khi có mạng
- Error handling đúng contract `specs/api-contracts.md`
- Không crash khi offline
