# ADR-006: Typography — Fredoka + Nunito qua google_fonts

**Status:** Accepted  
**Date:** 2026-06-27

## Context

Bảng thiết kế v2 (`wonderlens-mockup.html`) chốt hệ chữ thương hiệu:
**Fredoka** cho tiêu đề (display) — bo tròn, vui, thân thiện với trẻ — và
**Nunito** cho nội dung (body) — dễ đọc, hỗ trợ tiếng Việt tốt.

App đang dùng font hệ thống (Roboto/SF) nên lệch tinh thần thiết kế. Cần đưa hai
font này vào app. Có 3 hướng:

1. Bundle file `.ttf` trong `assets/fonts/` + khai báo `fonts:` trong pubspec.
2. Thêm package `google_fonts` (tải runtime, cache vào hệ thống file).
3. Giữ font hệ thống.

`AGENTS.md` yêu cầu: **không thêm dependency mới mà không có ADR** → đây là ADR đó.

## Decision

Thêm dependency **`google_fonts`** và dùng nó để nạp **Fredoka** (display) +
**Nunito** (body). Toàn bộ text style đi qua `theme/wonder_typography.dart` để
giữ một nguồn sự thật.

## Reasons

- Không phải commit file font nhị phân vào repo; tránh phình git.
- `google_fonts` cache font đã tải vào thư mục app → các lần sau chạy offline bình
  thường; chỉ lần chạy **đầu tiên** cần mạng để tải.
- Đúng hai họ chữ trong mockup, không phải chữ "gần giống".
- Tập trung qua `wonder_typography.dart` nên đổi font về sau chỉ sửa một chỗ.

## Consequences

- Lần chạy đầu tiên (chưa cache) cần mạng để tải font; nếu offline, `google_fonts`
  tự rơi về font hệ thống (không crash) — chấp nhận được, demo không vỡ.
- Nếu cần **offline tuyệt đối ngay từ lần đầu** (vd thiết bị sân khấu chưa mở mạng
  lần nào), nâng cấp sau bằng cách bundle `.ttf` qua `GoogleFonts.config` hoặc khai
  báo `fonts:` — không đảo ngược quyết định, chỉ là tối ưu phân phối.
- Thêm 1 dependency (`google_fonts`) vào `app/pubspec.yaml`.
