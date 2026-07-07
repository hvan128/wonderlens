import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;

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
import '../widgets/object_avatar.dart';
import '../widgets/share_sheet.dart';

/// Hành trình trong **MỘT màn cuộn dọc**: vật (cutout) + tên ở đầu; chặng hiện
/// tại ở **center**; **vuốt lên/xuống** đổi chặng (vẫn **tự đẩy theo audio**).
/// Chặng đã qua **thu nhỏ xếp ngang** phía trên; chặng chưa tới hiện **★** phía
/// dưới. Cuối cùng là phần thưởng. (Tạm dừng phim hành trình.)
///
/// Vòng auto-advance dùng token epoch đơn điệu để huỷ đúng khi vuốt/rời màn
/// (speak() trả về giống hệt lúc đọc xong & lúc bị stop()), có sàn dwell (đọc
/// nhanh vẫn giữ đủ lâu) và trần dwell (audio kẹt vẫn đi tiếp — chốt test pump).
class TimelineScreen extends StatefulWidget {
  final ObjectContent? content;

  /// Seam test: tiêm NarrationService giả để pump nhanh & tất định.
  final NarrationService? narration;

  /// Khi được NHÚNG trong màn camera (same-screen): thoát/soi-vật-khác gọi cái
  /// này thay cho điều hướng router (đóng overlay, quay lại chụp).
  final VoidCallback? onExit;

  const TimelineScreen({
    super.key,
    this.content,
    this.narration,
    this.onExit,
  });

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

class _TimelineScreenState extends State<TimelineScreen>
    with TickerProviderStateMixin {
  late final NarrationService _narration;
  late final ConfettiController _confetti;

  List<_Step> _steps = const <_Step>[];
  int _index = 0;
  bool _reverse = false;
  bool _narrating = false;
  int _epoch = 0;
  Timer? _dwell;

  Map<int, File> _stageImages = const {};
  bool _imagesLoading = false;

  // Đo vị trí để BAY ảnh chặng vào đúng node trên thanh chặng.
  final GlobalKey _carouselAreaKey = GlobalKey();
  List<GlobalKey> _nodeKeys = const <GlobalKey>[];

  bool _completed = false;
  DiscoveryResult? _result;

  static const Duration _minDwell = Duration(milliseconds: 2200);
  static const Duration _maxDwell = Duration(seconds: 45);
  static const double _headerCompact = 96; // chỗ chừa cho header thu gọn

  @override
  void initState() {
    super.initState();
    _narration = widget.narration ?? NarrationService();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final c = widget.content;
    if (c != null) {
      _steps = _buildSteps(c);
      _nodeKeys =
          List<GlobalKey>.generate(c.stages.length, (_) => GlobalKey());
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
    final imgs = await JourneyWarmup.instance.images(c);
    if (!mounted) return;
    setState(() {
      _stageImages = imgs;
      _imagesLoading = false;
    });
  }

  @override
  void dispose() {
    _epoch++;
    _dwell?.cancel();
    _confetti.dispose();
    _narration.dispose();
    super.dispose();
  }

  _Step get _step => _steps[_index];
  bool get _isCover => _steps.isNotEmpty && _step.kind == _Kind.cover;
  bool get _isOutro => _steps.isNotEmpty && _step.kind == _Kind.outro;
  bool get _inStages => _steps.isNotEmpty && _step.kind == _Kind.stage;
  int get _stageCount => widget.content?.stages.length ?? 0;

  /// Chỉ số chặng hiện tại (cover = -1, outro = chặng cuối).
  int get _currentStage {
    if (_steps.isEmpty) return -1;
    final s = _step;
    if (s.kind == _Kind.stage) return s.stageIndex;
    if (s.kind == _Kind.outro) return _stageCount - 1;
    return -1;
  }

  Future<void> _advanceTo(int target) async {
    if (!mounted || _steps.isEmpty) return;
    _dwell?.cancel();
    final i = target.clamp(0, _steps.length - 1);
    final myEpoch = ++_epoch;
    await _narration.stop();
    if (!mounted || myEpoch != _epoch) return;
    // Đi TỚI từ một chặng → bay ảnh chặng vừa rời vào node của NÓ trên thanh (nó
    // trở thành node đã-qua). Highlight đi CÙNG center (không lag).
    if (i > _index && _steps[_index].kind == _Kind.stage) {
      _flyToNode(_steps[_index].stageIndex);
    }
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
      await _wait(remain);
      if (!mounted || myEpoch != _epoch) return;
    }
    _advanceTo(i + 1);
  }

  Future<void> _wait(Duration d) {
    final gate = Completer<void>();
    _dwell?.cancel();
    _dwell = Timer(d, () {
      if (!gate.isCompleted) gate.complete();
    });
    return gate.future;
  }

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

  /// Bay một BẢN SAO ảnh chặng đang xem THU NHỎ vào đúng node của chặng đó trên
  /// thanh chặng (qua Overlay) — ảnh "chui vào" thanh hành trình đúng vị trí.
  void _flyToNode(int stageIndex) {
    final c = widget.content;
    if (c == null) return;
    final img = _imageForStage(c, stageIndex);
    if (img == null) return;
    final areaCtx = _carouselAreaKey.currentContext;
    final nodeCtx = (stageIndex >= 0 && stageIndex < _nodeKeys.length)
        ? _nodeKeys[stageIndex].currentContext
        : null;
    if (areaCtx == null || nodeCtx == null) return;
    final areaBox = areaCtx.findRenderObject() as RenderBox?;
    final nodeBox = nodeCtx.findRenderObject() as RenderBox?;
    if (areaBox == null || nodeBox == null || !areaBox.hasSize) return;
    final areaPos = areaBox.localToGlobal(Offset.zero);
    final aw = areaBox.size.width;
    final ah = areaBox.size.height;
    final side = aw < ah * 0.56 ? aw : ah * 0.56; // ảnh vuông ~phần trên vùng
    final start = Rect.fromCenter(
      center: Offset(areaPos.dx + aw / 2, areaPos.dy + side / 2 + 8),
      width: side,
      height: side,
    );
    final nodePos = nodeBox.localToGlobal(Offset.zero);
    final end = Rect.fromLTWH(
        nodePos.dx, nodePos.dy, nodeBox.size.width, nodeBox.size.height);
    final overlay = Overlay.of(context);
    final ctrl =
        AnimationController(vsync: this, duration: WonderTokens.durSlow);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: ctrl,
        builder: (_, _) {
          final t = WonderTokens.curveEmphasized.transform(ctrl.value);
          final rect = Rect.lerp(start, end, t)!;
          final radius = lerpDouble(26, rect.width / 2, t)!;
          final fade = 1.0 - ((ctrl.value - 0.72).clamp(0.0, 0.28) / 0.28);
          return Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: fade,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: WonderShadows.card,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9), width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image(image: img, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
    overlay.insert(entry);
    ctrl.forward().whenComplete(() {
      entry.remove();
      ctrl.dispose();
    });
  }

  void _next() => _advanceTo(_index + 1);
  void _prev() => _advanceTo(_index - 1);
  void _replay() => _advanceTo(_index);

  /// Vuốt dọc: lên = chặng sau, xuống = chặng trước.
  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -120) {
      _next();
    } else if (v > 120) {
      _prev();
    }
  }

  void _exit() {
    _epoch++;
    _narration.stop();
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit(); // nhúng trong camera → đóng overlay tại chỗ
      return;
    }
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
  }

  ImageProvider? _imageForStage(ObjectContent c, int stageIndex) {
    if (stageIndex < 0 || stageIndex >= c.stages.length) return null;
    return resolveStageImage(
      illustration: c.stages[stageIndex].illustration,
      liveFile: _stageImages[stageIndex],
    );
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

    // Outro = màn phần thưởng riêng (thoát khỏi bố cục cuộn).
    if (_isOutro) {
      return Scaffold(
        body: Stack(
          children: <Widget>[
            _OutroView(
              content: c,
              result: _result,
              onScanMore: () {
                final onExit = widget.onExit;
                onExit != null ? onExit() : context.go('/camera');
              },
              onShare: () => showDiscoveryShareSheet(context, c),
              onCollection: () => context.go('/collection'),
              reduce: reduce,
            ),
            _confettiLayer(),
            // Mũi tên quay lại — ghim góc trái, thoát hành trình.
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: WonderBackButton(onTap: _exit),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Nền sáng chấm bi — khớp style màn tách-nền (liền mạch, không tối).
          Positioned.fill(
            child: WonderBackground(child: const SizedBox.expand()),
          ),
          // A. Vùng cuộn (tray + center + stars) — dưới header, nhận vuốt dọc.
          Positioned.fill(
            child: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: _onSwipe,
                child: AnimatedOpacity(
                  duration: WonderTokens.durBase,
                  opacity: _inStages ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_inStages,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, _headerCompact + 4, 16, 12),
                      child: Column(
                        children: <Widget>[
                          // Thanh hành trình chặng: node đã-qua (ảnh nhỏ) · hiện
                          // tại (nổi bật) · sắp tới (chấm mờ). Là ĐÍCH để ảnh
                          // center thu nhỏ trôi vào.
                          _StageTrack(
                            count: _stageCount,
                            current: _currentStage,
                            imageFor: (i) => _imageForStage(c, i),
                            onTapStage: (i) => _advanceTo(i + 1), // +1: bỏ cover
                            nodeKeys: _nodeKeys,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: KeyedSubtree(
                              key: _carouselAreaKey,
                              child: PageTransitionSwitcher(
                              duration: WonderTokens.durBase,
                              transitionBuilder: (child, primary, secondary) =>
                                  _stageTransition(
                                      child, primary, secondary, reduce),
                              child: KeyedSubtree(
                                key: ValueKey<int>(_index),
                                child: _inStages
                                    ? _StageCenter(
                                        stage: c.stages[_step.stageIndex],
                                        image: _imageForStage(
                                            c, _step.stageIndex),
                                        imageLoading: _imagesLoading &&
                                            c.source == 'live',
                                        reduce: reduce,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // B. Cover: thẻ "đang kể" + lịch sử + gợi ý vuốt lên. LUÔN có trong cây
          // (fade bằng opacity, KHÔNG dùng `if`) để không xê dịch index của Stack
          // → header giữ được Element → AnimatedScale/Align animate mượt.
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: IgnorePointer(
                ignoring: !_isCover,
                child: AnimatedOpacity(
                  duration: WonderTokens.durBase,
                  opacity: _isCover ? 1 : 0,
                  child: _CoverStory(content: c, reduce: reduce),
                ),
              ),
            ),
          ),

          // C. Header: MORPH cutout+tên — cover: TO, DỌC (tên dưới), giữa-trên;
          // chặng: NHỎ, NGANG (tên bên phải), ở đầu. Lerp vị trí+cỡ+font theo
          // _inStages → thu nhỏ + di chuyển + đổi dọc↔ngang mượt.
          Positioned.fill(
            child: SafeArea(
              child: IgnorePointer(
                child: _HeaderMorph(content: c, stages: _inStages),
              ),
            ),
          ),

          // D. Thanh trên: thoát + nghe lại.
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
                    WonderBackButton(
                      onTap: _exit,
                      semanticLabel: 'Thoát hành trình',
                    ),
                    const Spacer(),
                    if (_inStages)
                      GlassIconButton(
                        icon: PhosphorIconsFill.speakerSimpleHigh,
                        tone: GlassTone.light,
                        size: 44,
                        onTap: _replay,
                        semanticLabel: 'Nghe lại',
                      ),
                  ],
                ),
              ),
            ),
          ),

          // E. Chỉ báo "Đang kể" (ẩn ở cover). LUÔN có trong cây (fade) để không
          // xê dịch index của Stack.
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: WonderTokens.durBase,
                  opacity: (_narrating && !_isCover) ? 1 : 0,
                  child: const Center(child: _ListeningPill()),
                ),
              ),
            ),
          ),

          _confettiLayer(),
        ],
      ),
    );
  }

  /// Chuyển chặng ở center: chặng RỜI đi **thu nhỏ + trôi lên** (về phía tray),
  /// chặng MỚI trồi từ dưới lên + phóng nhẹ. Hướng theo [_reverse] (vuốt xuống
  /// thì đảo lại).
  Widget _stageTransition(
    Widget child,
    Animation<double> primary,
    Animation<double> secondary,
    bool reduce,
  ) {
    if (reduce) {
      return FadeTransition(
        opacity: primary,
        child: FadeTransition(
          opacity: ReverseAnimation(secondary),
          child: child,
        ),
      );
    }
    final dir = _reverse ? -1.0 : 1.0;
    final inCurve =
        CurvedAnimation(parent: primary, curve: WonderTokens.curveEmphasized);
    final inSlide =
        Tween<Offset>(begin: Offset(0, 0.18 * dir), end: Offset.zero)
            .animate(inCurve);
    final inScale = Tween<double>(begin: 0.9, end: 1.0).animate(inCurve);
    // Chặng RỜI: mờ NHANH (bản sao ảnh bay vào node trên thanh lo phần thu-nhỏ-
    // đi-lên → không để chặng rời tự trôi lung tung).
    final outFade = CurvedAnimation(
      parent: secondary,
      curve: const Interval(0.0, 0.5),
    );
    return SlideTransition(
      position: inSlide,
      child: ScaleTransition(
        scale: inScale,
        child: FadeTransition(
          opacity: primary,
          child: FadeTransition(
            opacity: ReverseAnimation(outFade),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _confettiLayer() => Align(
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
      );
}

/// ---------------------------------------------------------------------------
/// Header MORPH: cutout + tên nội suy giữa hai trạng thái theo [stages].
/// - cover (stages=false): cutout TO ở giữa-trên, tên DỌC bên dưới (canh giữa).
/// - chặng (stages=true): cutout NHỎ ở đầu-trái, tên NGANG bên phải.
/// Lerp cỡ+vị trí+font theo `t` → thu nhỏ + di chuyển + đổi dọc↔ngang mượt liền,
/// giữ viền trắng tên.
class _HeaderMorph extends StatelessWidget {
  final ObjectContent content;
  final bool stages;
  const _HeaderMorph({required this.content, required this.stages});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: stages ? 1.0 : 0.0),
      duration: WonderTokens.durSlow,
      curve: WonderTokens.curveEmphasized,
      builder: (context, t, _) =>
          LayoutBuilder(builder: (context, cons) => _build(cons, t)),
    );
  }

  Widget _build(BoxConstraints cons, double t) {
    final w = cons.maxWidth;
    final h = cons.maxHeight;
    final dCover = (h * 0.30).clamp(160.0, 300.0);
    const dStage = 46.0;
    final d = lerpDouble(dCover, dStage, t)!;
    // Tâm cutout: cover = giữa & hơi trên; chặng = đầu, BÊN PHẢI nút back (66px).
    final cx = lerpDouble(w / 2, 66 + dStage / 2, t)!;
    final cy = lerpDouble(h * 0.06 + dCover / 2, 6 + dStage / 2, t)!;
    // Tên: cover = full-width canh giữa DƯỚI cutout; chặng = NGANG bên phải cutout.
    final nameFont = lerpDouble(26.0, 17.0, t)!;
    final nameLeft = lerpDouble(16.0, 66 + dStage + 10, t)!;
    final nameRight = lerpDouble(16.0, 56.0, t)!;
    final nameTop = lerpDouble(
      h * 0.06 + dCover + 6,
      6 + (dStage - nameFont * 1.25) / 2,
      t,
    )!;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: cx - d / 2,
          top: cy - d / 2,
          width: d,
          height: d,
          child: ObjectAvatar(
            objectId: content.id,
            emoji: content.emoji,
            diameter: d,
            emojiSize: d * 0.42,
            glowOpacity: 0.5,
            sticker: true,
          ),
        ),
        Positioned(
          left: nameLeft,
          right: nameRight,
          top: nameTop,
          child: _OutlinedName(
            content.name,
            fontSize: nameFont,
            align: t < 0.5 ? TextAlign.center : TextAlign.left,
          ),
        ),
      ],
    );
  }
}

/// Tên vật kiểu sticker: chữ đậm + viền trắng dày (khớp màn tách-nền).
class _OutlinedName extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign align;
  const _OutlinedName(this.text, {required this.fontSize, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    // 1 Text + 8 shadow trắng lệch quanh → viền trắng die-cut (chỉ 1 widget nên
    // find.text ở test vẫn khớp 1).
    final w = (fontSize * 0.11).clamp(2.0, 6.0);
    const offsets = <Offset>[
      Offset(-1, -1), Offset(0, -1), Offset(1, -1), Offset(-1, 0),
      Offset(1, 0), Offset(-1, 1), Offset(0, 1), Offset(1, 1),
    ];
    return Text(
      text,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: WonderType.display.copyWith(
        color: WonderColors.textStrong,
        fontSize: fontSize,
        shadows: <Shadow>[
          for (final o in offsets)
            Shadow(color: Colors.white, offset: o * w, blurRadius: 1.5),
        ],
      ),
    );
  }
}

/// Thanh hành trình chặng (stepper ngang): mỗi chặng là một node — đã qua (ảnh
/// nhỏ), hiện tại (nổi bật, viền teal, to hơn), sắp tới (chấm mờ). Nối bằng vạch
/// (tô teal tới chặng hiện tại). Là ĐÍCH trực quan để ảnh center thu nhỏ trôi vào.
class _StageTrack extends StatelessWidget {
  final int count;
  final int current;
  final ImageProvider? Function(int stageIndex) imageFor;
  final void Function(int stageIndex) onTapStage;
  final List<GlobalKey> nodeKeys;
  const _StageTrack({
    required this.count,
    required this.current,
    required this.imageFor,
    required this.onTapStage,
    required this.nodeKeys,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox(height: 4);
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < count; i++) ...<Widget>[
            if (i > 0)
              AnimatedContainer(
                duration: WonderTokens.durBase,
                width: 14,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= current
                      ? WonderColors.teal
                      : WonderColors.textStrong.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            KeyedSubtree(
              key: i < nodeKeys.length ? nodeKeys[i] : null,
              child: _StageNode(
                image: imageFor(i),
                number: i + 1,
                state: i < current
                    ? _NodeState.passed
                    : (i == current ? _NodeState.current : _NodeState.future),
                onTap: i < current ? () => onTapStage(i) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _NodeState { passed, current, future }

class _StageNode extends StatelessWidget {
  final ImageProvider? image;
  final int number;
  final _NodeState state;
  final VoidCallback? onTap;
  const _StageNode({
    required this.image,
    required this.number,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = state == _NodeState.current;
    final future = state == _NodeState.future;
    // Cỡ CỐ ĐỊNH → vị trí node KHÔNG xê dịch khi đổi chặng → ảnh bay đúng node.
    // Node hiện tại chỉ PHÓNG TO bằng Transform.scale (không ảnh hưởng layout).
    const size = 34.0;
    Widget node = AnimatedContainer(
      duration: WonderTokens.durBase,
      curve: WonderTokens.curveEmphasized,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: future
            ? WonderColors.textStrong.withValues(alpha: 0.12)
            : Colors.white,
        border: Border.all(
          color:
              current ? WonderColors.teal : Colors.white.withValues(alpha: 0.85),
          width: current ? 3 : 2,
        ),
        boxShadow: future ? null : WonderShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: future
          ? const SizedBox.shrink()
          : (image != null
              ? Image(image: image!, fit: BoxFit.cover, gaplessPlayback: true)
              : Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: WonderColors.textSoft,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                )),
    );
    if (current) {
      // Nổi bật node hiện tại nhưng KHÔNG đổi kích thước layout (vị trí ổn định).
      node = Transform.scale(scale: 1.22, child: node);
    }
    if (onTap == null) return node;
    return Pressable(onTap: onTap, semanticLabel: 'Chặng $number', child: node);
  }
}

/// Chặng ở CENTER: ảnh vuông + thẻ chữ.
class _StageCenter extends StatelessWidget {
  final Stage stage;
  final ImageProvider? image;
  final bool imageLoading;
  final bool reduce;
  const _StageCenter({
    required this.stage,
    required this.image,
    required this.imageLoading,
    required this.reduce,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: Center(
            child: _ImageCard(
              image: image,
              loading: imageLoading && image == null,
              reduce: reduce,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Flexible(
          flex: 4,
          child: _StoryScrim(stage: stage, reduce: reduce),
        ),
      ],
    );
  }
}

class _SwipeHint extends StatelessWidget {
  final bool reduce;
  const _SwipeHint({required this.reduce});

  @override
  Widget build(BuildContext context) {
    final w = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const PhosphorIcon(
          PhosphorIconsBold.arrowUp,
          size: 22,
          color: WonderColors.textSoft,
        ),
        const SizedBox(height: 2),
        Text(
          'Vuốt lên để khám phá',
          style: WonderType.label.copyWith(color: WonderColors.textSoft),
        ),
      ],
    );
    if (reduce) return w;
    return w
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 900.ms, curve: Curves.easeInOut);
  }
}

/// Cover (thay state lịch sử cũ): chỉ báo "đang kể" + sóng âm + lịch sử tổng
/// quan để đọc theo + gợi ý vuốt lên. Đỡ trống & rõ là đang kể chuyện.
class _CoverStory extends StatelessWidget {
  final ObjectContent content;
  final bool reduce;
  const _CoverStory({required this.content, required this.reduce});

  @override
  Widget build(BuildContext context) {
    final history = (content.history ?? '').trim();
    final maxH = MediaQuery.of(context).size.height * 0.20;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GlassSurface(
          tone: GlassTone.light,
          radius: WonderTokens.radiusLg,
          padding: const EdgeInsets.all(WonderTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _NarratingChip(reduce: reduce),
              if (history.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Text(
                      history,
                      style: const TextStyle(
                        color: WonderColors.textStrong,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SwipeHint(reduce: reduce),
      ],
    );
  }
}

/// "Đang kể chuyện" + 3 vạch sóng âm nhấp nháy.
class _NarratingChip extends StatelessWidget {
  final bool reduce;
  const _NarratingChip({required this.reduce});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const PhosphorIcon(
          PhosphorIconsFill.sparkle,
          size: 16,
          color: WonderColors.grape,
        ),
        const SizedBox(width: 7),
        Text(
          'Đang kể chuyện',
          style: WonderType.label.copyWith(
            color: WonderColors.grape,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        _SoundBars(reduce: reduce),
      ],
    );
  }
}

class _SoundBars extends StatelessWidget {
  final bool reduce;
  const _SoundBars({required this.reduce});

  @override
  Widget build(BuildContext context) {
    Widget bar(int i) {
      final b = Container(
        width: 3.5,
        height: 15,
        decoration: BoxDecoration(
          color: WonderColors.grape,
          borderRadius: BorderRadius.circular(2),
        ),
      );
      if (reduce) return b;
      return b
          .animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 140).ms)
          .scaleY(begin: 0.4, end: 1, duration: 480.ms, curve: Curves.easeInOut);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: bar(i),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Khung ảnh chặng: vuông, bo góc, viền sáng + glow.
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
          borderRadius: BorderRadius.circular(28),
          color: WonderColors.inkSoft,
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: WonderColors.teal.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: -12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _inner(),
        ),
      ),
    );
    return card;
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
      errorBuilder: (_, _, _) => const ColoredBox(color: WonderColors.inkSoft),
    );
  }
}

/// Thẻ kính tối chứa tiêu đề + lời kể + fun-fact của chặng.
class _StoryScrim extends StatelessWidget {
  final Stage stage;
  final bool reduce;
  const _StoryScrim({required this.stage, required this.reduce});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      radius: WonderTokens.radiusLg,
      padding: const EdgeInsets.all(WonderTokens.space16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              stage.title,
              style: WonderType.heading.copyWith(
                color: WonderColors.textStrong,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stage.kidText,
              style: const TextStyle(
                color: WonderColors.textStrong,
                fontSize: 15,
                height: 1.42,
              ),
            ),
            if (stage.funFact != null && stage.funFact!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: WonderColors.sunny.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
                  border: Border.all(
                    color: WonderColors.sunnyDeep.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const PhosphorIcon(
                      PhosphorIconsFill.lightbulb,
                      size: 17,
                      color: WonderColors.sunnyDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage.funFact!,
                        style: const TextStyle(
                          color: WonderColors.textStrong,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Outro: phần thưởng + hành động tiếp theo (KHÔNG còn phim).
class _OutroView extends StatelessWidget {
  final ObjectContent content;
  final DiscoveryResult? result;
  final VoidCallback onScanMore;
  final VoidCallback onShare;
  final VoidCallback onCollection;
  final bool reduce;

  const _OutroView({
    required this.content,
    required this.result,
    required this.onScanMore,
    required this.onShare,
    required this.onCollection,
    required this.reduce,
  });

  @override
  Widget build(BuildContext context) {
    final view = WonderBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              ObjectAvatar(
                objectId: content.id,
                emoji: content.emoji,
                diameter: 96,
                emojiSize: 48,
                glowOpacity: 0.5,
                hero: true,
                sticker: true,
              ),
              const SizedBox(height: 18),
              if (result?.newBadge != null) ...<Widget>[
                _BadgeBanner(material: result!.newBadge!),
                const SizedBox(height: 14),
              ],
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
