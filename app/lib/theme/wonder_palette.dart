import 'package:flutter/material.dart';

/// Bảng màu thương hiệu WonderLens dùng cho lớp giao diện "liquid glass".
///
/// v2: tông **tím kỳ diệu** làm chủ đạo, phối thêm sky/grape/spark/mint để vòng
/// quét phát sáng có cảm giác cầu vồng nhẹ — hiện đại nhưng vẫn trẻ thơ. Tên giữ
/// nguyên để tương thích; giá trị đồng bộ với `WonderColors` trong wonder_tokens.
class Wonder {
  Wonder._();

  static const Color teal = Color(0xFF6B4EE6); // tím chủ đạo
  static const Color cyan = Color(0xFF7C5BFF); // tím sáng
  static const Color mint = Color(0xFF2FD3BC);
  static const Color sky = Color(0xFF4FC3F7);
  static const Color grape = Color(0xFF8B6FE8);
  static const Color sunny = Color(0xFFFFC23C);

  /// Nền kính tối (đặt trên preview camera để chữ trắng luôn đọc được).
  static const Color ink = Color(0xFF14102E);

  /// Dải màu cho vòng quét — bắt đầu và kết thúc cùng màu để xoay liền mạch.
  static const List<Color> ring = <Color>[
    teal,
    sky,
    grape,
    sunny,
    mint,
    teal,
  ];

  /// Gradient cho nút hành động chính (CTA).
  static const LinearGradient cta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[cyan, teal, Color(0xFF5B3FD6)],
  );
}
