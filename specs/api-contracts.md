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

### HeroContent (bundled JSON)

Xem schema trong `AGENTS.md` → "Content schema".

Mở rộng cho video journey:

```json
{
  "id": "ball_pen",
  "name": "Bút bi",
  "video": {
    "asset": "assets/videos/ball_pen_making.mp4",
    "poster": "assets/images/ball_pen_video_poster.png",
    "duration_seconds": 45,
    "caption": "Cùng xem một cây bút bi được tạo ra như thế nào nhé!"
  }
}
```

Quy ước:
- `stages[].chapter` là optional — nhãn chương ngắn (vd "Dầu mỏ") cho chip ở màn Generating & Video Player. Thiếu thì UI tự rút gọn từ `title`. Nội dung AI-live (`/api/generate`) không sinh `chapter`, app tự fallback.
- `video` là optional để app có thể hiển thị timeline trước khi đủ video assets.
- Hero objects ưu tiên video bundled trong app để chạy offline.
- AI live fallback chưa sinh video; app hiển thị nhãn "Khám phá vui (AI)" và chỉ dùng text + audio on-device.
- Nếu `video.asset` thiếu hoặc load lỗi, app fallback sang poster + timeline text, không crash.

## Error handling contract

- HTTP 4xx: app hiện toast lỗi, không crash
- HTTP 5xx / timeout: fallback sang "thử lại" UI
- Confidence < 0.7: app hỏi "Có phải [X]? / Chọn lại"
- `object_id = "unknown"` + online: trigger AI live
- `object_id = "unknown"` + offline: hiện "Khám phá sau nhé!"
- Video asset lỗi/không tồn tại: hiện "Video đang được chuẩn bị" + vẫn cho nghe timeline
