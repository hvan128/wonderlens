---
title: WonderLens — App khám phá khoa học cho trẻ (chụp vật → hành trình tạo ra nó)
description: >-
  Flutter app + OpenAI Vision/TTS + Vercel proxy. Hybrid curated-first, chủ đề
  vật văn phòng, demo offline-first, tối ưu wow-factor cho hackathon.
status: completed
priority: P2
branch: main
tags:
  - hackathon
  - flutter
  - openai
  - kids
  - science
blockedBy: []
blocks: []
created: '2026-06-27T03:19:22.216Z'
createdBy: 'ck:plan'
source: skill
---

# WonderLens — App khám phá khoa học cho trẻ (chụp vật → hành trình tạo ra nó)

## Overview

App di động (Flutter) cho trẻ 6–10: chụp một đồ vật văn phòng → hiện **Origin Timeline** có **lồng tiếng** kể hành trình tạo ra vật đó, kèm **game sưu tầm + huy hiệu**. Engine **hybrid curated-first**: vật "anh hùng" có nội dung + audio đóng gói sẵn (offline, <2s); vật lạ gọi **OpenAI Vision + TTS** live qua **Vercel proxy** (giấu key). Tối ưu **wow-factor demo**, chạy được **không cần wifi** cho bộ vật hero.

Nguồn: [brainstorm-report.md](./brainstorm-report.md).

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Setup & Skeleton](./phase-01-setup-skeleton.md) | Completed |
| 2 | [Recognition Pipeline](./phase-02-recognition-pipeline.md) | Completed |
| 3 | [Timeline & Narration](./phase-03-timeline-narration.md) | Completed |
| 4 | [Collection & Badges](./phase-04-collection-badges.md) | Completed |
| 5 | [AI Live Fallback](./phase-05-ai-live-fallback.md) | Completed |
| 6 | [Polish & Demo](./phase-06-polish-demo.md) | Completed |
| 7 | [Video Journey](./phase-07-video-journey.md) | Planned |

## Dependency graph (nội bộ)

```
P1 ──► P2 ──► P3 ──► P6
        │      │      ▲
        ├──► P4 ──────┤
        ├──► P5 ──────┘
        └──► P7
```
- P2 phụ thuộc P1; P3, P4, P5 phụ thuộc P2 (P5 dùng thêm schema của P3); P6 phụ thuộc tất cả.
- P7 phụ thuộc P3 vì dùng cùng content schema/timeline và bổ sung video assets cho hero objects.
- Có thể demo được ngay sau P3 (đường xương sống wow). P4/P5/P6 là tăng cường.

## Acceptance criteria (toàn cục)
- [ ] Chụp vật hero → nhận diện đúng → timeline hiện **<5s** (offline) → giọng đọc tự chạy.
- [ ] ≥ 8 vật hero hoạt động **offline** (nội dung + audio bundled).
- [ ] Mở huy hiệu + vào bộ sưu tập sau mỗi khám phá.
- [ ] Vật lạ (có mạng) → AI live sinh hành trình kid-safe + TTS, ≥1 lần thành công.
- [ ] Vật hero → có nút "Xem cách tạo ra" → mở video 30–60s hoặc fallback poster nếu asset chưa sẵn.
- [ ] Demo 90s chạy trọn vẹn **không cần wifi** cho phần hero.

## Constraints (non-negotiable)
- Flutter (iOS/Android); OpenAI Vision (gpt-4o) + OpenAI TTS; proxy **Vercel serverless**.
- Tiếng Việt, trẻ 6–10; chủ đề **vật văn phòng**; **không** backend Java.
- Không gọi OpenAI thẳng từ app (key phải nằm sau proxy).

## Dependencies (môi trường)
- Flutter SDK (chưa cài máy local — cài ở P1), OpenAI API key, tài khoản Vercel + Vercel CLI.
- Bộ tranh minh hoạ + nội dung khoa học kiểm chứng cho 8 vật (chuẩn bị ở P3).

## Open questions (không chặn)
- Giọng TTS tiếng Việt phù hợp trẻ (OpenAI TTS voice + ngôn ngữ) — chốt ở P3.
- Animation: Rive vs Lottie — chốt ở P3/P6.
- Local store: Hive vs Drift — chốt ở P4 (mặc định Hive).
