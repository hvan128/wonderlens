# WonderLens — Promo 15s (Remotion)

Clip animation ~15s giới thiệu nhanh WonderLens, **dựng 100% bằng code** (React + Remotion → MP4).
Kịch bản: bé thông minh cầm điện thoại (giao diện _lens_) → quét & chụp **cốc giấy** → lao vào màn hình → app kể **hành trình tạo ra cốc giấy** (cây → bột giấy → tấm giấy → cốc) + huy hiệu → chốt logo.

## Chạy

```bash
npm install
npm run dev      # mở Remotion Studio (xem/tua trực tiếp)
npm run render   # xuất out/wonderlens-15s.mp4 (1080x1920, 30fps, 450f)
```

## Promo kể chuyện 61 giây

Composition `WonderLensStoryPromo` dựng luồng khám phá cốc giấy trong 61 giây,
gồm bốn chương storytelling chi tiết, khung dọc **1080x1920**, **30fps** và
tập trung hoàn toàn vào hành trình của đồ vật. Chạy từ thư mục `promo` theo thứ tự:

```bash
npm run render:story:final  # render hình, tạo lồng tiếng + nhạc, ghép master

# Hoặc chạy riêng từng bước:
npm run render:story        # render bản hình không tiếng
npm run audio:story         # tạo lồng tiếng + nhạc và ghép bản hoàn chỉnh
```

- Video hoàn chỉnh: `promo/out/wonderlens-story-promo.mp4`
- Poster: `promo/out/wonderlens-story-promo-poster.jpg`
- Bước audio dùng Eco88Labs **Tuyết Trâm** (voice ID `151688`, speed `0.9`)
  qua `MEDIA_API_BASE` và cần `ffmpeg` trong `PATH`. Script dừng nếu dịch vụ
  trả về giọng fallback hoặc một câu thoại chồng sang chặng kế tiếp.

```bash
# GSAP landing thử nghiệm
npm i -D playwright   # nếu chưa có cho script render landing
node scripts/render-gsap-landing.mjs --dry-run   # kiểm tra trước khi render
npm run render:gsap-landing                    # xuất out/wonderlens-gsap-landing.mp4
```

> `gsap-landing.html` nằm ở `promo/gsap-landing.html`, dùng CDN `GSAP` để chạy landing animation 100% web.
> Chạy từ thư mục `promo`:
>
> ```bash
> python3 -m http.server 4173
> ```
>
> rồi mở `http://localhost:4173/` để xem preview (hoặc `http://localhost:4173/promo/index.html` nếu bạn đang serve từ root).

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
gsap-landing.html           # landing page experiment dùng GSAP
scripts/render-gsap-landing.mjs  # render file HTML GSAP này thành MP4 (ffmpeg + playwright)
```

Mọi biểu tượng (cốc, cây, nồi bột giấy, tấm giấy, huy hiệu, logo) đều **vẽ bằng SVG** — không dùng emoji glyph để render headless luôn ổn định và hiển thị đủ dấu tiếng Việt.

## Tuỳ chỉnh nhanh

- **Đổi khung hình** sang ngang 16:9 hay vuông 1:1: sửa `WIDTH`/`HEIGHT` trong `src/theme.ts` rồi căn lại vài toạ độ trong các scene.
- **Đổi thời lượng**: sửa `DURATION_IN_FRAMES` trong `theme.ts` và mốc `from/durationInFrames` trong `WonderLensPromo.tsx`.
- **Đổi vật/nội dung**: sửa `content.ts` (lấy từ các file `app/assets/content/*.json`).
- **Thêm nhạc/lồng tiếng**: đặt file vào `public/` và thêm `<Audio src={staticFile('...')}/>` vào scene tương ứng.
- **Kiểm tra nhanh 1 cảnh**: `node scripts/render-stills.mjs 40,165,300,430` → ảnh PNG trong `out/`.
