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
- Immutable deployment:
  <https://wonderlens-landing-nfu6v0qtv-sireals-projects.vercel.app>
- Deployment ID: `dpl_8Vvnqh3W1Ax6jTFwyVoWoXxX8Q85` (`READY`, production,
  2026-07-26).
- Source: `3ec01e98748630c1f4ba63f959c9ebc4325b77d3`, khớp metadata
  `gitCommitSha` của deployment.
- Vercel project: `sireals-projects/wonderlens-landing`; Root Directory `.` là
  thư mục `landing-page/` của repo, framework Next.js và Node.js 24.x.

Deploy từ thư mục này:

```bash
vercel link --yes --scope sireals-projects --project wonderlens-landing
vercel deploy --prod --yes --scope sireals-projects
```

Evidence ngày 2026-07-26: 4/4 test, lint và build pass; `/` trả 200, trang 404
có nhận diện WonderLens trả đúng 404, các ảnh cốt lõi trả 200. Browser smoke ở
375×812, 768×1024 và 1440×1000 không tràn ngang, 24/24 ảnh tải được, anchor hoạt
động, reduced motion pass và không có console/page error. Build log, runtime
error/fatal và 5xx scan đều sạch.

Final-source redeploy ngày 2026-07-26 giữ nguyên kết quả trên; smoke lại live
desktop 1440×1000 có 24/24 ảnh tải được, không tràn ngang, không console/page
error. `/`, branded 404 và ảnh screenshot cốt lõi lần lượt trả 200, 404 và 200;
remote build hoàn tất trong 12 giây, không có build/runtime error mới.

## Ranh giới

- Không API route hoặc runtime fetch.
- Không OpenAI call, secret, cookie, analytics hay form thu PII.
- Không link store cho tới khi release owner duyệt.
- Asset marketing nằm trong `public/images/`; nguồn gốc được giữ ở
  `app/assets/` và `app/store-assets/`.

Vercel deploy app này như project riêng, với thư mục `landing-page/` làm project
root.
