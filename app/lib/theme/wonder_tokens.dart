import 'package:flutter/material.dart';

/// ============================================================================
/// WonderLens design tokens — nguồn sự thật duy nhất cho toàn bộ giao diện.
/// Mọi component/màn hình lấy màu, khoảng cách, bo góc, độ mờ kính, thời lượng
/// & đường cong animation từ đây để UI luôn đồng bộ.
///
/// v2 — "luồng video AI": bảng màu xoay quanh **tím kỳ diệu** (#6B4EE6) + vàng
/// tia sáng (#FFC23C), nền oải hương dịu, mực chữ ánh tím. Bám sát
/// `wonderlens-mockup.html`. Tên token cũ (teal/cyan/sky…) được giữ làm **bí danh
/// tương thích** để không phải sửa từng call-site; giá trị đã ánh xạ sang hệ tím.
/// ============================================================================

/// Bảng màu thương hiệu.
abstract final class WonderColors {
  // —— Hệ tím kỳ diệu (canonical) ——
  /// Tím chủ đạo — màu thương hiệu.
  static const Color wonder = Color(0xFF6B4EE6);

  /// Tím sâu — dùng cho mực nhấn, đáy gradient, chữ trên kính sáng.
  static const Color wonderDeep = Color(0xFF3A2A8C);

  /// Tím nhạt (oải hương) — nền chip, vùng nhấn dịu.
  static const Color wonderSoft = Color(0xFFEDE7FF);

  /// Tím sáng — đỉnh gradient nút/halo.
  static const Color violet = Color(0xFF7C5BFF);

  /// Tím-chàm trung gian cho gradient.
  static const Color indigoDeep = Color(0xFF5B3FD6);

  /// Vàng tia sáng — màu phụ rực rỡ (CTA, huy hiệu, sparkle).
  static const Color spark = Color(0xFFFFC23C);

  /// Mực nâu trên nền vàng tia sáng (đủ tương phản, ấm).
  static const Color onSpark = Color(0xFF4A2E00);

  // —— Bí danh tương thích (giá trị đã ánh xạ sang hệ tím) ——
  /// (legacy "teal") → tím chủ đạo.
  static const Color teal = wonder;

  /// (legacy "tealDeep") → tím sâu.
  static const Color tealDeep = wonderDeep;

  /// (legacy "cyan") → tím sáng (đỉnh gradient).
  static const Color cyan = violet;

  /// Xanh trời phụ — giữ cho dải cầu vồng & vài điểm nhấn mát.
  static const Color sky = Color(0xFF4FC3F7);

  /// (legacy "indigo") → tím-chàm trung gian.
  static const Color indigo = indigoDeep;

  /// Tím nho — nhấn phụ (wordmark, nút chia sẻ).
  static const Color grape = Color(0xFF8B6FE8);

  /// Bạc hà — điểm nhấn tươi (live-chip camera, thanh tiến độ).
  static const Color mint = Color(0xFF2FD3BC);

  /// (legacy "sunny") → vàng tia sáng.
  static const Color sunny = spark;

  /// San hô — cảnh báo nhẹ / nhãn "MỚI".
  static const Color coral = Color(0xFFFF7A8A);

  // —— Màu phản hồi (semantic) — dùng chung cho quiz/game/nhiệm vụ ——
  /// Xanh "đúng rồi" — đáp án đúng, bước hoàn thành.
  static const Color success = Color(0xFF2EBD85);

  /// Đỏ dịu "chưa đúng" — đáp án sai (không đáng sợ với trẻ).
  static const Color danger = Color(0xFFE5564E);

  /// Hổ phách — huy chương, mốc thưởng (đậm hơn spark, đọc được trên nền sáng).
  static const Color honey = Color(0xFFE08A00);

  // —— Nền tối cho kính đặt trên camera (chữ trắng luôn đọc rõ) ——
  static const Color ink = Color(0xFF14102E);
  static const Color inkSoft = Color(0xFF2B2550);

  // —— Mực chữ trên nền sáng ——
  static const Color textStrong = Color(0xFF2A2150);
  static const Color textSoft = Color(0xFF736A99);
  static const Color textFaint = Color(0xFFA9A1C9);

  // —— Nền sáng cho các màn nội dung (oải hương) ——
  static const Color canvasTop = Color(0xFFF7F3FF);
  static const Color canvasBottom = Color(0xFFEDE7FF);

  // —— Mã màu vật liệu (đồng bộ huy hiệu / nhãn lưới) ——
  static const Color matPlastic = Color(0xFF4FB0F7); // Nhựa
  static const Color matMetal = Color(0xFF9AA3B8); // Kim loại
  static const Color matPaper = Color(0xFFE8B873); // Giấy
  static const Color matWood = Color(0xFFB6855A); // Gỗ

  /// Màu đại diện cho một nhóm vật liệu (theo tên tiếng Việt trong catalog).
  static Color material(String name) {
    switch (name) {
      case 'Nhựa':
        return matPlastic;
      case 'Kim loại':
        return matMetal;
      case 'Giấy':
        return matPaper;
      case 'Gỗ':
        return matWood;
      default:
        return wonder;
    }
  }
}

/// Dải gradient dùng lại nhiều nơi.
abstract final class WonderGradients {
  /// Vòng quét cầu vồng — bắt đầu & kết thúc cùng màu để xoay liền mạch.
  static const List<Color> ring = <Color>[
    WonderColors.wonder,
    WonderColors.sky,
    WonderColors.grape,
    WonderColors.spark,
    WonderColors.mint,
    WonderColors.wonder,
  ];

  /// Nút hành động chính (tím).
  static const LinearGradient cta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[WonderColors.violet, WonderColors.wonder, WonderColors.indigoDeep],
  );

  /// Nút/điểm nhấn vàng tia sáng (CTA chào mừng, "Chia sẻ phim").
  static const LinearGradient sunny = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFD66B), WonderColors.spark],
  );

  /// Huy hiệu emoji / điểm nhấn tròn.
  static const LinearGradient badge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[WonderColors.violet, WonderColors.wonder],
  );

  /// Nền màn nội dung (sáng, dịu mắt cho trẻ đọc).
  static const LinearGradient canvas = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[WonderColors.canvasTop, WonderColors.canvasBottom],
  );

  /// Nền tối "kỳ diệu" cho các màn full-screen (Welcome / Generating / Badge).
  static const RadialGradient magic = RadialGradient(
    center: Alignment(0, -0.5),
    radius: 1.1,
    colors: <Color>[WonderColors.violet, Color(0xFF4226A6), Color(0xFF2A1670)],
    stops: <double>[0.0, 0.62, 1.0],
  );

  /// Nền camera (tím rất sâu, tối).
  static const RadialGradient camera = RadialGradient(
    center: Alignment(0, -0.1),
    radius: 1.0,
    colors: <Color>[WonderColors.inkSoft, WonderColors.ink],
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
      color: WonderColors.wonderDeep.withValues(alpha: 0.18),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: WonderColors.wonderDeep.withValues(alpha: 0.22),
      blurRadius: 30,
      offset: const Offset(0, 16),
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
