import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Lớp tương thích giữ API quen thuộc (`PhosphorIcon` + `PhosphorIconsBold/Fill/
/// Duotone`) nhưng ánh xạ sang **Iconsax** (ADR-010, đổi bộ icon 2026-07-06) —
/// bộ icon tròn thân thiện, hợp app trẻ em, có sẵn cặp Linear (nét) / Bold
/// (đặc) khớp đúng hệ hai-tầng của app.
///
/// Vì sao vẫn giữ tên `PhosphorIcons*`: đổi tên hàng loạt ~40 call-site không
/// tạo giá trị thị giác; shim là điểm đổi bộ icon DUY NHẤT. `iconsax_plus`
/// dùng `static const IconData` (KHÔNG `extends IconData`) nên biên dịch được
/// trên Flutter hiện tại — khác `phosphor_flutter`/`lucide_icons` (đã đóng).
///
/// Hai tầng bây giờ đến từ VARIANT, không phải trục fill của font:
///   • `PhosphorIconsBold.*`  → `IconsaxPlusLinear.*` (nét — điều hướng/công cụ)
///   • `PhosphorIconsFill/Duotone.*` → `IconsaxPlusBold.*` (đặc — trạng thái/nhấn)
class PhosphorIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;

  const PhosphorIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.shadows,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Iconsax không phải variable font → không dùng fill/weight; phân cấp
    // nét/đặc do lớp glyph (Linear vs Bold) quyết định tại call-site.
    return Icon(
      icon,
      size: size,
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
    );
  }
}

/// Tầng NÉT (outline) — điều hướng, công cụ, hành động.
abstract final class PhosphorIconsBold {
  static const IconData arrowClockwise = IconsaxPlusLinear.refresh;
  static const IconData arrowDown = IconsaxPlusLinear.arrow_down;
  static const IconData arrowUp = IconsaxPlusLinear.arrow_up;
  static const IconData arrowLeft = IconsaxPlusLinear.arrow_left;
  static const IconData arrowRight = IconsaxPlusLinear.arrow_right;
  static const IconData caretRight = IconsaxPlusLinear.arrow_right_3;
  static const IconData books = IconsaxPlusLinear.book_1;
  static const IconData camera = IconsaxPlusLinear.camera;
  static const IconData compass = IconsaxPlusLinear.discover;
  static const IconData flashlight = IconsaxPlusLinear.flash;
  static const IconData flask = IconsaxPlusLinear.microscope;
  static const IconData houseSimple = IconsaxPlusLinear.home_2;
  static const IconData lockSimple = IconsaxPlusLinear.lock_1;
  static const IconData magnifyingGlass = IconsaxPlusLinear.search_normal_1;
  static const IconData question = IconsaxPlusLinear.message_question;
  static const IconData shareNetwork = IconsaxPlusLinear.share;
  static const IconData saveAdd = IconsaxPlusLinear.save_add;
  static const IconData stop = IconsaxPlusLinear.stop;
  static const IconData trash = IconsaxPlusLinear.trash;
  static const IconData history = IconsaxPlusLinear.clock;
  static const IconData grid = IconsaxPlusLinear.grid_2;
  static const IconData journey = IconsaxPlusLinear.routing_2;
  static const IconData user = IconsaxPlusLinear.user;
  // X trần (đóng/huỷ) — Iconsax chỉ có close_circle/square (có viền), dùng
  // Material Icons.close cho nét X gọn không viền.
  static const IconData x = Icons.close;
}

/// Tầng ĐẶC (fill) — trạng thái, kết quả, điểm nhấn.
abstract final class PhosphorIconsFill {
  static const IconData checkCircle = IconsaxPlusBold.tick_circle;
  static const IconData filmSlate = IconsaxPlusBold.video;
  static const IconData filmStrip = IconsaxPlusBold.video_horizontal;
  static const IconData flask = IconsaxPlusBold.microscope;
  static const IconData handPointing = IconsaxPlusBold.finger_cricle;
  static const IconData image = IconsaxPlusBold.gallery;
  static const IconData lightbulb = IconsaxPlusBold.lamp_on;
  static const IconData lightning = IconsaxPlusBold.flash_1;
  static const IconData medal = IconsaxPlusBold.medal_star;
  static const IconData play = IconsaxPlusBold.play;
  static const IconData question = IconsaxPlusBold.message_question;
  static const IconData sealCheck = IconsaxPlusBold.verify;
  static const IconData sparkle = IconsaxPlusBold.magic_star;
  static const IconData star = IconsaxPlusBold.star;
  static const IconData speakerSimpleHigh = IconsaxPlusBold.volume_high;
  static const IconData trophy = IconsaxPlusBold.cup;
  static const IconData warningCircle = IconsaxPlusBold.warning_2;
  static const IconData xCircle = IconsaxPlusBold.close_circle;
}

/// Tầng ĐẶC cho các glyph trước đây là duotone.
abstract final class PhosphorIconsDuotone {
  static const IconData binoculars = IconsaxPlusBold.discover;
  static const IconData camera = IconsaxPlusBold.camera;
  static const IconData lockSimple = IconsaxPlusBold.lock_1;
  static const IconData magnifyingGlass = IconsaxPlusBold.search_normal_1;
}
