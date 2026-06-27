import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../models/journey_args.dart';
import '../models/object_content.dart';
import '../models/scene_emoji.dart';
import '../ui/ui.dart';

/// Màn 4 · Tia tạo phim (MỚI). Màn chờ có chủ đích: mascot "dựng phim", tiến độ
/// theo từng chặng, gắn nhãn AI. Vật hero gần như tức thì nên đây là pre-roll
/// tạo cảm giác mong chờ; tới cuối thì chuyển sang Trình phát. Bám `.s-gen`.
class GeneratingScreen extends StatefulWidget {
  final JourneyArgs? args;
  const GeneratingScreen({super.key, this.args});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  JourneyArgs? _args;

  @override
  void initState() {
    super.initState();
    final a = widget.args;
    if (a != null) {
      // Ghi nhận khám phá ngay khi bắt đầu "dựng phim".
      final result = CollectionRepository().record(a.content.id);
      _args = a.withResult(result);
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goToVideo();
      });
    _ctrl.forward();
  }

  void _goToVideo() {
    if (!mounted) return;
    final a = _args;
    if (a == null) {
      context.go('/camera');
    } else {
      context.pushReplacement('/video', extra: a);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _args;
    final stages = a?.content.stages ?? const <Stage>[];
    final fallbackEmoji = a?.content.emoji ?? '✨';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WonderGradients.magic),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final p = _ctrl.value;
              final pct = (p * 100).round();
              final cur = stages.isEmpty
                  ? 0
                  : (p * stages.length).floor().clamp(0, stages.length - 1);
              final status = stages.isEmpty
                  ? 'Đang dựng những thước phim đầu tiên…'
                  : 'Đang dựng cảnh “${sceneEmoji(stages[cur], fallbackEmoji)} '
                      '${sceneLabel(stages[cur])}”…';
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 2),
                    const _ConjureStage(),
                    const SizedBox(height: 30),
                    Text(
                      'Tia đang vẽ phim cho bạn…',
                      textAlign: TextAlign.center,
                      style: WonderType.display(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WonderType.body(
                        color: const Color(0xFFEBE3FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 222,
                      child: WonderProgressBar(value: p, onDark: true, animate: Duration.zero),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$pct%',
                      style: WonderType.body(
                        color: WonderColors.spark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (stages.isNotEmpty)
                      _ChapterStrip(
                        stages: stages,
                        fallbackEmoji: fallbackEmoji,
                        current: cur,
                        progress: p,
                      ),
                    const Spacer(flex: 3),
                    const _Note(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sân khấu "triệu hồi": vòng sweep-gradient xoay + lõi tối + Tia vàng + sparkle.
class _ConjureStage extends StatelessWidget {
  const _ConjureStage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: <Color>[
                  Colors.transparent,
                  WonderColors.spark,
                  Colors.transparent,
                  WonderColors.mint,
                  Colors.transparent,
                ],
                stops: <double>[0.0, 0.18, 0.42, 0.66, 1.0],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 2600.ms),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF140C2E).withValues(alpha: 0.55),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: WonderColors.spark.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
          ),
          const TiaMascot(size: 114, tone: TiaTone.sunny)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -5, end: 5, duration: 3.seconds, curve: Curves.easeInOut),
          const _Spark(emoji: '✨', top: 2, right: 24, ms: 1800),
          const _Spark(emoji: '🎬', bottom: 14, left: 6, ms: 1800, delayMs: 600),
          const _Spark(emoji: '⭐', top: 34, left: -2, ms: 1800, delayMs: 1100),
        ],
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  final String emoji;
  final double? top, bottom, left, right;
  final int ms;
  final int delayMs;
  const _Spark({
    required this.emoji,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.ms,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Text(emoji, style: const TextStyle(fontSize: 18))
          .animate(onPlay: (c) => c.repeat(reverse: true), delay: delayMs.ms)
          .scaleXY(begin: 0.8, end: 1.35, duration: ms.ms, curve: Curves.easeInOut)
          .fadeIn(),
    );
  }
}

/// Dải chương: từng cảnh đã xong (✓), đang dựng (viền vàng), hoặc chờ.
class _ChapterStrip extends StatelessWidget {
  final List<Stage> stages;
  final String fallbackEmoji;
  final int current;
  final double progress;

  const _ChapterStrip({
    required this.stages,
    required this.fallbackEmoji,
    required this.current,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Cuộn ngang + bó chiều cao 64 → không bao giờ tràn dọc dù vật lạ trả về
    // nhiều chặng; tự canh giữa khi đủ chỗ.
    return SizedBox(
      height: 64,
      child: Center(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: stages.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _ChapterBox(
            emoji: sceneEmoji(stages[i], fallbackEmoji),
            label: stages[i].chapter ?? sceneLabel(stages[i]),
            done: i < current || progress >= 1,
            current: i == current && progress < 1,
          ),
        ),
      ),
    );
  }
}

class _ChapterBox extends StatelessWidget {
  final String emoji;
  final String label;
  final bool done;
  final bool current;
  const _ChapterBox({
    required this.emoji,
    required this.label,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: done
            ? WonderColors.mint.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current
              ? WonderColors.spark
              : (done ? WonderColors.mint : Colors.transparent),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            done ? '✓ $label' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: WonderType.body(
              color: const Color(0xFFD7CEF3),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    if (!current) return box;
    return box
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.06, duration: 1.6.seconds, curve: Curves.easeInOut);
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '🧪 Phim tạo bằng AI · vật hero có sẵn nên hiện gần như tức thì',
        textAlign: TextAlign.center,
        style: WonderType.body(
          color: const Color(0xFFC9BEF0),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
