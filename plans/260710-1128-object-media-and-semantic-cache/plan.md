# Object media (audio + ảnh chặng) + Semantic cache DB

Status: Phase 1 DONE (media 6 vật). Phase 2 (Supabase) chờ ADR + greenlight.
Branch: feature/TASK-011-effort-gated-discovery
Ngày: 2026-07-10

## Goal

1. Nâng các vật mẫu (6 vật mới + dần các hero khác) lên chuẩn `paper_cup`: mỗi
   chặng có **ảnh minh hoạ** + **giọng đọc** (eco88 Tuyết Trâm), bundle offline.
2. Xây hệ **generate-once + semantic cache**: user quét vật bất kỳ → hệ sinh
   text/audio/ảnh (video sau) MỘT lần, lưu Supabase, lần sau quét lại đúng/gần
   đúng vật thì lấy cache, không gọi lại API. Tiết kiệm chi phí + nhanh.

## Quyết định đã chốt (owner)

- **Giọng:** eco88labs **Tuyết Trâm** (id 151688). Truy cập qua media-processing-api
  trên máy Windows `win-media` (Tailscale `100.77.64.36:8000`, public
  `https://media-processing-api.hvan.it.com`).
- **DB/Storage:** Supabase (Postgres + pgvector + Storage).
- **Semantic match:** embedding + pgvector similarity theo ngưỡng + tích luỹ alias.

## Tham chiếu kỹ thuật (đã verify)

### eco88 TTS
- `POST /eco88labs_tts` body `{gen_text, name_character:"Tuyết Trâm", output_format:"mp3", speed?}`
  → `{job_id, status:"pending"}`.
- Poll `GET /job/{id}` → `{status:"done", result:{file_url:"/static/{id}.mp3", fallback:null}}`.
  `fallback:"gcloud"` = eco88 từ chối giọng/đang sập (đã kiểm: giọng ngoài catalog rớt gcloud).
- `GET /eco88labs/voices` = 316 giọng (name + id). Tuyết Trâm: Miền Bắc, Happy,
  Đọc truyện/Sách nói, wps 4.5. Không có "Bảo Trâm".
- Cùng host còn `/gcloud_tts`, `/tts`, `/stt`, `/separate`, `/merge`, `/job/{id}`.

### Chuẩn asset "paper_cup" (đích của Phase 1)
- content JSON mỗi stage: `illustration: assets/images/{id}_stage{i}.png`,
  `audio: assets/audio/{id}_stage{i}.mp3`.
- Ngoài stage: `{id}_history.mp3`, `{id}_result.mp3`, (video optional `assets/videos/{id}.mp4`).
- Timeline ưu tiên `Stage.audio`/`Stage.illustration`; thiếu → fallback flutter_tts / runtime journey-images.

### Proxy hiện tại (chưa có DB)
- `/api/generate` (text), `/api/journey-images` (ảnh chặng runtime, cache file local),
  `/api/speech` (OpenAI TTS), `/api/video`, `/api/recognize`.

## Phase 1 — Media cho 6 vật mẫu (concrete, thấp rủi ro)

Vật: chopsticks, metal_spoon, eraser, ruler, paper_straw, popsicle_stick.

- [x] Script `proxy/scripts/pregen-object-media.mjs` (tái dùng cho vật bất kỳ):
  - Ảnh 4 chặng: OpenAI (style plaque paper_cup) → sips JPEG q82 → `{id}_stage{i}.jpg` (~240KB).
  - Audio 4 chặng + history: eco88 Tuyết Trâm speed 0.9 → `{id}_stage{i}.mp3`, `{id}_history.mp3`. Không fallback.
- [x] Cập nhật 6 content JSON: `illustration` + `audio` mỗi stage (24 stage).
- [x] Generalize `journeyCoverAudio` (set `heroesWithBundledAudio` ở hero_catalog) để dùng `{id}_history.mp3`.
- [x] Fix màn mission onboarding (camera-giả): gen `{id}_onboarding_prompt.mp3` + `{id}_onboarding_reveal.mp3`
  (Tuyết Trâm), wire `promptAudio`/`resultAudio` trong `forObjectId` (gate bằng set). Trước đó đọc device TTS.
- [x] `flutter analyze` sạch; `flutter test` 87/87 (1 flaky onboarding pass khi chạy riêng).
- [~] Build sim (bundle +14MB) — đang verify timeline có ảnh + giọng Tuyết Trâm.
- AC: mở mission onboarding vật mới → timeline hiện ảnh từng chặng + đọc giọng Tuyết Trâm.
- Ghi chú: text audio khớp timeline — stage = `${kid_text} ${fun_fact}`, cover = `history`.
  Result audio (onboarding) chưa làm — mission flow để trống, không thuộc timeline.

## Phase 2 — Semantic cache Supabase (cần ADR mới)

- [ ] ADR: dependency Supabase + pgvector + storage; luồng generate-once; ngưỡng match; chi phí.
- [ ] Schema: `objects(canonical_id, label, aliases[], embedding vector, text_json, created_at)`,
  `object_assets(object_id, kind[text|audio|image|video], stage_index, storage_path, meta)`.
- [ ] Endpoint proxy `/api/object-content` (thay/wrap generate):
  1. nhận label từ recognize → embedding (OpenAI text-embedding) →
  2. pgvector `<=>` similarity, nếu ≥ ngưỡng → trả cache (+ ghi alias nếu label mới);
  3. else generate (text→eco88 audio→ảnh) → upload Supabase Storage → insert rows → trả.
- [ ] Client: đọc từ endpoint, cache Hive/file L1; audio/ảnh từ Storage URL.
- [ ] Tinh chỉnh ngưỡng: "cốc thủy tinh ≈ cốc nước thủy tinh" khớp; "cốc giấy" ≠ "cốc thủy tinh".
- Rủi ro: an toàn nội dung trẻ em cho vật tuỳ ý; chi phí gen lần đầu; độ trễ lần đầu (~10-20s).

## Phụ thuộc & thứ tự

Phase 1 độc lập, làm trước (quick win + tạo logic gen tái dùng cho Phase 2).
Phase 2 cần ADR + Supabase project trước khi code backend.

## Open questions

- Tốc độ đọc Tuyết Trâm (wps 4.5 hơi nhanh với trẻ) — cần chỉnh `speed`?
- Ảnh chặng: phong cách (giống scene mission ấm/gỗ, hay minh hoạ hoạt hình)?
- Phase 2: vật tuỳ ý có cần kiểm duyệt nội dung/allowlist chủ đề cho trẻ 6-10 không?
- media-processing-api (Windows/Tailscale) dùng cho gen lúc build ổn; nhưng runtime
  production Phase 2 nên gọi eco88 qua domain public `media-processing-api.hvan.it.com`
  hay tự host TTS? (độ ổn định/uptime).
