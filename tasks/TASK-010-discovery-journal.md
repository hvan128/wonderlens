# TASK-010: Nhật ký khám phá (lưu vật AI-live)

**Owner:** Dev
**Status:** Code Done — `flutter test` 23/23 pass; analyze sạch trong scope TASK-010
(12 lỗi analyze còn lại thuộc widget WIP của TASK-011, luồng song song)
**Branch:** feature/TASK-008-object-cutout
**Ref:** [plan.md](../plans/2026-07-02-discovery-journal/plan.md)

## Goal

Bộ sưu tập hiện chỉ nhận 8 vật hero cố định — vật lạ bé chụp (AI-live) biến mất
sau phiên. Thêm khu **"Khám phá thêm (AI)"**: mọi vật AI-live được lưu bền
(ảnh cutout thật + tên + ngày + nội dung hành trình) và mở lại được offline.

Giữ nguyên trục gamification hero (level + huy hiệu chỉ tính 8 vật hero) để
tôn trọng ràng buộc kid-safety: nội dung AI chưa red-team không được tính vào
tiến độ/huy hiệu chính, luôn gắn nhãn "Khám phá vui (AI)".

## Acceptance Criteria

- [ ] Mở timeline vật AI-live → vật được ghi vào nhật ký (Hive, bền qua restart)
- [ ] Collection screen hiện section "Khám phá thêm (AI)" với ảnh cutout thật + tên
- [ ] Bấm một mục nhật ký → mở lại timeline từ nội dung đã lưu (không gọi lại proxy)
- [ ] Vật AI-live mới → confetti (như hero), nhưng KHÔNG mở huy hiệu, KHÔNG tính level
- [ ] Dedup theo `id`: khám phá lại cùng vật → không tạo entry mới
- [ ] Hero flow không đổi hành vi (lưới 8 ô, badge, level như cũ)
- [ ] Không có journal entry → collection screen y hệt trước (không section rỗng)

## DoD

- `flutter analyze` sạch, `flutter test` pass (test mới cho journal)
- `specs/features.md`, `specs/domains.md`, `specs/api-contracts.md` cập nhật khớp
- Không dependency mới
