# Domains — WonderLens

> Domain split = context nhỏ + ownership rõ + parallel an toàn.

## Domain map

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                         │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────────┐ │
│  │  Camera  │  │ Timeline │  │      Collection       │ │
│  │ & Recog  │→ │& Narrate │  │  Cards & Missions     │ │
│  └──────────┘  └──────────┘  └───────────────────────┘ │
│       │              ↑                    ↑↓            │
│       │              │            ┌───────────────┐    │
│       │              │            │ Learn & Play  │    │
│       │              │            └───────────────┘    │
└───────│──────────────│──────────────────────────────────┘
        │              │
        ▼              │
┌───────────────────────────────────┐
│         Vercel Proxy              │
│   /api/recognize                  │
│   /api/generate-journey           │
│   /api/tts · /api/journey-images  │
└───────────────────────────────────┘
        │
        ▼
   OpenAI API (gpt-4o Vision + TTS + Images)
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
- `proxy/lib/openai-generate.ts`
- `proxy/lib/kid-safe-prompt.ts`

**Contract in:** `RecognitionResult` từ Domain 1  
**Contract out:**
- → Domain 3 nhận `DiscoveryEvent { objectId, objectName, completedAt }`
- → Domain 5 nhận `JourneyCompleted { objectId, source }` + `ObjectContent` (đọc `quiz`/`assembly`)

**Business rules:**
- Hero content: load từ bundled assets (offline, < 2s)
- AI live content: gọi `/api/generate-journey` + TTS qua `flutter_tts`
- AI live content vào bộ sưu tập ở **track "khám phá AI" riêng + nhãn "vui (AI)"**
  (xem `ADR-011`); track lõi (hero, verified) vẫn tách biệt. Chưa red-team kid-safe
  runtime (F-08) → giữ nhãn AI tới khi audit xong
- Text mỗi stage ≤ 50 từ, ngôn ngữ trẻ 6–10
- Giọng đọc tự chạy khi vào stage, không cần nhấn play

---

## Domain 3: Collection, Cards & Missions

**Responsibility:** Lưu trữ local, quản lý bộ sưu tập, mở huy hiệu, **thẻ vật liệu + mạng lưới (C1)** và **nhiệm vụ (D6)**.

**Owns:**
- `lib/screens/collection_screen.dart`
- `lib/services/collection_service.dart` / `lib/data/collection_repository.dart`
- `lib/models/collected_object.dart` (Hive entity)
- `lib/widgets/badge_widget.dart`
- `lib/data/material_catalog.dart` + `assets/content/materials.json` *(C1 — ADR-012)*
- `lib/screens/material_cards_screen.dart` *(C1)*
- `lib/data/mission_repository.dart` + `assets/content/missions.json` *(D6 — ADR-014)*
- `lib/screens/missions_screen.dart` *(D6)*

**Contract in:** `DiscoveryEvent` từ Domain 2; `RewardEarned` từ Domain 5  
**Contract out:** `MaterialGraph` API → Domain 5 (`materialsOf`, `sharedMaterials`, `objectsUsing`, `derivationChain`, `unlockedCards`)

**Business rules:**
- Hero objects → **track lõi verified** (4 huy hiệu vật liệu cố định). Vật AI-live →
  **track "khám phá AI" riêng**, huy hiệu **động** theo `material_badge` AI, nhãn "vui (AI)"
  (xem `ADR-011`). Cấp độ chỉ tính theo hero verified; AI là bonus
- Chỉ **hero objects** vào **mạng lưới vật liệu / thẻ** — AI-live **loại khỏi** material graph
  (chưa kiểm chứng, nhất quán với `ADR-012`)
- Mỗi object lưu 1 lần (dedup theo `objectId`)
- Badge + thẻ vật liệu **suy ra từ `discoveredIds`** (không thêm Hive field — `ADR-012`)
- Nhiệm vụ hoàn thành lưu ở Hive box `wonderlens_progress` (persist, dedup — `ADR-014`)
- Confetti + haptics khi badge / thẻ / nhiệm vụ mở lần đầu
- Data persist qua restart (Hive)

---

## Domain 5: Learn & Play (mở rộng Trục C)

**Responsibility:** Lớp tương tác học sâu — đố vui (C3), cây "Tại sao?" (C4), game ghép ngược (C2), so sánh 2 vật (D8). Xem [ADR-013](../adrs/ADR-013-learn-play-domain.md).

**Owns:**
- `lib/screens/quiz_screen.dart`, `lib/screens/assembly_game_screen.dart`, `lib/screens/compare_screen.dart`
- `lib/widgets/why_tree.dart`
- `lib/services/learn_play_service.dart` (business logic)
- `lib/models/quiz.dart`, `lib/models/assembly.dart`

**Contract in:** `JourneyCompleted` + `ObjectContent` (đọc `quiz`/`assembly`/`stages[].why`) từ Domain 2; `MaterialGraph` API từ Domain 3  
**Contract out:** `RewardEarned { kind, refId }` → Domain 3

**Business rules:**
- Dữ liệu quiz/assembly/why **soạn sẵn** trong content hero (offline, kiểm chứng)
- AI-live KHÔNG sinh quiz/assembly; why-tree AI-live = optional qua Domain 4, **chặn bởi F-08**
- Không chặn luồng chính: bỏ qua quiz/game vẫn nhận huy hiệu + vào Collection
- Business logic không trong widget (AGENTS.md)

---

## Domain 6: Teacher/Parent (Trục D — B2B) — **DEFERRED**

> ⏸️ **Ngoài phạm vi đợt tích hợp game hiện tại** (xem `ADR-014` §"Phạm vi tích hợp").
> Ghi lại thiết kế để không mất context; cần task B2B riêng sau.

**Responsibility:** Khu người lớn — bài học theo trình tự + tour dẫn dắt (D7). Xem [ADR-014](../adrs/ADR-014-missions-and-teacher-parent.md).

**Owns (khi mở lại):**
- `lib/screens/teacher_home_screen.dart`, `lib/screens/lesson_player_screen.dart`
- `lib/widgets/parent_gate.dart`
- `assets/content/lessons.json`

**Contract in:** content (Domain 2) + collection/material graph (Domain 3) — **read-only**  
**Contract out:** điều hướng mở timeline của Domain 2 theo `object_sequence`

**Business rules:**
- Offline, không backend, không account, không PII
- Parent gate chỉ "chặn trẻ", **không** phải bảo mật thật (ghi rõ)
- Không ghi đè business logic domain khác (chỉ đọc qua contract)
- **D5 (album chung) HOÃN** — cần ADR backend riêng (PRD §9)

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
| Timeline | Learn & Play | `JourneyCompleted` + `ObjectContent` |
| Collection (D3) | Learn & Play | `MaterialGraph` API (read-only) |
| Learn & Play | Collection | `RewardEarned` object |
| Teacher (D6, DEFERRED) | Timeline | mở timeline theo `object_sequence` |
| Flutter app | Proxy | HTTP REST (`specs/api-contracts.md`) |
| Proxy | OpenAI | OpenAI SDK (server-side only) |

**KHÔNG được:** Domain 3 gọi trực tiếp proxy. Domain 1 đọc bundled content. App gọi OpenAI không qua proxy. Domain 5/6 ghi đè business logic domain khác (chỉ đọc qua contract). AI-live vào **mạng lưới vật liệu / thẻ**.
