# TASK-017: Hoàn thiện backlog Jira của Hoàng Hiệp

**Owner:** Hoàng Hiệp  
**Status:** In Progress  
**Branch:** `feature/TASK-017-hiep-jira-handoff`  
**Jira:** KAN-4, KAN-5, KAN-6, KAN-31, KAN-32, KAN-34, KAN-35,
KAN-36, KAN-37, KAN-38, KAN-39, KAN-40, KAN-41

## Goal

Chuyển toàn bộ task Jira đang giao cho Hoàng Hiệp thành bộ tài liệu có thể dùng
ngay trong repo; triển khai những phần phù hợp với hiện trạng sản phẩm và ghi rõ
phần nào còn cần quyền truy cập, phê duyệt hoặc hạ tầng bên ngoài.

## Acceptance Criteria

- [ ] Có bảng đối chiếu đủ 13 Jira task và deliverable tương ứng.
- [ ] Sprint scope, beta metrics, product flow và handoff phản ánh đúng code/spec.
- [ ] Privacy, age rating, store metadata dùng nguồn chính thức hiện hành và
      không ghi nhận định pháp lý như một kết luận đã được luật sư duyệt.
- [ ] Growth strategy, lịch 30 ngày, build-in-public, press kit và Product Hunt
      draft có copy dùng được, owner/checkpoint rõ.
- [ ] Waitlist có copy, schema, consent, tracking và phương án triển khai; không
      tự thu thập PII khi chưa có owner lưu trữ và phê duyệt privacy.
- [ ] Mọi link nội bộ và asset path được kiểm tra tồn tại.
- [ ] Không sửa hoặc commit thay đổi có sẵn của người dùng trong
      `docs/workflow.md`.

## Definition of Done

- [ ] Tất cả tài liệu mới nằm dưới `docs/`.
- [ ] Markdown/diagram được kiểm tra cú pháp và link nội bộ.
- [ ] `flutter test`, `flutter analyze` và build phù hợp pass trên HEAD cuối.
- [ ] Báo cáo phân biệt rõ: hoàn tất trong repo, cần PM/legal review, và bị chặn
      bởi external state.

