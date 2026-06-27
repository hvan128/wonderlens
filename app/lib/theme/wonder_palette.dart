import 'package:flutter/material.dart';

/// Bảng màu thương hiệu WonderLens dùng cho lớp giao diện "liquid glass".
///
/// Tông teal vui mắt làm chủ đạo, phối thêm sky/grape/sunny để vòng quét phát
/// sáng có cảm giác cầu vồng nhẹ nhàng — hiện đại như Apple nhưng vẫn trẻ thơ.
class Wonder {
  Wonder._();

  static const Color teal = Color(0xFF26C6DA);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color mint = Color(0xFF5EEAD4);
  static const Color sky = Color(0xFF38BDF8);
  static const Color grape = Color(0xFFB794F4);
  static const Color sunny = Color(0xFFFFC857);

  /// Nền kính tối (đặt trên preview camera để chữ trắng luôn đọc được).
  static const Color ink = Color(0xFF0B1220);

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
    colors: <Color>[cyan, teal, sky],
  );
}
