# TASK-017: Nền tích hợp game vào main-lineage

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-017-game-integration
**Ref ADR:** [ADR-012](../adrs/ADR-012-material-graph-model.md) · [ADR-013](../adrs/ADR-013-learn-play-domain.md) · [ADR-014](../adrs/ADR-014-missions-and-teacher-parent.md)

## Bối cảnh

Các tính năng game (thẻ vật liệu, đố vui, ghép ngược, nhiệm vụ) sống ở nhánh
`integration/truc-c-d` — nhánh này fork sớm và **đụng số hiệu ADR/TASK** với main-lineage:
nhánh game dùng `ADR-007/008/009` trong khi main-lineage đã có `ADR-007-journey-stage-images`
(Accepted) + `ADR-010`/`ADR-011`. TASK-008/009 trên main-lineage cũng đã thuộc việc khác
(`object-cutout`, `journey-stage-images`).

Task này là **nền tích hợp**: đưa mô hình dữ liệu + service game vào main-lineage một cách
**backward-compatible** và **giải quyết xung đột số hiệu** trước khi thêm UI game. UI game
để các task sau (B/D1/D2/A).

## Goal

Nền tích hợp game vào main-lineage: **union** `ObjectContent` (giữ story/history hiện có +
thêm `materials`/`quiz`/`assembly`), port mô hình **mạng lưới vật liệu** (`MaterialCatalog`) +
**nhiệm vụ** (`MissionRepository`) + `LearnPlayService`, thêm `materials.json`/`missions.json`,
mở rộng `HeroItem.materials`, khởi tạo trong `main.dart`, và **GIẢI QUYẾT xung đột số hiệu**
`ADR-007/008/009` → `ADR-012/013/014`. **Chưa** thêm UI game (để các task B/D1/D2/A sau).

## Phạm vi

IN:
- **Renumber ADR**: port `ADR-007/008/009` (nhánh game) → `ADR-012/013/014` trên main-lineage,
  sửa cross-reference nội bộ (material graph = ADR-012; learn-play = ADR-013; missions/teacher = ADR-014).
- **ObjectContent union**: giữ nguyên `stages`/`video`/`illustration`/story-history hiện có,
  thêm các trường **optional** `materials: [materialId]`, `quiz[]`, `assembly`.
- **MaterialCatalog** (`lib/data/material_catalog.dart`): load `assets/content/materials.json`,
  index + truy vấn graph (`materialsOf`, `objectsUsing`, `sharedMaterials`, `derivationChain`, `unlockedCards`).
- **MissionRepository** (`lib/data/mission_repository.dart`): load `assets/content/missions.json`,
  Hive box `wonderlens_progress` (key-value đơn giản: `completed_missions`, `quiz_badges`).
- **LearnPlayService** (`lib/services/learn_play_service.dart`): chấm quiz, dựng bước ghép, tính điểm chung.
- **Assets mới**: `assets/content/materials.json`, `assets/content/missions.json` (bundled, offline).
- **Mở rộng `HeroItem.materials`** + gắn `materials[]` cho hero (khớp id `hero_catalog.dart`).
- **Khởi tạo** MaterialCatalog + MissionRepository trong `main.dart`.
- Cập nhật docs: `specs/api-contracts.md`, `specs/domains.md`, `specs/features.md`, `specs/materials.md`.

OUT (để task sau):
- **UI game** — không thêm màn/UI trong task này:
  - TASK-018 (B): mini-game **quiz + ghép ngược** + CTA "Chơi tiếp" sau timeline (A3).
  - TASK-019 (D1): **nhiệm vụ** + section thẻ/nhiệm vụ trong Bộ sưu tập (A2).
  - TASK-020 (D2): **chuỗi ngày khám phá** (daily streak — mới).
  - TASK-021 (A1): tab **"Sân chơi"** trên bottom-nav.
- **Domain 6 Giáo viên/Phụ huynh** + album chung — DEFERRED (ADR-014).
- AI-live sinh quiz/assembly — không làm (chưa kiểm chứng, ADR-013).

## Acceptance Criteria

- [ ] `flutter analyze` sạch.
- [ ] `flutter test` pass — gồm **5 test game đã port** (material graph / mission / learn-play)
      **và** `collection_logic_test` **không hồi quy**.
- [ ] `ObjectContent` mới **backward-compatible**: `materials`/`quiz`/`assembly` là **optional** —
      content cũ (thiếu trường) vẫn parse + chạy, không crash.
- [ ] **Renumber ADR xong**: `ADR-012/013/014` tồn tại, có ghi chú đánh số lại từ `ADR-007/008/009`,
      cross-reference nội bộ đã sửa; không đụng `ADR-007-journey-stage-images`/`ADR-010`/`ADR-011`.
- [ ] `MaterialCatalog` + `MissionRepository` load được asset bundled, thiếu file → coi rỗng (không crash).
- [ ] Hive box `wonderlens_progress` persist qua restart; box/khoá thiếu → migrate mềm (rỗng).
- [ ] Chỉ **hero** vào mạng lưới vật liệu (AI-live loại khỏi graph — ADR-012).
- [ ] Docs cập nhật: `specs/api-contracts.md` (union schema), `specs/domains.md` (D3 mở rộng + D5 + D6 deferred),
      `specs/features.md` (F-09/10/12/13 + Sân chơi + streak), `specs/materials.md`.

## DoD

- [ ] Code đúng phạm vi + AC; ADR-012/013/014 + `specs/*` cập nhật.
- [ ] `flutter analyze` sạch · `flutter test` pass · build pass.
- [ ] Tuân ADR + AGENTS.md (business logic không trong widget, không dependency mới, không gọi OpenAI trực tiếp).
- [ ] PR reviewed & merged.
