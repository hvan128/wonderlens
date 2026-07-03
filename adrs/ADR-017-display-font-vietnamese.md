# ADR-017: Display font — Baloo 2 thay Fredoka (hỗ trợ tiếng Việt)

**Status:** Accepted
**Date:** 2026-07-02
**Supersedes:** phần chọn **Fredoka** làm display font trong [ADR-010](ADR-010-typography.md).
Phần còn lại của ADR-010 (dùng `google_fonts`, Nunito cho body, một nguồn sự thật
`theme/wonder_typography.dart`) **giữ nguyên hiệu lực**.

## Context

Test trên thiết bị thật (TASK-022) cho thấy mọi tiêu đề Fredoka có **dấu chồng**
tiếng Việt render sai: "Đố vui" → "Đõ vui", "Bậc thầy" → "Bậc thãy", "dầu mỏ" →
"dãu mỏ"…

Nguyên nhân xác minh qua metadata chính thức của Google Fonts:
- **Fredoka** coverage chỉ có `latin / latin-ext / hebrew` — **không có bảng chữ
  Việt** (thiếu toàn bộ dải precomposed U+1EA0–1EF9). Text shaper phải tự ghép
  dấu và ghép sai với các tổ hợp mũ + thanh (ố, ầ, ấ, ồ…).
- **Baloo 2** coverage có `vietnamese` đầy đủ (768-769, 771-772, 776-777, 803,
  7840-7929…).

App target trẻ em Việt 6–10 tuổi, tiếng Việt là ngôn ngữ duy nhất (AGENTS.md) —
font tiêu đề bắt buộc phải render dấu chuẩn.

## Decision

Đổi display font **Fredoka → Baloo 2** (vẫn nạp qua `google_fonts`, không thêm
dependency). Body giữ **Nunito**. Điểm sửa duy nhất: `theme/wonder_typography.dart`
(đúng thiết kế "một nguồn sự thật" của ADR-010).

## Reasons

- Baloo 2 hỗ trợ tiếng Việt đầy đủ, đã kiểm chứng qua Google Fonts metadata.
- Cùng chất bo tròn – mập – vui (rounded display) như Fredoka; hợp tinh thần
  Duolingo-style của TASK-022; Google Fonts xếp Baloo 2 vào nhóm font trẻ em/giáo dục.
- Không đổi kiến trúc: mọi call-site dùng `WonderType.display` / TextTheme nên
  chỉ sửa 1 file.

## Consequences

- Lần chạy đầu sau update cần mạng để `google_fonts` tải Baloo 2 (cache như cũ —
  hệ quả đã chấp nhận ở ADR-010; offline rơi về font hệ thống, không crash).
- Metrics Baloo 2 hơi khác Fredoka (x-height/độ rộng) — chênh lệch nhỏ, các layout
  đều co giãn; đã chạy lại analyze/test/build.
- Fredoka không còn được tham chiếu ở bất kỳ đâu trong code.
