import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/wonder_tokens.dart';
import 'motion.dart';
import 'phosphor_compat.dart';

/// Nạp & cache fragment program tan biến (`shaders/dissolve.frag`) một lần cho
/// toàn app — để lúc bé chụp xong tạo shader tức thì, không delay.
///
/// Nuốt lỗi nạp → [create] trả null → [CaptureDissolve] rớt về crossfade đơn
/// giản (không bao giờ làm vỡ luồng chụp).
class DissolveShader {
  DissolveShader._();

  static ui.FragmentProgram? _program;
  static bool _tried = false;

  static Future<void> ensureLoaded() async {
    if (_program != null || _tried) return;
    _tried = true;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/dissolve.frag');
    } catch (e) {
      debugPrint('DissolveShader load error: $e');
      _program = null;
    }
  }

  static ui.FragmentShader? create() => _program?.fragmentShader();
}

/// Màn "vật đã tách nền" sau khi bé chụp, nền **lưới chấm** kiểu CapWords:
///   1. **Tan biến** nền + **vẽ viền** chủ thể (fragment shader).
///   2. **Đang dựng** (`title == null`): halftone cầu vồng toả quanh chủ thể +
///      chú thích; có "Huỷ".
///   3. **Xong** (`title != null`): chủ thể **đẩy lên trên**, RỒI hiện tên + loa
///      + 3 nút tròn (soi lại · mở hành trình · huỷ) + link chỉnh.
///
/// Widget **sở hữu** [frame]/[mask]: tự `dispose()` (đặt trong AnimatedSwitcher
/// nên chạy sau crossfade — an toàn).
class CaptureDissolve extends StatefulWidget {
  final ui.Image frame;
  final ui.Image mask;
  final Offset center;

  /// Tên vật khi AI dựng xong (null = còn đang dựng).
  final String? title;

  /// Mở hành trình (nút ✓).
  final VoidCallback onOpen;

  /// Soi lại / huỷ / chỉnh — đều quay về ống kính.
  final VoidCallback onRetake;

  /// Đọc tên (loa). Null → ẩn.
  final VoidCallback? onSpeak;

  const CaptureDissolve({
    super.key,
    required this.frame,
    required this.mask,
    required this.onOpen,
    required this.onRetake,
    this.onSpeak,
    this.title,
    this.center = const Offset(0.5, 0.5),
  });

  @override
  State<CaptureDissolve> createState() => _CaptureDissolveState();
}

class _CaptureDissolveState extends State<CaptureDissolve>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// Vệt sáng chạy vòng quanh viền lúc đang tải (loop).
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  ui.FragmentShader? _shader;
  bool _introDone = false;
  bool _reduce = false;
  // Bật khi nền đã tan ~60% → cho halftone mờ VÀO ngay trong lúc tan biến (crossfade
  // mượt), thay vì đợi tan xong mới pop lên.
  bool _burstIn = false;

  @override
  void initState() {
    super.initState();
    _shader = DissolveShader.create();
    _c.addListener(() {
      if (!_burstIn && _c.value > 0.6 && mounted) {
        setState(() => _burstIn = true);
      }
    });
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_introDone) {
        setState(() => _introDone = true);
        // Tan biến xong mà vẫn đang tải → cho viền tự vẽ chạy quanh.
        if (widget.title == null && !_reduce) _spin.repeat();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reduce = reduceMotionOf(context);
      if (_reduce) _c.duration = const Duration(milliseconds: 420);
      _c.forward();
    });
  }

  @override
  void didUpdateWidget(covariant CaptureDissolve old) {
    super.didUpdateWidget(old);
    // Có kết quả → dừng vệt sáng chạy, viền đứng yên.
    if (old.title == null && widget.title != null) _spin.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    _spin.dispose();
    _shader?.dispose();
    widget.frame.dispose();
    widget.mask.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    final bool ready = widget.title != null;
    // Halftone mờ vào sớm (trong lúc tan biến) → crossfade mượt, không pop.
    final bool showBurst = _burstIn && !ready;
    // Viền tự vẽ chạy chỉ bật khi viền đã vẽ trọn (tan biến xong).
    final bool spinOn = _introDone && !ready && !_reduce;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _DotGridBackdrop(glow: widget.center),
        // Chủ thể (+ halftone phía sau) — đẩy lên khi có kết quả.
        AnimatedSlide(
          offset: ready ? const Offset(0, -0.11) : Offset.zero,
          duration: const Duration(milliseconds: 540),
          curve: WonderTokens.curveEmphasized,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: showBurst ? 1 : 0,
                    duration: const Duration(milliseconds: 560),
                    curve: Curves.easeInOut,
                    child: _HalftoneBurst(center: widget.center),
                  ),
                ),
              ),
              if (shader != null)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[_c, _spin]),
                    builder: (BuildContext context, _) {
                      final double t = _c.value;
                      final double progress = Curves.easeInOut
                          .transform((t / 0.72).clamp(0.0, 1.0));
                      final double border = Curves.easeInOut
                          .transform(((t - 0.12) / 0.78).clamp(0.0, 1.0));
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _DissolvePainter(
                          shader: shader,
                          frame: widget.frame,
                          mask: widget.mask,
                          center: widget.center,
                          progress: progress,
                          border: border,
                          spin: _spin.value,
                          spinOn: spinOn ? 1.0 : 0.0,
                        ),
                      );
                    },
                  ),
                )
              else
                _FallbackFade(frame: widget.frame, controller: _c),
            ],
          ),
        ),
        // Chớp trắng nhẹ lúc mở màn.
        IgnorePointer(
          child: const ColoredBox(color: Colors.white)
              .animate()
              .fadeOut(duration: 260.ms, curve: Curves.easeOut),
        ),
        // Đáy: đang dựng ↔ kết quả.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: AnimatedSwitcher(
                duration: WonderTokens.durBase,
                switchInCurve: WonderTokens.curveStandard,
                // Đang tải: KHÔNG chữ, KHÔNG nút — hiệu ứng tải là vệt sáng chạy
                // quanh viền chủ thể (shader). Xong mới hiện tên + nút.
                child: ready
                    ? _ResultPanel(
                        key: const ValueKey<String>('result'),
                        title: widget.title!,
                        onOpen: widget.onOpen,
                        onRetake: widget.onRetake,
                        onSpeak: widget.onSpeak,
                      )
                    : const SizedBox.shrink(key: ValueKey<String>('loading')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nền lưới chấm + glow ấm sau chủ thể.
// ─────────────────────────────────────────────────────────────────────────────

class _DotGridBackdrop extends StatelessWidget {
  final Offset glow;
  const _DotGridBackdrop({required this.glow});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFAF7F3), Color(0xFFF1EEF5)],
        ),
      ),
      child: CustomPaint(painter: _DotGridPainter(glow), size: Size.infinite),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Offset glow;
  const _DotGridPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    // Glow ấm phía sau chủ thể.
    final gc = Offset(size.width * glow.dx, size.height * glow.dy);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          WonderColors.sunny.withValues(alpha: 0.22),
          WonderColors.sunny.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: gc, radius: size.width * 0.62));
    canvas.drawRect(Offset.zero & size, glowPaint);

    // Lưới chấm mờ.
    final dot = Paint()..color = WonderColors.tealDeep.withValues(alpha: 0.06);
    const gap = 26.0;
    for (double y = gap; y < size.height; y += gap) {
      for (double x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) => old.glow != glow;
}

// ─────────────────────────────────────────────────────────────────────────────
// Halftone cầu vồng toả (lúc đang dựng chuyện).
// ─────────────────────────────────────────────────────────────────────────────

class _HalftoneBurst extends StatefulWidget {
  final Offset center;
  const _HalftoneBurst({required this.center});

  @override
  State<_HalftoneBurst> createState() => _HalftoneBurstState();
}

class _HalftoneBurstState extends State<_HalftoneBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !reduceMotionOf(context)) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) => CustomPaint(
          size: Size.infinite,
          painter: _HalftonePainter(widget.center, _c.value),
        ),
      ),
    );
  }
}

class _HalftonePainter extends CustomPainter {
  final Offset centerN;
  final double t;
  _HalftonePainter(this.centerN, this.t);

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Một vòng sáng gaussian ở bán kính chuẩn hoá `front*1.08` (lan từ trong ra).
  static double _ring(double dn, double front) {
    const w = 0.17;
    final x = (dn - front * 1.08) / w;
    return math.exp(-0.5 * x * x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * centerN.dx, size.height * centerN.dy);
    // Bán kính rộng (theo cạnh DÀI) để dot toả ra ngoài cả khi chủ thể to, không
    // bị object che hết. Fade ngoài dịu để vành dot quanh object vẫn sáng rõ.
    final radius = size.longestSide * 0.60;
    const gap = 20.0;
    final paint = Paint();
    final front2 = (t + 0.5) % 1.0;

    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        final dx = x - center.dx;
        final dy = y - center.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        final dn = d / radius;
        if (dn > 1.08) continue;
        final env = 1.0 - _smooth(0.10, 1.12, dn);
        if (env <= 0.02) continue;
        // Hai vòng lệch pha nửa chu kỳ → luôn có một vòng đang lan, liền mạch.
        final pulse = math.max(_ring(dn, t), _ring(dn, front2));
        final inten = (env * (0.16 + 0.95 * pulse)).clamp(0.0, 1.0);
        if (inten <= 0.03) continue;
        final hue = ((math.atan2(dy, dx) / (2 * math.pi)) + 0.5) * 360.0;
        paint.color =
            HSVColor.fromAHSV(inten * 0.8, hue % 360.0, 0.5, 1.0).toColor();
        // Dot nhỏ, mịn (bán kính ~≤ 6px) — thanh mảnh thay vì blob thô.
        canvas.drawCircle(Offset(x, y), gap * 0.28 * inten + 0.35, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HalftonePainter old) =>
      old.t != t || old.centerN != centerN;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shader tan biến + fallback.
// ─────────────────────────────────────────────────────────────────────────────

class _DissolvePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image frame;
  final ui.Image mask;
  final Offset center;
  final double progress;
  final double border;
  final double spin;
  final double spinOn;

  _DissolvePainter({
    required this.shader,
    required this.frame,
    required this.mask,
    required this.center,
    required this.progress,
    required this.border,
    required this.spin,
    required this.spinOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, frame.width.toDouble())
      ..setFloat(3, frame.height.toDouble())
      ..setFloat(4, progress)
      ..setFloat(5, border)
      ..setFloat(6, center.dx)
      ..setFloat(7, center.dy)
      ..setFloat(8, spin)
      ..setFloat(9, spinOn)
      ..setImageSampler(0, frame)
      ..setImageSampler(1, mask);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _DissolvePainter old) =>
      old.progress != progress ||
      old.border != border ||
      old.spin != spin ||
      old.spinOn != spinOn;
}

class _FallbackFade extends StatelessWidget {
  final ui.Image frame;
  final AnimationController controller;

  const _FallbackFade({required this.frame, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Opacity(
          opacity: (1.0 - controller.value).clamp(0.0, 1.0),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: frame.width.toDouble(),
                height: frame.height.toDouble(),
                child: RawImage(image: frame, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Đáy: kết quả (image 3) — tên + loa + 3 nút tròn, hiện so le.
// ─────────────────────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  final String title;
  final VoidCallback onOpen;
  final VoidCallback onRetake;
  final VoidCallback? onSpeak;

  const _ResultPanel({
    super.key,
    required this.title,
    required this.onOpen,
    required this.onRetake,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(child: _NamePlate(title: title)),
            if (onSpeak != null) ...<Widget>[
              const SizedBox(width: 12),
              _SpeakerIcon(onTap: onSpeak!),
            ],
          ],
        ).animate().fadeIn(duration: 300.ms).slideY(
              begin: 0.3,
              end: 0,
              curve: WonderTokens.curveStandard,
            ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _CircleAction(
              icon: Icons.refresh_rounded,
              semantic: 'Soi lại',
              onTap: onRetake,
            ),
            const SizedBox(width: 26),
            _CircleAction(
              icon: Icons.check_rounded,
              semantic: 'Mở hành trình',
              primary: true,
              onTap: onOpen,
            ),
            const SizedBox(width: 26),
            _CircleAction(
              icon: Icons.close_rounded,
              semantic: 'Huỷ',
              onTap: onRetake,
            ),
          ],
        ).animate(delay: 160.ms).fadeIn(duration: 320.ms).slideY(
              begin: 0.3,
              end: 0,
              curve: WonderTokens.curveStandard,
            ),
      ],
    );
  }
}

/// Tên vật kiểu **sticker chữ**: viền trắng dày ôm theo nét chữ (không phải hộp
/// bo góc) — vẽ một bản chữ stroke trắng phía sau + bản fill đen phía trước.
class _NamePlate extends StatelessWidget {
  final String title;
  const _NamePlate({required this.title});

  @override
  Widget build(BuildContext context) {
    final base = WonderType.display.copyWith(fontSize: 26, height: 1.06);
    return Stack(
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 11
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(color: WonderColors.textStrong),
        ),
      ],
    );
  }
}

class _SpeakerIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakerIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Đọc tên',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: PhosphorIcon(
            PhosphorIconsFill.speakerSimpleHigh,
            size: 28,
            color: WonderColors.textStrong,
          ),
        ),
      ),
    );
  }
}

/// Nút tròn trắng có bóng; nút chính (✓) to hơn, dấu tím.
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String semantic;
  final VoidCallback onTap;
  final bool primary;

  const _CircleAction({
    required this.icon,
    required this.semantic,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final double size = primary ? 76 : 58;
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: WonderShadows.card,
          ),
          child: Icon(
            icon,
            size: primary ? 36 : 26,
            color: primary ? WonderColors.grape : WonderColors.textSoft,
          ),
        ),
      ),
    );
  }
}
