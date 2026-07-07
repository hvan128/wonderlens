# Phase 01 — Lớp trung tâm `WonderHaptics` + refactor call hiện có

## Context

Haptic đang gọi `HapticFeedback.*` trực tiếp ở ≥6 file, không tên ngữ nghĩa, khó test/mở
rộng. Phase này tạo 1 lớp `WonderHaptics` và trỏ mọi call hiện có vào đó. **Chưa** thêm
package (dùng built-in trước; phase 02 nâng success/warning/error).

## Tạo mới

- `app/lib/ui/wonder_haptics.dart` — API tĩnh, phi thị giác, không gate reduce-motion.

### Vocabulary → mapping (giai đoạn này dùng built-in)

| Ngữ nghĩa | Dùng khi | Built-in (phase 01) | Nâng ở phase 02 |
|---|---|---|---|
| `selection()` | tap nút/thẻ, đóng sheet, đổi toggle | `selectionClick()` | giữ nguyên |
| `tick()` | chạm mép/ranh giới tinh tế | `lightImpact()` | giữ nguyên |
| `primary()` | hành động chính (scan, chụp) | `mediumImpact()` | giữ nguyên |
| `success()` | phần thưởng (vật mới), share xong | `heavyImpact()` | iOS notificationSuccess |
| `warning()` | xác nhận/nhắc quyền | `mediumImpact()` | iOS notificationWarning |
| `error()` | thất bại (permission/chụp/share/video) | `heavyImpact()` | iOS notificationError |

Skeleton:

```dart
import 'package:flutter/services.dart';

/// Phản hồi rung tập trung cho toàn app. Phi thị giác → **không** gate theo
/// Reduce Motion (OS đã quản "System Haptics"); nhất quán với timeline reward.
/// Phase 02 sẽ nâng success/warning/error lên notification haptic của iOS.
class WonderHaptics {
  const WonderHaptics._();

  static void selection() => HapticFeedback.selectionClick();
  static void tick() => HapticFeedback.lightImpact();
  static void primary() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void warning() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.heavyImpact();
}
```

## Refactor (trỏ call cũ vào WonderHaptics)

| File:line | Hiện tại | Đổi thành |
|---|---|---|
| `ui/pressable.dart:78` | `selectionClick()` | `WonderHaptics.selection()` |
| `ui/scan_ring_button.dart:110` | `mediumImpact()` | `WonderHaptics.primary()` |
| `ui/glass_panel.dart:364` | `lightImpact()` (clamp mép) | `WonderHaptics.tick()` |
| `ui/glass_panel.dart:374` | `selectionClick()` (settle) | `WonderHaptics.selection()` |
| `ui/glass_sheet.dart:132` | `selectionClick()` | `WonderHaptics.selection()` |
| `screens/camera_screen.dart:182` | `selectionClick()` | `WonderHaptics.selection()` |
| `screens/camera_screen.dart:249` | `selectionClick()` | `WonderHaptics.selection()` |
| `screens/camera_screen.dart:273` | `mediumImpact()` (chụp) | `WonderHaptics.primary()` |
| `screens/camera_screen.dart:283` | `lightImpact()` | `WonderHaptics.tick()` |
| `screens/camera_screen.dart:314` | `selectionClick()` | `WonderHaptics.selection()` |
| `screens/timeline_screen.dart:79` | `heavyImpact()` (reward) | `WonderHaptics.success()` |

> Xác minh từng dòng bằng grep trước khi sửa (số dòng có thể trôi). Sau refactor, chạy
> `grep -rn "HapticFeedback\." app/lib | grep -v wonder_haptics.dart` phải **rỗng**.

## Export

- Thêm `export 'wonder_haptics.dart';` vào `app/lib/ui/ui.dart` (nếu ui.dart là barrel).
  Kiểm tra file có barrel không; nếu có, đảm bảo import qua `ui.dart` không tạo vòng lặp.

## Validation

- `flutter analyze` sạch.
- `flutter test` pass (test hiện có không assert HapticFeedback nên không vỡ).
- Grep chứng minh không còn call trực tiếp ngoài `wonder_haptics.dart`.

## Rollback

Thuần đổi tên hàm gọi + 1 file mới; revert commit là đủ.
