import 'package:flutter/material.dart';

/// ============================================================================
/// WonderLens design tokens — nguồn sự thật duy nhất cho toàn bộ giao diện.
/// Mọi component/màn hình lấy màu, khoảng cách, bo góc, độ mờ kính, thời lượng
/// & đường cong animation từ đây để UI luôn đồng bộ.
/// ============================================================================

/// Bảng màu thương hiệu.
abstract final class WonderColors {
  // Màu chủ đạo — teal vui mắt, phối sky/grape/sunny/mint cho cảm giác cầu vồng.
  static const Color teal = Color(0xFF26C6DA);
  static const Color tealDeep = Color(0xFF0E97AC);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color sky = Color(0xFF38BDF8);
  static const Color indigo = Color(0xFF7C8CF8);
  static const Color grape = Color(0xFFB794F4);
  static const Color mint = Color(0xFF5EEAD4);
  static const Color sunny = Color(0xFFFFC857);
  static const Color coral = Color(0xFFFF8A65);

  // Nền tối cho kính đặt trên camera (chữ trắng luôn đọc rõ).
  static const Color ink = Color(0xFF0B1220);
  static const Color inkSoft = Color(0xFF14203A);

  // Mực chữ trên nền sáng.
  static const Color textStrong = Color(0xFF15233B);
  static const Color textSoft = Color(0xFF54657F);

  // Nền sáng cho các màn nội dung.
  static const Color canvasTop = Color(0xFFEAF8FB);
  static const Color canvasBottom = Color(0xFFF4EFFF);
}

/// Dải gradient dùng lại nhiều nơi.
abstract final class WonderGradients {
  /// Vòng quét cầu vồng — bắt đầu & kết thúc cùng màu để xoay liền mạch.
  static const List<Color> ring = <Color>[
    WonderColors.teal,
    WonderColors.sky,
    WonderColors.grape,
    WonderColors.sunny,
    WonderColors.mint,
    WonderColors.teal,
  ];

  /// Nút hành động chính.
  static const LinearGradient cta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[WonderColors.cyan, WonderColors.teal, WonderColors.sky],
  );

  /// Huy hiệu emoji / điểm nhấn tròn.
  static const LinearGradient badge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[WonderColors.teal, WonderColors.sky],
  );

  /// Nền màn nội dung (sáng, dịu mắt cho trẻ đọc).
  static const LinearGradient canvas = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[WonderColors.canvasTop, WonderColors.canvasBottom],
  );
}

/// Hằng số bố cục: spacing, bo góc, kích thước icon/nút.
abstract final class WonderTokens {
  // Spacing (thang 4pt).
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  // Bo góc.
  static const double radiusSm = 14;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 34;
  static const double pill = 999;

  // Kính (liquid glass hand-rolled).
  static const double glassBlur = 18;
  static const double glassSaturation = 1.6;
  static const double iconBtnSize = 54;
  static const double scanSize = 96;

  // Thời lượng animation.
  static const Duration durFast = Duration(milliseconds: 160);
  static const Duration durBase = Duration(milliseconds: 280);
  static const Duration durSlow = Duration(milliseconds: 440);

  // Đường cong.
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeOutBack;
  static const Curve curveSpring = Curves.elasticOut;
}

/// Shadow dùng chung.
abstract final class WonderShadows {
  static List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: WonderColors.tealDeep.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.5}) =>
      <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 22,
          spreadRadius: 1,
        ),
      ];
}
