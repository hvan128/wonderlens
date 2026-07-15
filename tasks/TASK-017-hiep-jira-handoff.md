# TASK-017: Hoàn thiện backlog Jira của Hoàng Hiệp

**Owner:** Hoàng Hiệp  
**Status:** Repo Ready — external gates pending  
**Branch:** `feature/TASK-017-hiep-jira-handoff`  
**Jira:** KAN-4, KAN-5, KAN-6, KAN-31, KAN-32, KAN-34, KAN-35,
KAN-36, KAN-37, KAN-38, KAN-39, KAN-40, KAN-41

## Goal

Chuyển toàn bộ task Jira đang giao cho Hoàng Hiệp thành bộ tài liệu có thể dùng
ngay trong repo; triển khai những phần phù hợp với hiện trạng sản phẩm và ghi rõ
phần nào còn cần quyền truy cập, phê duyệt hoặc hạ tầng bên ngoài.

## Acceptance Criteria

- [x] Có bảng đối chiếu đủ 13 Jira task và deliverable tương ứng.
- [x] Sprint scope, beta metrics, product flow và handoff phản ánh đúng code/spec.
- [x] Privacy, age rating, store metadata dùng nguồn chính thức hiện hành và
      không ghi nhận định pháp lý như một kết luận đã được luật sư duyệt.
- [x] Growth strategy, lịch 30 ngày, build-in-public, press kit và Product Hunt
      draft có copy dùng được, owner/checkpoint rõ.
- [x] Waitlist có copy, schema, consent, tracking và phương án triển khai; không
      tự thu thập PII khi chưa có owner lưu trữ và phê duyệt privacy.
- [x] Mọi link nội bộ và asset path được kiểm tra tồn tại.
- [x] Không sửa hoặc commit thay đổi có sẵn của người dùng trong
      `docs/workflow.md`.

## Definition of Done

- [x] Tất cả tài liệu deliverable mới nằm dưới `docs/`.
- [x] Markdown/diagram được kiểm tra cú pháp và link nội bộ.
- [x] `flutter test`, `flutter analyze` và Android release build pass trên HEAD
      cuối.
- [ ] iOS release build: bị chặn bởi Xcode 26.6 SDK `23F81a` trong khi Apple
      catalog chưa cung cấp runtime iOS 26.5.1 khớp.
- [x] Báo cáo phân biệt rõ: hoàn tất trong repo, cần PM/legal review, và bị chặn
      bởi external state.

## Verification

- Ngày: 2026-07-15.
- Chi tiết: [Hoàng Hiệp — Jira delivery index](../docs/hiep-jira-delivery.md).
- Commits:
  - `d099cb0` — thiết kế bàn giao backlog.
  - `b80fbbd` — kế hoạch triển khai.
  - `fb7e74b` — nhãn AI, tests và screenshot core flow.
  - `2385f5e` — product/growth/release handoff + verification record.
