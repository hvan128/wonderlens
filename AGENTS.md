# AGENTS.md — WonderLens

> Luật repo cho AI & team. Đọc SAU `docs/workflow.md`, TRƯỚC khi code.

## Stack

| Layer | Tech |
|-------|------|
| Mobile | Flutter (iOS/Android) |
| AI Vision | OpenAI gpt-4o (qua proxy) |
| Narration | TTS mặc định hệ điều hành (`flutter_tts`); OpenAI speech proxy giữ sau flag |
| Proxy | Vercel serverless (`/proxy`) |
| Local storage | Hive |
| Animation | Rive hoặc Lottie |

## Cấu trúc thư mục

```
wonderlens/
├── app/           # Flutter app
│   ├── lib/       # Source code Dart
│   ├── test/      # Unit + widget tests
│   └── assets/    # Ảnh, audio bundled (hero objects)
├── proxy/         # Vercel serverless proxy
├── specs/         # Product specs (what/why)
├── adrs/          # Architectural decisions (how)
├── tasks/         # Task lớn: Goal, AC, DoD, owner
├── plans/         # Brainstorm reports + phase plans
├── docs/          # Workflow, journal, demo script
├── AGENTS.md      # File này
├── DESIGN.md      # Visual design system cho UI agents
└── README.md
```

## Constraints (non-negotiable)

- **KHÔNG** gọi OpenAI thẳng từ app — phải qua Vercel proxy
- **KHÔNG** commit API key vào repo
- Flutter only — không thêm backend Java/Spring
- Tiếng Việt, target audience: trẻ 6–10 tuổi
- Content kid-safe: không nội dung nguy hiểm, bạo lực, phản khoa học

## Coding rules

### Flutter / Dart
- Dart null-safety bắt buộc
- State management: provider hoặc riverpod (không thêm bloc/redux)
- Tên file: `snake_case.dart`
- Widget lớn → tách file riêng trong `lib/widgets/`
- Business logic KHÔNG viết trong widget

### Vercel proxy
- Mỗi endpoint là một file trong `proxy/api/`
- Validate request trước khi forward tới OpenAI
- Cache response khi có thể (tránh gọi lặp cùng object)

### Content / Assets
- Hero object content nằm trong `app/assets/content/`
- Audio pre-generated nằm trong `app/assets/audio/`
- Tên file asset: `{object_id}_{stage}.{ext}` (ví dụ: `ball_pen_stage1.mp3`)
- Visual đại diện cho hero/onboarding/mission object phải dùng cutout của object;
  không dùng emoji thay ảnh vật. Emoji chỉ là metadata/fallback cuối cho vật
  AI-live/unknown chưa có cutout.

## Git rules

- **KHÔNG** push thẳng `main`
- Branch: `feature/TASK-XXX-slug` hoặc `fix/TASK-XXX-slug`
- Commit: `TASK-XXX: mô tả ngắn gọn`
- PR bắt buộc review trước merge
- Chỉ merge khi DoD đủ (xem `docs/workflow.md §10`)

## Content schema (hero objects)

```json
{
  "id": "string",
  "name": "string",
  "emoji": "string",
  "material_badge": "string",
  "stages": [
    {
      "title": "string",
      "illustration": "assets/images/...",
      "kid_text": "string (≤50 từ, ngôn ngữ trẻ 6-10)",
      "fun_fact": "string (≤20 từ)",
      "audio": "assets/audio/..."
    }
  ],
  "video": {
    "asset": "assets/videos/{id}_making.mp4",
    "poster": "assets/images/{id}_video_poster.png",
    "duration_seconds": 45,
    "caption": "string"
  }
}
```

> `video` là **optional** — app không crash nếu thiếu. AI live KHÔNG sinh video.  
> Xem đầy đủ: `specs/api-contracts.md`

## AI agent instructions

### Thứ tự đọc context bắt buộc

Đọc theo thứ tự sau — **không bỏ bước, không code trước khi xong**:

| Thứ tự | File | Mục đích |
|--------|------|----------|
| 1 | `docs/workflow.md` | Quy trình & nguyên tắc vận hành |
| 2 | `AGENTS.md` (file này) | Luật repo |
| 3 | `specs/prd.md` | Business goals, features, risks |
| 4 | `specs/domains.md` | Domain split, ownership, contracts |
| 5 | `specs/api-contracts.md` | HTTP API + local schema |
| 6 | `adrs/` | Quyết định kiến trúc |
| 7 | Task trong `tasks/` | Goal, AC, DoD, owner |

Khi task đụng UI/UX, đọc thêm `DESIGN.md` sau file này. `DESIGN.md` là nguồn
sự thật visual; `AGENTS.md`, specs, contracts, ADR vẫn thắng nếu có xung đột.

### Quy tắc cứng

- Không code khi task chưa có Goal + AC rõ
- Không thêm dependency mới mà không có ADR
- Khi sửa schema/API → cập nhật `specs/api-contracts.md` ngay, không để sau
- Ưu tiên offline-first cho hero objects
- Không gọi OpenAI trực tiếp từ Flutter app
- Không commit secret/key bất kỳ
- Test pass trước push — không push nếu `flutter test` hoặc build fail

### Khi AI sai → sửa context trước

1. Task có Goal + AC đúng không?
2. Spec / ADR còn đúng không?
3. Contract khớp implementation không?
4. Rules file này có bị vi phạm không?
5. Chỉ sau đó xem lại prompt/model

## Definition of Done

- [ ] Code đúng spec + AC trong task
- [ ] `flutter test` pass
- [ ] Build không lỗi (`flutter build`)
- [ ] Docs/contracts cập nhật nếu có thay đổi
- [ ] Tuân ADR & rules file này
- [ ] PR reviewed & merged
