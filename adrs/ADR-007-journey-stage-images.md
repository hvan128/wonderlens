# ADR-007: Ảnh minh hoạ "đồng nhất bối cảnh" cho từng chặng hành trình

**Status:** Accepted
**Date:** 2026-06-27

## Context

Timeline "hành trình tạo ra vật" mới chỉ có chữ + audio + phim. Muốn thêm ảnh
minh hoạ cho **từng chặng** để trẻ dễ hình dung. Yêu cầu cốt lõi: các ảnh của
cùng một vật phải **đồng nhất bối cảnh** (cùng phong cách, bảng màu, nền) — như
một bộ truyện tranh — thay vì 4 ảnh lệch tông.

Hai trục quyết định: (1) sinh/phân phối thế nào, (2) làm sao giữ đồng nhất khi
mỗi chặng là một lần sinh ảnh riêng.

## Decision

- **Provider:** OpenAI Images `gpt-image-1` qua proxy (nối tiếp ADR-003/ADR-004,
  không gọi thẳng từ app). Đổi model/size/quality qua env.
- **Đồng nhất bối cảnh = "world bible" chung:** mỗi chặng sinh 1 ảnh riêng nhưng
  dùng chung một tiền tố mô tả style + bối cảnh nền + bảng màu + bố cục
  (`lib/image-prompt.ts`), chỉ "scene beat" đổi theo chặng. Sinh **song song**.
- **Phân phối kép theo nguồn nội dung:**
  - Hero objects: pre-gen 1 lần bằng `scripts/pregen-hero-images.mjs` → bundle
    `assets/images/{id}_stage{n}.png`, điền `stages[].illustration`. Offline, $0
    lúc demo (đúng nguyên tắc offline-first cho hero).
  - Vật AI-live: sinh runtime qua `POST /api/journey-images` rồi cache file local
    theo `objectId`.

## Reasons

- World bible đạt đồng nhất phong cách đủ tốt mà vẫn **song song** (nhanh, rẻ),
  tránh phụ thuộc khả năng chia ô đều của model (cách "1 ảnh ghép 4 ô") hoặc độ
  trễ tuần tự của cách "reference ảnh chặng trước".
- Tái dùng đúng pattern đã có của phim hành trình (style guidance tiếng Anh + bỏ
  emoji + moderation gate), giữ codebase đồng bộ.
- Tách hero/live giữ hero chạy offline-first, chỉ vật lạ mới tốn phí runtime.

## Consequences

- gpt-image-1 cần OpenAI org đã verify; nếu chưa, đặt `IMAGE_MODEL=dall-e-3`.
- Ảnh chặng là **optional** ở mọi tầng: thiếu/lỗi → tile không-ảnh, không crash.
- Prompt logic bị lặp ở `lib/image-prompt.ts` và script pre-gen — phải giữ đồng
  bộ (script ghi chú rõ điều này).
- Response trả base64 (vài MB/vật) — chấp nhận cho scale demo, app cache để khỏi
  gọi lại.
