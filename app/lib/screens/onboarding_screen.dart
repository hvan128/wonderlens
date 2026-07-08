import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_settings.dart';
import '../ui/ui.dart';

/// Onboarding "chụp thử" kiểu CapWords: mô phỏng đúng màn camera thật — ảnh
/// cốc giấy trên bàn hiện như viewfinder, 4 góc ngắm + câu đố mời chạm nút
/// khẩu độ. Bé bấm chụp → nền tối dần + bụi lấp lánh, riêng chiếc cốc (cutout
/// cùng khung hình) vẫn sắc nét — rồi thẻ khen dẫn vào hành trình thật.
/// Toàn bộ diễn ra dưới 10 giây, có "Bỏ qua", chỉ hiện đúng một lần.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  bool _captured = false;

  // 0 → 1: nền chìm xuống + cutout nổi lên (spring, có overshoot nhẹ).
  late final AnimationController _reveal = AnimationController.unbounded(
    vsync: this,
  );
  // Vòng twinkle cho bụi lấp lánh + nhịp bồng bềnh của cutout.
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nạp sẵn cả hai ảnh để khoảnh khắc "chụp" không bị khựng giải mã.
    precacheImage(
      const AssetImage('assets/images/onboarding_scene.jpg'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/onboarding_cutout.png'),
      context,
    );
  }

  @override
  void dispose() {
    _reveal.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  void _onCaptured() {
    if (_captured) return;
    setState(() => _captured = true);
    if (reduceMotionOf(context)) {
      _reveal.value = 1;
      return;
    }
    // Spring xong phải đặt value về đúng đích (ADR-009) — không thì controller
    // dừng trong khoảng tolerance và gate `t == 0` bên dưới không bao giờ đúng.
    _reveal
        .animateWith(
          WonderSpring.bouncy.simulation(
            from: _reveal.value,
            to: 1,
            tolerance: WonderSpring.unitTolerance,
          ),
        )
        .whenComplete(() => _reveal.value = 1);
  }

  void _replay() {
    setState(() => _captured = false);
    if (reduceMotionOf(context)) {
      _reveal.value = 0;
      return;
    }
    _reveal
        .animateWith(
          WonderSpring.smooth.simulation(
            from: _reveal.value,
            to: 0,
            tolerance: WonderSpring.unitTolerance,
          ),
        )
        .whenComplete(() => _reveal.value = 0);
  }

  void _finish() {
    AppSettings.markOnboardingSeen();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    // Twinkle chỉ chạy khi lớp khám phá đang hiện (trang trí → tôn trọng
    // Reduce Motion).
    final wantTwinkle = _captured && !reduce;
    if (wantTwinkle && !_twinkle.isAnimating) {
      _twinkle.repeat();
    } else if (!wantTwinkle && _twinkle.isAnimating) {
      _twinkle.stop();
    }

    // Thẻ khen: scale vào khi chụp xong, chạy ngược khi "Chụp thử lại"
    // (target-driven — không phải one-shot lúc mount); Reduce Motion chỉ giữ
    // fade mang nghĩa của AnimatedOpacity bên dưới.
    Widget praise = _PraiseCard(onFinish: _finish, onReplay: _replay);
    if (!reduce) {
      praise = praise
          .animate(target: _captured ? 1 : 0)
          .scaleXY(
            begin: 0.92,
            end: 1,
            duration: WonderTokens.durSlow,
            curve: WonderTokens.curveEmphasized,
          );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Cảnh mẫu — đóng vai preview camera. Thiếu asset thì nền tối, flow
          // vẫn chạy (không bao giờ crash vì media).
          Image.asset(
            'assets/images/onboarding_scene.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: WonderColors.ink),
          ),
          // Nền "tan" sau cú chụp: phủ nâu ấm tối dần + bụi lấp lánh, riêng
          // cutout cốc (cùng khung hình → khớp pixel với cảnh) vẫn sắc nét.
          // RepaintBoundary cô lập re-record của lớp này (twinkle chạy vô hạn
          // khi thẻ khen mở) khỏi phần còn lại của trang — ADR-009 quy ước 5.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_reveal, _twinkle]),
              builder: (context, _) {
                final t = _reveal.value.clamp(0.0, 1.0);
                if (t == 0) return const SizedBox.shrink();
                final phase = _twinkle.value;
                final floatY = reduce
                    ? 0.0
                    : -4 * math.sin(2 * math.pi * phase);
                return IgnorePointer(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ColoredBox(
                        color: const Color(
                          0xFF332416,
                        ).withValues(alpha: 0.62 * t),
                      ),
                      CustomPaint(
                        painter: _SparklesPainter(phase: phase, reveal: t),
                      ),
                      Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, floatY),
                          child: Transform.scale(
                            // _reveal là spring bouncy → vượt 1 một nhịp = cú
                            // "nhún" của chiếc cốc lúc được tách ra.
                            scale: 0.97 + 0.05 * _reveal.value,
                            child: Image.asset(
                              'assets/images/onboarding_cutout.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const _Scrims(),
          // Khung ngắm + câu đố — mờ đi sau cú chụp.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _captured ? 0 : 1,
                duration: WonderTokens.durBase,
                child: const _AimChrome(),
              ),
            ),
          ),
          // Thương hiệu (trái) + Bỏ qua (phải) trên scrim đỉnh.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const WonderLogo(size: 22, spin: false),
                        const SizedBox(width: 8),
                        Text(
                          'WonderLens',
                          style: WonderType.title.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            shadows: const <Shadow>[
                              Shadow(color: Colors.black45, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GlassSurface(
                      tone: GlassTone.dark,
                      radius: WonderTokens.pill,
                      blur: 0,
                      tintOpacity: 0.35,
                      // vertical 12 → tổng cao ~46px, đạt touch target ≥44px
                      // (DESIGN.md §4) cho ngón tay trẻ.
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onTap: _finish,
                      child: Text(
                        'Bỏ qua',
                        style: WonderType.textButton.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Đáy lúc ngắm: đúng nút khẩu độ của app (hiệu ứng chụp có sẵn).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: _captured,
              child: AnimatedOpacity(
                opacity: _captured ? 0 : 1,
                duration: WonderTokens.durBase,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: ApertureCaptureButton(
                        size: WonderTokens.scanSize,
                        showGuide: false,
                        onCapture: _onCaptured,
                        semanticLabel: 'Chụp thử chiếc cốc',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Thẻ khen sau cú chụp → dẫn vào app thật. Luôn nằm trong cây với
          // IgnorePointer — KHÔNG dùng AnimatedSwitcher: child đang fade-out
          // vẫn nhận tap, bé bấm lại nút chụp trong 280ms có thể trúng nút
          // "Bắt đầu khám phá" và bị đẩy về home ngoài ý muốn.
          IgnorePointer(
            ignoring: !_captured,
            child: AnimatedOpacity(
              opacity: _captured ? 1 : 0,
              duration: WonderTokens.durBase,
              curve: WonderTokens.curveStandard,
              child: praise,
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ngắm 4 góc + câu đố mời chụp — dáng góc đồng bộ `_CornersPainter`
/// của camera_screen.dart. Khác camera thật (khung căn giữa, người dùng tự
/// lia máy cho vật vào khung): cảnh ở đây cố định nên khung tự hạ xuống ôm
/// chiếc cốc, còn câu đố nằm TRÊN khung trong hộp kính tối — vùng giữa ảnh
/// sáng màu, chữ trắng trần không đủ tương phản.
class _AimChrome extends StatelessWidget {
  const _AimChrome();

  /// Tâm chủ thể theo trục dọc của ảnh scene (đo từ bbox alpha của cutout).
  /// Màn dọc cover chỉ crop chiều ngang nên tỉ lệ dọc giữ nguyên mọi phone.
  static const double _subjectCenterFrac = 0.615;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final side = math.min(w * 0.74, h * 0.46);
        // Chừa 120px hai đầu cho hàng thương hiệu (trên) và nút chụp (dưới).
        final frameTop = (h * _subjectCenterFrac - side / 2)
            .clamp(120.0, math.max(120.0, h - side - 120.0))
            .toDouble();
        return Stack(
          children: <Widget>[
            Positioned(
              top: frameTop,
              left: (w - side) / 2,
              width: side,
              height: side,
              child: CustomPaint(painter: _CornersPainter()),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: h - frameTop + 14,
              child: Center(
                child: GlassSurface(
                  tone: GlassTone.dark,
                  radius: WonderTokens.radiusLg,
                  blur: 0,
                  tintOpacity: 0.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Đố bé biết chiếc cốc này từ đâu tới?',
                        textAlign: TextAlign.center,
                        style: WonderType.body.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chạm nút tròn bên dưới để chụp thử nhé!',
                        textAlign: TextAlign.center,
                        style: WonderType.heading.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PraiseCard extends StatelessWidget {
  final VoidCallback onFinish;
  final VoidCallback onReplay;

  const _PraiseCard({required this.onFinish, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassSurface(
                tone: GlassTone.dark,
                radius: WonderTokens.radiusLg,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                tintOpacity: 0.42,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(
                      child: WonderChip(
                        label: 'Cốc giấy',
                        icon: PhosphorIconsFill.sparkle,
                        color: WonderColors.mint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Giỏi quá, bé chụp được rồi!',
                      textAlign: TextAlign.center,
                      style: WonderType.title.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cứ chụp một món đồ như vậy, WonderLens sẽ kể '
                      'chuyện nó ra đời cho bé nghe.',
                      textAlign: TextAlign.center,
                      style: WonderType.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 18),
                    WonderButton(label: 'Bắt đầu khám phá', onTap: onFinish),
                    const SizedBox(height: 4),
                    Center(
                      child: WonderTextButton(
                        label: 'Chụp thử lại',
                        color: Colors.white,
                        onTap: onReplay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrim tối 2 đầu màn — cùng thông số với `_Scrims` của camera_screen.dart.
class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: <Widget>[
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.42),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bản sao dáng `_CornersPainter` (camera_screen.dart) — 4 góc trắng bo mềm.
class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final m = math.min(size.width, size.height);
    final len = m * 0.26;
    final r = m * 0.1;
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    void corner(Offset o, Offset h, Offset v) {
      final cross = h.dx * v.dy - h.dy * v.dx;
      final path = Path()
        ..moveTo(o.dx + h.dx * len, o.dy + h.dy * len)
        ..lineTo(o.dx + h.dx * r, o.dy + h.dy * r)
        ..arcToPoint(
          Offset(o.dx + v.dx * r, o.dy + v.dy * r),
          radius: Radius.circular(r),
          clockwise: cross < 0,
        )
        ..lineTo(o.dx + v.dx * len, o.dy + v.dy * len);
      canvas.drawPath(path, shadow);
      canvas.drawPath(path, line);
    }

    final w = size.width;
    final h = size.height;
    corner(Offset.zero, const Offset(1, 0), const Offset(0, 1));
    corner(Offset(w, 0), const Offset(-1, 0), const Offset(0, 1));
    corner(Offset(0, h), const Offset(1, 0), const Offset(0, -1));
    corner(Offset(w, h), const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) => false;
}

/// Bụi lấp lánh quanh vật sau cú chụp — chấm nhỏ trắng/vàng nhấp nháy theo
/// [phase], mờ dần theo [reveal]. Vị trí cố định (seed) để không nhảy lung tung.
class _SparklesPainter extends CustomPainter {
  final double phase;
  final double reveal;

  _SparklesPainter({required this.phase, required this.reveal});

  static final List<_Sparkle> _sparks = _seed();

  static List<_Sparkle> _seed() {
    final rng = math.Random(7);
    return List<_Sparkle>.generate(46, (i) {
      return _Sparkle(
        x: rng.nextDouble(),
        // Dồn về dải giữa màn (quanh vật) — đỉnh/đáy đã có scrim + chữ.
        y: 0.18 + rng.nextDouble() * 0.6,
        r: 1.2 + rng.nextDouble() * 1.6,
        offset: rng.nextDouble(),
        warm: rng.nextBool(),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (reveal <= 0) return;
    final paint = Paint()..isAntiAlias = true;
    for (final s in _sparks) {
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (phase + s.offset));
      final alpha = (0.55 * reveal * tw).clamp(0.0, 1.0);
      if (alpha < 0.02) continue;
      paint.color = (s.warm ? WonderColors.sunny : Colors.white).withValues(
        alpha: alpha,
      );
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) =>
      old.phase != phase || old.reveal != reveal;
}

class _Sparkle {
  final double x;
  final double y;
  final double r;
  final double offset;
  final bool warm;

  const _Sparkle({
    required this.x,
    required this.y,
    required this.r,
    required this.offset,
    required this.warm,
  });
}
