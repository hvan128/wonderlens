# WonderLens — product + technical overview

**Jira:** [KAN-35](https://aichoem.atlassian.net/browse/KAN-35)  
**Đọc mất:** khoảng 8 phút  
**Cập nhật:** 2026-07-15

## Sản phẩm trong một câu

WonderLens là app STEM tiếng Việt để phụ huynh cùng trẻ 6–10 tuổi chụp đồ vật
quanh mình, xem câu chuyện vật liệu/cách tạo ra món đồ, rồi lưu hoặc chia sẻ thẻ
khám phá.

## Ai dùng và vì sao

| Persona | Nhu cầu | Vai trò trong sản phẩm |
|---|---|---|
| Trẻ 6–10 | Hiểu đồ vật bằng hình, giọng kể, thao tác ngắn | Người trải nghiệm chính |
| Phụ huynh | Hoạt động STEM an toàn, không ads/account | Install, consent, đồng hành, share |
| Giáo viên | Nội dung curated để mở đầu bài học | Pilot/B2B, không dùng AI-live tự do mặc định |

Core promise, scope và non-goals nằm trong
[sprint scope](../product/sprint-scope.md). Cách đo nằm trong
[beta metrics](../product/beta-success-metrics.md).

## Trạng thái sản phẩm tại HEAD

- Có Flutter app iOS/Android, onboarding, camera, cutout, reveal, timeline,
  narration, journal/collection, share, subscription foundation và reminder.
- Camera production gọi AI qua Vercel cho mọi ảnh. Nó cần mạng/token hợp lệ.
- Hero content/media bundled vẫn phục vụ flow curated, demo, mission và mở lại.
- Hive và file local giữ journal, collection, settings, entitlement và media
  cache; không có account/backend user database.
- Proxy public có privacy/support pages và các endpoint AI.
- Có store build/assets/report, nhưng release approval và console declarations
  không được suy ra là hoàn tất chỉ từ file trong repo.
- Safety guardrail có trong prompt/moderation, nhưng PRD vẫn ghi runtime red-team
  là release blocker cho trẻ thật.

## Kiến trúc

```mermaid
flowchart TB
  subgraph Mobile[Flutter app]
    UI[Onboarding / Home / Camera / Timeline / Collection]
    SVC[Services]
    LOCAL[Hive + local files + bundled assets]
    UI --> SVC
    SVC <--> LOCAL
  end

  subgraph Proxy[Vercel serverless]
    GEN[/api/generate]
    REC[/api/recognize]
    IMG[/api/journey-images]
    SPEECH[/api/speech]
    VIDEO[/api/video/*]
  end

  subgraph AI[OpenAI API]
    VISION[Chat/Vision]
    IMAGES[Images]
    TTS[Speech]
    VID[Video]
    MOD[Moderation]
  end

  SVC -->|HTTPS + x-app-token| Proxy
  GEN --> VISION
  REC --> VISION
  IMG --> MOD
  IMG --> IMAGES
  SPEECH --> TTS
  VIDEO --> VID
```

## Thành phần và ownership

| Domain | Source chính | Trách nhiệm |
|---|---|---|
| Navigation/UI | `app/lib/router.dart`, `app/lib/screens/` | Flow và presentation |
| Recognition/generation | `recognition_service.dart`, `generate_service.dart` | Gọi proxy, parse/fallback |
| Cutout | `segmentation_service.dart`, native bridges | Tách nền on-device |
| Journey media | `journey_warmup.dart`, image/speech/video services | Prefetch/cache/fallback |
| Collection | `collection_repository.dart` | Hive journal, hero dedup, badges |
| Parent controls | profile/subscription/reminder data/services | IAP gate và local reminders |
| Proxy | `proxy/api/`, `proxy/lib/` | Auth, validation, OpenAI, safe prompt |
| Content | `app/assets/content/`, audio/images/videos | Curated/offline artifacts |

Chi tiết ownership: [domains](../../specs/domains.md). Schema local và HTTP:
[API contracts](../../specs/api-contracts.md).

## Contract thực tế quan trọng

| Endpoint | Request chính | Vai trò hiện tại |
|---|---|---|
| `POST /api/generate` | `image_base64` | Camera production: nhận diện + sinh ObjectContent |
| `POST /api/recognize` | `image_base64` | Classify hero/unknown; service còn trong app nhưng không phải capture path chính |
| `POST /api/journey-images` | name/material/stages | Sinh ảnh cho AI-live, moderation trước |
| `POST /api/speech` | text | MP3, app cache và fallback on-device TTS |
| `POST /api/video/create` | prompt/object data | Media tăng cường, không được chặn timeline |
| `GET /api/video/status` | job id | Poll job |
| `GET /api/video/content` | job id/variant | Stream video/thumbnail |

Known context debt: đầu `specs/api-contracts.md` vẫn dùng tên cũ
`/api/generate-journey` và `/api/tts`; `specs/domains.md` cũng còn sơ đồ cũ.
Khi implement API tiếp theo phải chuẩn hoá source-of-truth, không copy tên cũ
vào code mới.

## Data flow và privacy

| Dữ liệu | Nơi xử lý/lưu | Ghi chú |
|---|---|---|
| Ảnh camera tạm | file camera → Flutter → proxy → OpenAI | Flutter xoá file tạm; proxy không lưu DB |
| OpenAI request/log | OpenAI | Mặc định có thể giữ abuse-monitoring logs tối đa 30 ngày |
| Cutout | file local app sandbox | Dùng lại cho timeline/collection/share |
| ObjectContent/journal | Hive local | Mở lại offline, không gửi ảnh lại |
| Settings/reminders | Hive/local OS notification | Không có push token/backend |
| Subscription entitlement | Store bridge + Hive local | Chưa có backend receipt validation |

Không ghi “zero collection” trong store/privacy copy khi ảnh được chuyển tới
third party có retention. Xem [privacy and age rating](../release/privacy-age-rating.md).

## Constraints không được phá

- Không gọi OpenAI trực tiếp từ Flutter.
- Không commit API key, token production, signing secret hay service account.
- Flutter only; state management Riverpod/provider, không tự thêm backend Java.
- Dependency mới cần ADR.
- Tiếng Việt, child-safe, không hướng dẫn nguy hiểm hoặc phản khoa học.
- Hero/onboarding/mission visual dùng object cutout, emoji chỉ fallback unknown.
- AI-live phải có nhãn; không tính như curated curriculum đã kiểm chứng.
- Share/purchase/external link phải có ngữ cảnh phụ huynh phù hợp.

## Failure model

- Camera/permission fail: giải thích + retry, không crash.
- Proxy/token/network fail: trả null/lỗi thân thiện; không giả hero thành công.
- Image/speech/video fail: timeline text vẫn hoạt động.
- Segmentation fail: fallback visual, không mất content.
- Hive/cache fail: không được làm core reveal crash; log để triage.
- AI safety fail: proxy trả lỗi, không render nội dung.

## Cấu hình và release

- `PROXY_BASE_URL` và `APP_TOKEN` đi qua `--dart-define`.
- `OPENAI_API_KEY` và `APP_SHARED_SECRET` chỉ ở Vercel env.
- Token mẫu `dev-wonderlens` không phù hợp public release.
- Release phải pass `flutter test`, `flutter analyze`, Android release build,
  iOS release no-codesign build và smoke test máy thật.
- Submit/publish store chỉ sau checklist privacy/safety/metadata.

## Source map cho người mới

1. [Workflow](../workflow.md)
2. [AGENTS.md](../../AGENTS.md)
3. [PRD](../../specs/prd.md)
4. [Domains](../../specs/domains.md)
5. [API contracts](../../specs/api-contracts.md)
6. [ADRs](../../adrs/)
7. [TASK-017](../../tasks/TASK-017-hiep-jira-handoff.md)
8. [Product flows](product-flows.md)

## Chỗ cần PM/tech lead chốt

- [ ] Online-first cho mọi capture hay restore curated-first cho hero?
- [ ] `/api/recognize` còn thuộc production architecture hay deprecate?
- [ ] OpenAI speech/video có bật production mặc định hay giữ sau flag?
- [ ] Safety sample và reviewer đủ để mở beta cho gia đình chưa?
- [ ] Subscription chỉ foundation hay nằm trong beta proposition?
- [ ] Context debt trong PRD/domains/contracts được tạo task sửa riêng.

