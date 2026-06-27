---
phase: 1
title: Setup & Skeleton
status: completed
priority: P1
dependencies: []
effort: D1
---

# Phase 1: Setup & Skeleton

## Overview
Dựng nền: Flutter app shell + điều hướng + Vercel proxy scaffold + cấu hình secret. Hết phase này app chạy được, có màn camera trống và proxy trả lời "ping".

## Requirements
- Functional: app mở được trên iOS/Android sim; có 3 màn (Camera, Timeline placeholder, Collection placeholder) + onboarding mascot tối giản; proxy `/api/recognize` trả mock JSON.
- Non-functional: API key chỉ nằm ở Vercel env (không hardcode trong app); cấu trúc thư mục rõ ràng.

## Architecture
- App: Flutter, state đơn giản (Riverpod hoặc provider), router (go_router).
- Proxy: Vercel serverless (TypeScript) trong `proxy/` — 1 endpoint nhận ảnh base64, sau này gọi OpenAI; giai đoạn này trả mock.

## Related Code Files
- Create: `app/` (flutter create), `app/lib/main.dart`, `app/lib/router.dart`, `app/lib/screens/{camera,timeline,collection}_screen.dart`, `app/lib/theme/` (màu trẻ em, font bo tròn)
- Create: `proxy/api/recognize.ts`, `proxy/package.json`, `proxy/vercel.json`, `proxy/.env.example`
- Create: `app/pubspec.yaml` deps: `camera`, `go_router`, `http`, `flutter_riverpod`, `hive`+`hive_flutter`, `just_audio`/`audioplayers`, `lottie` hoặc `rive`, `confetti`, `permission_handler`

## Implementation Steps
1. Cài Flutter SDK (chưa có máy local) + verify `flutter doctor`.
2. `flutter create app` trong `hackathon_codex/`; thêm deps vào `pubspec.yaml`.
3. Dựng router + 3 màn placeholder + theme trẻ em + onboarding mascot 1 màn.
4. Màn Camera: xin quyền + preview + nút chụp (chưa gọi API).
5. Scaffold Vercel proxy: `recognize.ts` trả mock `{object_id, confidence, source:"mock"}`; `.env.example` có `OPENAI_API_KEY`.
6. App gọi proxy (mock) khi bấm chụp → log kết quả.

## Success Criteria
- [ ] `flutter run` chạy app, chuyển được giữa 3 màn.
- [ ] Bấm chụp → app gọi proxy mock → nhận JSON → hiển thị tạm trên màn.
- [ ] Không có key nào hardcode trong app.

## Risk Assessment
- Flutter chưa cài → cài + `flutter doctor` ngay đầu; nếu kẹt môi trường, ưu tiên 1 nền tảng (Android emulator).
- Quyền camera bị từ chối → xử lý permission_handler + thông báo thân thiện.
