# Domains — WonderLens

> Domain split = context nhỏ + ownership rõ + parallel an toàn.

## Domain map

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                         │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────────┐ │
│  │  Camera  │  │ Timeline │  │      Collection       │ │
│  │ & Recog  │→ │& Narrate │  │      & Badges         │ │
│  └──────────┘  └──────────┘  └───────────────────────┘ │
│       │              ↑                                  │
└───────│──────────────│──────────────────────────────────┘
        │              │
        ▼              │
┌───────────────────────────────────┐
│         Vercel Proxy              │
│   /api/recognize                  │
│   /api/research-summary           │
│   /api/generate-journey           │
│   /api/generate-video-script      │
│   /api/tts                        │
└───────────────────────────────────┘
        │
        ▼
   OpenAI API (gpt-4o Vision + TTS)
```

---

## Domain 1: Camera & Recognition

**Responsibility:** Capture ảnh từ camera → nhận diện vật → trả về `object_id + confidence`.

**Owns:**
- `lib/screens/camera_screen.dart`
- `lib/services/recognition_service.dart`
- `lib/services/segmentation_service.dart` + `lib/services/image_cutout.dart` (tách nền on-device)
- `lib/data/capture_store.dart` (lưu ảnh sản phẩm cutout)
- `lib/widgets/object_avatar.dart` (hiển thị ảnh sản phẩm, dùng chung Domain 2/3)
- `ios/Runner/AppDelegate.swift` (Apple Vision) · `MainActivity.kt` (ML Kit) — xem `ADR-006`
- `proxy/api/recognize.ts`
- `proxy/lib/openai-vision.ts`
- `proxy/lib/hero-objects.ts`

**Contract out:**
- → Domain 2 nhận `RecognitionResult { objectId, isHero, confidence }`
- Ảnh sản phẩm (cutout PNG) lưu theo `objectId` qua `CaptureStore`; Domain 2/3 đọc
  để hiển thị thay emoji (fallback emoji nếu thiếu).

**Business rules:**
- Confidence < 0.7 → hỏi user "Có phải [X]? / Chụp lại"
- `isHero = true` → Domain 2 dùng bundled content
- `isHero = false` + online → Domain 2 gọi AI live
- `isHero = false` + offline → hiện "Khám phá sau nhé!"
- Ảnh không gửi thẳng OpenAI từ app — luôn qua proxy

---

## Domain 2: Timeline & Narration

**Responsibility:** Nhận `RecognitionResult` → hiện Origin Timeline + tự động phát giọng đọc.

**Owns:**
- `lib/screens/timeline_screen.dart`
- `lib/widgets/stage_card.dart`
- `lib/services/narration_service.dart`
- `lib/services/content_service.dart`
- `app/assets/content/` (bundled JSON hero objects)
- `proxy/api/generate.ts` (AI live journey)
- `proxy/api/research-summary.ts` (wiki/official → summary)
- `proxy/api/generate-video-script.ts` (kịch bản video cách làm)
- `proxy/lib/openai-generate.ts`
- `proxy/lib/kid-safe-prompt.ts`
- `proxy/lib/research-summary-prompt.ts`
- `proxy/lib/video-making-prompt.ts`

**Contract in:** `RecognitionResult` từ Domain 1  
**Contract out:** → Domain 3 nhận `DiscoveryEvent { objectId, objectName, completedAt }`

**Business rules:**
- Hero content: load từ bundled assets (offline, < 2s)
- Có mạng: gọi `/api/research-summary` → hiển thị `object_info` + `history_summary` + sources
- AI live content: gọi `/api/generate-journey` + TTS qua `flutter_tts`
- Video: `/api/generate-video-script` từ research + stages → CTA "Xem cách tạo ra"
- AI live content KHÔNG vào bộ sưu tập (chưa kiểm chứng)
- Text mỗi stage ≤ 50 từ, ngôn ngữ trẻ 6–10
- Giọng đọc tự chạy khi vào stage, không cần nhấn play

---

## Domain 3: Collection & Badges

**Responsibility:** Lưu trữ local, quản lý bộ sưu tập, mở huy hiệu.

**Owns:**
- `lib/screens/collection_screen.dart`
- `lib/services/collection_service.dart`
- `lib/models/collected_object.dart` (Hive entity)
- `lib/widgets/badge_widget.dart`

**Contract in:** `DiscoveryEvent` từ Domain 2  
**Contract out:** (cuối chain — không out)

**Business rules:**
- Chỉ hero objects được lưu vào bộ sưu tập
- Mỗi object lưu 1 lần (dedup theo `objectId`)
- Badge unlock ngay sau khi timeline xem xong
- Confetti + haptics khi badge mở lần đầu
- Data persist qua restart (Hive)

---

## Domain 4: Proxy (server-side)

**Responsibility:** Trung gian giữa app và OpenAI — giấu API key, validate request, route.

**Owns:**
- `proxy/api/recognize.ts`
- `proxy/api/generate.ts`
- `proxy/lib/`
- `proxy/.env` (server only, không commit)

**Contract in:** HTTP requests từ Flutter app  
**Contract out:** HTTP responses (JSON hoặc audio/mpeg)

**Business rules:**
- `OPENAI_API_KEY` chỉ tồn tại ở Vercel env vars
- Validate `APP_SHARED_SECRET` header trên mọi request
- Giới hạn image size (tránh payload lớn)
- Kid-safe prompt guardrail cho generate endpoint

---

## Domain boundaries (không được cross)

| Từ | Sang | Cách giao tiếp |
|----|------|----------------|
| Camera & Recog | Timeline | `RecognitionResult` object |
| Timeline | Collection | `DiscoveryEvent` object |
| Flutter app | Proxy | HTTP REST (`specs/api-contracts.md`) |
| Proxy | OpenAI | OpenAI SDK (server-side only) |

**KHÔNG được:** Domain 3 gọi trực tiếp proxy. Domain 1 đọc bundled content. App gọi OpenAI không qua proxy.
