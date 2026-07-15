# WonderLens 🔍✨

App khám phá khoa học cho trẻ 6–10: **chụp một đồ vật → hiện hành trình tạo ra nó** (Origin Timeline có lồng tiếng) + game sưu tầm huy hiệu.

Chủ đề demo: **đồ vật văn phòng** (cốc giấy, bút bi, kẹp giấy…). Engine **hybrid curated-first**: vật "anh hùng" có nội dung đóng gói sẵn (offline); vật lạ gọi OpenAI Vision/generate qua Vercel proxy. Narration hiện dùng TTS mặc định của hệ điều hành; OpenAI speech proxy vẫn giữ sau công tắc code.

## Cấu trúc

```
hackathon_codex/
├─ app/      # Flutter app (iOS/Android)
├─ proxy/    # Vercel serverless — giấu OpenAI key (recognize, generate, video)
└─ plans/    # Kế hoạch + brainstorm report
```

## Chạy app (dev)

```bash
cd app
flutter pub get
flutter run                     # Mock offline: chụp lần lượt ra 8 vật hero (xoay tua)
# Khi đã deploy proxy:
flutter run \
  --dart-define=PROXY_BASE_URL=https://<your-proxy>.vercel.app \
  --dart-define=APP_TOKEN=<APP_SHARED_SECRET>
```

> Mock offline chỉ dùng cho demo/dev. Luồng camera thật gọi `/api/generate`; nếu proxy/token/mạng lỗi thì app báo lỗi thân thiện, **không** tự rớt về vật hero giả.
>
> Đổi **Mock ↔ API thật ngay trong app** (không cần build lại) bằng **Dev panel ẩn**: **nhấn giữ** logo "WonderLens" (màn chào) hoặc nhãn "CHẾ ĐỘ KHÁM PHÁ" (màn camera). Panel cho bật/tắt API thật + nhập Proxy URL/token (lưu Hive).

## Chạy proxy (dev)

```bash
cd proxy
npm install
cp .env.example .env            # điền OPENAI_API_KEY (KHÔNG commit .env)
npm run dev                     # vercel dev → http://localhost:3000
```

## Secret production với Infisical

Production dùng Infisical project `shared-platform-secrets`, environment
`prod`, path `/wonderlens/android-proxy`. Path này có hai key:
`OPENAI_API_KEY` và `APP_SHARED_SECRET`. Không paste giá trị vào repo hoặc chat.

Alias `wonderlens-android-proxy.vercel.app` hiện dùng tạm cho development. AAB
không được upload Google Play khi thiếu `app/android/key.properties`.

Build Android bằng secret injection, không cần tạo file `.env`:

```bash
infisical run --env=prod --path=/wonderlens/android-proxy \
  --project-config-dir=. -- bash -ceu 'cd app && ./scripts/build-appbundle.sh'
```

Xem runbook deploy: [docs/release/android-proxy-deploy.md](docs/release/android-proxy-deploy.md).

## Trạng thái

| Phase | Nội dung | Trạng thái |
|---|---|---|
| 1 | Setup & Skeleton (camera + proxy mock + điều hướng) | ✅ Done |
| 2 | Recognition Pipeline (OpenAI Vision + nội dung hero) | ✅ Done |
| 3 | Timeline & Narration (8 vật + giọng đọc offline) | ✅ Done |
| 4 | Collection & Badges (Hive + confetti + cấp độ) | ✅ Done |
| 5 | AI Live Fallback (vật lạ → OpenAI sinh + kid-safe) | ✅ Done |
| 6 | Polish & Demo (haptics, animation, kịch bản) | ✅ Done |

Chi tiết: [plans/2026-06-27-wonderlens/plan.md](plans/2026-06-27-wonderlens/plan.md) · Kịch bản demo: [docs/demo-script.md](docs/demo-script.md).

## ⚠️ Trước khi deploy proxy công khai

1. Lưu `OPENAI_API_KEY` và `APP_SHARED_SECRET` trong Infisical production path;
   sync chúng vào Vercel Production trước khi deploy.
2. Truyền `APP_SHARED_SECRET` vào Android qua build script/`--dart-define`;
   không bao giờ đưa `OPENAI_API_KEY` vào app.
3. **Đặt spend limit** ở dashboard OpenAI — lớp phòng vệ chi phí THẬT SỰ cho app gọi client-side. **Bắt buộc NGAY khi proxy live**: `/api/video/create` (Sora text-to-video) tốn ~$0.80/clip và không có rate limit trong code.
4. Nếu demo bằng Flutter Web: proxy hiện chưa xử lý CORS/preflight → cần bổ sung trước.

## Video hành trình (text-to-video, Sora) — tuỳ chọn

TimelineScreen có khối "Phim hành trình 🎬". Vật lạ tạo on-demand qua proxy; vật hero phát video đóng gói sẵn nếu đã sinh:

```bash
cd proxy && npm run pregen:videos          # tạo sẵn 8 video hero (~$0.80/vật) → app/assets/videos/
flutter pub get && flutter run ...          # build lại để đóng gói video
```

Mặc định `sora-2` / 8s / 720p, đổi qua env `VIDEO_MODEL|VIDEO_SIZE|VIDEO_SECONDS`. An toàn: text-to-video (không dùng ảnh), moderation server-side + rào chắn prompt kid-safe.
