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

  /// Cam mật ong đậm — icon huy hiệu/cúp trên nền sáng (sunny quá nhạt cho icon).
  static const Color sunnyDeep = Color(0xFFE08A00);
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

  // Nền giấy ấm — fallback Scaffold cho màn chưa bọc WonderBackground.
  static const Color paper = Color(0xFFFFFDF7);
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

  /// Hành động phụ nổi bật (khoe/chia sẻ, AI) — tím mộng mơ.
  static const LinearGradient secondary = LinearGradient(
    colors: <Color>[WonderColors.grape, WonderColors.indigo],
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

  /// Chiều cao vùng bị thanh tab nổi che — các tab chừa padding đáy này.
  static const double tabBarClearance = 96;

  // Panel nổi (GlassPanel).
  static const double panelMinWidth = 200;
  static const double panelMinHeight = 150;
  static const double panelBarHeight = 44;
  static const double panelSnapMargin = 12;
  static const double resizeHitSize = 28;

  // Thời lượng animation.
  static const Duration durFast = Duration(milliseconds: 160);
  static const Duration durBase = Duration(milliseconds: 280);
  static const Duration durSlow = Duration(milliseconds: 440);

  // Đường cong.
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeOutBack;
  static const Curve curveSpring = Curves.elasticOut;
}

/// Thang chữ dùng chung — KHÔNG set fontFamily để kế thừa font hệ thống mỗi
/// Font BUNDLE offline (ADR-010): Baloo 2 cho display/title/brand — tròn mập,
/// ấm áp; Nunito cho toàn bộ chữ còn lại — x-height cao, đọc tốt cho trẻ.
/// Baloo 2 cố ý KHÔNG dùng ở cỡ nhỏ/weight nặng: dấu tiếng Việt chồng tầng
/// (ắ, ậ, ỗ…) dễ dính nét ở 17px trở xuống. Không font tải mạng.
/// Màu chữ áp tại call-site bằng `.copyWith(color: …)` theo [GlassTone].
abstract final class WonderType {
  static const String displayFamily = 'Baloo 2';
  static const String bodyFamily = 'Nunito';

  /// Số to / màn chào — điểm nhấn lớn nhất.
  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800, // Baloo 2 tối đa 800
    letterSpacing: 0.2,
    height: 1.15, // Baloo cao ascender hơn — nới nhẹ để dấu không chạm dòng trên
  );

  /// Tiêu đề màn / header.
  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    height: 1.1,
  );

  /// Tiêu đề khối nội dung (card, chặng) — Nunito để giữ nét rõ ở cỡ 17.
  static const TextStyle heading = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 17,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
    height: 1.2,
  );

  /// Chữ đọc chính cho trẻ — nâng 15→16 cho dễ đọc, thoáng dòng.
  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.45,
  );

  /// Chữ trên nút chính.
  static const TextStyle button = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 17,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
  );

  /// Nút phụ dạng chữ.
  static const TextStyle textButton = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  /// Nhãn chip / tag.
  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  /// Phụ đề / chú thích nhỏ.
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
  );
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
