# ADR-013: Domain "Learn & Play" cho lớp tương tác chiều sâu

**Status:** Accepted
**Date:** 2026-06-27

> **Ghi chú đánh số:** Đánh số lại từ `ADR-008` (nhánh `integration/truc-c-d`) để tránh
> đụng dải `ADR-007/008/009` của main-lineage — theo tiền lệ `ADR-010`. Mô hình mạng lưới
> vật liệu nay là `ADR-012`; domain Learn & Play này là `ADR-013`. Nội dung kỹ thuật không đổi.

## Context

Trục C ("từ *xem* sang *chơi & hiểu*") thêm các trải nghiệm tương tác **sau/bên cạnh** Origin Timeline:

- ❓ Đố vui sau timeline (C3)
- 🌳 Cây "Tại sao?" — đào sâu mỗi chặng (C4)
- 🔧 Game ghép ngược — kéo nguyên liệu lắp ra đồ vật (C2)
- ⚖️ So sánh 2 vật (D8)

Các tính năng này **không thuộc** Domain 2 (Timeline thuần hiển thị + narration) cũng không thuộc Domain 3 (Collection lưu trữ). Nếu nhét vào Timeline/Collection sẽ phình widget + business logic lẫn UI (vi phạm AGENTS.md) + chặn parallel (file ownership chồng nhau).

## Decision

Tạo **Domain 5: Learn & Play** — lớp tương tác học sâu, **offline-first**, đọc dữ liệu qua contract từ Domain 2 (content) và Domain 3 (material graph + collection).

**Ownership (file riêng, không chồng):**
- `lib/screens/quiz_screen.dart` (hoặc widget overlay sau timeline)
- `lib/screens/assembly_game_screen.dart`
- `lib/screens/compare_screen.dart`
- `lib/widgets/why_tree.dart`
- `lib/services/learn_play_service.dart` (business logic: chấm quiz, dựng bước ghép, tính điểm chung)
- `lib/models/quiz.dart`, `lib/models/assembly.dart`

**Contract vào:**
- Từ Domain 2: `JourneyCompleted { objectId, source }` → mở Quiz (C3).
- Từ Domain 2: `ObjectContent` (đọc `stages[].why`, `quiz[]`, `assembly`).
- Từ Domain 3: `MaterialGraph` API (ADR-012) — `materialsOf(objectId)`, `sharedMaterials(a, b)`, `objectsUsing(materialId)`.

**Contract ra:**
- → Domain 3: `RewardEarned { kind: 'quiz_badge'|'mission_step', refId }` để Collection ghi nhận huy hiệu/tiến độ.

**Nguồn dữ liệu (bundled, offline cho hero):**
- Quiz, why-tree (1 tầng), assembly steps: **soạn sẵn trong content JSON** của hero (kiểm chứng kid-safe).
- AI-live: quiz/assembly **không** sinh tự động (chưa kiểm chứng). Why-tree AI-live = **optional** qua `/api/explain-deeper`, **kế thừa blocker kid-safe F-08** (ADR-003).

**State management:** provider/riverpod (theo AGENTS.md), không thêm bloc/redux.

## Reasons

- **Context nhỏ + ownership rõ** → parallel an toàn (workflow §8).
- Giữ Domain 2 mỏng (chỉ hiển thị + narration) và Domain 3 thuần lưu trữ.
- Offline cho hero (dữ liệu soạn sẵn) → giữ wow-factor demo không phụ thuộc wifi.
- Tách AI-live why-tree ra optional → không chặn phần offline khi F-08 chưa xong.

## Consequences

- Thêm domain mới → cập nhật `specs/domains.md` (boundaries, contract).
- Content schema mở rộng (`quiz`, `assembly`, `stages[].why`) → cập nhật `specs/api-contracts.md`.
- Cần soạn quiz + assembly + why cho hero objects (tăng công soạn nội dung, như ADR-002).
- Compare (D8) phụ thuộc material graph (ADR-012) → xếp sau task nền material graph (TASK-017).
- Game ghép ngược dùng `Draggable`/`DragTarget` của Flutter core → **không** thêm package.

## Alternatives rejected

- **Nhét quiz/why vào TimelineScreen**: phình widget, business logic trong UI, khó test, chặn parallel.
- **Sinh quiz/assembly bằng AI cho cả hero**: mất tính kiểm chứng + tốn mạng; chỉ dùng AI cho nhánh live tuỳ chọn (why-tree) sau khi qua F-08.
