import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/hero_catalog.dart';
import '../models/journey_args.dart';
import '../ui/ui.dart';

/// Màn 7 · Mở huy hiệu. Phần thưởng sau mỗi phim: confetti + huy chương + tiến độ.
/// Bám mockup `.s-badge`.
class BadgeScreen extends StatefulWidget {
  final JourneyArgs? args;
  const BadgeScreen({super.key, this.args});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final repo = CollectionRepository();
    final count = repo.discoveredIds().length;
    final total = heroCatalog.length;

    final content = a?.content;
    final emoji = content?.emoji ?? '🏅';
    final name = content?.name ?? 'Huy hiệu';
    final material = a?.result?.newBadge ??
        (content != null ? heroById(content.id)?.material : null) ??
        content?.materialBadge ??
        '';
    final isNewBadge = a?.result?.newBadge != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WonderGradients.magic),
        child: Stack(
          children: <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      isNewBadge ? '🎉 Huy hiệu mới!' : '🎬 Phim mới của bé!',
                      style: WonderType.display(
                        color: WonderColors.spark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(duration: WonderTokens.durBase),
                    const SizedBox(height: 22),
                    _Medal(emoji: emoji)
                        .animate()
                        .scaleXY(
                          begin: 0.6,
                          end: 1,
                          duration: WonderTokens.durSlow,
                          curve: WonderTokens.curveSpring,
                        )
                        .fadeIn(),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: WonderType.display(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),
                    if (material.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        'Nhà sưu tầm $material 🧪',
                        style: WonderType.body(
                          color: const Color(0xFFEBE3FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate(delay: 220.ms).fadeIn(),
                    ],
                    const SizedBox(height: 26),
                    _Progress(count: count, total: total)
                        .animate(delay: 280.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const Spacer(),
                    WonderButton(
                      label: 'Khám phá tiếp 🔍',
                      gradient: WonderGradients.sunny,
                      foreground: WonderColors.onSpark,
                      glowColor: WonderColors.spark,
                      height: 58,
                      onTap: () => context.go('/camera'),
                    ).animate(delay: 340.ms).fadeIn().slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 10),
                    _GhostButton(
                      label: 'Xem bộ sưu tập',
                      onTap: () => context.go('/collection'),
                    ).animate(delay: 420.ms).fadeIn(),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 24,
                maxBlastForce: 14,
                minBlastForce: 7,
                emissionFrequency: 0.05,
                colors: const <Color>[
                  WonderColors.spark,
                  WonderColors.coral,
                  WonderColors.mint,
                  WonderColors.sky,
                  WonderColors.wonder,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Huy chương: vành conic vàng xoay + đĩa kem + emoji + sao nhấp nháy.
class _Medal extends StatelessWidget {
  final String emoji;
  const _Medal({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: <Color>[
                  WonderColors.spark,
                  Color(0xFFFFE9A8),
                  WonderColors.spark,
                  Color(0xFFFFD66B),
                  WonderColors.spark,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: WonderColors.spark.withValues(alpha: 0.6),
                  blurRadius: 50,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 14.seconds),
          Container(
            width: 142,
            height: 142,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFFFF6DD), Color(0xFFFFE6A6)],
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 72,
                  shadows: <Shadow>[Shadow(color: Color(0x55A06E00), blurRadius: 6)],
                ),
              ),
            ),
          ),
          const Positioned(top: -4, right: 18, child: _Star(ms: 2000)),
          const Positioned(bottom: 6, left: -2, child: _Star(ms: 2000, delayMs: 700)),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final int ms;
  final int delayMs;
  const _Star({required this.ms, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return const Text('⭐', style: TextStyle(fontSize: 22))
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delayMs.ms)
        .scaleXY(begin: 0.8, end: 1.3, duration: ms.ms, curve: Curves.easeInOut)
        .fadeIn();
  }
}

class _Progress extends StatelessWidget {
  final int count;
  final int total;
  const _Progress({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Bộ sưu tập',
                style: WonderType.body(
                  color: const Color(0xFFEBE3FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$count / $total',
                style: WonderType.body(
                  color: const Color(0xFFEBE3FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          WonderProgressBar(value: total == 0 ? 0 : count / total, onDark: true),
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
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
        ),
        child: Text(
          label,
          style: WonderType.display(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
