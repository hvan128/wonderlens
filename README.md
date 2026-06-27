# WonderLens 🔍✨

App khám phá khoa học cho trẻ 6–10: **chụp một đồ vật → hiện hành trình tạo ra nó** (Origin Timeline có lồng tiếng) + game sưu tầm huy hiệu.

Chủ đề demo: **đồ vật văn phòng** (cốc giấy, bút bi, kẹp giấy…). Engine **hybrid curated-first**: vật "anh hùng" có nội dung đóng gói sẵn (offline); vật lạ gọi OpenAI Vision + TTS qua Vercel proxy.

## Cấu trúc

```
hackathon_codex/
├─ app/      # Flutter app (iOS/Android)
├─ proxy/    # Vercel serverless — giấu OpenAI key (recognize, generate)
└─ plans/    # Kế hoạch + brainstorm report
```

## Chạy app (dev)

```bash
cd app
flutter pub get
flutter run                     # dùng mock offline (chụp luôn ra "Cốc giấy")
# Khi đã deploy proxy:
flutter run --dart-define=PROXY_BASE_URL=https://<your-proxy>.vercel.app
```

> Phase 1: `RecognitionService` mặc định trả **mock** khi `PROXY_BASE_URL` rỗng hoặc lỗi mạng → app/demo không bao giờ vỡ.

## Chạy proxy (dev)

```bash
cd proxy
npm install
cp .env.example .env            # điền OPENAI_API_KEY (KHÔNG commit .env)
npm run dev                     # vercel dev → http://localhost:3000
```

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

1. Set `OPENAI_API_KEY` trong Vercel env (KHÔNG để trong app).
2. **Đổi `APP_SHARED_SECRET`** khỏi giá trị mẫu `dev-wonderlens` (giá trị mẫu nằm sẵn trong repo) và truyền vào app bằng `--dart-define=APP_TOKEN=<giá trị mới>`.
3. **Đặt spend limit** ở dashboard OpenAI — đây là lớp phòng vệ thật sự cho app gọi client-side.
4. Nếu demo bằng Flutter Web: proxy hiện chưa xử lý CORS/preflight → cần bổ sung trước.
