# TASK-024 — Landing page giới thiệu WonderLens

**Owner:** Dev
**Status:** In Review — iteration 3 complete
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

- [x] Hero và điều hướng ưu tiên ba câu hỏi: lịch sử, cách làm ra, guardrails.
- [x] Có section lịch sử riêng, dùng đúng content curated của cốc giấy; không
      bịa năm, nhân vật hoặc claim môi trường.
- [x] Dây chuyền bốn bước khớp `paper_cup.json` và có phần kết “sau khi dùng”
      không tuyên bố mọi cốc giấy đều tái chế được.
- [x] Guardrails xuất hiện sớm, nói rõ adult co-use, AI-live có thể sai, ảnh đi
      qua proxy và runtime kid-safety audit chưa hoàn tất.
- [x] Không thêm dependency, Client Component, API, form, analytics, cookie hoặc
      release/safety claim.
- [x] Focused test, full test, lint, build và browser 375/768/1440 pass.
- [x] Production redeploy READY, smoke pass và PR hiện có được cập nhật.

## Iteration 3 — copy an tâm cho phụ huynh

Iteration này thay cách trình bày public của guardrails; trạng thái safety audit
nội bộ vẫn được theo dõi trong PRD và release docs.

- [x] Điều hướng và section dùng ngôn ngữ `An tâm khám phá`, không dùng
      `Rào chắn` hoặc trạng thái kỹ thuật làm thông điệp chính.
- [x] Copy nói rõ các lớp kiểm tra an toàn, nội dung phù hợp lứa tuổi, adult
      co-use và nhãn khi AI tham gia bằng tiếng Việt thân thiện.
- [x] Public copy không hiện `runtime`, `kid-safety audit`, `safety pass`,
      `prompt`, `moderation`, `proxy`, `tracking`, `cookie`, `analytics` hoặc
      `AI-live`.
- [x] Không tạo claim chứng nhận an toàn: vẫn nói AI có thể nhầm, không thay
      giáo viên/sách đã kiểm chứng và ảnh được gửi tới dịch vụ AI để nhận diện.
- [x] Giữ `#rao-chan`, cấu trúc semantic, Server Component, CSS/token và không
      thêm dependency/API/form/runtime data.
- [x] Focused/full test, lint, build và browser 375/768/1440 pass.
- [x] Production redeploy READY, smoke pass và PR #9 được cập nhật.

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

- `npm test`: 3 test file, 6/6 test pass.
- `npm run lint`: pass.
- `npm run build`: static route `/`, `/_not-found`, icon và Open Graph image.
- Flutter regression: 92/92 test pass; landing iteration không sửa Flutter app.
- Task 1 review: Spec Compliance PASS, Task Quality PASS; không có finding
  Critical, Important hoặc Minor. Final branch review từ merge base đến
  `ac0a70c` cũng không có finding Critical, Important hoặc Minor.
- Browser production local tại 375×812, 768×1024 và 1440×1000: không tràn
  ngang; 26/26 ảnh tải sau lazy-load sweep; copy phụ huynh bắt buộc hiển thị;
  jargon bị cấm không xuất hiện trong `#rao-chan`; năm anchor còn lại đều có;
  `An tâm khám phá` một dòng tại tablet/desktop, liên kết `#rao-chan`; mobile
  giữ header gọn và trust section theo sau hero; không có browser warning/error.

### Production

- Project: `sireals-projects/wonderlens-landing`, Next.js, Node.js 24.x.
- Deployment `dpl_FVWbzWH4jhKfvTJkBEgs5STT4K5u`: `READY`, production.
- Source `ac0a70c7b6a578d85a4cb1f1f0d9d291a493b2d4` khớp metadata
  `gitCommitSha` của deployment.
- URL: <https://wonderlens-landing.vercel.app>
- Immutable URL:
  <https://wonderlens-landing-oala6pc5x-sireals-projects.vercel.app>
- HTTP: `/` trả 200; đường dẫn không tồn tại trả branded 404; ảnh brand,
  journey, object và screen cốt lõi trả 200.
- Metadata/H1 tiếng Việt đúng nội dung đã duyệt.
- Browser smoke production pass tại 375×812, 768×1024 và 1440×1000: không tràn
  ngang, 26/26 ảnh tải được, copy bắt buộc hiển thị, jargon bị cấm không xuất
  hiện trong `#rao-chan`, anchor hoạt động và không có console/page error.
- `An tâm khám phá` liên kết `#rao-chan`; các anchor giữ lại đều resolve.
- Remote build hoàn tất trong 11 giây; runtime error clusters, error/fatal và
  5xx scan không có entry.
- PR #9 vẫn OPEN, base `main`, head `feature/TASK-024-landing-page`; headRefOid
  khớp `ac0a70c` sau push. Sau commit evidence này sẽ redeploy final source và
  ghi deployment ID/SHA cuối vào PR #9 để tránh tài liệu tự tham chiếu.
