import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/journey_args.dart';
import '../models/object_content.dart';
import '../models/scene_emoji.dart';
import '../services/narration_service.dart';
import '../ui/ui.dart';

/// Màn 5 · Trình phát video (MỚI). "Phim AI" được dựng từ các chặng hành trình:
/// mỗi chặng là một cảnh (emoji chủ đề) + phụ đề + lồng tiếng (TTS on-device),
/// có mốc chương theo chặng, watermark, nút Chia sẻ nổi bật. Hoạt động offline,
/// không phụ thuộc file mp4. Bám mockup `.s-video`.
class VideoPlayerScreen extends StatefulWidget {
  final JourneyArgs? args;
  const VideoPlayerScreen({super.key, this.args});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  static const int _secondsPerChapter = 6;

  final _narration = NarrationService();
  late final AnimationController _ctrl;
  late final List<Stage> _stages;
  int _chapter = -1;

  ObjectContent get _content => widget.args!.content;
  int get _n => _stages.isEmpty ? 1 : _stages.length;

  @override
  void initState() {
    super.initState();
    _stages = widget.args?.content.stages ?? const <Stage>[];
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _n * _secondsPerChapter),
    )..addListener(_onTick);
    // Tự phát sau khi vào màn. setState để build chạy lại với isAnimating=true
    // → nút phát ở giữa mờ dần đi (nếu không, nó kẹt nguyên trên cảnh đang chạy).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ctrl.forward());
    });
  }

  void _onTick() {
    if (_ctrl.value >= 1) {
      _ctrl.stop();
      _narration.stop();
      if (mounted) setState(() {});
      return;
    }
    final ch = (_ctrl.value * _n).floor().clamp(0, _n - 1);
    if (ch != _chapter) {
      _chapter = ch;
      if (_ctrl.isAnimating) _speakChapter(ch);
    }
  }

  void _speakChapter(int ch) {
    if (_stages.isEmpty) return;
    final s = _stages[ch];
    _narration.speak('${s.kidText} ${s.funFact ?? ''}'.trim());
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    if (_ctrl.isAnimating) {
      _ctrl.stop();
      _narration.stop();
    } else {
      if (_ctrl.value >= 1) _ctrl.value = 0;
      _ctrl.forward();
      _speakChapter((_ctrl.value * _n).floor().clamp(0, _n - 1));
    }
    setState(() {});
  }

  void _seek(double fraction) {
    _ctrl.value = fraction.clamp(0.0, 0.999);
    _narration.stop();
    setState(() {});
  }

  void _seekToChapter(int i) {
    // Nhảy tới chương, tiếp tục phát và đọc chương đó. Gán _chapter để _onTick
    // không đọc lại lần nữa ở tick kế tiếp.
    _ctrl.value = (i / _n).clamp(0.0, 0.999);
    _chapter = i;
    _narration.stop();
    _ctrl.forward();
    _speakChapter(i);
    setState(() {});
  }

  void _replay() {
    _ctrl
      ..value = 0
      ..forward();
    _speakChapter(0);
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _narration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    if (a == null) {
      return Scaffold(
        backgroundColor: WonderColors.ink,
        body: Center(
          child: WonderButton(
            label: 'Về khám phá',
            expand: false,
            onTap: () => context.go('/camera'),
          ),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final stageH = (size.height * 0.42).clamp(260.0, 380.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0A26),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(
              title: '${_content.emoji} ${_content.name}',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/camera'),
              onMore: () => context.push('/timeline', extra: _content),
            ),
            _Stage(
              height: stageH,
              stages: _stages,
              fallbackEmoji: _content.emoji,
              controller: _ctrl,
              chapterCount: _n,
              playing: _ctrl.isAnimating,
              onToggle: _togglePlay,
            ),
            Expanded(
              child: _Controls(
                controller: _ctrl,
                stages: _stages,
                fallbackEmoji: _content.emoji,
                chapterCount: _n,
                onSeek: _seek,
                onSeekChapter: _seekToChapter,
                onShare: () => context.push('/share', extra: a),
                onSave: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                      content: Text('Đã lưu phim vào bộ sưu tập của bé! 🎬'),
                      behavior: SnackBarBehavior.floating,
                    ));
                },
                onReplay: _replay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMore;
  const _TopBar({required this.title, required this.onBack, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: <Widget>[
          _IconBtn(icon: PhosphorIconsBold.arrowLeft, onTap: onBack, tooltip: 'Quay lại'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WonderType.display(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _IconBtn(icon: PhosphorIconsBold.dotsThree, onTap: onMore, tooltip: 'Xem từng chặng'),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _IconBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: tooltip,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(child: PhosphorIcon(icon, size: 18, color: Colors.white)),
      ),
    );
  }
}

/// Sân khấu phim: nền tím, nhãn AI, sparkle, cảnh emoji, phụ đề, watermark, nút phát.
class _Stage extends StatelessWidget {
  final double height;
  final List<Stage> stages;
  final String fallbackEmoji;
  final AnimationController controller;
  final int chapterCount;
  final bool playing;
  final VoidCallback onToggle;

  const _Stage({
    required this.height,
    required this.stages,
    required this.fallbackEmoji,
    required this.controller,
    required this.chapterCount,
    required this.playing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRect(
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.24),
                      radius: 0.85,
                      colors: <Color>[Color(0xFF4A3A8F), Color(0xFF170F33)],
                      stops: <double>[0.0, 0.78],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 40, top: 56, child: _Twinkle('✦', 0)),
              const Positioned(right: 42, top: 110, child: _Twinkle('✧', 800)),
              const Positioned(left: 60, bottom: 92, child: _Twinkle('✦', 1400)),
              // Cảnh emoji + phụ đề đổi theo chương.
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final ch = (controller.value * chapterCount)
                      .floor()
                      .clamp(0, chapterCount - 1);
                  final emoji = stages.isEmpty
                      ? fallbackEmoji
                      : sceneEmoji(stages[ch], fallbackEmoji);
                  final subtitle = stages.isEmpty
                      ? 'Cùng Tia khám phá nhé!'
                      : stages[ch].kidText;
                  return Stack(
                    children: <Widget>[
                      Center(
                        child: Text(
                          emoji,
                          key: ValueKey<String>('scene_$ch'),
                          style: const TextStyle(
                            fontSize: 116,
                            shadows: <Shadow>[Shadow(color: Colors.black54, blurRadius: 22)],
                          ),
                        )
                            .animate(key: ValueKey<int>(ch))
                            .fadeIn(duration: 350.ms)
                            .scaleXY(begin: 0.86, end: 1, curve: WonderTokens.curveStandard),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 34,
                        child: Text(
                          '“$subtitle”',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: WonderType.body(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ).copyWith(
                            shadows: const <Shadow>[
                              Shadow(color: Colors.black, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Nhãn AI.
              Positioned(
                left: 16,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: WonderColors.spark.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '✨ Phim AI',
                    style: WonderType.body(
                      color: WonderColors.onSpark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              // Watermark.
              Positioned(
                right: 14,
                bottom: 12,
                child: Text(
                  '✨ WonderLens',
                  style: WonderType.display(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Nút phát/tạm dừng giữa sân khấu.
              Center(
                child: Pressable(
                  onTap: onToggle,
                  semanticLabel: playing ? 'Tạm dừng' : 'Phát',
                  child: AnimatedOpacity(
                    opacity: playing ? 0.0 : 1.0,
                    duration: WonderTokens.durBase,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.92),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Colors.black45, blurRadius: 26),
                        ],
                      ),
                      child: const Center(
                        child: PhosphorIcon(
                          PhosphorIconsFill.play,
                          size: 30,
                          color: WonderColors.wonder,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Twinkle extends StatelessWidget {
  final String char;
  final int delayMs;
  const _Twinkle(this.char, this.delayMs);

  @override
  Widget build(BuildContext context) {
    return Text(
      char,
      style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.85)),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delayMs.ms)
        .scaleXY(begin: 0.8, end: 1.35, duration: 2200.ms, curve: Curves.easeInOut)
        .fadeIn();
  }
}

/// Vùng điều khiển: thanh tua + mốc chương + thời gian + chip chương + hành động.
class _Controls extends StatelessWidget {
  final AnimationController controller;
  final List<Stage> stages;
  final String fallbackEmoji;
  final int chapterCount;
  final ValueChanged<double> onSeek;
  final ValueChanged<int> onSeekChapter;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onReplay;

  const _Controls({
    required this.controller,
    required this.stages,
    required this.fallbackEmoji,
    required this.chapterCount,
    required this.onSeek,
    required this.onSeekChapter,
    required this.onShare,
    required this.onSave,
    required this.onReplay,
  });

  String _fmt(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = controller.duration!.inSeconds.toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: <Widget>[
          // Thanh tua + mốc chương.
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => onSeek(d.localPosition.dx / w),
                    onHorizontalDragUpdate: (d) => onSeek(d.localPosition.dx / w),
                    child: SizedBox(
                      height: 18,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: controller.value.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[WonderColors.spark, WonderColors.coral],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Chấm mốc chương.
                          for (var i = 1; i < chapterCount; i++)
                            Positioned(
                              left: (i / chapterCount) * w - 4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.45),
                                  border: Border.all(color: const Color(0xFF0E0A26), width: 2),
                                ),
                              ),
                            ),
                          // Núm tua.
                          Positioned(
                            left: (controller.value.clamp(0.0, 1.0) * w - 7.5)
                                .clamp(0.0, w - 15),
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 9),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(_fmt(controller.value * total), style: _timeStyle),
                Text(_fmt(total), style: _timeStyle),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Chip chương.
          if (stages.isNotEmpty)
            SizedBox(
              height: 34,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final cur = (controller.value * chapterCount)
                      .floor()
                      .clamp(0, chapterCount - 1);
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _ChapterChip(
                      emoji: sceneEmoji(stages[i], fallbackEmoji),
                      label: stages[i].chapter ?? sceneLabel(stages[i]),
                      active: i == cur,
                      onTap: () => onSeekChapter(i),
                    ),
                  );
                },
              ),
            ),
          const Spacer(),
          // Hành động.
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: WonderButton(
                    label: 'Chia sẻ phim',
                    icon: PhosphorIconsBold.shareNetwork,
                    gradient: WonderGradients.sunny,
                    foreground: WonderColors.onSpark,
                    glowColor: WonderColors.spark,
                    onTap: onShare,
                  ),
                ),
                const SizedBox(width: 10),
                _MiniAction(icon: PhosphorIconsBold.downloadSimple, onTap: onSave, tooltip: 'Lưu phim'),
                const SizedBox(width: 10),
                _MiniAction(icon: PhosphorIconsBold.repeat, onTap: onReplay, tooltip: 'Xem lại'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final TextStyle _timeStyle = WonderType.body(
    color: const Color(0xFFB9B0D9),
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
  );
}

class _ChapterChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChapterChip({
    required this.emoji,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? WonderColors.wonder : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: WonderType.body(
                color: active ? Colors.white : const Color(0xFFCFC7EC),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _MiniAction({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: tooltip,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Center(child: PhosphorIcon(icon, size: 21, color: Colors.white)),
      ),
    );
  }
}
