import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:animations/animations.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../models/object_content.dart';
import '../services/journey_image_service.dart';
import '../services/journey_warmup.dart';
import '../services/narration_service.dart';
import '../ui/ui.dart';
import '../widgets/journey_video.dart';
import '../widgets/object_avatar.dart';
import '../widgets/share_sheet.dart';

/// Timeline kiểu CapWords: mỗi chặng là **một trạng thái full màn** (ảnh nền +
/// chữ). Giọng kể đọc chặng hiện tại; **đọc xong tự đẩy chặng tiếp lên** bằng
/// chuyển cảnh shared-axis. Chạm bất kỳ = bỏ qua ngay tới chặng sau. Offline-safe
/// (giọng máy fallback) + tôn trọng Giảm chuyển động.
///
/// Vòng lặp auto-advance dùng **token epoch đơn điệu** để huỷ đúng khi chạm/rời
/// màn (speak() trả về giống hệt lúc đọc xong tự nhiên và lúc bị stop()), có
/// **sàn dwell** (đọc quá nhanh vẫn giữ đủ lâu để kịp nhìn) và **trần dwell**
/// (audio kẹt / không có engine TTS vẫn đi tiếp — cũng là chốt để test pump).
class TimelineScreen extends StatefulWidget {
  final ObjectContent? content;

  /// Seam test: tiêm NarrationService giả để pump nhanh & tất định (mặc định
  /// tạo mới trong initState).
  final NarrationService? narration;

  const TimelineScreen({super.key, this.content, this.narration});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

enum _Kind { cover, stage, outro }

class _Step {
  final _Kind kind;
  final int stageIndex; // chỉ dùng cho stage
  final String speech;
  const _Step(this.kind, this.stageIndex, this.speech);
}

class _TimelineScreenState extends State<TimelineScreen> {
  late final NarrationService _narration;
  late final ConfettiController _confetti;

  List<_Step> _steps = const <_Step>[];
  int _index = 0;
  bool _reverse = false;
  bool _narrating = false;
  int _epoch = 0; // token huỷ đơn điệu
  Timer? _dwell; // timer chờ (huỷ được để không treo khi chạm/rời màn)

  Map<int, File> _stageImages = const {};
  bool _imagesLoading = false;

  bool _completed = false;
  DiscoveryResult? _result;
  final _videoKey = GlobalKey<JourneyVideoState>();

  static const Duration _minDwell = Duration(milliseconds: 2200);
  static const Duration _maxDwell = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _narration = widget.narration ?? NarrationService();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final c = widget.content;
    if (c != null) {
      _steps = _buildSteps(c);
      if (c.source == 'live' && JourneyImageService.available) {
        _loadStageImages(c);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _advanceTo(0);
      });
    }
  }

  List<_Step> _buildSteps(ObjectContent c) {
    final steps = <_Step>[];
    // Dùng helper CHUNG với warm-up để text khớp đúng cache audio pre-sinh.
    final cover = journeyCoverSpeech(c);
    if (cover != null) steps.add(_Step(_Kind.cover, -1, cover));
    for (var i = 0; i < c.stages.length; i++) {
      steps.add(_Step(_Kind.stage, i, journeyStageSpeech(c.stages[i])));
    }
    steps.add(const _Step(_Kind.outro, -1, ''));
    return steps;
  }

  Future<void> _loadStageImages(ObjectContent c) async {
    setState(() => _imagesLoading = true);
    // Đọc từ coordinator: nếu warm-up đã bắt đầu (lúc chụp) thì gần như tức thì.
    final imgs = await JourneyWarmup.instance.images(c);
    if (!mounted) return;
    setState(() {
      _stageImages = imgs;
      _imagesLoading = false;
    });
  }

  @override
  void dispose() {
    _epoch++; // huỷ vòng lặp đang chạy
    _dwell?.cancel();
    _confetti.dispose();
    _narration.dispose();
    super.dispose();
  }

  bool get _isOutro => _steps.isNotEmpty && _steps[_index].kind == _Kind.outro;
  int get _stageCount => widget.content?.stages.length ?? 0;

  /// Chuyển tới bước [target]: bump epoch (huỷ vòng cũ) + stop TTS (mở khoá
  /// speak() đang treo), đọc bước mới, chờ tối thiểu, rồi tự đẩy sang bước kế.
  Future<void> _advanceTo(int target) async {
    if (!mounted || _steps.isEmpty) return;
    _dwell?.cancel(); // huỷ chờ của vòng cũ (không để timer treo)
    final i = target.clamp(0, _steps.length - 1);
    final myEpoch = ++_epoch;
    await _narration.stop();
    if (!mounted || myEpoch != _epoch) return;
    setState(() {
      _reverse = i < _index;
      _index = i;
      _narrating = false;
    });
    final step = _steps[i];
    if (step.kind == _Kind.outro) {
      _complete();
      return;
    }
    setState(() => _narrating = true);
    final sw = Stopwatch()..start();
    await _speakGuarded(step.speech);
    if (!mounted || myEpoch != _epoch) return;
    setState(() => _narrating = false);
    final remain = _minDwell - sw.elapsed;
    if (remain > Duration.zero) {
      await _wait(remain); // sàn dwell (huỷ được)
      if (!mounted || myEpoch != _epoch) return;
    }
    _advanceTo(i + 1);
  }

  /// Chờ [d] bằng Timer huỷ được (lưu vào [_dwell]) để chạm/rời màn không treo.
  Future<void> _wait(Duration d) {
    final gate = Completer<void>();
    _dwell?.cancel();
    _dwell = Timer(d, () {
      if (!gate.isCompleted) gate.complete();
    });
    return gate.future;
  }

  /// Đọc, đua với trần [_maxDwell] để audio kẹt / không có engine TTS vẫn đi tiếp.
  /// Timer trần được HUỶ khi đọc xong để không để lại timer treo.
  Future<void> _speakGuarded(String text) async {
    final ceiling = Completer<void>();
    final timer = Timer(_maxDwell, () {
      if (!ceiling.isCompleted) ceiling.complete();
    });
    await Future.any<void>(<Future<void>>[
      _narration.speak(text).whenComplete(() {
        if (!ceiling.isCompleted) ceiling.complete();
      }),
      ceiling.future,
    ]);
    timer.cancel();
  }

  void _onTapAdvance() => _advanceTo(_index + 1);
  void _prev() => _advanceTo(_index - 1);
  void _replay() => _advanceTo(_index);

  void _exit() {
    _epoch++;
    _narration.stop();
    context.canPop() ? context.pop() : context.go('/camera');
  }

  void _complete() {
    if (_completed) return;
    final c = widget.content;
    if (c == null) return;
    final result = CollectionRepository().record(c);
    setState(() {
      _completed = true;
      _result = result;
      _narrating = false;
    });
    if (result.isNewObject) {
      if (!reduceMotionOf(context)) _confetti.play();
      WonderHaptics.success();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _videoKey.currentState?.autoGenerate();
    });
  }

  int _activeStageForDots() {
    final step = _steps[_index];
    if (step.kind == _Kind.stage) return step.stageIndex;
    if (step.kind == _Kind.outro) return _stageCount - 1;
    return -1; // cover: chưa có chấm nào active
  }

  Widget _viewForIndex(ObjectContent c, int i) {
    final step = _steps[i];
    switch (step.kind) {
      case _Kind.cover:
        return _CoverView(content: c);
      case _Kind.stage:
        final s = c.stages[step.stageIndex];
        final img = resolveStageImage(
          illustration: s.illustration,
          liveFile: _stageImages[step.stageIndex],
        );
        return _StageView(
          stage: s,
          image: img,
          imageLoading: _imagesLoading && c.source == 'live' && img == null,
          reduce: reduceMotionOf(context),
        );
      case _Kind.outro:
        return _OutroView(
          content: c,
          result: _result,
          videoKey: _videoKey,
          onScanMore: () => context.go('/camera'),
          onShare: () => showDiscoveryShareSheet(context, c),
          onCollection: () => context.go('/collection'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    if (c == null) {
      return WonderScaffold(
        header: WonderHeader(
          title: 'Hành trình',
          showBack: true,
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/camera'),
        ),
        body: const Center(
          child: Text('Chưa có manh mối hành trình nào để mở.'),
        ),
      );
    }
    final reduce = reduceMotionOf(context);

    return Scaffold(
      backgroundColor: WonderColors.ink,
      body: Stack(
        children: <Widget>[
          // 1. Bước hiện tại + chuyển cảnh (crossfade khi Giảm chuyển động).
          Positioned.fill(
            child: PageTransitionSwitcher(
              duration: WonderTokens.durBase,
              reverse: _reverse,
              transitionBuilder: (child, primary, secondary) => reduce
                  ? FadeTransition(opacity: primary, child: child)
                  : SharedAxisTransition(
                      animation: primary,
                      secondaryAnimation: secondary,
                      transitionType: SharedAxisTransitionType.vertical,
                      fillColor: Colors.transparent,
                      child: child,
                    ),
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: _viewForIndex(c, _index),
              ),
            ),
          ),
          // 2. Chạm bất kỳ = đi tiếp (tắt trên outro để nút outro nhận chạm).
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _isOutro,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapAdvance,
              ),
            ),
          ),
          // 3. Trên: thoát + chấm tiến độ.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: <Widget>[
                    GlassIconButton(
                      icon: PhosphorIconsBold.arrowLeft,
                      tone: GlassTone.dark,
                      size: 44,
                      onTap: _exit,
                      semanticLabel: 'Thoát hành trình',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProgressDots(
                        count: _stageCount,
                        activeStage: _activeStageForDots(),
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
              ),
            ),
          ),
          // 5. Prev + nghe lại (giữa-phải, tránh scrim đáy). Trên lớp chạm.
          if (!_isOutro)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_index > 0)
                      _MiniButton(
                        icon: PhosphorIconsBold.arrowUp,
                        semantic: 'Chặng trước',
                        onTap: _prev,
                      ),
                    const SizedBox(height: 12),
                    _MiniButton(
                      icon: PhosphorIconsFill.speakerSimpleHigh,
                      semantic: 'Nghe lại',
                      onTap: _replay,
                    ),
                  ],
                ),
              ),
            ),
          // 5b. Chỉ báo "Đang kể" nhỏ, canh giữa dưới chấm tiến độ.
          if (!_isOutro && _narrating)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(child: const _ListeningPill()),
                ),
              ),
            ),
          // 6. Confetti.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              maxBlastForce: 12,
              minBlastForce: 6,
              emissionFrequency: 0.05,
              colors: const <Color>[
                WonderColors.teal,
                WonderColors.sky,
                WonderColors.grape,
                WonderColors.sunny,
                WonderColors.mint,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Cover: giới thiệu vật trước khi vào hành trình.
class _CoverView extends StatelessWidget {
  final ObjectContent content;
  const _CoverView({required this.content});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: WonderGradients.canvas),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ObjectAvatar(
                  objectId: content.id,
                  emoji: content.emoji,
                  diameter: 128,
                  emojiSize: 64,
                  glowOpacity: 0.5,
                  hero: true,
                ),
                const SizedBox(height: 22),
                Text(
                  content.name,
                  textAlign: TextAlign.center,
                  style: WonderType.display.copyWith(
                    color: WonderColors.textStrong,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (content.materialBadge.isNotEmpty)
                      WonderChip(
                        label: content.materialBadge,
                        icon: PhosphorIconsBold.flask,
                        tone: GlassTone.light,
                      ),
                    if (content.source == 'live')
                      WonderChip(
                        label: 'AI kể chuyện vui',
                        icon: PhosphorIconsFill.sparkle,
                        color: WonderColors.grape,
                        tone: GlassTone.light,
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'Chạm để bắt đầu hành trình',
                  style: WonderType.label.copyWith(color: WonderColors.textSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Một chặng full màn: ảnh nền tràn viền + scrim tối + thẻ kính chứa chữ.
class _StageView extends StatelessWidget {
  final Stage stage;
  final ImageProvider? image;
  final bool imageLoading;
  final bool reduce;

  const _StageView({
    required this.stage,
    required this.image,
    required this.imageLoading,
    required this.reduce,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Nền mờ ambient lấy màu từ chính ảnh chặng → chiều sâu, không "phẳng".
        _AmbientBackground(image: image, reduce: reduce),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 44), // chừa cho back + chấm tiến độ
                // Ảnh VUÔNG hiện TRỌN (ảnh gốc 1:1) trong khung glow — không crop.
                Expanded(
                  child: Center(
                    child: _ImageCard(
                      image: image,
                      loading: imageLoading,
                      reduce: reduce,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _StoryScrim(stage: stage, reduce: reduce),
                const SizedBox(height: 52), // chừa cho nút prev / nghe lại
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nền mờ theo màu ảnh chặng (ảnh cover + blur mạnh + phủ tối) — tạo chiều sâu.
class _AmbientBackground extends StatelessWidget {
  final ImageProvider? image;
  final bool reduce;
  const _AmbientBackground({required this.image, required this.reduce});

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[WonderColors.inkSoft, WonderColors.ink],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 42, sigmaY: 42),
          child: Image(
            image: image!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) => const ColoredBox(color: WonderColors.ink),
          ),
        ),
        // Phủ tối để ảnh nét + thẻ chữ nổi bật.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xB30B1220), Color(0xE60B1220)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Khung ảnh chặng: vuông, bo góc, viền sáng + glow — hiện trọn ảnh gốc 1:1.
class _ImageCard extends StatelessWidget {
  final ImageProvider? image;
  final bool loading;
  final bool reduce;
  const _ImageCard({
    required this.image,
    required this.loading,
    required this.reduce,
  });

  @override
  Widget build(BuildContext context) {
    final card = AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: WonderColors.inkSoft,
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: WonderColors.teal.withValues(alpha: 0.34),
              blurRadius: 44,
              spreadRadius: -12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: _inner(),
        ),
      ),
    );
    if (reduce) return card;
    return card
        .animate()
        .fadeIn(duration: WonderTokens.durBase)
        .scaleXY(begin: 0.94, end: 1, curve: WonderTokens.curveEmphasized);
  }

  Widget _inner() {
    if (image == null) {
      final box = ColoredBox(
        color: WonderColors.teal.withValues(alpha: 0.14),
        child: const Center(
          child: PhosphorIcon(
            PhosphorIconsFill.image,
            size: 40,
            color: Colors.white38,
          ),
        ),
      );
      if (!loading || reduce) return box;
      return box
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.16));
    }
    return Image(
      image: image!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSync) {
        if (wasSync || frame != null) {
          return child.animate().fadeIn(duration: WonderTokens.durBase);
        }
        return ColoredBox(color: WonderColors.inkSoft.withValues(alpha: 0.6));
      },
      errorBuilder: (_, _, _) => const ColoredBox(color: WonderColors.inkSoft),
    );
  }
}

/// Thẻ kính tối chứa tiêu đề + lời kể + fun-fact của chặng.
class _StoryScrim extends StatelessWidget {
  final Stage stage;
  final bool reduce;
  const _StoryScrim({required this.stage, required this.reduce});

  Widget _anim(Widget w, int delayMs) {
    if (reduce) return w;
    return w
        .animate(delay: delayMs.ms)
        .fadeIn(duration: WonderTokens.durBase)
        .slideY(begin: 0.14, end: 0, curve: WonderTokens.curveStandard);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.32;
    return GlassSurface(
      tone: GlassTone.dark,
      radius: WonderTokens.radiusLg,
      padding: const EdgeInsets.all(WonderTokens.space16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _anim(
                Text(
                  stage.title,
                  style: WonderType.heading.copyWith(
                    color: Colors.white,
                    fontSize: 19,
                  ),
                ),
                80,
              ),
              const SizedBox(height: 8),
              _anim(
                Text(
                  stage.kidText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15.5,
                    height: 1.42,
                  ),
                ),
                160,
              ),
              if (stage.funFact != null && stage.funFact!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _anim(
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: WonderColors.sunny.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
                      border: Border.all(
                        color: WonderColors.sunny.withValues(alpha: 0.42),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const PhosphorIcon(
                          PhosphorIconsFill.lightbulb,
                          size: 17,
                          color: WonderColors.sunny,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stage.funFact!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  240,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Outro: phần thưởng + phim hành trình + hành động tiếp theo.
class _OutroView extends StatelessWidget {
  final ObjectContent content;
  final DiscoveryResult? result;
  final GlobalKey<JourneyVideoState> videoKey;
  final VoidCallback onScanMore;
  final VoidCallback onShare;
  final VoidCallback onCollection;

  const _OutroView({
    required this.content,
    required this.result,
    required this.videoKey,
    required this.onScanMore,
    required this.onShare,
    required this.onCollection,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    final view = WonderBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (result?.newBadge != null) ...<Widget>[
                _BadgeBanner(material: result!.newBadge!),
                const SizedBox(height: 14),
              ],
              JourneyVideo(key: videoKey, content: content),
              const SizedBox(height: 16),
              GlassSurface(
                tone: GlassTone.light,
                tint: WonderColors.mint,
                tintOpacity: 0.22,
                padding: const EdgeInsets.all(WonderTokens.space16),
                shadows: WonderShadows.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const PhosphorIcon(
                          PhosphorIconsFill.trophy,
                          size: 24,
                          color: WonderColors.sunnyDeep,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Bé đã xem hết hành trình!',
                            textAlign: TextAlign.center,
                            style: WonderType.heading.copyWith(
                              color: WonderColors.textStrong,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    WonderButton(
                      label: 'Soi vật khác',
                      icon: PhosphorIconsBold.magnifyingGlass,
                      onTap: onScanMore,
                    ),
                    const SizedBox(height: 10),
                    WonderButton(
                      label: 'Khoe khám phá',
                      icon: PhosphorIconsBold.shareNetwork,
                      gradient: WonderGradients.secondary,
                      onTap: onShare,
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: WonderTextButton(
                        label: 'Mở rương khám phá',
                        onTap: onCollection,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return reduce ? view : view.animate().fadeIn(duration: WonderTokens.durBase);
  }
}

/// ---------------------------------------------------------------------------
/// Overlay nhỏ.
class _ProgressDots extends StatelessWidget {
  final int count;
  final int activeStage;
  const _ProgressDots({required this.count, required this.activeStage});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: WonderTokens.durBase,
            curve: WonderTokens.curveStandard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == activeStage ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= activeStage
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _ListeningPill extends StatelessWidget {
  const _ListeningPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WonderColors.grape.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PhosphorIcon(
            PhosphorIconsFill.speakerSimpleHigh,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'Đang kể',
            style: WonderType.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String semantic;
  final VoidCallback onTap;
  const _MiniButton({
    required this.icon,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semantic,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: PhosphorIcon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

/// Băng huy hiệu vật liệu mới (giữ nguyên style cũ).
class _BadgeBanner extends StatelessWidget {
  final String material;
  const _BadgeBanner({required this.material});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      tint: WonderColors.sunny,
      tintOpacity: 0.32,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          const PhosphorIcon(
            PhosphorIconsFill.medal,
            size: 30,
            color: WonderColors.sunnyDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mở khóa huy hiệu: Vật liệu $material!',
              style: const TextStyle(
                color: WonderColors.textStrong,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
