// Hệ motion spring v2 (ADR-009): preset WonderSpring quy đổi SpringDescription
// chuẩn, smooth dừng êm không overshoot, bouncy nảy rõ; projectMomentum chiếu
// đà kiểu UIKit; SpringOffsetSimulation chạy hai trục đồng bộ. Test thuần Dart,
// không cần render.
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/ui/motion.dart';

/// Đỉnh cao nhất của [sim] trên đoạn [0, 3] giây, lấy mẫu 240 Hz — đủ mịn để
/// bắt đỉnh overshoot đầu tiên của spring underdamped.
double _peak(Simulation sim) {
  var peak = double.negativeInfinity;
  for (var t = 0.0; t <= 3.0; t += 1 / 240) {
    final x = sim.x(t);
    if (x > peak) peak = x;
  }
  return peak;
}

void main() {
  const presets = <String, WonderSpring>{
    'smooth': WonderSpring.smooth,
    'snappy': WonderSpring.snappy,
    'bouncy': WonderSpring.bouncy,
    'interactive': WonderSpring.interactive,
  };

  test('4 preset quy đổi SpringDescription hữu hạn, stiffness/damping dương',
      () {
    presets.forEach((name, spring) {
      final d = spring.description;
      expect(d.mass, 1, reason: 'preset $name');
      expect(d.stiffness.isFinite, isTrue, reason: 'preset $name');
      expect(d.damping.isFinite, isTrue, reason: 'preset $name');
      expect(d.stiffness, greaterThan(0), reason: 'preset $name');
      expect(d.damping, greaterThan(0), reason: 'preset $name');
    });
  });

  test('smooth (ζ = 1) đi 0→1 dừng êm, không vượt quá đích', () {
    final sim = WonderSpring.smooth.simulation(from: 0, to: 1);
    expect(_peak(sim), lessThanOrEqualTo(1 + 1e-3));
  });

  test('bouncy (ζ < 1) đi 0→1 có overshoot rõ', () {
    final sim = WonderSpring.bouncy.simulation(from: 0, to: 1);
    expect(_peak(sim), greaterThan(1.01));
  });

  test('velocity 0, đi 0→1: mọi preset isDone trong 3 giây và x tiến về 1', () {
    presets.forEach((name, spring) {
      final sim = spring.simulation(from: 0, to: 1);
      expect(sim.isDone(3), isTrue, reason: 'preset $name');
      expect(sim.x(3), closeTo(1, 0.01), reason: 'preset $name');
      // Càng về sau càng sát đích — chuyển động hội tụ chứ không phân kỳ.
      expect(
        (sim.x(2) - 1).abs(),
        lessThanOrEqualTo((sim.x(0.05) - 1).abs()),
        reason: 'preset $name',
      );
    });
  });

  test('projectMomentum: velocity 0 giữ nguyên vị trí, velocity dương chiếu xa hơn',
      () {
    expect(projectMomentum(120, 0), 120);
    expect(projectMomentum(120, 600), greaterThan(120));
  });

  test('SpringOffsetSimulation đi from→to trên cả hai trục', () {
    final sim = SpringOffsetSimulation(
      spring: WonderSpring.smooth,
      from: const Offset(10, -20),
      to: const Offset(130, 40),
    );
    // t = 0 xuất phát đúng from.
    expect(sim.x(0).dx, closeTo(10, 1e-6));
    expect(sim.x(0).dy, closeTo(-20, 1e-6));
    // t = 3 đã dừng sát to trên cả hai trục.
    expect(sim.isDone(3), isTrue);
    expect(sim.x(3).dx, closeTo(130, 0.01));
    expect(sim.x(3).dy, closeTo(40, 0.01));
  });

  test('SpringOffsetSimulation.isDone chỉ true khi CẢ HAI trục xong', () {
    // Trục x đi 500px (lâu), trục y đi 1px (xong sớm) — isDone phải chờ trục
    // chậm hơn.
    final sim = SpringOffsetSimulation(
      spring: WonderSpring.smooth,
      from: Offset.zero,
      to: const Offset(500, 1),
    );
    expect(sim.isDone(0), isFalse);
    // Quét tìm thời điểm isDone đầu tiên trong 3 giây.
    double? firstDone;
    for (var t = 0.0; t <= 3.0; t += 1 / 60) {
      if (sim.isDone(t)) {
        firstDone = t;
        break;
      }
    }
    expect(firstDone, isNotNull, reason: 'spring phải kết thúc trong 3 giây');
    // Lúc isDone lần đầu, CẢ HAI trục đều đã sát đích trong tolerance
    // (distance 0.1 của WonderSpring.simulation).
    final p = sim.x(firstDone!);
    expect(p.dx, closeTo(500, 0.2));
    expect(p.dy, closeTo(1, 0.2));
  });
}
