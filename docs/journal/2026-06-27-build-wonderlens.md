# Journal — Dựng WonderLens (2026-06-27)

## Bối cảnh
Ý tưởng hackathon: app khơi gợi hứng thú khoa học cho trẻ — chụp một đồ vật → hiện hành trình tạo ra nó. Từ brainstorm → plan 6 phase → build trọn vẹn trong một phiên.

## Đã làm (6/6 phase)
- **P1 Setup:** Flutter app shell (go_router, riverpod), camera, Vercel proxy mock, quyền iOS/Android.
- **P2 Recognition:** proxy gọi OpenAI Vision (gpt-4o, structured output strict) ép phân loại vào bộ 8 "vật văn phòng hero"; app map id → nội dung asset; auth shared-secret + giới hạn size.
- **P3 Timeline & Narration:** Origin Timeline cuộn dọc, 8 vật hero nội dung kid-safe kiểm chứng, giọng đọc on-device.
- **P4 Collection & Badges:** bộ sưu tập + huy hiệu vật liệu + cấp độ (Hive) + confetti.
- **P5 AI Live:** vật lạ → proxy sinh hành trình kid-safe (guardrail prompt, temperature thấp); nhãn "Khám phá vui (AI)".
- **P6 Polish:** mascot pulse, haptics, hiệu ứng xuất hiện chặng, kịch bản demo 90s.

## Quyết định & điều chỉnh đáng nhớ
- **Hybrid curated-first thay vì AI thuần:** vật hero đóng gói sẵn để demo chạy offline, không phụ thuộc wifi sân khấu — đổi lấy độ tin cậy demo.
- **flutter_tts (on-device) thay OpenAI TTS pre-gen:** bám mục tiêu offline-first, bỏ khâu sinh + bundle audio, không cần key cho giọng đọc. Giữ trường `Stage.audio` làm đường nâng cấp.
- **Proxy giấu key:** OpenAI key chỉ ở server (Vercel env), không bao giờ trong app.
- **AI-live không vào bộ sưu tập:** tránh phồng số liệu + phân biệt nội dung chưa kiểm chứng với hero đã verify.

## Khó khăn & cách xử lý
- Code review (P1/P2) phát hiện loạt lỗi vòng đời camera (setState sau await thiếu `mounted`, rò controller khi unmount, thiếu xử lý background/resume, race khi init) → đã vá hết; đây là nhóm lỗi dễ làm vỡ demo live nhất.
- Build debug trên iPhone bị "Lost connection" khi khoá máy → chuyển sang build **release** để app chạy độc lập, cầm đi thử quanh văn phòng.
- Vài lần lệnh chạy nhầm thư mục (cwd shell trôi theo lệnh `cd` trước) → phải di chuyển app về đúng chỗ.

## Kiểm chứng
`flutter analyze` sạch · 5 widget/unit test pass · proxy `tsc --noEmit` sạch · build + chạy thật trên iPhone (debug + release).

## Còn lại để đi từ demo sang "thật"
- AI-live + kid-safe guardrail là prompt-based, **chưa test runtime** (cần OpenAI key + deploy proxy) → phải red-team output thật trước khi cho trẻ dùng.
- Đặt OpenAI spend limit + đổi `APP_SHARED_SECRET` khỏi giá trị mẫu trước khi deploy công khai.
- Tranh minh hoạ hiện là emoji (trường `Stage.illustration` đã sẵn).
- OpenAI key cần đặt ở `proxy/.env` (server), không phải `app/.env` (app không đọc .env).
