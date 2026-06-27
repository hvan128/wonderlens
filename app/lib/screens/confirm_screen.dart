import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/journey_args.dart';
import '../ui/ui.dart';

/// Màn 3 · Xác nhận. Lưới an toàn trước khi dựng phim: hiện vật Tia nghĩ là +
/// độ tin cậy, và luôn cho "chọn lại". Bám mockup `.s-confirm`.
class ConfirmScreen extends StatelessWidget {
  final JourneyArgs? args;
  const ConfirmScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final a = args;
    if (a == null) {
      return _Fallback(onBack: () => context.go('/camera'));
    }
    final content = a.content;
    final pct = a.confidencePct;
    final isLive = content.source == 'live';

    return Scaffold(
      backgroundColor: WonderColors.ink,
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // —— Vùng "ảnh" với vòng quét + emoji vật ——
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.25),
                      radius: 0.9,
                      colors: <Color>[Color(0xFF34507A), Color(0xFF15224A), Color(0xFF0D1430)],
                      stops: <double>[0.0, 0.7, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        const _DashedScanRing(size: 210)
                            .animate(onPlay: (c) => c.repeat())
                            .rotate(duration: 9.seconds),
                        Text(
                          content.emoji,
                          style: const TextStyle(
                            fontSize: 116,
                            shadows: <Shadow>[Shadow(color: Colors.black54, blurRadius: 22)],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: -8, end: 8, duration: 4.seconds, curve: Curves.easeInOut),
                      ],
                    ),
                  ),
                ),
              ),
              // —— Tấm xác nhận ——
              _ConfirmSheet(
                name: content.name,
                emoji: content.emoji,
                confident: a.confident,
                pct: pct,
                isLive: isLive,
                onCreate: () => context.push('/generating', extra: a),
                onReject: () =>
                    context.canPop() ? context.pop() : context.go('/camera'),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: GlassIconButton(
                  icon: PhosphorIconsBold.arrowLeft,
                  semanticLabel: 'Quay lại',
                  size: 46,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/camera'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String name;
  final String emoji;
  final bool confident;
  final int? pct;
  final bool isLive;
  final VoidCallback onCreate;
  final VoidCallback onReject;

  const _ConfirmSheet({
    required this.name,
    required this.emoji,
    required this.confident,
    required this.pct,
    required this.isLive,
    required this.onCreate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final confLabel = confident ? 'Khá chắc chắn' : 'Hình như là…';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WonderTokens.radiusXl)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black38, blurRadius: 40, offset: Offset(0, -16)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: WonderColors.wonderSoft,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tia nhìn thấy đây là…',
                style: WonderType.body(
                  color: WonderColors.textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: WonderType.display(
                        color: WonderColors.textStrong,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Chip(
                label: pct != null ? '$confLabel · $pct%' : confLabel,
                isLive: isLive,
              ),
              const SizedBox(height: 22),
              WonderButton(
                label: 'Tạo phim khám phá 🎬',
                onTap: onCreate,
                height: 58,
              ),
              const SizedBox(height: 10),
              _GhostButton(label: 'Không phải — chọn lại', onTap: onReject),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isLive;
  const _Chip({required this.label, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? WonderColors.spark : WonderColors.wonder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLive ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(WonderTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(
            isLive ? PhosphorIconsFill.sparkle : PhosphorIconsBold.magnifyingGlass,
            size: 15,
            color: isLive ? const Color(0xFF8A5A00) : WonderColors.wonder,
          ),
          const SizedBox(width: 6),
          Text(
            isLive ? 'Khám phá vui (AI) · $label' : label,
            style: WonderType.body(
              color: isLive ? const Color(0xFF8A5A00) : WonderColors.wonder,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: WonderColors.wonderSoft, width: 2),
        ),
        child: Text(
          label,
          style: WonderType.display(
            color: WonderColors.textSoft,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Vòng quét nét đứt (gạch chấm) cho vùng ảnh.
class _DashedScanRing extends StatelessWidget {
  final double size;
  const _DashedScanRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DashedRingPainter()),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..color = WonderColors.mint.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dashes = 32;
    const gap = 0.45; // tỉ lệ khe hở trên mỗi cung
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      final start = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        step * (1 - gap),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Fallback extends StatelessWidget {
  final VoidCallback onBack;
  const _Fallback({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return WonderScaffold(
      header: WonderHeader(title: 'Xác nhận', showBack: true, onBack: onBack),
      body: const Center(child: Text('Chưa có dữ liệu để xác nhận.')),
    );
  }
}
