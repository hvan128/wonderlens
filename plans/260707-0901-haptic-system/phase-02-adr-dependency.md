# Phase 02 — ADR-011 + thêm dependency + wiring notification haptics

## Context

Nâng `success/warning/error` từ impact built-in lên **notification haptic kiểu iOS**
(Success / Warning / Error) qua 1 package. AGENTS.md: **dependency mới bắt buộc có ADR**.

## Bước 1 — Viết ADR-011 (làm TRƯỚC khi thêm package)

File: `adrs/ADR-011-haptic-system.md` (số kế tiếp sau ADR-008/009/010).

Nội dung tối thiểu:
- **Context**: haptic rải rác, muốn lớp trung tâm + notification haptic iOS.
- **Decision**: thêm package `haptic_feedback` (đề xuất) cho 3 loại notification;
  selection/tick/primary giữ built-in.
- **Alternatives**:
  - `gaimon` — chỉ iOS (Taptic Engine), Android no-op. Gọn nhưng Android không có
    pattern success/warning/error.
  - `vibration` / `flutter_vibrate` — điều khiển thời lượng thô, không có notification
    semantic chuẩn.
  - **`haptic_feedback`** (chọn) — cross-platform, có `HapticFeedbackType.success/
    warning/error/heavy/medium/light/selection`, có `Haptics.canVibrate()`.
- **Consequences**: +1 dep; iOS SPM/CocoaPods cần kiểm tra tương thích (memory
  `wonderlens-ios-spm-pods`); demo offline vẫn OK (không cần mạng); fallback built-in.
- **Status**: Accepted.

> Đây là file trong `adrs/` — sẽ tạo ở bước IMPLEMENT, không tạo ở bước plan.

## Bước 2 — Thêm dependency

`app/pubspec.yaml` dependencies:

```yaml
  haptic_feedback: ^0.5.1   # chốt version thực tế lúc thêm (kiểm pub.dev)
```

- `flutter pub get`; commit `pubspec.lock`.
- iOS: kiểm tra pod/SPM resolve (chạy build 1 lần). Nếu package chỉ hỗ trợ CocoaPods và
  repo đang SPM → xử lý theo memory; cân nhắc `gaimon` (iOS-only) nếu vướng.

## Bước 3 — Init + nâng WonderHaptics

Thêm cờ khả dụng + init, và nâng 3 hàm notification:

```dart
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as hf;

class WonderHaptics {
  const WonderHaptics._();

  static bool _canVibrate = false; // false cho tới khi init() → test không chạm plugin

  /// Gọi 1 lần lúc khởi động (cạnh AppSettings.init / CollectionRepository.init).
  static Future<void> init() async {
    try {
      _canVibrate = await hf.Haptics.canVibrate();
    } catch (_) {
      _canVibrate = false; // fallback built-in
    }
  }

  static void selection() => HapticFeedback.selectionClick();
  static void tick() => HapticFeedback.lightImpact();
  static void primary() => HapticFeedback.mediumImpact();

  static void success() => _notify(hf.HapticFeedbackType.success, HapticFeedback.heavyImpact);
  static void warning() => _notify(hf.HapticFeedbackType.warning, HapticFeedback.mediumImpact);
  static void error() => _notify(hf.HapticFeedbackType.error, HapticFeedback.heavyImpact);

  static void _notify(hf.HapticFeedbackType type, void Function() fallback) {
    if (_canVibrate) {
      try {
        hf.Haptics.vibrate(type); // fire-and-forget
        return;
      } catch (_) {/* rơi xuống fallback */}
    }
    fallback();
  }
}
```

- Gọi `await WonderHaptics.init();` trong `app/lib/main.dart` (xác minh nơi init
  AppSettings/CollectionRepository để đặt cạnh). Không chặn khởi động nếu lỗi.

## Validation

- `flutter analyze` sạch · `flutter pub get` OK · build iOS + Android pass.
- `flutter test` vẫn pass (init không chạy trong test → `_canVibrate=false` → built-in no-op).
- Thử tay trên device thật: reward vật mới cho cảm giác "success" rõ hơn heavy đơn.

## Rollback

Gỡ dep khỏi pubspec, `_notify` quay lại fallback thuần, revert ADR nếu cần.
