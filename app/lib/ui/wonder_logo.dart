import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'pressable.dart';
import 'wonder_haptics.dart';

/// Độ "mở" khẩu độ lúc nghỉ (0 = sập kín hẳn, 1 = mở toang). 0.61 cho lỗ mở
/// vừa — giữ đúng dáng cũ sau khi sàn lỗ mở hạ về ~0 để sập kín được cả tâm.
const double _kIdleOpen = 0.61;

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Logo WonderLens — **khẩu độ pinwheel pastel** (6 cánh đều, tâm sáng). Dựng
/// bằng [AperturePainter], không asset. [spin] = xoay chậm nhẹ (tôn trọng
/// Reduce Motion). Dùng cho nhận diện thương hiệu (header…). Nút chụp tương tác
/// có hiệu ứng shutter là [ApertureCaptureButton].
class WonderLogo extends StatefulWidget {
  final double size;
  final bool spin;

  const WonderLogo({super.key, this.size = 36, this.spin = true});

  @override
  State<WonderLogo> createState() => _WonderLogoState();
}

class _WonderLogoState extends State<WonderLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    final wantSpin = widget.spin && !reduce;
    if (wantSpin && !_c.isAnimating) {
      _c.repeat();
    } else if (!wantSpin && _c.isAnimating) {
      _c.stop();
    }

    final Widget mark = RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: const AperturePainter(openness: _kIdleOpen)),
      ),
    );

    if (!wantSpin) return mark;
    return RotationTransition(turns: _c, child: mark);
  }
}

/// Nút chụp là logo khẩu độ — dùng ở trang chủ (mở camera) lẫn shutter màn
/// camera. [animateOnTap] = true: chạm chạy **hiệu ứng chụp** (mở khẩu →
/// xoay vài vòng → sập vào + chớp sáng) rồi gọi [onCapture];
/// ngoài ra lúc nghỉ cứ vài giây tự chạy một nhịp "gợi ý chụp" — cú chụp thu
/// nhỏ (tách cánh → xoay một vòng → sập trập kín tận tâm → hé mở lại) để trẻ
/// hình dung đây là nút vào màn chụp ảnh.
/// = false: gọi [onCapture] ngay, không hiệu ứng nào (shutter camera).
/// Reduce Motion bỏ cả hiệu ứng chụp lẫn nhịp gợi ý.
class ApertureCaptureButton extends StatefulWidget {
  final double size;
  final VoidCallback? onCapture;

  /// Gọi NGAY lúc chạm (đầu hiệu ứng) — vd pre-warm camera để nó nạp trong lúc
  /// vòng đang xoay.
  final VoidCallback? onPressStart;

  /// Đang bận (AI xử lý) → xoay liên tục nhanh, bỏ qua chạm.
  final bool busy;

  /// Vành chấm ngắm quanh nút (home bật; màn camera tắt vì nền tối).
  final bool showGuide;

  /// true → chạm chạy hiệu ứng chụp rồi mới [onCapture]; false → [onCapture]
  /// ngay (dùng cho shutter camera: chụp tức thì, hiệu ứng tan-biến lo phần sau).
  final bool animateOnTap;

  final String? semanticLabel;

  const ApertureCaptureButton({
    super.key,
    this.size = 220,
    this.onCapture,
    this.onPressStart,
    this.busy = false,
    this.showGuide = true,
    this.animateOnTap = true,
    this.semanticLabel,
  });

  @override
  State<ApertureCaptureButton> createState() => _ApertureCaptureButtonState();
}

class _ApertureCaptureButtonState extends State<ApertureCaptureButton>
    with TickerProviderStateMixin {
  // Xoay chậm lúc nghỉ.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );
  // Chuỗi hiệu ứng chụp (một lần).
  late final AnimationController _cap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  // Nhịp "gợi ý chụp" lúc nghỉ (một lần, hẹn giờ lặp lại). 3s thong thả:
  // riêng cú sập trập phải NHANH như click máy ảnh thật, còn mở ra thì từ tốn
  // — nhịp không đều mới giống thật.
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  Timer? _hintTimer;
  bool _capturing = false;
  // Góc xoay tại lúc chạm — để hiệu ứng chụp nối tiếp mượt từ xoay nghỉ/gợi ý
  // thay vì giật về 0.
  double _rotStart = 0;

  static const double _turns = 2.5; // số vòng xoay khi chụp
  static const Duration _hintEvery = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _scheduleHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _idle.dispose();
    _cap.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _scheduleHint() {
    if (!widget.animateOnTap) return; // shutter camera: không gợi ý
    _hintTimer?.cancel();
    _hintTimer = Timer(_hintEvery, _playHint);
  }

  Future<void> _playHint() async {
    if (!mounted) return;
    final skip = _capturing ||
        widget.busy ||
        widget.onCapture == null ||
        reduceMotionOf(context);
    if (!skip) {
      // Đứng hình xoay nghỉ: trong nhịp gợi ý, góc xoay do một mình
      // _hintRotation quản — không thế thì lúc trập ngậm kín vẫn bị trôi góc.
      _idle.stop();
      try {
        await _hint.forward(from: 0).orCancel;
      } on TickerCanceled {
        // Bị chạm giữa chừng — _startCapture tiếp quản góc xoay.
      }
      if (!mounted) return;
      _hint.reset();
      // build() sẽ nối lại xoay nghỉ theo điều kiện chung (trừ khi đang chụp
      // — _startCapture tự setState khi xong).
      if (!_capturing) setState(() {});
    }
    _scheduleHint();
  }

  Future<void> _startCapture() async {
    if (_capturing || widget.busy || widget.onCapture == null) return;
    widget.onPressStart?.call();
    if (!widget.animateOnTap || reduceMotionOf(context)) {
      WonderHaptics.primary();
      widget.onCapture!.call();
      return;
    }
    setState(() => _capturing = true);
    _hintTimer?.cancel();
    _rotStart = _idle.value * 2 * math.pi + _hintRotation(_hint.value);
    if (_hint.isAnimating) _hint.stop();
    _hint.reset();
    _idle.stop();
    WonderHaptics.primary();
    try {
      await _cap.forward(from: 0);
    } catch (_) {}
    if (!mounted) return;
    WonderHaptics.success(); // khoảnh khắc "chụp"
    widget.onCapture!.call();
    if (!mounted) return;
    _cap.reset();
    setState(() => _capturing = false);
    _scheduleHint();
  }

  // Chuỗi chụp giữ dáng gốc, liền mạch không khoảng dừng — cú trập "thật"
  // (tách cánh, đứng hình khi kín) dành cho nhịp gợi ý lúc nghỉ.
  // openness theo timeline: mở nhanh → giữ → sập.
  double _openness(double t) {
    const open = 0.28, hold = 0.62;
    if (t < open) {
      return _lerp(_kIdleOpen, 1, Curves.easeOutCubic.transform(t / open));
    }
    if (t < hold) return 1;
    return _lerp(1, 0, Curves.easeInCubic.transform((t - hold) / (1 - hold)));
  }

  double _rotation(double t) =>
      _turns * 2 * math.pi * Curves.easeInOutCubic.transform(t);

  // Mốc pha nhịp gợi ý — một cú chụp thu nhỏ: tách mở [0→_hOpen] → xoay giữ
  // [→_hClose] → sập kín tận tâm [→_hSealed] → giữ kín [→_hReopen] → hé mở về
  // dáng nghỉ [→1]. Chính cú "đóng trập" này dạy người dùng đây là nút chụp.
  // Tỷ lệ trên nền 3s: mở 540ms, ngắm 720ms, SẬP 300ms (cú click), ngậm
  // 540ms, nhả 900ms.
  static const double _hOpen = 0.18,
      _hClose = 0.42,
      _hSealed = 0.52,
      _hReopen = 0.70;

  double _hintOpenness(double t) {
    if (t < _hOpen) {
      return _lerp(_kIdleOpen, 1, Curves.easeOutCubic.transform(t / _hOpen));
    }
    if (t < _hClose) return 1;
    if (t < _hSealed) {
      return _lerp(
        1,
        0,
        Curves.easeInCubic.transform((t - _hClose) / (_hSealed - _hClose)),
      );
    }
    if (t < _hReopen) return 0;
    return _lerp(
      0,
      _kIdleOpen,
      Curves.easeOutCubic.transform((t - _hReopen) / (1 - _hReopen)),
    );
  }

  // Tách cánh của nhịp gợi ý: dịu hơn lúc chụp thật (~50%), khít lại đúng lúc
  // trập đóng.
  double _hintSeparation(double t) {
    if (t < _hOpen) return 0.5 * Curves.easeOutCubic.transform(t / _hOpen);
    if (t < _hClose) return 0.5;
    if (t < _hSealed) {
      return 0.5 *
          (1 -
              Curves.easeInCubic.transform(
                (t - _hClose) / (_hSealed - _hClose),
              ));
    }
    return 0;
  }

  // Gợi ý xoay đúng MỘT vòng phụ (2π), dồn hết vào pha ngắm và PHANH ĐỨNG
  // trước cú sập — màn trập thật không xoay khi đóng. Tròn vòng 2π nên nối
  // lại xoay nghỉ không bị giật.
  double _hintRotation(double t) {
    if (t >= _hClose) return 2 * math.pi;
    return 2 * math.pi * Curves.easeInOutCubic.transform(t / _hClose);
  }

  double _scale(double t) {
    const snap = 0.62;
    if (t < snap) return 1 + 0.06 * Curves.easeOut.transform(t / snap);
    return _lerp(
      1.06,
      0.9,
      Curves.easeInCubic.transform((t - snap) / (1 - snap)),
    );
  }

  double _flash(double t) {
    const s = 0.78;
    if (t < s) return 0;
    return Curves.easeIn.transform((t - s) / (1 - s)) * 0.55;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    // Xoay lúc nghỉ (trang trí) hoặc lúc bận (báo đang xử lý — bận thì bỏ qua
    // Reduce Motion vì là phản hồi chức năng). Bận → xoay nhanh hơn.
    final spinning = !_capturing && (widget.busy || !reduce);
    final dur = widget.busy
        ? const Duration(milliseconds: 1100)
        : const Duration(seconds: 20);
    if (_idle.duration != dur) {
      _idle.duration = dur;
      if (_idle.isAnimating) _idle.repeat();
    }
    // Không nối lại xoay nghỉ khi nhịp gợi ý đang chạy — nó tự quản góc xoay
    // (kể cả khoảng đứng hình lúc trập ngậm kín).
    if (spinning) {
      if (!_idle.isAnimating && !_hint.isAnimating) _idle.repeat();
    } else if (_idle.isAnimating) {
      _idle.stop();
    }
    final size = widget.size;

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? 'Mở ống kính để soi đồ vật',
      child: Pressable(
        onTap: _startCapture,
        haptic: false,
        child: SizedBox.square(
          dimension: size,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_idle, _cap, _hint]),
            builder: (context, _) {
              final t = _cap.value;
              // Nhịp gợi ý (h=0 khi không chạy): cú chụp thu nhỏ — tách cánh,
              // xoay thêm một vòng, sập trập kín rồi hé mở lại.
              final h = _capturing ? 0.0 : _hint.value;
              final openness = _capturing ? _openness(t) : _hintOpenness(h);
              // Tách cánh chỉ dùng cho nhịp gợi ý — chuỗi chụp giữ dáng gốc.
              final separation = _capturing ? 0.0 : _hintSeparation(h);
              final rotation = _capturing
                  ? _rotStart + _rotation(t)
                  : (spinning ? _idle.value * 2 * math.pi : 0.0) +
                      _hintRotation(h);
              final scale =
                  _capturing ? _scale(t) : 1 + 0.08 * _hintSeparation(h);
              final flash = _capturing ? _flash(t) : 0.0;

              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (widget.showGuide)
                    const Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(painter: _GuidePainter()),
                      ),
                    ),
                  Positioned.fill(
                    child: Transform.scale(
                      scale: scale,
                      child: CustomPaint(
                        painter: AperturePainter(
                          openness: openness,
                          rotation: rotation,
                          separation: separation,
                        ),
                      ),
                    ),
                  ),
                  if (flash > 0)
                    IgnorePointer(
                      child: Container(
                        width: size * 0.86,
                        height: size * 0.86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: flash),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Vẽ khẩu độ camera: [_n] cánh cong chồng nhau tạo lỗ mở đa giác ở giữa.
/// [openness] 0→1 điều khiển bán kính lỗ mở (0 = sập kín, 1 = mở toang);
/// [rotation] (radian) xoay cả khẩu độ; [separation] 0→1 trượt từng cánh ra
/// ngoài theo phương bán kính riêng của nó — các cánh tách rời, hở khe giữa
/// chúng (0 = liền khít). Mỗi cánh nằm GIỮA hai mép xoắn giống hệt (lệch đúng
/// một bước góc) nên các cánh bằng nhau, không đè nhau.
class AperturePainter extends CustomPainter {
  final double openness;
  final double rotation;
  final double separation;

  const AperturePainter({
    this.openness = _kIdleOpen,
    this.rotation = 0,
    this.separation = 0,
  });

  static const int _n = 6;

  static const List<Color> _blades = <Color>[
    Color(0xFFFFD15A), // vàng
    Color(0xFF74E0B0), // mint
    Color(0xFF6FC0F2), // xanh dương
    Color(0xFF9AA4F2), // chàm-lavender
    Color(0xFFC79BEE), // tím grape
    Color(0xFFFF97AE), // hồng
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double ro = side * 0.47;
    // Sàn ~0 (epsilon để arcTo không suy biến): openness 0 = cánh chụm kín
    // tận tâm như màn trập thật, không chừa lỗ.
    final double ri = _lerp(side * 0.002, side * 0.32, openness.clamp(0, 1));
    final double ctrlR = ri + (ro - ri) * 0.42; // luôn nằm giữa ri..ro
    final Rect outer = Rect.fromCircle(center: c, radius: ro);
    final Rect inner = Rect.fromCircle(center: c, radius: ri);

    const double step = 2 * math.pi / _n;
    const double swirl = step * 0.9;
    final double base = -math.pi / 2 + rotation;
    // Cự ly tách: tối đa ~10% cạnh — đủ hở khe rõ mà cánh không văng quá xa.
    final double sep = separation.clamp(0.0, 1.0) * side * 0.10;

    Offset polar(double a, double r) =>
        c + Offset(math.cos(a) * r, math.sin(a) * r);
    Offset edgeCtrl(double a) => polar(a - swirl * 0.55, ctrlR);

    for (int k = 0; k < _n; k++) {
      final double t0 = base + k * step;
      final double t1 = t0 + step;
      final Offset startK = polar(t0, ro);

      final Path path = Path()
        ..moveTo(startK.dx, startK.dy)
        ..arcTo(outer, t0, step, false)
        ..quadraticBezierTo(
          edgeCtrl(t1).dx,
          edgeCtrl(t1).dy,
          polar(t1 - swirl, ri).dx,
          polar(t1 - swirl, ri).dy,
        )
        ..arcTo(inner, t1 - swirl, -step, false)
        ..quadraticBezierTo(
          edgeCtrl(t0).dx,
          edgeCtrl(t0).dy,
          startK.dx,
          startK.dy,
        )
        ..close();

      // Tâm góc thực của cánh (đã xét độ xoắn) — hướng trượt khi tách.
      final double mid = t0 + step / 2 - swirl / 2;
      final Path drawn = sep > 0
          ? path.shift(Offset(math.cos(mid), math.sin(mid)) * sep)
          : path;

      canvas.drawPath(
        drawn,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = _blades[k],
      );
    }

    // Tâm sáng dịu (thu nhỏ theo lỗ mở → khi sập kín biến mất hẳn).
    canvas.drawCircle(
      c,
      ri * 0.78,
      Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFFFDFEFF),
    );
  }

  @override
  bool shouldRepaint(covariant AperturePainter old) =>
      old.openness != openness ||
      old.rotation != rotation ||
      old.separation != separation;
}

/// Vành chấm bi mờ bao ngoài — gợi "ống ngắm" quanh nút chụp.
class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    const dots = 46;
    final paint = Paint()
      ..color = const Color(0xFF54657F).withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < dots; i++) {
      final a = 2 * math.pi * i / dots;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * radius,
        1.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => false;
}
