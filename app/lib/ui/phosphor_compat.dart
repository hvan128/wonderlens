import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lớp tương thích giữ API quen thuộc (`PhosphorIcon` + `PhosphorIconsBold/Fill/
/// Duotone`) nhưng ánh xạ sang **Material Symbols** (rounded, filled) và render
/// bằng `Icon`.
///
/// Lý do: mọi bản `phosphor_flutter` (và `lucide_icons`) đều `extends IconData`,
/// mà Flutter 3.44 đã đóng `IconData` thành `final class` → không biên dịch nổi.
/// Material Symbols dùng `IconData` trực tiếp nên tương thích, vẫn cho look hiện
/// đại bo tròn. Giữ shim này để không phải sửa từng call-site.
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
    return Icon(
      icon,
      size: size,
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
      // Filled + hơi đậm → cảm giác chắc chắn, thân thiện cho trẻ.
      fill: 1,
      weight: 600,
    );
  }
}

/// Nét đậm (outline) — map sang Material Symbols tương ứng.
abstract final class PhosphorIconsBold {
  static const IconData arrowClockwise = Symbols.refresh;
  static const IconData arrowLeft = Symbols.arrow_back;
  static const IconData arrowRight = Symbols.arrow_forward;
  static const IconData books = Symbols.auto_stories;
  static const IconData camera = Symbols.photo_camera;
  static const IconData caretRight = Symbols.chevron_right;
  static const IconData compass = Symbols.explore;
  static const IconData dotsThree = Symbols.more_horiz;
  static const IconData downloadSimple = Symbols.download;
  static const IconData flashlight = Symbols.flashlight_on;
  static const IconData flask = Symbols.science;
  static const IconData floppyDisk = Symbols.save;
  static const IconData gridFour = Symbols.grid_view;
  static const IconData houseSimple = Symbols.home;
  static const IconData lockSimple = Symbols.lock;
  static const IconData magnifyingGlass = Symbols.search;
  static const IconData question = Symbols.help;
  static const IconData repeat = Symbols.replay;
  static const IconData shareNetwork = Symbols.share;
  static const IconData star = Symbols.star;
  static const IconData stop = Symbols.stop_circle;
  static const IconData x = Symbols.close;
}

/// Nét đặc (fill).
abstract final class PhosphorIconsFill {
  static const IconData filmSlate = Symbols.slideshow;
  static const IconData filmStrip = Symbols.movie;
  static const IconData image = Symbols.image;
  static const IconData lightbulb = Symbols.lightbulb;
  static const IconData lightning = Symbols.bolt;
  static const IconData medal = Symbols.workspace_premium;
  static const IconData pause = Symbols.pause;
  static const IconData play = Symbols.play_arrow;
  static const IconData sealCheck = Symbols.verified;
  static const IconData sparkle = Symbols.auto_awesome;
  static const IconData speakerSimpleHigh = Symbols.volume_up;
  static const IconData star = Symbols.star;
  static const IconData trophy = Symbols.emoji_events;
  static const IconData warningCircle = Symbols.error;
}

/// Hai tông (duotone) — Material Symbols không có duotone, dùng bản filled.
abstract final class PhosphorIconsDuotone {
  static const IconData binoculars = Symbols.travel_explore;
  static const IconData camera = Symbols.photo_camera;
  static const IconData lockSimple = Symbols.lock;
  static const IconData magnifyingGlass = Symbols.search;
}
