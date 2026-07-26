# TASK-024 — Landing page giới thiệu WonderLens

**Owner:** Dev
**Status:** In Progress — iteration 2
**Branch:** `feature/TASK-024-landing-page`

## Goal

Tạo landing page Next.js trong `landing-page/`, giới thiệu WonderLens cho phụ
huynh và giáo viên bằng hình ảnh sản phẩm thật, giữ nhận diện WonderLens nhưng có
bố cục marketing tối giản, giàu khoảng thở theo tinh thần Apple. Trang phải có
design token, component dùng chung, responsive, truy cập được, build độc lập và
được deploy production trên Vercel.

## Acceptance Criteria

- [x] `landing-page/` là ứng dụng Next.js App Router + TypeScript độc lập.
- [x] Design token tập trung cho màu, typography, spacing, radius, shadow, motion
      và z-index; component không tự phát minh token trùng lặp.
- [x] Header, button/link, section heading, product/device frame và footer là
      component dùng chung.
- [x] Route `/` kể rõ flow chụp vật → nhận diện/tách nền → hành trình STEM →
      bộ sưu tập, bằng copy tiếng Việt hướng phụ huynh đồng hành cùng trẻ 6–10.
- [x] Trang dùng nhiều asset thật có sẵn: logo, object cutout, ảnh chặng và
      screenshot production; không dùng emoji hoặc stock photo làm visual vật.
- [x] Không có form waitlist, analytics, testimonial, rating hoặc release claim
      chưa có bằng chứng.
- [x] Copy trust nói đúng trạng thái: không tài khoản trẻ/quảng cáo/tracking;
      AI-live có nhãn; không tuyên bố ảnh không bao giờ rời thiết bị.
- [x] Mobile 375px, tablet và desktop không tràn ngang; CTA/touch target tối
      thiểu 44px; focus rõ; ảnh có alt; hỗ trợ `prefers-reduced-motion`.
- [x] Test component/page, lint và `next build` pass.
- [x] Production deployment Vercel ở trạng thái READY; route `/` trả 200 và
      browser smoke test không có lỗi console nghiêm trọng.

## Iteration 2 — lịch sử, cách làm ra và guardrails

- [ ] Hero và điều hướng ưu tiên ba câu hỏi: lịch sử, cách làm ra, guardrails.
- [ ] Có section lịch sử riêng, dùng đúng content curated của cốc giấy; không
      bịa năm, nhân vật hoặc claim môi trường.
- [ ] Dây chuyền bốn bước khớp `paper_cup.json` và có phần kết “sau khi dùng”
      không tuyên bố mọi cốc giấy đều tái chế được.
- [ ] Guardrails xuất hiện sớm, nói rõ adult co-use, AI-live có thể sai, ảnh đi
      qua proxy và runtime kid-safety audit chưa hoàn tất.
- [ ] Không thêm dependency, Client Component, API, form, analytics, cookie hoặc
      release/safety claim.
- [ ] Focused test, full test, lint, build và browser 375/768/1440 pass.
- [ ] Production redeploy READY, smoke pass và PR hiện có được cập nhật.

## Out of scope

- Thu email, waitlist backend, CRM hoặc analytics.
- Store install link chưa được release owner xác nhận.
- Gọi proxy/OpenAI từ landing page.
- Thay đổi Flutter app, proxy API hoặc schema local.
- Tự tuyên bố safety audit, beta public, rating hoặc số người dùng.

## Definition of Done

- [x] Code đúng AC và ADR-016.
- [x] Test, lint, build và visual/browser checks có evidence.
- [x] Docs setup/deploy và URL production được cập nhật.
- [x] Không secret, `.env*` hoặc Vercel credential trong diff.
- [ ] PR reviewed trước merge; không push thẳng `main`.

## Verification — 2026-07-26

### Local

- `npm test`: 3 test file, 4/4 test pass.
- `npm run lint`: pass.
- `npm run build`: static route `/`, `/_not-found`, icon và Open Graph image.

### Production

- Project: `sireals-projects/wonderlens-landing`, Next.js, Node.js 24.x.
- Deployment `dpl_8Vvnqh3W1Ax6jTFwyVoWoXxX8Q85`: `READY`, production.
- Source `3ec01e98748630c1f4ba63f959c9ebc4325b77d3` khớp metadata
  `gitCommitSha` của deployment.
- URL: <https://wonderlens-landing.vercel.app>
- Immutable URL:
  <https://wonderlens-landing-nfu6v0qtv-sireals-projects.vercel.app>
- HTTP: `/` trả 200; đường dẫn không tồn tại trả branded 404; ảnh brand,
  journey, object và screen cốt lõi trả 200.
- Metadata/H1 tiếng Việt đúng nội dung đã duyệt.
- Browser smoke pass tại 375×812, 768×1024 và 1440×1000: không tràn ngang,
  24/24 ảnh tải được, anchor hoạt động, không console/page error; reduced motion
  không còn animation/transition dài.
- Final-source redeploy được smoke lại ở desktop 1440×1000: không tràn ngang,
  24/24 ảnh tải được, named sections và H1 đúng, không console/page error.
- Remote build hoàn tất trong 12 giây, không có lỗi; runtime error/fatal và 5xx
  scan không có entry.
