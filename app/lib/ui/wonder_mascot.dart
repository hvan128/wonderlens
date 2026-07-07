import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/wonder_tokens.dart';
import 'motion.dart';

/// ============================================================================
/// WonderLens mascot — "Rái", chú rái cá thám hiểm làm bạn đồng hành của bé.
///
/// Một nhân vật minh hoạ duy nhất, **7 sắc thái ([MascotMood])**, đặt được ở mọi
/// màn. Mỗi mood là **một ảnh pose riêng** (`assets/images/mascot/otter_*.png`);
/// widget làm nó "sống" bằng **chuyển động thủ tục** trên hệ `motion.dart`:
///   • float/bob thở, squash & stretch, nghiêng nhẹ — nhịp riêng theo mood.
///   • **spring pop** khi đổi mood, kèm cross-fade giữa hai pose.
///   • **lookAt**: cả thân né nhẹ về phía điểm nhìn (dõi theo vật/ngón tay).
///   • FX vẽ bằng Flutter: quầng glow, lấp lánh (celebrate/proud), "zzz" (sleepy).
///
/// Widget CHỈ *thể hiện* mood truyền vào — màn hình quyết định "khi nào mood nào"
/// (không nhét business logic vào đây). Tôn trọng "Giảm chuyển động"
/// ([reduceMotionOf]): đứng yên ở pose đích, tắt FX động.
///
/// Ví dụ đặt:
///   WonderMascot(mood: MascotMood.curious)             // camera đang ngắm
///   WonderMascot(mood: MascotMood.celebrate, size: 120) // nhận diện xong
/// ============================================================================

/// Các sắc thái của Rái. Màn hình chọn theo ngữ cảnh của bé.
enum MascotMood { idle, curious, celebrate, thinking, telling, sleepy, proud }

class WonderMascot extends StatefulWidget {
  /// Sắc thái hiện tại — đổi giá trị này để Rái đổi pose + cảm xúc.
  final MascotMood mood;

  /// Cạnh vùng vẽ (px). Ảnh pose vuông, tự canh theo.
  final double size;

  /// Hướng nhìn, mỗi trục [-1, 1] (phải/xuống là dương). Truyền để Rái "né" nhẹ
  /// về phía vật/ngón tay; null = nhìn thẳng.
  final Offset? lookAt;

  /// Nhãn cho trình đọc màn hình. Mặc định null = coi như trang trí (không đọc).
  final String? semanticLabel;

  const WonderMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 96,
    this.lookAt,
    this.semanticLabel,
  });

  @override
  State<WonderMascot> createState() => _WonderMascotState();
}

class _WonderMascotState extends State<WonderMascot>
    with TickerProviderStateMixin {
  /// Đồng hồ đơn điệu (giây) chạy bằng Ticker — không "nhảy pha" khi lặp như
  /// AnimationController 0..1. Nuôi mọi dao động ambient.
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  late final Ticker _ticker;

  /// Chuyển pose: 0 = pose cũ, 1 = pose mới (cross-fade + spring pop).
  late final AnimationController _transition;

  late MascotMood _mood;
  MascotMood? _prevMood;

  @override
  void initState() {
    super.initState();
    _mood = widget.mood;
    _transition = AnimationController(
      vsync: this,
      duration: WonderTokens.durSlow,
      value: 1,
    );
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    });
  }

  @override
  void didUpdateWidget(WonderMascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _prevMood = _mood;
      _mood = widget.mood;
      if (reduceMotionOf(context)) {
        _transition.value = 1; // đổi tức thì, không cross-fade
        _prevMood = null;
      } else {
        _transition.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transition.dispose();
    _clock.dispose();
    super.dispose();
  }

  static String _asset(MascotMood m) => 'assets/images/mascot/otter_${m.name}.png';

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    // Bật/tắt đồng hồ theo Giảm chuyển động.
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      _clock.value = 0;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }

    final content = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_clock, _transition]),
      builder: (context, _) => _paint(reduce),
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        label: widget.semanticLabel,
        image: true,
        child: SizedBox.square(dimension: widget.size, child: content),
      );
    }
    return ExcludeSemantics(
      child: SizedBox.square(dimension: widget.size, child: content),
    );
  }

  Widget _paint(bool reduce) {
    final size = widget.size;
    final m = _Motion.of(_mood);
    final t = _clock.value;
    final e = _transition.value;

    // Dao động nền theo nhịp riêng của mood.
    double bob = 0, sq = 0, tiltDeg = 0, glowPulse = 0.5;
    if (!reduce) {
      final ang = t * m.speed;
      final w = ang * m.freq * 2 * math.pi;
      bob = math.sin(w) * m.bob * size;
      sq = math.sin(w) * m.breathe;
      tiltDeg = math.sin(ang * m.tiltFreq * 2 * math.pi) * m.tilt;
      glowPulse = 0.4 + (0.5 + 0.5 * math.sin(w)) * 0.28 * (m.spark > 0 ? 1.3 : 1);
    }

    // Spring pop khi đổi mood: bướu nhô rồi lắng về 1.
    final pop = reduce ? 1.0 : 1 + math.sin(e * math.pi) * (1 - e) * 0.18;

    // lookAt + "lean" của mood → cả thân né nhẹ.
    final look = widget.lookAt ?? Offset.zero;
    final tx = (look.dx.clamp(-1.0, 1.0) * 0.045 + m.lean) * size;
    final ty = bob + m.sink * size + look.dy.clamp(-1.0, 1.0) * 0.03 * size;

    final sx = (1 + sq) * m.scale * pop;
    final sy = (1 - sq) * m.scale * pop;

    // Cross-fade hai pose khi chuyển.
    final showPrev = _prevMood != null && _prevMood != _mood && e < 1;

    const pivot = Alignment(0, 0.72); // xoay/scale quanh điểm gần chân
    final character = Transform.translate(
      offset: Offset(tx, ty),
      child: Transform.rotate(
        angle: tiltDeg * math.pi / 180,
        alignment: pivot,
        child: Transform.scale(
          scaleX: sx,
          scaleY: sy,
          alignment: pivot,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (showPrev)
                Opacity(
                  opacity: (1 - e).clamp(0.0, 1.0),
                  child: _poseImage(_prevMood!, size),
                ),
              Opacity(
                opacity: showPrev ? e.clamp(0.0, 1.0) : 1.0,
                child: _poseImage(_mood, size),
              ),
            ],
          ),
        ),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Quầng sáng phía sau.
        IgnorePointer(
          child: Transform.scale(
            scale: 1 + sq * 2,
            child: Container(
              width: size * 0.86,
              height: size * 0.86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    WonderColors.teal.withValues(alpha: (glowPulse * 0.5).clamp(0, 1)),
                    WonderColors.teal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        character,
        // Lấp lánh / zzz phía trước.
        if (!reduce && (m.spark > 0 || m.zzz > 0))
          IgnorePointer(
            child: CustomPaint(
              size: Size.square(size),
              painter: _FxPainter(phase: t, spark: m.spark, zzz: m.zzz),
            ),
          ),
      ],
    );
  }

  Widget _poseImage(MascotMood m, double size) => Image.asset(
        _asset(m),
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) => _fallback(size),
      );

  Widget _fallback(double size) => Container(
        width: size * 0.7,
        height: size * 0.7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: WonderGradients.badge,
        ),
      );
}

/// Tham số dao động nền của từng mood (chỉ số cảm xúc, không phải hình học pose).
class _Motion {
  final double bob; // biên độ float theo tỉ lệ size
  final double freq; // tần số float (chu kỳ/giây, đã nhân speed)
  final double breathe; // biên độ squash & stretch
  final double tilt; // biên độ nghiêng (độ)
  final double tiltFreq;
  final double sink; // dịch dọc nền theo tỉ lệ size (âm = nhấc lên)
  final double scale;
  final double speed;
  final double lean; // né ngang cố định theo tỉ lệ size
  final double spark; // 0..1 lấp lánh
  final double zzz; // 0..1 hạt buồn ngủ

  const _Motion({
    this.bob = 0.03,
    this.freq = 0.9,
    this.breathe = 0.03,
    this.tilt = 2.5,
    this.tiltFreq = 0.6,
    this.sink = 0,
    this.scale = 1,
    this.speed = 1,
    this.lean = 0,
    this.spark = 0,
    this.zzz = 0,
  });

  static _Motion of(MascotMood mood) {
    switch (mood) {
      case MascotMood.idle:
        return const _Motion();
      case MascotMood.curious:
        return const _Motion(
            bob: 0.022, freq: 1.5, breathe: 0.02, tilt: 4, tiltFreq: 1.1,
            scale: 1.02, speed: 1.4, lean: 0.03);
      case MascotMood.celebrate:
        return const _Motion(
            bob: 0.075, freq: 2.4, breathe: 0.05, tilt: 3, tiltFreq: 2,
            sink: -0.02, scale: 1.03, speed: 1.8, spark: 1);
      case MascotMood.thinking:
        return const _Motion(
            bob: 0.014, freq: 0.6, breathe: 0.02, tilt: 6.5, tiltFreq: 0.45,
            speed: 0.8, lean: -0.02);
      case MascotMood.telling:
        return const _Motion(
            bob: 0.018, freq: 3.4, breathe: 0.035, tilt: 2, tiltFreq: 1.4);
      case MascotMood.sleepy:
        return const _Motion(
            bob: 0.02, freq: 0.42, breathe: 0.045, tilt: 2, tiltFreq: 0.35,
            sink: 0.03, scale: 0.99, speed: 0.6, zzz: 1);
      case MascotMood.proud:
        return const _Motion(
            bob: 0.022, freq: 0.9, breathe: 0.02, tilt: 2, tiltFreq: 0.6,
            sink: -0.015, scale: 1.05, spark: 0.5);
    }
  }
}

/// Vẽ lấp lánh (sao 4 cánh nhấp nháy) và hạt "zzz" bay lên.
class _FxPainter extends CustomPainter {
  final double phase; // giây
  final double spark;
  final double zzz;

  _FxPainter({required this.phase, required this.spark, required this.zzz});

  static const List<Offset> _seeds = <Offset>[
    Offset(-0.42, -0.40),
    Offset(0.44, -0.34),
    Offset(0.40, 0.30),
    Offset(-0.36, 0.30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final w = size.width;

    if (spark > 0.02) {
      for (var i = 0; i < _seeds.length; i++) {
        final p = (phase * 0.6 + i / _seeds.length) % 1.0;
        final twinkle = (0.5 + 0.5 * math.sin(p * 2 * math.pi)) * spark;
        if (twinkle < 0.06) continue;
        _star(canvas, c + _seeds[i] * w, w * 0.06 * twinkle,
            Paint()..color = WonderColors.sunny.withValues(alpha: twinkle.clamp(0, 1)));
      }
    }

    if (zzz > 0.02) {
      for (var i = 0; i < 3; i++) {
        final p = (phase * 0.32 + i / 3) % 1.0; // 0..1 vòng đời
        final alpha = (math.sin(p * math.pi)) * zzz; // mờ ở hai đầu
        if (alpha < 0.06) continue;
        final pos = c +
            Offset(w * (0.24 + p * 0.12), -w * (0.16 + p * 0.34));
        _z(canvas, pos, w * (0.07 + i * 0.02), alpha.clamp(0, 1));
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var k = 0; k < 4; k++) {
      final ang = k * math.pi / 2;
      final tip = c + Offset(math.cos(ang), math.sin(ang)) * r;
      final mid = c +
          Offset(math.cos(ang + math.pi / 4), math.sin(ang + math.pi / 4)) * r * 0.34;
      if (k == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(mid.dx, mid.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _z(Canvas canvas, Offset pos, double fontSize, double alpha) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: WonderColors.indigo.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _FxPainter old) =>
      old.phase != phase || old.spark != spark || old.zzz != zzz;
}
