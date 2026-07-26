# WonderLens landing page

Trang marketing tĩnh dành cho phụ huynh và giáo viên muốn tìm hiểu WonderLens
cùng trẻ 6–10 tuổi. App dùng Next.js App Router, TypeScript, CSS Modules, asset
thật của sản phẩm và font local Baloo 2/Nunito.

## Chạy local

Yêu cầu Node.js 24.x (khớp môi trường local và Vercel của team).

```bash
npm install
npm run dev
```

Mở `http://localhost:3000`.

## Quality gates

```bash
npm test
npm run lint
npm run build
npm start
```

Browser check bản production ở 375×812, 768×1024 và 1440×1000; kiểm tra focus
bàn phím, reduced motion, ảnh lỗi, console và horizontal overflow.

## Production

- URL: <https://wonderlens-landing.vercel.app>
- Validation deployment immutable URL:
  <https://wonderlens-landing-oala6pc5x-sireals-projects.vercel.app>
- Validation deployment ID: `dpl_FVWbzWH4jhKfvTJkBEgs5STT4K5u` (`READY`,
  production, 2026-07-26).
- Validation source: `ac0a70c7b6a578d85a4cb1f1f0d9d291a493b2d4`, khớp metadata
  `gitCommitSha` của deployment.
- Vercel project: `sireals-projects/wonderlens-landing`; Root Directory `.` là
  thư mục `landing-page/` của repo, framework Next.js và Node.js 24.x.

Deploy từ thư mục này:

```bash
vercel link --yes --scope sireals-projects --project wonderlens-landing
vercel deploy --prod --yes --scope sireals-projects
```

Evidence ngày 2026-07-26: Task 1 review đạt Spec Compliance PASS và Task Quality
PASS; final branch review từ merge base đến `ac0a70c` không có finding Critical,
Important hoặc Minor. Local `npm test` (3 file, 6/6 test), lint, build và Flutter
regression (92/92 test) đều pass; build tạo static `/`, `/_not-found`, icon và
Open Graph image.

Browser production local và production ở 375×812, 768×1024 và 1440×1000 không
tràn ngang; 26/26 ảnh tải sau lazy-load sweep; copy phụ huynh yêu cầu hiển thị;
jargon bị cấm không xuất hiện trong `#rao-chan`; năm anchor còn lại đều resolve;
`An tâm khám phá` liên kết `#rao-chan`; không có browser warning/error. `/` trả
200, branded missing route trả 404 và asset core trả 200. Remote build hoàn tất
trong 11 giây; runtime error clusters, error/fatal logs và 5xx logs không có
entry.

PR #9 vẫn OPEN, base `main`, head `feature/TASK-024-landing-page`; headRefOid
khớp `ac0a70c` sau push. Sau mỗi evidence commit, deployment ID/SHA final-source
và evidence smoke cuối được ghi trên PR #9, tránh tài liệu tự tham chiếu.

## Ranh giới

- Không API route hoặc runtime fetch.
- Không OpenAI call, secret, cookie, analytics hay form thu PII.
- Không link store cho tới khi release owner duyệt.
- Asset marketing nằm trong `public/images/`; nguồn gốc được giữ ở
  `app/assets/` và `app/store-assets/`.

Vercel deploy app này như project riêng, với thư mục `landing-page/` làm project
root.
