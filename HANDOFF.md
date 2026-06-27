# HANDOFF — WonderLens

> Đọc file này đầu tiên khi mở Claude session mới tại `/Users/haivan/Documents/wonderlens`.
> Cập nhật: 2026-06-27.

## 1. Dự án là gì
App cho trẻ 6–10: **chụp một đồ vật văn phòng → app kể "hành trình tạo ra nó"** (Origin Timeline có giọng đọc) + game sưu tầm huy hiệu. Mục tiêu hackathon: khoảnh khắc wow + demo không vỡ.

Repo: https://github.com/hvan128/wonderlens (branch `main`). Đã tách hẳn khỏi `vocaberry_be`.

## 2. Trạng thái hiện tại
- **Code: 6/6 phase HOÀN TẤT**, đã push. Xem `ck plan status plans/2026-06-27-wonderlens/plan.md`.
- **Proxy: ĐANG LIVE** tại **https://wonderlens-proxy.vercel.app** (đã test end-to-end: chụp ảnh → OpenAI Vision → JSON ✅).
- **App: đã cài (release) trên iPhone** "Hai Van's iPhone" (`00008120-0014450C0E58201E`) NHƯNG là **bản cũ dùng mock** → chụp gì cũng ra "Cốc giấy".
- `flutter analyze` sạch · 5 test pass · proxy `tsc` sạch.

## 3. ⚠️ VIỆC CẦN LÀM TIẾP (ưu tiên P0)
**Build lại app trỏ vào proxy live** → nhận diện thật + AI-live hoạt động:
```bash
cd /Users/haivan/Documents/wonderlens/app
SECRET=$(grep '^APP_SHARED_SECRET=' ../proxy/.env | cut -d= -f2-)
flutter run --release -d 00008120-0014450C0E58201E \
  --dart-define=PROXY_BASE_URL=https://wonderlens-proxy.vercel.app \
  --dart-define=APP_TOKEN=$SECRET
# (flutter devices để xem id thiết bị nếu khác)
```
Sau đó: chụp vật văn phòng thật → ra đúng tên; chụp vật lạ → AI-live sinh hành trình.

Tiếp theo (P1): **red-team kid-safety** output AI-live (chụp ~20 vật, kể cả vật nhạy cảm) trước khi tin trên sân khấu.

## 4. Bí mật & hạ tầng (QUAN TRỌNG)
- **`proxy/.env`** (local, đã gitignore — KHÔNG commit) chứa `OPENAI_API_KEY` + `APP_SHARED_SECRET`.
- **Vercel** project `wonderlens-proxy` (scope `vannh120802-4480`) đã set 2 biến này cho Production + Preview + Development. `vercel env ls` để xem.
- **OpenAI key TUYỆT ĐỐI không để trong `app/`** (app không đọc `.env`; key chỉ ở proxy). `app/.env` đã bị xoá.
- Trước khi mở public rộng: **đặt spend limit OpenAI** + đổi `APP_SHARED_SECRET` (giá trị mẫu `dev-wonderlens` đã có trong repo lịch sử, đừng dùng lại).
- **Video (Sora) ĐẮT**: `/api/video/create` ~**$0.80/clip** (sora-2 8s 720p, ≈80× recognize/generate), **không rate limit** trong code. Proxy ĐÃ live → **đặt hard spend limit OpenAI NGAY** (không chờ "public rộng"); cân nhắc thêm rate-limit qua Vercel WAF cho `/api/video/create`. Theo dõi `vercel logs` của create để bắt lạm dụng. Đã có moderation server-side (omni-moderation) chặn input không phù hợp trước khi tốn tiền tạo video.

## 5. Cấu trúc
```
app/    Flutter (iOS/Android). lib/: screens, services, data, models, widgets, theme
        assets/content/*.json = 8 "vật hero" (nội dung kid-safe, offline)
        assets/videos/*.mp4   = video hành trình hero (do pregen sinh, có thể trống)
proxy/  Vercel serverless TS. api/recognize.ts (nhận diện) + api/generate.ts (AI-live)
        + api/video/{create,status,content}.ts (text-to-video Sora: async tạo→poll→stream)
        lib/: openai-vision, openai-generate, hero-objects, kid-safe-prompt, openai-video, video-prompt
        scripts/pregen-hero-videos.mjs (tạo sẵn video hero → app/assets/videos/; `npm run pregen:videos`)
plans/2026-06-27-wonderlens/  brainstorm-report.md + plan.md + phase-01..06
docs/   demo-script.md (kịch bản 90s) + journal/
```

## 6. Chạy & test
```bash
# App (offline, mock — không cần proxy):
cd app && flutter run
# App trỏ proxy thật: xem mục 3.
# Test app:           cd app && flutter test && flutter analyze
# Proxy local:        cd proxy && npm install && cp .env.example .env (điền key) && npm run dev
# Proxy type-check:   cd proxy && npx tsc --noEmit
# Proxy deploy:       cd proxy && vercel deploy --prod --yes
# Proxy logs:         cd proxy && vercel logs https://wonderlens-proxy.vercel.app
```

## 7. Quyết định & điều chỉnh (đừng đảo ngược nếu không có lý do mới)
- **Hybrid curated-first**: 8 vật hero đóng gói sẵn chạy offline (demo không phụ thuộc wifi); vật lạ mới gọi AI-live.
- **Giọng đọc: `flutter_tts` on-device** (không phải OpenAI TTS) → offline, không cần key. Trường `Stage.audio` để dành nâng cấp audio pre-gen.
- **AI-live KHÔNG tính vào bộ sưu tập** (chỉ `heroCatalog` mới tính) — tránh phồng số liệu + tách nội dung chưa kiểm chứng.
- **`RecognitionService` fallback mock** khi `PROXY_BASE_URL` rỗng/lỗi → demo không vỡ (đây là chủ ý).
- **Tranh minh hoạ = emoji** (chưa làm asset thật); `Stage.illustration` đã sẵn để gắn ảnh sau.
- **Proxy phải là ESM**: `package.json` có `"type":"module"` + import tương đối phải có đuôi `.js` (Vercel transpile .ts giữ ESM, không bundle lib). Đừng gỡ đuôi `.js`.
- **Chia sẻ = ảnh thẻ + caption, fallback text** (offline, không backend): màn Hành trình (chia sẻ 1 khám phá) và màn Bộ sưu tập (khoe cấp độ + tiến độ + huy hiệu) đều có nút "Chia sẻ" → mở bảng xem trước thẻ (`widgets/share_card.dart`: `ShareCard` + `CollectionShareCard`, chung khung `_WonderCardShell`) → chụp PNG (`services/share_service.dart`) → khay chia sẻ hệ thống (`share_plus`). Chụp ảnh lỗi thì tự gửi text → demo không vỡ. Nút "khoe bộ sưu tập" chỉ hiện khi đã khám phá ≥1 vật. Đã thêm `NSPhotoLibraryAddUsageDescription` (iOS) cho mục "Lưu ảnh".
- **Video hành trình = text-to-video (Sora)**: TimelineScreen có khối "Phim hành trình 🎬" (`widgets/journey_video.dart`). Vật hero → phát video asset đóng gói sẵn (offline, tức thì); vật lạ AI-live → nút tạo on-demand qua `services/video_service.dart` → `/api/video/*` (create→poll→tải file tạm→phát). Dùng **text-to-video, KHÔNG ảnh chụp** (Sora từ chối mặt người + dễ kiểm soát an toàn). An toàn: moderation server-side + strip emoji khỏi prompt + rào chắn "no scary/dark/sharp…". Mặc định **sora-2 / 8s / 720p** (đổi qua env `VIDEO_MODEL|VIDEO_SIZE|VIDEO_SECONDS`). Video hero KHÔNG có sẵn trong repo — chạy `cd proxy && npm run pregen:videos` (tốn ~$0.80/vật) để sinh + đóng gói; chưa chạy thì hero rớt về tạo on-demand như vật lạ.

## 8. Gotchas đã gặp
- **Vercel URL theo-deploy** (dạng `...-xxxx-...vercel.app`) bị **SSO chặn (302)**. Dùng **alias production** `https://wonderlens-proxy.vercel.app` (public).
- **iOS debug** mất kết nối khi khoá máy → dùng **`--release`** để app chạy độc lập.
- **cwd shell hay trôi** sau lệnh `cd`/move → luôn `cd` đường dẫn tuyệt đối trước khi chạy `flutter`/`git`.
- `flutter_tts` cảnh báo "không hỗ trợ SPM" — **vô hại** (iOS dùng CocoaPods).
- `confidence` do LLM tự khai → nhánh "Có phải …?" (ngưỡng 0.6) có thể hiếm khi kích hoạt; test với vật mơ hồ.

## 9. Cách tiếp tục trong Claude
Mở `claude` tại thư mục này. Đọc `HANDOFF.md` (file này) + `plans/2026-06-27-wonderlens/plan.md`. Đây là session MỚI — không có lịch sử chat cũ, mọi context cần thiết nằm trong repo + file này.
