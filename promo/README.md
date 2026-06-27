# WonderLens — Promo 15s (Remotion)

Clip animation ~15s giới thiệu nhanh WonderLens, **dựng 100% bằng code** (React + Remotion → MP4).
Kịch bản: bé thông minh cầm điện thoại (giao diện *lens*) → quét & chụp **cốc giấy** → lao vào màn hình → app kể **hành trình tạo ra cốc giấy** (cây → bột giấy → tấm giấy → cốc) + huy hiệu → chốt logo.

## Chạy

```bash
npm install
npm run dev      # mở Remotion Studio (xem/tua trực tiếp)
npm run render   # xuất out/wonderlens-15s.mp4 (1080x1920, 30fps, 450f)
```

> Output mặc định: `out/wonderlens-15s.mp4`. Render lần đầu tự tải Chrome Headless Shell.

## Cấu trúc

```
src/
  Root.tsx              # đăng ký Composition (1080x1920, 30fps, 450f)
  WonderLensPromo.tsx   # ghép 5 cảnh bằng <Sequence>
  theme.ts              # brand tokens (teal #26C6DA, nền giấy #FFFDF7) + WIDTH/HEIGHT
  fonts.ts              # Baloo 2 + Nunito (subset 'vietnamese')
  content.ts            # 4 chặng cốc giấy (port từ app/assets/content/paper_cup.json)
  scenes/   BoyWorld · TimelineScene · LogoScene
  components/ Boy · Phone · LensOverlay · StageCard · Badge · Confetti · Icons · BackgroundPaper
scripts/render-stills.mjs   # bundle 1 lần, render nhiều still để kiểm tra nhanh
```

Mọi biểu tượng (cốc, cây, nồi bột giấy, tấm giấy, huy hiệu, logo) đều **vẽ bằng SVG** — không dùng emoji glyph để render headless luôn ổn định và hiển thị đủ dấu tiếng Việt.

## Tuỳ chỉnh nhanh

- **Đổi khung hình** sang ngang 16:9 hay vuông 1:1: sửa `WIDTH`/`HEIGHT` trong `src/theme.ts` rồi căn lại vài toạ độ trong các scene.
- **Đổi thời lượng**: sửa `DURATION_IN_FRAMES` trong `theme.ts` và mốc `from/durationInFrames` trong `WonderLensPromo.tsx`.
- **Đổi vật/nội dung**: sửa `content.ts` (lấy từ các file `app/assets/content/*.json`).
- **Thêm nhạc/lồng tiếng**: đặt file vào `public/` và thêm `<Audio src={staticFile('...')}/>` vào scene tương ứng.
- **Kiểm tra nhanh 1 cảnh**: `node scripts/render-stills.mjs 40,165,300,430` → ảnh PNG trong `out/`.
