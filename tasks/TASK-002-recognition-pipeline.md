# TASK-002: Recognition Pipeline

**Owner:** Dev  
**Status:** Done  
**Branch:** main  
**Ref:** [phase-02-recognition-pipeline.md](../plans/2026-06-27-wonderlens/phase-02-recognition-pipeline.md)

## Goal

Chụp ảnh → Vercel proxy → OpenAI Vision → nhận diện hero object hoặc unknown.

## Acceptance Criteria

- [ ] Chụp ảnh → gửi base64 lên `/api/recognize`
- [ ] Nhận về `object_id`, `confidence`, `is_hero`
- [ ] Confidence < 0.7 → hiện "Có phải [X]? / Chụp lại"
- [ ] `is_hero = true` → load nội dung bundled
- [ ] `object_id = unknown` → trigger AI live flow
- [ ] Timeout 10s → hiện lỗi, không crash

## DoD

- Flow end-to-end: camera → recognize → timeline hiện đúng object
- 2 hero objects hoạt động
- Theo ADR-002, ADR-003, contract `specs/api-contracts.md`
- Test: unit test cho recognition service
