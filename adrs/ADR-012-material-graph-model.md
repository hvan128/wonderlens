# ADR-012: Material graph data model (object ↔ vật liệu ↔ nguồn gốc)

**Status:** Accepted
**Date:** 2026-06-27

> **Ghi chú đánh số:** Đánh số lại từ `ADR-007` (nhánh `integration/truc-c-d`) để tránh
> đụng `ADR-007-journey-stage-images` (đã Accepted trên main-lineage) — theo tiền lệ
> `ADR-010`. Nội dung kỹ thuật không đổi.

## Context

Bộ huy hiệu hiện tại (`hero_catalog.dart`) gán **mỗi vật đúng 1 material string thô** (Giấy / Nhựa / Kim loại / Gỗ). Mô hình này đủ cho MVP nhưng chặn 4 tính năng Trục C/D:

- 🃏 Thẻ vật liệu sưu tầm (C1) — cần "vật liệu nguồn" mịn hơn (Dầu mỏ, Thép, Gỗ, Cát→Thuỷ tinh) có thông tin riêng.
- 🔧 Game ghép ngược (C2) — cần chuỗi biến đổi `Dầu mỏ → hạt nhựa → vỏ bút`.
- 🗺️ Nhiệm vụ (D6) — "tìm 3 vật làm từ kim loại" cần đếm theo vật liệu.
- ⚖️ So sánh 2 vật (D8) — cần biết 2 vật **chung vật liệu nào** ("bút chì và cái ghế đều từ gỗ").

Một vật thực tế làm từ **nhiều vật liệu** (bút bi = nhựa + thép + mực), và mỗi vật liệu có **nguồn gốc/chuỗi biến đổi** (Nhựa ← Dầu mỏ; Thép ← quặng sắt; Giấy ← bột giấy ← gỗ). Cần một mô hình **đồ thị (graph)**, không phải 1 nhãn phẳng.

## Decision

Mô hình **graph hai lớp**, dữ liệu **bundled offline** (không backend):

1. **Material catalog** — file mới `app/assets/content/materials.json`. Mỗi vật liệu là một node:
   ```
   Material { id, name, emoji, kind: 'source'|'derived', category, derived_from: [id], blurb, fun_facts[] }
   ```
   - `kind=source`: vật liệu thô (Dầu mỏ, Gỗ, Than chì, Cát).
   - `kind=derived`: vật liệu chế biến (Nhựa ← Dầu mỏ; Thép ← quặng sắt; Thuỷ tinh ← Cát; Giấy/Bột giấy ← Gỗ).
   - `category`: nhóm thô tương thích huy hiệu cũ (Giấy / Nhựa / Kim loại / Gỗ / Thuỷ tinh) → **không phá vỡ** badge hiện có.

2. **Object → materials edge** — content JSON mỗi vật thêm `materials: [materialId]` (mảng id, optional). Quan hệ **many-to-many** tạo ra "mạng lưới vật liệu".

3. **Material network** = đồ thị bipartite `object ↔ material`, suy ra runtime: "các vật khác cùng vật liệu này", "vật liệu chung của 2 vật".

**Unlock thẻ vật liệu = suy ra từ `discoveredIds`** (giống `badges()` hiện tại) — **không thêm Hive field**, không migration. Thẻ mới mở = diff giống `newBadge`.

## Reasons

- **Offline-first, không backend** — đúng triết lý ADR-002/ADR-005.
- **Backward compatible** — giữ `material_badge` (string) + `hero_catalog.material` cho badge cũ; thêm `materials[]` mới song song. Vật thiếu `materials[]` vẫn chạy.
- **Một nguồn sự thật cho nhiều feature** — C1/C2/D6/D8 đều đọc chung graph này.
- **Không dependency mới** — chỉ là JSON + Dart model + tính toán graph in-memory.

## Consequences

- Phải soạn `materials.json` (~6–8 thẻ) + gắn `materials[]` cho 8 hero object. Nội dung kid-safe, kiểm chứng khoa học (giống yêu cầu hero content ADR-002).
- `hero_catalog.dart` giữ `material` đơn (badge thô) **hoặc** derive từ `materials[].category` — chọn derive để tránh trùng nguồn sự thật (xem TASK-017 — nền material graph).
- Graph tính runtime → cần helper `material_catalog.dart` (load + index + truy vấn shared materials). Business logic **không** đặt trong widget (AGENTS.md).
- Thẻ "Cát→Thuỷ tinh" có thể chưa có hero nào dùng → hiện trạng "chưa khám phá", khuyến khích mở rộng bộ hero (gắn với roadmap v2 mở rộng vật).
- Khi sửa schema → cập nhật `specs/api-contracts.md` + `specs/materials.md` ngay (AGENTS.md).

## Alternatives rejected

- **Giữ 1 material string/vật**: đơn giản nhưng không biểu diễn được "nhiều vật liệu" và "nguồn gốc" → chặn C2/D8.
- **Backend graph DB**: thừa cho dữ liệu tĩnh, phá vỡ non-goal "no backend".
- **Sinh material bằng AI live**: không kiểm chứng được, dính blocker kid-safe F-08; thẻ sưu tầm cần dữ liệu ổn định.
