# ADR-011: Lớp haptic tập trung `WonderHaptics` + package `haptic_feedback`

**Status:** Accepted
**Date:** 2026-07-07
**Ref:** yêu cầu owner "thêm haptic cho app" (phiên 2026-07-07); plan `plans/260707-0901-haptic-system/`

## Bối cảnh

1. Haptic đang gọi `HapticFeedback.*` (Flutter built-in) rải rác ≥7 file
   (`pressable`, `scan_ring_button`, `glass_panel`, `glass_sheet`, `camera_screen`,
   `timeline_screen`, `discovery_reveal_screen`) — đặt tên theo *cường độ*
   (`selectionClick/lightImpact/mediumImpact/heavyImpact`), không theo ngữ nghĩa;
   khó đổi cảm giác đồng loạt, khó test/mock, không có một điểm gate.
2. `HapticFeedback` built-in **thiếu notification haptic** kiểu iOS
   (Success / Warning / Error). Phần thưởng "vật mới" và các trạng thái lỗi chỉ
   rung được impact thô → cảm giác kém phân biệt.

## Quyết định

1. **Gom về một lớp `app/lib/ui/wonder_haptics.dart`** với API tĩnh, ngữ nghĩa:
   `selection / tick / primary / success / warning / error`. Mọi call-site trỏ vào
   đây; **không còn** `HapticFeedback.*` trực tiếp ngoài file này (kiểm bằng grep).
2. **Thêm dependency `haptic_feedback: ^0.6.4+3`** (cross-platform iOS + Android)
   cho 3 loại notification `success/warning/error` qua `Haptics.vibrate(HapticsType)`.
   - `selection/tick/primary` **giữ built-in** `HapticFeedback` (chạy mọi nơi,
     không phụ thuộc plugin).
   - `WonderHaptics.init()` gọi `Haptics.canVibrate()` một lần lúc khởi động
     (`main`); cờ `_rich` mặc định `false` tới khi init → **test không chạm plugin**
     (tránh `MissingPluginException`). Không hỗ trợ / lỗi → **rớt về impact built-in**.
   - `Haptics.vibrate` fire-and-forget, nuốt lỗi async → rung không bao giờ chặn UI.
3. **Không gate theo Reduce Motion.** Haptic phi thị giác; iOS đã có mục "System
   Haptics" riêng ở cấp OS. Giữ nhất quán với quyết định sẵn có ở `timeline_screen`
   (vẫn rung khi Reduce Motion).
4. **Không thêm công tắc bật/tắt trong app** (theo chốt của owner) — chỉ theo OS.
   `app_settings` giữ nguyên. Nếu sau này cần: lớp trung tâm đã có sẵn một điểm gate.

## Phương án đã cân nhắc

- **`gaimon`** — chỉ iOS (Taptic Engine), Android no-op → mất success/warning/error
  trên Android. Loại.
- **`vibration` / `flutter_vibrate`** — điều khiển thời lượng thô, không có
  notification semantic chuẩn. Loại.
- **Chỉ built-in, tự "chế" notification bằng chuỗi impact** — cảm giác giả, không
  khớp Taptic Engine iOS. Loại.
- **`haptic_feedback` (chọn)** — cross-platform, enum `HapticsType`
  (success/warning/error/light/medium/heavy/rigid/soft/selection), có
  `canVibrate()`; no-op an toàn khi platform không hỗ trợ.

## Hệ quả

- ✅ Một nguồn duy nhất: đổi cảm giác/nâng cấp về sau chỉ sửa `wonder_haptics.dart`.
- ✅ Reward + lỗi có notification haptic đúng chất iOS; Android dùng vibration
  primitive mô phỏng pattern iOS (mặc định package, `useAndroidHapticConstants=false`).
- ✅ `haptic_feedback` **hỗ trợ Swift Package Manager** (không nằm trong cảnh báo
  SPM của `flutter pub get`; chỉ `flutter_tts` chưa hỗ trợ) → khớp iOS SPM của repo.
- ⚠️ +1 dependency. Demo offline không ảnh hưởng (rung là API thiết bị, không cần mạng).
- ⚠️ Cần build thật iOS + Android xác nhận pod/SPM + minSdk resolve; simulator không
  có Taptic Engine nên phải cảm nhận trên thiết bị thật.
