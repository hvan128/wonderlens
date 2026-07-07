# Plan — Hệ thống Haptic cho WonderLens

> Trạng thái: **DRAFT (chờ duyệt)** · Ngày: 2026-07-07 · Branch đề xuất: `feature/haptic-system`

## Mục tiêu

Gom mọi phản hồi rung đang rải rác về **một lớp trung tâm `WonderHaptics`** với tên
ngữ nghĩa (selection / tick / primary / success / warning / error), refactor các call
hiện có về lớp đó, rồi **bổ sung haptic ở các chỗ còn thiếu** (lỗi/cảnh báo, swipe
onboarding). Thêm **1 package** cho haptic notification kiểu iOS (success/warning/error)
— bắt buộc qua **ADR-011** trước khi thêm.

## Quyết định đã chốt (từ người dùng)

| Câu hỏi | Chốt |
|---|---|
| Phạm vi | Gom lớp trung tâm + lấp trống (KHÔNG tinh chỉnh iOS ở tầng UX riêng) |
| Toggle người dùng | **Không** — chỉ theo OS. `app_settings` giữ nguyên, không thêm cờ |
| Dependency | **Có** — thêm package + viết ADR-011 |

## Nguyên tắc

- **Không gate theo Reduce Motion.** Haptic là phản hồi *phi thị giác*; OS đã tự quản
  "System Haptics". Giữ nhất quán với quyết định hiện có ở `timeline_screen` (vẫn rung
  khi Reduce Motion). Document rõ trong `WonderHaptics`.
- **Degrade an toàn.** Package chỉ dùng cho 3 loại notification (success/warning/error);
  selection/tick/primary vẫn dùng `HapticFeedback` built-in (chạy mọi nơi, không cần plugin).
  Nếu package chưa init / không hỗ trợ → fallback impact built-in, bọc `try/catch`.
- **YAGNI/KISS/DRY.** Không thêm toggle, không thêm intensity, không refactor widget ngoài
  phạm vi. `wonder_chip` không bấm được → **không** thêm haptic.

## Phases

| # | Tên | File | Phụ thuộc |
|---|---|---|---|
| 01 | Lớp trung tâm `WonderHaptics` + refactor call hiện có | `phase-01-central-layer.md` | — |
| 02 | ADR-011 + thêm dependency + wiring notification haptics | `phase-02-adr-dependency.md` | 01 |
| 03 | Lấp trống coverage (lỗi/cảnh báo/onboarding) + verify | `phase-03-coverage-verify.md` | 01, 02 |

> Có thể làm 01 độc lập trước; 02 và 03 gộp được nếu muốn 1 PR. Đề xuất **1 PR** vì
> phạm vi nhỏ, nhưng ADR-011 phải merge (hoặc accepted) trước khi thêm package.

## Acceptance Criteria

- [ ] `WonderHaptics` là nguồn duy nhất; **không còn** `HapticFeedback.*` trực tiếp trong
      `app/lib/**` ngoài file `wonder_haptics.dart`.
- [ ] 6 loại ngữ nghĩa hoạt động: `selection / tick / primary / success / warning / error`.
- [ ] ADR-011 tồn tại (Accepted) mô tả package + lý do + fallback + phạm vi nền tảng.
- [ ] Bổ sung haptic tại: lỗi camera permission, lỗi chụp, `journey_video` `_Phase.error`,
      lỗi share; và `success()` khi share xong; swipe đổi trang onboarding.
- [ ] `flutter analyze` sạch · `flutter test` pass · build iOS/Android pass.
- [ ] Không thêm toggle; reduce-motion không tắt haptic (ghi chú trong code).

## Definition of Done (theo CLAUDE.md)

Code đúng spec/AC · `flutter test` pass · build pass · ADR-011 + `specs`/docs cập nhật nếu
đụng contract (haptic là UX nội bộ → **không** đổi api-contracts) · tuân AGENTS.md (dep có ADR)
· PR reviewed & merged.

## Rủi ro / Ghi chú

- Package có platform channel → trong `flutter test` có thể `MissingPluginException`.
  Mitigation: `WonderHaptics` chỉ gọi package khi cờ `_canVibrate == true` (đặt sau
  `WonderHaptics.init()` lúc khởi động app). Test không init → không chạm package.
- iOS dùng SPM (xem memory `wonderlens-ios-spm-pods`) — chọn package hỗ trợ SPM hoặc
  CocoaPods tương thích; kiểm tra khi thêm.
- Nếu sau này muốn toggle: lớp trung tâm đã có sẵn 1 điểm gate → chi phí thấp.
