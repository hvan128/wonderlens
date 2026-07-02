import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/ui.dart';
import '../widgets/dev_panel.dart';

/// Màn chào: mascot Tia trong vầng hào quang dẫn dắt + 1 nút bắt đầu khám phá.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WonderBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const _HeroBadge(),
                const SizedBox(height: 28),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Cử chỉ ẩn: nhấn giữ logo để mở Dev panel (Mock ↔ API thật).
                  onLongPress: () => showDevPanel(context),
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: <Color>[
                        WonderColors.violet,
                        WonderColors.wonder,
                        WonderColors.grape,
                      ],
                    ).createShader(rect),
                    child: Text(
                      'WonderLens',
                      style: WonderType.display(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: WonderTokens.durSlow).slideY(
                      begin: 0.3,
                      end: 0,
                      curve: WonderTokens.curveStandard,
                    ),
                const SizedBox(height: 14),
                Text(
                  'Chĩa máy ảnh vào một đồ vật rồi quét nhé!\n'
                  'Mình sẽ kể cho bạn nghe nó được làm ra như thế nào.',
                  textAlign: TextAlign.center,
                  style: WonderType.body(
                    color: WonderColors.textSoft,
                    fontSize: 17,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate(delay: 120.ms).fadeIn(duration: WonderTokens.durSlow),
                const SizedBox(height: 40),
                WonderButton(
                  label: 'Bắt đầu khám phá',
                  icon: PhosphorIconsBold.camera,
                  trailingIcon: PhosphorIconsBold.arrowRight,
                  onTap: () => context.go('/camera'),
                ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.4, end: 0),
                const SizedBox(height: 6),
                WonderTextButton(
                  label: 'Bộ sưu tập của tôi',
                  onTap: () => context.go('/collection'),
                ).animate(delay: 360.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: WonderGradients.badge,
        boxShadow: WonderShadows.glow(WonderColors.wonder, opacity: 0.5),
      ),
      child: const Center(
        child: TiaMascot(size: 92, tone: TiaTone.light),
      ),
    );

    return SizedBox(
      width: 180,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          badge
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 2600.ms, curve: Curves.easeInOut),
          Positioned(
            top: 6,
            right: 16,
            child: const PhosphorIcon(PhosphorIconsFill.sparkle,
                    size: 26, color: WonderColors.sunny)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.7, end: 1.1, duration: 1400.ms)
                .fadeIn(),
          ),
          Positioned(
            bottom: 10,
            left: 18,
            child: const PhosphorIcon(PhosphorIconsFill.sparkle,
                    size: 18, color: WonderColors.grape)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.1, end: 0.7, duration: 1700.ms)
                .fadeIn(),
          ),
        ],
      ),
    );
  }
}
