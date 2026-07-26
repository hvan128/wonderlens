# WonderLens landing page

Trang marketing tĩnh dành cho phụ huynh và giáo viên muốn tìm hiểu WonderLens
cùng trẻ 6–10 tuổi. App dùng Next.js App Router, TypeScript, CSS Modules, asset
thật của sản phẩm và font local Baloo 2/Nunito.

## Chạy local

Yêu cầu Node.js 20.9 trở lên.

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

## Ranh giới

- Không API route hoặc runtime fetch.
- Không OpenAI call, secret, cookie, analytics hay form thu PII.
- Không link store cho tới khi release owner duyệt.
- Asset marketing nằm trong `public/images/`; nguồn gốc được giữ ở
  `app/assets/` và `app/store-assets/`.

Vercel phải deploy với Root Directory là `landing-page/`. Production URL được
ghi vào task sau khi deployment ở trạng thái `READY`.
