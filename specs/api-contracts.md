# API Contracts — WonderLens

> Giao tiếp giữa Flutter app ↔ Vercel proxy ↔ OpenAI.

## Proxy endpoints

### POST /api/recognize

Nhận diện vật từ ảnh.

**Request:**
```json
{
  "image_base64": "string (base64 JPEG)",
  "max_candidates": 3
}
```

**Response (success):**
```json
{
  "object_id": "ball_pen | a4_paper | ... | unknown",
  "confidence": 0.0,
  "display_name": "string",
  "is_hero": true
}
```

**Response (error):**
```json
{
  "error": "string",
  "code": "RATE_LIMIT | INVALID_IMAGE | TIMEOUT"
}
```

### POST /api/generate-journey

Sinh hành trình cho vật lạ (AI live fallback).

**Request:**
```json
{
  "object_description": "string",
  "language": "vi",
  "target_age": 8
}
```

**Response:**
```json
{
  "object_name": "string",
  "stages": [
    {
      "title": "string",
      "kid_text": "string",
      "fun_fact": "string"
    }
  ]
}
```

### POST /api/research-summary

Lấy thông tin + lịch sử vật từ Wikipedia / trang chính thống, tóm tắt kid-safe.

**Request:**
```json
{
  "object_id": "ball_pen",
  "display_name": "Bút bi",
  "language": "vi"
}
```

**Response (success):**
```json
{
  "object_name": "Bút bi",
  "emoji": "🖊️",
  "object_info": "Bút bi là dụng cụ viết dùng mực lỏng...",
  "history_summary": "Bút bi hiện đại được phát minh vào thế kỷ 20...",
  "fun_facts": ["Viên bi ở đầu bút giúp mực chảy đều."],
  "sources": [
    {
      "title": "Bút bi - Wikipedia",
      "url": "https://vi.wikipedia.org/wiki/Bút_bi",
      "type": "wiki"
    }
  ],
  "confidence": "high"
}
```

**Response (partial / low confidence):**
```json
{
  "object_name": "Bút bi",
  "object_info": "...",
  "history_summary": "",
  "fun_facts": [],
  "sources": [],
  "confidence": "low"
}
```

**Quy ước:**
- Proxy fetch snippet từ Wikipedia (vi) trước; optional whitelist URL `official` / `educational`.
- OpenAI summarize theo `proxy/lib/research-summary-prompt.ts`; không bịa ngoài snippet.
- Cache theo `object_id` 24h ở proxy.
- App hero: không chặn timeline bundled; gọi research song song hoặc sau khi timeline đã hiện.

---

### POST /api/generate-video-script

Sinh kịch bản video "cách làm / cách tạo ra" từ research summary + stages.

**Request:**
```json
{
  "object_name": "Bút bi",
  "research": {
    "object_info": "string",
    "history_summary": "string",
    "fun_facts": ["string"]
  },
  "stages": [
    {
      "title": "string",
      "kid_text": "string",
      "fun_fact": "string"
    }
  ],
  "language": "vi",
  "target_age": 8
}
```

**Response:**
```json
{
  "title": "Cùng xem bút bi được tạo ra thế nào!",
  "caption": "Nhấn để xem cách làm bút bi nhé!",
  "total_duration_seconds": 45,
  "scenes": [
    {
      "order": 1,
      "title": "Từ dầu mỏ",
      "narration": "Vỏ bút làm từ nhựa. Nhựa được chế từ dầu mỏ sâu dưới lòng đất.",
      "visual_hint": "Giọt dầu chuyển thành hạt nhựa trắng, nền sáng màu.",
      "duration_seconds": 8
    }
  ]
}
```

**Quy ước:**
- System prompt: `proxy/lib/video-making-prompt.ts`.
- Output dùng cho CTA "Xem cách tạo ra" (phase 7a: scene preview; phase 7b: ghép video thật).
- `scenes = []` nếu vật không phù hợp hoặc thiếu dữ liệu.

---

### POST /api/tts

Text-to-speech cho narration.

**Request:**
```json
{
  "text": "string",
  "voice": "nova",
  "language": "vi"
}
```

**Response:** `audio/mpeg` binary stream

### POST /api/journey-images

Sinh ảnh minh hoạ kid-safe cho **từng chặng** của hành trình (vật AI-live).
Mọi chặng dùng chung một "world bible" (style + bối cảnh + bảng màu) nên các ảnh
**đồng nhất bối cảnh**. Sinh song song bằng OpenAI Images (`gpt-image-1`).

Hero objects **không** gọi endpoint này — ảnh đã pre-gen & bundle sẵn
(`scripts/pregen-hero-images.mjs`), tham chiếu qua `stages[].illustration`.

**Request:** (header `x-app-token`)
```json
{
  "name": "string",
  "material_badge": "string (optional)",
  "stages": [{ "title": "string", "kid_text": "string (optional)" }]
}
```

**Response:**
```json
{
  "images": [
    { "stage_index": 0, "image_base64": "string (base64 PNG)" }
  ]
}
```

Quy ước:
- Tối đa 4 chặng có ảnh (khớp UI). Chặng nào lỗi thì **vắng mặt** trong mảng —
  app rớt về tile không-ảnh, không crash.
- `422 content_not_kid_safe` nếu text journey bị moderation gắn cờ.
- App cache ảnh ra file local theo `objectId` → mở lại tức thì, không gọi lại.

## Local data schema

### CollectedObject (Hive)

```dart
@HiveType(typeId: 0)
class CollectedObject {
  @HiveField(0) String objectId;
  @HiveField(1) String displayName;
  @HiveField(2) String emoji;
  @HiveField(3) DateTime discoveredAt;
  @HiveField(4) bool badgeUnlocked;
}
```

### Ảnh sản phẩm (cutout, local-only)

Không có thay đổi proxy. Khi quét, app tách nền **trên máy** (xem
`ADR-006`) qua MethodChannel `wonderlens/segmentation`:

- Request (app → native): method `cutout`, args `{ "path": "<đường dẫn ảnh chụp>" }`
- Response: PNG bytes (nền trong suốt) hoặc `null` (rớt về emoji).

Lưu local: `getApplicationDocumentsDirectory()/captures/{object_id}.png`
(`CaptureStore`). Ảnh thật của vật được hiển thị thay emoji; thiếu ảnh → emoji.

### HeroContent (bundled JSON)

Xem schema trong `AGENTS.md` → "Content schema".

Mở rộng cho video journey + ảnh minh hoạ từng chặng:

```json
{
  "id": "ball_pen",
  "name": "Bút bi",
  "stages": [
    {
      "title": "Bắt đầu từ dầu mỏ",
      "illustration": "assets/images/ball_pen_stage0.png",
      "kid_text": "..."
    }
  ],
  "video": {
    "asset": "assets/videos/ball_pen_making.mp4",
    "poster": "assets/images/ball_pen_video_poster.png",
    "duration_seconds": 45,
    "caption": "Cùng xem một cây bút bi được tạo ra như thế nào nhé!"
  }
}
```

### ObjectResearch (từ `/api/research-summary`)

```dart
class ObjectResearch {
  String objectName;
  String emoji;
  String objectInfo;       // "Vật này là gì?"
  String historySummary;   // Lịch sử ngắn
  List<String> funFacts;
  List<ResearchSource> sources;
  String confidence;       // high | medium | low
}

class ResearchSource {
  String title;
  String url;
  String type;             // wiki | official | educational
}
```

### VideoMakingScript (từ `/api/generate-video-script`)

```dart
class VideoMakingScript {
  String title;
  String caption;
  int totalDurationSeconds;
  List<VideoScene> scenes;
}

class VideoScene {
  int order;
  String title;
  String narration;
  String visualHint;
  int durationSeconds;
}
```

Quy ước:
- `video` là optional để app có thể hiển thị timeline trước khi đủ video assets.
- Hero objects ưu tiên video bundled trong app để chạy offline.
- AI live: nhãn "Khám phá vui (AI)"; video on-demand qua `/api/video/*` (Sora) hoặc script từ `/api/generate-video-script`.
- Nếu `video.asset` thiếu hoặc load lỗi, app fallback sang poster + timeline text, không crash.
- `stages[].illustration` là **optional**: hero objects pre-gen sẵn (asset bundle);
  vật AI-live sinh runtime qua `POST /api/journey-images` rồi cache local. Thiếu
  ảnh → tile chặng hiển thị không-ảnh (giữ look cũ), không crash.
- Research summary (TASK-007): hero offline timeline ngay; wiki summary load nền khi có mạng.

## Error handling contract

- HTTP 4xx: app hiện toast lỗi, không crash
- HTTP 5xx / timeout: fallback sang "thử lại" UI
- Confidence < 0.7: app hỏi "Có phải [X]? / Chọn lại"
- `object_id = "unknown"` + online: trigger AI live
- `object_id = "unknown"` + offline: hiện "Khám phá sau nhé!"
- Research timeout/lỗi: timeline vẫn hiện; toast "Chưa tìm thêm được thông tin"
- Video script rỗng hoặc video asset lỗi: hiện "Video đang được chuẩn bị" + vẫn cho nghe timeline
- Ảnh chặng lỗi/không có: tile chặng hiển thị không-ảnh (không placeholder vỡ), timeline vẫn đầy đủ chữ + audio
