---
phase: 3
title: Timeline & Narration
status: completed
priority: P1
dependencies:
  - 2
effort: D3
---

# Phase 3: Timeline & Narration

## Overview
Trải nghiệm cốt lõi (wow): màn Origin Timeline cuộn dọc, mỗi chặng có tranh + 1 câu khoa học + fun fact, **giọng đọc tự chạy** theo chặng. Soạn + đóng gói nội dung kid-safe cho đủ **8 vật hero** (offline).

## Requirements
- Functional: timeline render từ `ObjectContent.stages`; audio narration phát theo chặng (auto + nút play/pause); cuối hành trình có nút "Hoàn thành khám phá".
- Non-functional: time-to-wow <5s; 8 vật chạy offline (text + tranh + audio bundled); nội dung **kiểm chứng**, ngôn ngữ phù hợp trẻ 6–10.

## Architecture
- `TimelineScreen`: ListView/PageView dọc, mỗi `StageCard` (tranh + tiêu đề + kid_text + fun_fact).
- `NarrationController`: dùng `just_audio`/`audioplayers` phát file mp3 pre-gen theo stage; đồng bộ highlight chặng đang đọc.
- Audio pre-gen bằng OpenAI TTS (script ngoài app, lưu vào `assets/audio/<id>/stN.mp3`).

## Related Code Files
- Create: `app/lib/screens/timeline_screen.dart`, `app/lib/widgets/stage_card.dart`, `app/lib/services/narration_controller.dart`
- Create: `app/assets/content/{paper_a4,plastic_bottle,paper_clip,pencil,sticky_note,battery_aa}.json` (đủ 8)
- Create: `app/assets/illustrations/<id>/*.png`, `app/assets/audio/<id>/*.mp3`
- Create: `scripts/generate-tts.ts` (gọi OpenAI TTS pre-gen audio cho mọi stage)
- Modify: `app/pubspec.yaml` (khai báo assets audio + illustrations)

## Implementation Steps
1. Soạn nội dung 8 vật (kid-safe, 3–4 stage/vật) — **kiểm chứng khoa học**, giọng tò mò vui.
2. Tạo/sưu tầm tranh minh hoạ mỗi stage (vẽ tay hoặc sinh sẵn, phong cách nhất quán).
3. Viết `scripts/generate-tts.ts`: đọc JSON → OpenAI TTS (chọn voice + tiếng Việt) → lưu mp3.
4. Dựng `TimelineScreen` + `StageCard` + cuộn mượt.
5. `NarrationController`: auto phát theo chặng, đồng bộ highlight, play/pause.
6. Nút "Hoàn thành khám phá" → callback sang Phase 4 (badge).

## Success Criteria
- [ ] Mở 1 vật hero bất kỳ → timeline + giọng đọc chạy offline.
- [ ] Đủ 8 vật có nội dung + tranh + audio.
- [ ] Time-to-wow <5s từ lúc nhận diện xong.

## Điều chỉnh khi triển khai (ghi nhận)
- **Narration:** dùng **flutter_tts (giọng máy, offline)** thay cho OpenAI TTS pre-gen → bám mục tiêu offline-first, bỏ khâu sinh + bundle audio, không cần key. Model `Stage.audio` vẫn giữ làm đường nâng cấp (phát asset audio pre-gen nếu sau này muốn giọng chất lượng cao hơn).
- **Tranh minh hoạ:** chưa thêm; timeline hiện dùng emoji + thẻ màu. Việc làm/sinh tranh cho từng chặng chuyển sang khâu chuẩn bị asset (đánh bóng ở Phase 6). `Stage.illustration` đã sẵn để gắn ảnh.
- **Review:** Phase 3 chủ yếu là nội dung + wrapper TTS nhỏ + UI → self-review (đã kiểm máy trạng thái play/stop/speak-one + độ chính xác khoa học 8 vật). Pattern kiến trúc đã được 2 vòng code-reviewer ở P1/P2 phủ.

## Risk Assessment
- Nội dung sai khoa học cho trẻ → review thủ công từng vật trước khi chốt.
- Tranh không kịp/không đồng bộ → dùng style icon tối giản nhất quán làm dự phòng.
- Audio nặng → nén mp3 bitrate vừa phải.
