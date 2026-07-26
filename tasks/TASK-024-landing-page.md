# TASK-024 — Landing page giới thiệu WonderLens

**Owner:** Dev
**Status:** In Progress
**Branch:** `feature/TASK-024-landing-page`

## Goal

Tạo landing page Next.js trong `landing-page/`, giới thiệu WonderLens cho phụ
huynh và giáo viên bằng hình ảnh sản phẩm thật, giữ nhận diện WonderLens nhưng có
bố cục marketing tối giản, giàu khoảng thở theo tinh thần Apple. Trang phải có
design token, component dùng chung, responsive, truy cập được, build độc lập và
được deploy production trên Vercel.

## Acceptance Criteria

- [ ] `landing-page/` là ứng dụng Next.js App Router + TypeScript độc lập.
- [ ] Design token tập trung cho màu, typography, spacing, radius, shadow, motion
      và z-index; component không tự phát minh token trùng lặp.
- [ ] Header, button/link, section heading, product/device frame và footer là
      component dùng chung.
- [ ] Route `/` kể rõ flow chụp vật → nhận diện/tách nền → hành trình STEM →
      bộ sưu tập, bằng copy tiếng Việt hướng phụ huynh đồng hành cùng trẻ 6–10.
- [ ] Trang dùng nhiều asset thật có sẵn: logo, object cutout, ảnh chặng và
      screenshot production; không dùng emoji hoặc stock photo làm visual vật.
- [ ] Không có form waitlist, analytics, testimonial, rating hoặc release claim
      chưa có bằng chứng.
- [ ] Copy trust nói đúng trạng thái: không tài khoản trẻ/quảng cáo/tracking;
      AI-live có nhãn; không tuyên bố ảnh không bao giờ rời thiết bị.
- [ ] Mobile 375px, tablet và desktop không tràn ngang; CTA/touch target tối
      thiểu 44px; focus rõ; ảnh có alt; hỗ trợ `prefers-reduced-motion`.
- [ ] Test component/page, lint và `next build` pass.
- [ ] Production deployment Vercel ở trạng thái READY; route `/` trả 200 và
      browser smoke test không có lỗi console nghiêm trọng.

## Out of scope

- Thu email, waitlist backend, CRM hoặc analytics.
- Store install link chưa được release owner xác nhận.
- Gọi proxy/OpenAI từ landing page.
- Thay đổi Flutter app, proxy API hoặc schema local.
- Tự tuyên bố safety audit, beta public, rating hoặc số người dùng.

## Definition of Done

- [ ] Code đúng AC và ADR-016.
- [ ] Test, lint, build và visual/browser checks có evidence.
- [ ] Docs setup/deploy và URL production được cập nhật.
- [ ] Không secret, `.env*` hoặc Vercel credential trong diff.
- [ ] PR reviewed trước merge; không push thẳng `main`.
