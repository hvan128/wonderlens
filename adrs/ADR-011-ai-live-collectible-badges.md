# ADR-011: Vật AI-live vào bộ sưu tập + huy hiệu động (gắn nhãn kid-safe)

**Status:** Accepted
**Date:** 2026-06-30
**Liên quan:** `specs/domains.md` (Domain 3), `specs/prd.md` (F-08), ADR-002, ADR-003

## Context

Huy hiệu hiện chỉ đến từ **4 vật liệu lõi** + **8 hero object định sẵn**. Vật AI-live
bị loại khỏi bộ sưu tập (`specs/domains.md`: "Chỉ hero objects được lưu"; PRD: nội dung
AI chưa red-team kid-safe). Hệ quả: **chụp vật lạ không bao giờ mở thêm huy hiệu** — bộ
sưu tập "đóng", thiếu cảm giác khám phá-vô-hạn.

Proxy AI **đã** trả `material_badge` cho mọi vật (`JOURNEY_SCHEMA`). Vậy dữ liệu để mở
huy hiệu động **đã có**; rào cản là *chính sách* (kid-safe) + *đường ống lưu/chuẩn hoá*.

## Decision

Cho vật **AI-live** vào bộ sưu tập trong một **track riêng "khám phá AI"**, mở **huy hiệu
vật liệu động** theo `material_badge` (đã chuẩn hoá), **gắn nhãn "vui (AI)"**. Giữ **4 huy
hiệu lõi + 8 hero** là track **verified** (offline, kiểm chứng) — **tách biệt** với track AI.

Cụ thể:
- Lưu vật AI `{id, name, emoji, material}` vào Hive, **tách** khỏi danh sách hero.
- Chuẩn hoá tên vật liệu về một tập canonical (đồng nghĩa → 1 tên); vật liệu lạ giữ
  nguyên (title-case).
- Huy hiệu AI hiển thị ở section riêng, **luôn có nhãn "vui (AI)"**.
- **Cấp độ** vẫn tính theo 8 hero verified (AI là bonus, không làm loãng tiến độ lõi).

## Reasons

- Mở "khám phá vô hạn" mà **không** đụng lõi verified → không hạ chuẩn kid-safe của lõi.
- Nhãn "vui (AI)" minh bạch nguồn gốc nội dung chưa kiểm chứng (đúng tinh thần PRD F-08).
- Dùng lại dữ liệu sẵn có (`material_badge`) → chi phí thấp, không thêm dependency/endpoint.
- Tách track → dễ tắt/ẩn track AI nếu audit phát hiện vấn đề.

## Consequences

- **Đảo một phần** nguyên tắc cũ "AI-live không vào bộ sưu tập" → cập nhật `specs/domains.md`
  (Domain 2/3) cho khớp: AI-live **có** vào, nhưng **track riêng + nhãn AI**.
- Schema collection (Hive) thêm khóa cho vật AI; cần migrate mềm (thiếu khóa → coi rỗng).
- Vật liệu AI đa dạng → cần màu/emoji **fallback** cho ngoài 4 lõi.
- **Vẫn cần F-08 (red-team runtime)** trước khi bỏ nhãn "vui (AI)" / cho AI vào track verified.
- Không sinh ảnh/cutout cho vật AI (giữ quyết định TASK-015: vật AI hiện emoji).
