import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Phản hồi rung tập trung cho toàn app — nguồn duy nhất, thay cho việc gọi
/// [HapticFeedback] rải rác. Đặt tên theo **ngữ nghĩa** (việc gì đang xảy ra)
/// chứ không theo cường độ, để đổi cảm giác về sau chỉ sửa một chỗ.
///
/// Haptic là phản hồi *phi thị giác* nên **không** gate theo Reduce Motion (OS
/// đã tự quản "System Haptics"); nhất quán với phần thưởng ở timeline vẫn rung
/// khi bật Reduce Motion.
///
/// - selection/tick/primary → dùng [HapticFeedback] built-in (chạy mọi nơi,
///   không cần plugin).
/// - success/warning/error → khi thiết bị hỗ trợ, dùng **notification haptic**
///   kiểu iOS qua `haptic_feedback` ([Haptics.vibrate]); nếu không thì rớt về
///   impact built-in tương đương. Xem ADR-011.
class WonderHaptics {
  const WonderHaptics._();

  /// Có notification haptic phong phú không. Mặc định `false` tới khi [init]
  /// chạy lúc khởi động app → trong test (không init) sẽ không chạm plugin,
  /// tránh `MissingPluginException`.
  static bool _rich = false;

  /// Gọi **một lần** lúc khởi động (cạnh các init khác trong `main`). Không
  /// chặn khởi động nếu dò khả năng thất bại.
  static Future<void> init() async {
    try {
      _rich = await Haptics.canVibrate();
    } catch (_) {
      _rich = false;
    }
  }

  /// Tap nút/thẻ bấm được, đóng sheet, đổi toggle — cú "tách" nhẹ nhất.
  static void selection() => HapticFeedback.selectionClick();

  /// Chạm mép/ranh giới tinh tế (spring clamp, gợi ý giới hạn kéo).
  static void tick() => HapticFeedback.lightImpact();

  /// Hành động chính của màn hình (bấm scan, chụp ảnh).
  static void primary() => HapticFeedback.mediumImpact();

  /// Hoàn tất có phần thưởng/kết quả tốt (khám phá vật mới, chia sẻ xong).
  static void success() =>
      _notify(HapticsType.success, HapticFeedback.heavyImpact);

  /// Nhắc nhở/xác nhận cần chú ý nhẹ (bước cần cân nhắc trước khi làm).
  static void warning() =>
      _notify(HapticsType.warning, HapticFeedback.mediumImpact);

  /// Thao tác thất bại (thiếu quyền, chụp hỏng, video/chia sẻ lỗi).
  static void error() =>
      _notify(HapticsType.error, HapticFeedback.heavyImpact);

  /// Chạy notification haptic nếu khả dụng; ngược lại rớt về [fallback].
  /// Fire-and-forget: nuốt lỗi async để rung không bao giờ chặn luồng UI.
  static void _notify(HapticsType type, void Function() fallback) {
    if (_rich) {
      Haptics.vibrate(type).catchError((_) {});
      return;
    }
    fallback();
  }
}
