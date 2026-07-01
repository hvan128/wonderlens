# TASK-016: Huy hiệu động từ vật AI-live (hybrid)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-016-dynamic-ai-badges (stack trên feature/TASK-015)
**Ref ADR:** [ADR-011](../adrs/ADR-011-ai-live-collectible-badges.md)

## Bối cảnh

Hiện tại huy hiệu hoàn toàn **định sẵn**: 4 vật liệu lõi (`Giấy/Nhựa/Kim loại/Gỗ`) +
8 hero object hard-code trong `hero_catalog.dart`. `CollectionRepository.record()` chỉ
tính hero (`heroById(id)==null → bỏ`). Vật AI-live **không** vào bộ sưu tập, **không**
mở huy hiệu (theo `specs/domains.md` cũ + PRD: nội dung AI chưa red-team).

Owner chọn **hướng A (hybrid)**: cho vật AI-live mở huy hiệu **động** theo `material_badge`
mà proxy AI **đã** trả về, **gắn nhãn "vui (AI)"**, giữ nguyên 4 huy hiệu lõi đã kiểm chứng.

## Goal

Chụp một vật **lạ** (AI-live) → app lưu nó vào một **track khám phá AI** riêng và **mở
huy hiệu vật liệu động** (vd "Thuỷ tinh 🥃"), gắn nhãn "vui (AI)" — **không** cần setup
trước, **không** phá lõi verified, **không** vỡ offline/kid-safe contract.

## Phạm vi

IN:
- `CollectionRepository`: lưu vật AI-live `{id,name,emoji,material}` (Hive, tách khỏi
  `discovered` hero); chuẩn hoá tên vật liệu; trả huy hiệu AI động.
- `record()` nhận `ObjectContent` (thay vì chỉ `id`) để phân nhánh hero vs AI.
- `collection_screen`: section "Khám phá thêm (AI)" cho vật + huy hiệu AI, gắn nhãn rõ.
- Màu/emoji fallback cho vật liệu ngoài 4 lõi.
- ADR-011 + cập nhật `specs/domains.md` + ghi chú PRD.

OUT:
- Không đổi cấp độ (level vẫn theo 8 hero verified — AI là bonus).
- Không sinh ảnh/lưu cutout cho vật AI (giữ TASK-015: vật AI hiện emoji).
- Không red-team kid-safe runtime (vẫn là F-08 backlog) — chỉ gắn nhãn + chính sách.

## Acceptance Criteria

- [ ] Chụp vật lạ (Live API) → vật xuất hiện ở section "Khám phá thêm (AI)" của Bộ sưu tập.
- [ ] Vật liệu AI mới (vd "Thuỷ tinh") → mở 1 huy hiệu AI động, có nhãn "vui (AI)".
- [ ] 4 huy hiệu lõi + 8 hero + cấp độ **không đổi hành vi**.
- [ ] Tên vật liệu chuẩn hoá ("nhựa"/"Chất dẻo" → "Nhựa"); vật liệu lạ vẫn hiển thị gọn.
- [ ] Vật liệu ngoài 4 lõi có màu/emoji fallback hợp lý (không vỡ UI).
- [ ] Bền qua restart (Hive). Offline: không có vật AI thì section ẩn, không crash.
- [ ] `flutter analyze` sạch · `flutter test` pass (thêm test cho record AI + normalize).

## DoD

- [ ] Code đúng phạm vi + AC; ADR-011 + `specs/domains.md` cập nhật.
- [ ] `flutter analyze` sạch · `flutter test` pass · build pass.
- [ ] PR reviewed & merged (stack sau TASK-015).
