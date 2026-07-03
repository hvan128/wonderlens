# ADR-014: Nhiệm vụ (Domain 3) + Chế độ Giáo viên/Phụ huynh (Domain 6, HOÃN)

**Status:** Accepted (phần **Nhiệm vụ** — Domain 3) · **Deferred** (phần **Giáo viên/Phụ huynh** — Domain 6 + album chung)
**Date:** 2026-06-27

> **Ghi chú đánh số:** Đánh số lại từ `ADR-009` (nhánh `integration/truc-c-d`) để tránh
> đụng dải `ADR-007/008/009` của main-lineage — theo tiền lệ `ADR-010`. Nội dung kỹ thuật
> không đổi. **Phạm vi tích hợp hiện tại:** chỉ giữ **Nhiệm vụ (Domain 3)** là ACTIVE;
> **Giáo viên/Phụ huynh (Domain 6)** + **Album chung** được đánh dấu **HOÃN/ngoài phạm vi**
> (xem §"Phạm vi tích hợp" bên dưới).

## Context

Trục D ("cùng nhau") gồm các tính năng tăng gắn kết + mở thị trường trường học:

- 🗺️ Nhiệm vụ — "Tìm 3 vật làm từ kim loại trong nhà!" (D6)
- 🍎 Chế độ Giáo viên/Phụ huynh — tour dẫn dắt, bài học theo trình tự (D7)
- 👨‍👩‍👧 Album chung gia đình/lớp (D5) — **HOÃN** (cần backend, đảo non-goal — xem PRD §6).

D6 và D7 đều **offline-first, không cần backend, không account** → vẫn nằm trong ràng buộc kiến trúc hiện tại. D7 là lớp **curation + UX** trên nội dung có sẵn, không phải tính năng đa người dùng thật.

## Phạm vi tích hợp (main-lineage, đợt TASK-017)

- ✅ **ACTIVE — Nhiệm vụ (Domain 3):** port `missions.json` + `MissionRepository` + Hive box
  `wonderlens_progress`. Đây là phần được tích hợp trong đợt này (UI ở TASK-019).
- ⏸️ **DEFERRED — Giáo viên/Phụ huynh (Domain 6):** `teacher_home_screen`, `lesson_player_screen`,
  `parent_gate`, `lessons.json` — **KHÔNG** thuộc đợt tích hợp này. Giữ lại làm định hướng B2B,
  cần task riêng sau. Domain 6 vẫn ghi trong `specs/domains.md` nhưng đánh dấu **DEFERRED**.
- ⏸️ **DEFERRED — Album chung (D5):** như quyết định gốc, cần **ADR backend riêng** trước khi làm.

## Decision

### Domain 3 mở rộng (Collection, Cards & Missions) — ACTIVE

Nhiệm vụ (D6) thuộc Domain 3 — vì là **tiến độ bền vững** trên các vật/vật liệu đã khám phá.
- `app/assets/content/missions.json` (bundled).
- `lib/services/mission_repository.dart` + Hive box `wonderlens_progress` (lưu mission đã hoàn thành).
- Mission goal types: `material_count` (đếm vật theo category/material — dựa trên material graph **ADR-012**), `discover_set` (danh sách object id), `collect_card` (mở thẻ vật liệu cụ thể — thẻ suy ra từ material graph **ADR-012**).

### Domain 6 mới: Teacher/Parent — DEFERRED (ngoài phạm vi đợt này)

> Ghi nhận thiết kế để không mất context; **chưa** triển khai trong đợt tích hợp game hiện tại.

- `lib/screens/teacher_home_screen.dart` — danh sách bài học (lesson playlist).
- `lib/screens/lesson_player_screen.dart` — tour dẫn dắt qua trình tự object (intro → từng vật → wrap-up).
- `lib/widgets/parent_gate.dart` — cổng chặn đơn giản (giải phép tính/ngày sinh) trước khi vào khu người lớn — **không** PII, không account.
- `app/assets/content/lessons.json` (bundled): `{ id, title, audience, object_sequence[], intro, wrap_up }`.

**Contract:** Domain 6 đọc content (Domain 2) + collection/material graph (Domain 3) qua API read-only; **không** ghi đè business logic của domain khác.

### Album chung (D5) — HOÃN có chủ đích

Không làm trong mốc này. Khi làm: **bắt buộc ADR riêng** đảo 3 non-goal (no backend / no account / no social). Hai hướng ghi nhận trước:
1. **Offline khéo** — xuất/nhập bộ sưu tập qua share-code/QR, gộp local (giữ no-backend).
2. **Backend thật** — Firebase/Supabase đồng bộ (mở B2B đầy đủ, chi phí + rủi ro cao nhất).

## Reasons

- D6/D7 giữ nguyên ràng buộc offline-first → không tăng rủi ro demo, không chi phí hạ tầng.
- Tách Domain 6 → ownership rõ, parallel an toàn; parent gate cô lập, dễ audit.
- D7 mở đường B2B trường học bằng **đóng gói nội dung**, chưa cần đa người dùng → đi nhanh, rủi ro thấp.
- Hoãn D5 đúng quyết định sản phẩm (chốt với owner): tránh kéo backend vào quá sớm.
- **Đợt tích hợp này** ưu tiên phần chơi/tiến độ có wow-factor cho trẻ (nhiệm vụ) → giữ Domain 6 lại sau để giảm phạm vi.

## Consequences

- Thêm Hive box `wonderlens_progress` → cần TypeAdapter hoặc dùng key-value đơn giản (ưu tiên key-value như box collection hiện tại để tránh `build_runner`).
- Nhiệm vụ đọc material graph (ADR-012) để đếm `material_count`/kiểm `collect_card` → phụ thuộc task nền material graph (TASK-017).
- Parent gate **không** là bảo mật thật — chỉ chặn trẻ vô tình; ghi rõ trong spec để không hiểu nhầm (khi Domain 6 được bật lại).
- Lessons.json là nội dung curated → cần soạn + kiểm chứng (kid-safe + sư phạm) — **khi** Domain 6 mở lại.
- Cập nhật `specs/domains.md` (Domain 3 mở rộng ACTIVE; Domain 6 đánh dấu DEFERRED), `specs/api-contracts.md` (missions schema), `specs/prd.md` (D5 hoãn, B2B path).

## Alternatives rejected

- **Account giáo viên + backend tiến độ ngay**: đảo non-goal sớm, chậm, vượt scope mốc này → để D5/v2.
- **Parent gate bằng mật khẩu lưu local**: phức tạp hơn mà không an toàn hơn cổng phép tính cho mục đích "chặn trẻ".
- **Làm cả Domain 6 trong đợt tích hợp game này**: phình phạm vi, kéo dài; tách ra task B2B riêng an toàn hơn.
