import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// ============================================================================
/// Hệ chuyển động WonderLens — spring vật lý theo tham số kiểu Apple.
///
/// Thay vì duration + curve rời rạc, mọi tương tác mô tả bằng cặp
/// `(response, dampingFraction)` như SwiftUI:
///   • `response`        — chu kỳ tự nhiên (giây); nhỏ = phản hồi nhanh.
///   • `dampingFraction` — 1.0 dừng êm không nảy; < 1.0 nảy nhẹ vui mắt.
///
/// Quy đổi sang [SpringDescription] (mass = 1):
///   stiffness = (2π / response)²
///   damping   = 4π · dampingFraction / response
///
/// Kéo/thả phải bàn giao velocity thật của ngón tay vào [simulation] —
/// tuyệt đối không cắt sang Tween cứng giữa chừng (mất đà là mất "mượt").
/// ============================================================================
class WonderSpring {
  final double response;
  final double dampingFraction;

  const WonderSpring(this.response, this.dampingFraction)
      : assert(response > 0),
        assert(dampingFraction > 0);

  /// Chuyển trạng thái UI thông thường (mở card, đổi layout) — êm, không nảy.
  static const WonderSpring smooth = WonderSpring(0.42, 1.0);

  /// Phản hồi nút bấm, toggle — nhanh, dứt khoát, nảy rất nhẹ.
  static const WonderSpring snappy = WonderSpring(0.32, 0.85);

  /// Phần thưởng, badge, yếu tố chơi — nảy rõ cho trẻ thấy vui.
  static const WonderSpring bouncy = WonderSpring(0.42, 0.65);

  /// Bám theo ngón tay (kéo panel, sheet) — response ngắn để không tụt hậu.
  static const WonderSpring interactive = WonderSpring(0.24, 0.86);

  SpringDescription get description => SpringDescription(
        mass: 1,
        stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
        damping: 4 * math.pi * dampingFraction / response,
      );

  /// Tolerance mặc định hiệu chỉnh cho ĐƠN VỊ PIXEL. Trục chạy đơn vị khác
  /// (scale 0..1, fraction 0..1) PHẢI truyền tolerance mịn tương ứng, nếu
  /// không spring bị coi là "xong" ngay đỉnh nảy đầu tiên và đứng sai đích.
  static const Tolerance pixelTolerance = Tolerance(distance: 0.1, velocity: 0.1);

  /// Tolerance cho trục 0..1 (scale, fraction).
  static const Tolerance unitTolerance = Tolerance(distance: 0.001, velocity: 0.01);

  /// Simulation một trục từ [from] → [to], tiếp nhận [velocity] bàn giao
  /// (đơn vị/giây — cùng đơn vị với from/to).
  SpringSimulation simulation({
    required double from,
    required double to,
    double velocity = 0,
    Tolerance tolerance = pixelTolerance,
  }) =>
      SpringSimulation(description, from, to, velocity, tolerance: tolerance);
}

/// Người dùng bật "Giảm chuyển động" (Reduce Motion) ở cấp hệ điều hành.
/// Quy ước WonderLens: tắt chuyển động TRANG TRÍ (vòng xoay ambient, lơ lửng,
/// shimmer, confetti, slide chuyển màn) nhưng GIỮ chuyển động mang nghĩa
/// (phản hồi nhấn, thanh tiến trình) — trẻ vẫn cần thấy nhân-quả.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Chiếu điểm dừng theo đà (kiểu UIScrollView.decelerationRate): ngón tay thả
/// với velocity v thì nội dung "muốn" trôi thêm một đoạn trước khi dừng.
/// [rate] mặc định ≈ `.normal` của UIKit. Trả về vị trí dự kiến để chọn đích
/// snap TRƯỚC khi chạy spring — panel/sheet đọc ý định người dùng từ đây.
double projectMomentum(double position, double velocity,
    {double rate = 0.998}) {
  // Công thức UIKit: x' = x + v·(rate / (1000·(1 − rate))) với v tính theo pt/s.
  return position + velocity * (rate / (1000 * (1 - rate)));
}

/// Chạy spring 2D (Offset) trên một Ticker — dùng cho panel trôi tự do,
/// nơi hai trục phải chuyển động đồng bộ trong một frame.
class SpringOffsetSimulation {
  final Simulation _x;
  final Simulation _y;

  SpringOffsetSimulation({
    required WonderSpring spring,
    required Offset from,
    required Offset to,
    Offset velocity = Offset.zero,
  })  : _x = spring.simulation(from: from.dx, to: to.dx, velocity: velocity.dx),
        _y = spring.simulation(from: from.dy, to: to.dy, velocity: velocity.dy);

  Offset x(double t) => Offset(_x.x(t), _y.x(t));

  /// Velocity tại thời điểm [t] — để bàn giao khi phải đổi đích giữa chừng.
  Offset v(double t) => Offset(_x.dx(t), _y.dx(t));

  bool isDone(double t) => _x.isDone(t) && _y.isDone(t);
}
