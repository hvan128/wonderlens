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

### Bộ sưu tập (Hive box `wonderlens_collection`, không TypeAdapter)

Hai key trong cùng box:

- `discovered`: `List<String>` — id các **hero object** đã khám phá. Level +
  huy hiệu vật liệu suy ra từ danh sách này (chỉ hero, xem `specs/domains.md`).
- `journal`: `List<String>` — nhật ký **"Khám phá thêm (AI)"**, mỗi phần tử là
  JSON string của một vật NON-hero (AI-live), mới nhất đứng đầu, dedup theo `id`:

```json
{
  "id": "wooden_spoon",
  "name": "Thìa gỗ",
  "emoji": "🥄",
  "discovered_at": "2026-07-02T10:30:00.000",
  "content": { "id": "wooden_spoon", "name": "...", "stages": [] }
}
```

`discovered_at` là **giờ Việt Nam (UTC+7)**, ghi bằng `vnNow()` — độc lập múi
giờ thiết bị nên ngày nhật ký luôn đúng ngày VN dù máy đặt sai múi giờ. Định
dạng ISO **không có hậu tố 'Z'** (giờ tường, không quy đổi khi đọc lại).

`content` là `ObjectContent` JSON đầy đủ (schema như response `/api/generate`)
để mở lại timeline **offline, không gọi lại proxy**. Ảnh chặng đã cache theo
`content.id` nên mở lại cũng không tốn phí sinh ảnh. Vật journal không mở
huy hiệu, không tính level (AI content chưa red-team).

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
      "kid_text": "...",
      "predict": {
        "question": "Dầu mỏ sẽ biến thành gì tiếp theo?",
        "options": ["Hạt nhựa nhỏ xíu", "Nước ngọt", "Cục đá"],
        "answer_index": 0,
        "hint": "Nghĩ xem vỏ bút cứng làm bằng gì nhỉ?"
      },
      "action": { "type": "hold", "label": "Nhấn giữ để nung chảy hạt nhựa" }
    }
  ],
  "experiment": {
    "title": "Thử nghiệm nhỏ tại nhà",
    "prompt": "Viết vài chữ rồi lật ngửa bút viết tiếp — viên bi có còn ra mực không?",
    "reveal": "Viên bi lăn được mọi hướng nên viết ngược vẫn ra mực một chút đấy!",
    "badge": "Nhà khoa học nhí"
  },
  "video": {
    "asset": "assets/videos/ball_pen_making.mp4",
    "poster": "assets/images/ball_pen_video_poster.png",
    "duration_seconds": 45,
    "caption": "Cùng xem một cây bút bi được tạo ra như thế nào nhé!"
  }
}
```

Quy ước:
- `video` là optional để app có thể hiển thị timeline trước khi đủ video assets.
- Hero objects ưu tiên video bundled trong app để chạy offline.
- Vật KHÔNG có video bundled (gồm AI-live): app TỰ SINH phim hành trình runtime
  qua proxy (`JourneyVideo.autoGenerate`, kích hoạt ngầm sau giọng kể / khi xem
  hết trang). Phim phát tắt tiếng, là tăng cường tuỳ chọn: proxy lỗi/thiếu token
  → thẻ phim hiện nút "Thử lại", không chặn hành trình text + audio.
- Nếu `video.asset` thiếu hoặc load lỗi, app fallback sang poster + timeline text, không crash.
- `stages[].illustration` là **optional**: hero objects pre-gen sẵn (asset bundle);
  vật AI-live sinh runtime qua `POST /api/journey-images` rồi cache local. Thiếu
  ảnh → tile chặng hiển thị không-ảnh (giữ look cũ), không crash.
- `stages[].predict`, `stages[].action`, `experiment` là **optional** và được giữ
  để tương thích content cũ. Timeline hiện tại không render các field này thành
  cổng chặn; mọi chặng hiển thị ngay theo thứ tự để trẻ xem nhanh và trực quan.
  `action.type` vẫn parse trong `hold | swipe | tap | drag`; field thiếu/hỏng
  không làm app crash.
- Phần thưởng (ghi bộ sưu tập + confetti + badge) **không** chạy trước khi trẻ
  thấy nội dung; kích hoạt khi trẻ cuộn tới cuối hành trình, hoặc tự kích hoạt nếu
  nội dung quá ngắn không cần cuộn. Hero (`source: asset`) → `discovered` (level +
  huy hiệu); vật `live` → nhật ký `journal` "Khám phá thêm (AI)" (không level/huy hiệu).

## Error handling contract

- HTTP 4xx: app hiện toast lỗi, không crash
- HTTP 5xx / timeout: fallback sang "thử lại" UI
- Confidence < 0.7: app hỏi "Có phải [X]? / Chọn lại"
- `object_id = "unknown"` + online: trigger AI live
- `object_id = "unknown"` + offline: hiện "Khám phá sau nhé!"
- Video asset lỗi/không tồn tại: hiện "Video đang được chuẩn bị" + vẫn cho nghe timeline
- Ảnh chặng lỗi/không có: tile chặng hiển thị không-ảnh (không placeholder vỡ), timeline vẫn đầy đủ chữ + audio
