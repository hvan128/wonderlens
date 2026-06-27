---
phase: 2
title: Recognition Pipeline
status: completed
priority: P1
dependencies:
  - 1
effort: D1-D2
---

# Phase 2: Recognition Pipeline

## Overview
Đường xương sống nhận diện: ảnh → Vercel proxy → OpenAI Vision → `{object_id, confidence}` → map về bộ vật hero → load nội dung. Chạy end-to-end với 2 vật hero (cốc giấy + bút bi).

## Requirements
- Functional: chụp → proxy gọi OpenAI Vision (gpt-4o) phân loại ảnh vào 1 trong N `object_id` hero (hoặc `unknown`); app khớp hero → load nội dung bundled; confidence thấp → UX "Có phải [X]? / Chọn lại".
- Non-functional: thời gian phản hồi proxy hợp lý; key an toàn; nội dung hero đọc offline từ asset bundle.

## Architecture
- Proxy `recognize.ts`: nhận `{image_base64}`; gọi OpenAI Vision với prompt ép chọn trong danh sách `object_id` hero + trả JSON `{object_id, confidence, display_name}`. Cache theo hash ảnh (tùy chọn).
- App: `RecognitionService` (gọi proxy) → `ContentRepository` (đọc JSON hero từ assets) → trả `ObjectContent`.
- Bộ vật hero (8): paper_a4, ball_pen, paper_cup, plastic_bottle, paper_clip, pencil, sticky_note, battery_aa.

## Related Code Files
- Create: `app/lib/services/recognition_service.dart`, `app/lib/data/content_repository.dart`, `app/lib/models/object_content.dart`
- Create: `app/assets/content/{paper_cup,ball_pen}.json` (2 vật trước, đủ end-to-end)
- Modify: `proxy/api/recognize.ts` (mock → OpenAI Vision thật), `app/pubspec.yaml` (khai báo assets)
- Modify: `app/lib/screens/camera_screen.dart` (gọi service + điều hướng sang timeline)

## Implementation Steps
1. Định nghĩa `ObjectContent` model + schema JSON (id, name, emoji, material_badge, stages[]).
2. Viết prompt Vision: "phân loại ảnh vào đúng 1 id trong danh sách; không chắc → unknown + confidence".
3. `recognize.ts`: gọi OpenAI Vision, parse JSON, trả `{object_id, confidence, display_name}`.
4. `RecognitionService` + `ContentRepository` đọc asset JSON theo id.
5. Camera → chụp → recognize → nếu hero & confidence cao → sang Timeline; thấp → bottom-sheet xác nhận/chọn lại.
6. Test với ảnh thật của cốc giấy + bút bi.

## Success Criteria
- [ ] Chụp cốc giấy/bút bi → nhận đúng id → điều hướng Timeline với nội dung tương ứng.
- [ ] Ảnh mơ hồ → hiện xác nhận "Có phải …?" + nút chọn lại.
- [ ] Nội dung hero đọc được khi tắt mạng (asset bundled).

## Risk Assessment
- Vision phân loại sai → ép schema + danh sách đóng + ngưỡng confidence + UX chọn lại.
- Chi phí/độ trễ Vision → ảnh resize trước khi gửi; cache theo hash; demo dùng hero (không gọi mỗi lần nếu đã có).

## Carry-over từ review Phase 1 (phải xử lý ở phase này)
- **Proxy auth (M3):** endpoint `recognize`/`generate` đang mở. Trước khi nối OpenAI thật → thêm shared-secret header (app gửi token) + rate limit, tránh bị lạm dụng đốt quota.
- **Giới hạn payload (L5):** ảnh base64 có thể vượt giới hạn body ~4.5MB của Vercel serverless → resize/nén ảnh phía app trước khi gửi; validate size phía proxy.
- **Dây nối recognition→content (L1):** map `RecognitionResult` → `ObjectContent` và truyền qua `context.push('/timeline', extra: content)` (router + TimelineScreen đã sẵn sàng nhận `extra`).
- **Fallback nuốt lỗi (N1):** `RecognitionService` hiện rơi về mock cho mọi lỗi → khi tích hợp proxy thật, phân biệt fallback-do-baseUrl-rỗng vs fallback-do-lỗi (log/cờ) để debug.
