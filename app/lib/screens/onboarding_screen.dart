import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/ui.dart';

/// Màn 1 · Chào mừng. Nền tím kỳ diệu, vài đồ vật trôi nhẹ, mascot Tia có vầng
/// hào quang, wordmark hai tông + một câu dẫn, CTA vàng. Onboarding < 10 giây.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WonderGradients.magic),
        child: Stack(
          children: <Widget>[
            // Đồ vật trôi lơ lửng quanh màn.
            const _Floaty(emoji: '📎', top: 92, left: 30, size: 26, ms: 5000),
            const _Floaty(emoji: '✏️', top: 138, right: 26, size: 30, ms: 6000),
            const _Floaty(emoji: '☕', top: 232, left: 22, size: 24, ms: 5500),
            const _Floaty(emoji: '🔋', top: 206, right: 40, size: 24, ms: 6500),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Spacer(flex: 3),
                    const _HaloMascot(),
                    const SizedBox(height: 26),
                    const _Wordmark()
                        .animate()
                        .fadeIn(duration: WonderTokens.durSlow)
                        .slideY(begin: 0.25, end: 0, curve: WonderTokens.curveStandard),
                    const SizedBox(height: 14),
                    Text(
                      'Chĩa ống kính vào một đồ vật — xem Tia kể chuyện '
                      'bằng phim nhé! 🎬✨',
                      textAlign: TextAlign.center,
                      style: WonderType.body(
                        color: const Color(0xFFEFE9FF),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate(delay: 140.ms).fadeIn(duration: WonderTokens.durSlow),
                    const Spacer(flex: 4),
                    WonderButton(
                      label: 'Bắt đầu khám phá',
                      trailingIcon: PhosphorIconsBold.arrowRight,
                      gradient: WonderGradients.sunny,
                      foreground: WonderColors.onSpark,
                      glowColor: WonderColors.spark,
                      height: 58,
                      onTap: () => context.go('/camera'),
                    )
                        .animate(delay: 260.ms)
                        .fadeIn()
                        .slideY(begin: 0.4, end: 0, curve: WonderTokens.curveStandard),
                    const SizedBox(height: 18),
                    const _Dots(active: 0, count: 3),
                    const SizedBox(height: 6),
                    WonderTextButton(
                      label: 'Bộ sưu tập của tôi',
                      color: Colors.white.withValues(alpha: 0.9),
                      onTap: () => context.go('/collection'),
                    ).animate(delay: 380.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wordmark "Wonder" + "Lens" (Lens vàng tia sáng) bằng Fredoka.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          const TextSpan(text: 'Wonder'),
          TextSpan(
            text: 'Lens',
            style: WonderType.display(color: WonderColors.spark, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: WonderType.display(
        color: Colors.white,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Mascot Tia (thấu kính trắng) trên vầng hào quang vàng nhấp nháy, trôi lên xuống.
class _HaloMascot extends StatelessWidget {
  const _HaloMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 188,
            height: 188,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[Color(0x8CFFC23C), Color(0x00FFC23C)],
                stops: <double>[0.0, 0.66],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.08, duration: 3500.ms, curve: Curves.easeInOut),
          const TiaMascot(size: 138, tone: TiaTone.light)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 2600.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

/// Một emoji đồ vật trôi lơ lửng.
class _Floaty extends StatelessWidget {
  final String emoji;
  final double? top;
  final double? left;
  final double? right;
  final double size;
  final int ms;

  const _Floaty({
    required this.emoji,
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.ms,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: size,
          shadows: const <Shadow>[Shadow(color: Colors.black38, blurRadius: 10)],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -7, end: 7, duration: ms.ms, curve: Curves.easeInOut),
    );
  }
}

/// Chấm trang onboarding — chấm đang hoạt động kéo dài, màu vàng tia sáng.
class _Dots extends StatelessWidget {
  final int active;
  final int count;
  const _Dots({required this.active, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: WonderTokens.durBase,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active
                  ? WonderColors.spark
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}
