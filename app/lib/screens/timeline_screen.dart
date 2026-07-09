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
import '../widgets/object_sticker_grid.dart';
import '../widgets/share_sheet.dart';

/// Nhịp chuyển động CHUNG của màn hành trình — dùng cho fly ảnh (center↔node),
/// đổi chặng, và morph header (cutout+tên trôi lên) → tất cả ăn khớp MỘT nhịp.
/// Mượt kiểu iOS: ease vào–ra đối xứng, KHÔNG overshoot (không nảy).
const Duration _kJourneyDur = WonderTokens.durSlow;
const Curve _kJourneyCurve = Curves.easeInOutCubic;

/// Cỡ ô node & bo góc thẻ ảnh trên thanh chặng — dùng CHUNG cho [_StageNode] và
/// đích bay ([_flyGhost]) để ghost đáp KHỚP đúng thẻ (liền mạch, không lệch góc).
const double _kNodeCell = 36.0;
const double _kNodeCorner = 11.0;

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

  const TimelineScreen({super.key, this.content, this.narration, this.onExit});

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
  // Node đang có ghost bay LÊN (park, lúc TIẾN) → render TRỐNG tới khi ghost đáp
  // (tránh ảnh nhảy vào node trước khi ghost tới nơi).
  final Set<int> _parking = <int>{};
  // Khi vào lại một chặng đã ghé: ảnh của nó phóng to từ node xuống center; ẩn
  // _StageCenter của chặng này tới khi ghost đáp (giống lúc tiến, đảo chiều).
  int? _growingStage;

  /// park-ghost đáp → node [stage] hết "đang bay" → hiện ảnh.
  void _parkLanded(int stage) {
    if (mounted && _parking.contains(stage)) {
      setState(() => _parking.remove(stage));
    }
  }

  /// grow-ghost đáp → center của [stage] hiện ra (kết thúc phóng to).
  void _revealCenter(int stage) {
    if (mounted && _growingStage == stage) {
      setState(() => _growingStage = null);
    }
  }

  // Đã "vào" màn chưa — frame đầu giữ header ở mốc reveal (TO) để khớp crossfade
  // từ màn tách-nền, rồi tự tiến tới cover (0.5): vật+tên thu nhỏ + trôi lên khi
  // bắt đầu kể history. Sau đó vào chặng → 1.
  bool _entered = false;

  /// Mốc morph header: chưa vào = reveal (0); cover/history = 0.5; chặng = 1.
  double get _headerProgress {
    if (_inStages) return 1.0;
    // Mở lại qua route (Rương/nhật ký, KHÔNG nhúng camera): vào thẳng cover — bỏ
    // mốc reveal (vốn để crossfade từ màn tách-nền) → cutout đứng yên cho Hero
    // morph từ Rương đáp đúng chỗ. Nhúng camera (onExit != null): giữ reveal.
    if (widget.onExit == null) return 0.5;
    return _entered ? 0.5 : 0.0;
  }

  bool _completed = false;
  DiscoveryResult? _result;

  static const Duration _minDwell = Duration(milliseconds: 2200);
  static const Duration _maxDwell = Duration(seconds: 45);
  static const double _headerCompact =
      104; // chỗ chừa cho header thu gọn (to hơn)
  // Bay ảnh center↔node & đổi chặng: cùng nhịp với _HeaderMorph (xem _kJourney*).
  static const Duration _flyDur = _kJourneyDur;
  static const Curve _flyCurve = _kJourneyCurve;
  static const Duration _stageSwitch = _kJourneyDur;

  @override
  void initState() {
    super.initState();
    _narration = widget.narration ?? NarrationService();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final c = widget.content;
    if (c != null) {
      _steps = _buildSteps(c);
      _nodeKeys = List<GlobalKey>.generate(c.stages.length, (_) => GlobalKey());
      if (c.source == 'live' && JourneyImageService.available) {
        _loadStageImages(c);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Frame đầu header ở mốc reveal (TO); giờ tiến tới cover → vật+tên thu
        // nhỏ + trôi lên rồi mới kể history (khớp crossfade từ màn tách-nền).
        setState(() => _entered = true);
        _advanceTo(0);
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
    final fromStage = _steps[_index].kind == _Kind.stage
        ? _steps[_index].stageIndex
        : null;
    final toStep = _steps[i];
    final toStage = toStep.kind == _Kind.stage ? toStep.stageIndex : null;
    // TIẾN (rời chặng đi tới) → ảnh center chặng vừa rời thu nhỏ bay LÊN node của
    // NÓ (node đó thành "đã qua", phía sau); render TRỐNG tới khi ghost đáp.
    final parkFrom = (fromStage != null && i > _index) ? fromStage : null;
    // LÙI về một chặng phía sau → ảnh của nó từ node PHÓNG TO xuống center (đảo
    // chiều). Chặng vừa rời giờ nằm PHÍA TRƯỚC chặng đích → node của nó thành
    // "chưa tới" (sao), KHÔNG cất ảnh vào node (chỉ node phía sau mới có ảnh).
    final growTo =
        (fromStage != null &&
            toStage != null &&
            i < _index &&
            !_parking.contains(toStage))
        ? toStage
        : null;
    if (parkFrom != null) _parking.add(parkFrom);
    _growingStage = growTo;
    if (parkFrom != null) _flyGhost(parkFrom, toCenter: false);
    if (growTo != null) _flyGhost(growTo, toCenter: true);
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

  /// Bay một BẢN SAO ảnh chặng giữa **center** và **node của nó** trên thanh
  /// chặng (qua Overlay), khớp đúng vị trí + cỡ hai đầu nên đổi chỗ liền mạch:
  /// - [toCenter] = false (PARK, lúc rời chặng): center → node, đáp xong node
  ///   mới hiện ảnh ([_deliver]).
  /// - [toCenter] = true  (GROW, lúc lùi về chặng): node → center, đáp xong mới
  ///   hiện _StageCenter ([_revealCenter]) → ảnh "phóng to ra center".
  void _flyGhost(int stageIndex, {required bool toCenter}) {
    void settle() =>
        toCenter ? _revealCenter(stageIndex) : _parkLanded(stageIndex);
    final c = widget.content;
    if (c == null) return settle();
    final img = _imageForStage(c, stageIndex);
    if (img == null) return settle();
    final areaCtx = _carouselAreaKey.currentContext;
    final nodeCtx = (stageIndex >= 0 && stageIndex < _nodeKeys.length)
        ? _nodeKeys[stageIndex].currentContext
        : null;
    if (areaCtx == null || nodeCtx == null) return settle();
    final areaBox = areaCtx.findRenderObject() as RenderBox?;
    final nodeBox = nodeCtx.findRenderObject() as RenderBox?;
    if (areaBox == null || nodeBox == null || !areaBox.hasSize) return settle();
    final areaPos = areaBox.localToGlobal(Offset.zero);
    final aw = areaBox.size.width;
    final ah = areaBox.size.height;
    final side = aw < ah * 0.56 ? aw : ah * 0.56; // ảnh vuông ~phần trên vùng
    final centerRect = Rect.fromCenter(
      center: Offset(areaPos.dx + aw / 2, areaPos.dy + side / 2 + 8),
      width: side,
      height: side,
    );
    final nodePos = nodeBox.localToGlobal(Offset.zero);
    final nodeRect = Rect.fromLTWH(
      nodePos.dx,
      nodePos.dy,
      nodeBox.size.width,
      nodeBox.size.height,
    );
    final start = toCenter ? nodeRect : centerRect;
    final end = toCenter ? centerRect : nodeRect;
    // Bo góc: đầu node = bo thẻ ([_kNodeCorner]); đầu center = bo ảnh lớn (26).
    final startR = toCenter ? _kNodeCorner : 26.0;
    final endR = toCenter ? 26.0 : _kNodeCorner;
    final overlay = Overlay.of(context);
    final ctrl = AnimationController(vsync: this, duration: _flyDur);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: ctrl,
        builder: (_, _) {
          final t = _flyCurve.transform(ctrl.value);
          final rect = Rect.lerp(start, end, t)!;
          final radius = lerpDouble(startR, endR, t)!;
          // Ghost giữ NGUYÊN độ đục tới khi đáp: rect hai đầu == đúng rect
          // node/center nên lúc bên kia hiện ảnh là đổi chỗ liền mạch, không chớp.
          return Positioned.fromRect(
            rect: rect,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: WonderShadows.card,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 3,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image(image: img, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
    overlay.insert(entry);
    ctrl.forward().whenComplete(() {
      entry.remove();
      ctrl.dispose();
      settle(); // đáp → bên nhận (node hoặc center) mới hiện ảnh
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
                        16,
                        _headerCompact + 4,
                        16,
                        12,
                      ),
                      child: Column(
                        children: <Widget>[
                          // Thanh hành trình chặng: node đã-qua (ảnh nhỏ) · hiện
                          // tại (nổi bật) · sắp tới (chấm mờ). Là ĐÍCH để ảnh
                          // center thu nhỏ trôi vào.
                          _StageTrack(
                            count: _stageCount,
                            current: _currentStage,
                            parking: _parking,
                            imageFor: (i) => _imageForStage(c, i),
                            onTapStage: (i) =>
                                _advanceTo(i + 1), // +1: bỏ cover
                            nodeKeys: _nodeKeys,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: KeyedSubtree(
                              key: _carouselAreaKey,
                              child: PageTransitionSwitcher(
                                duration: _stageSwitch,
                                transitionBuilder:
                                    (child, primary, secondary) =>
                                        _stageTransition(
                                          child,
                                          primary,
                                          secondary,
                                          reduce,
                                        ),
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_index),
                                  child: _inStages
                                      // Lùi về chặng đã ghé: ẩn center tới khi ảnh
                                      // phóng to từ node đáp xuống (grow-ghost) →
                                      // hết chồng ảnh, đổi chỗ liền mạch.
                                      ? AnimatedOpacity(
                                          opacity:
                                              _growingStage == _step.stageIndex
                                              ? 0.0
                                              : 1.0,
                                          duration:
                                              _growingStage == _step.stageIndex
                                              ? Duration.zero
                                              : WonderTokens.durFast,
                                          child: _StageCenter(
                                            stage: c.stages[_step.stageIndex],
                                            image: _imageForStage(
                                              c,
                                              _step.stageIndex,
                                            ),
                                            imageLoading:
                                                _imagesLoading &&
                                                c.source == 'live',
                                            reduce: reduce,
                                          ),
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

          // B. Cover: thẻ "đang kể" + lịch sử (CĂN GIỮA vùng dưới header, hết
          // khoảng trống) + gợi ý vuốt lên ghim đáy. LUÔN có trong cây (fade bằng
          // opacity, KHÔNG dùng `if`) để không xê dịch index của Stack → header
          // giữ được Element → morph animate mượt.
          Positioned.fill(
            child: SafeArea(
              // LUÔN bỏ qua pointer: thẻ cover chỉ để HIỂN THỊ (không nút bấm) →
              // cử chỉ vuốt dọc xuyên xuống handler ở lớp A (đổi chặng), không bị
              // scroll của thẻ nuốt mất.
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: WonderTokens.durBase,
                  opacity: _isCover ? 1 : 0,
                  child: LayoutBuilder(
                    builder: (context, cons) => Padding(
                      // top chừa cho cutout+tên ở mốc cover (hero to, ở trên);
                      // thẻ BÁM NGAY DƯỚI tên (không căn giữa) → hết trống ở giữa.
                      padding: EdgeInsets.fromLTRB(
                        20,
                        cons.maxHeight * 0.35,
                        20,
                        14,
                      ),
                      child: Column(
                        children: <Widget>[
                          // "Modal" history TRƯỢT LÊN lúc vào (gated _entered) →
                          // lúc nút reveal mờ đi thì thẻ history hiện ra có chuyển
                          // tiếp rõ, không "bụp" ra.
                          AnimatedSlide(
                            offset: _entered
                                ? Offset.zero
                                : const Offset(0, 0.22),
                            duration: _kJourneyDur,
                            curve: _kJourneyCurve,
                            child: _CoverStory(content: c, reduce: reduce),
                          ),
                          const Spacer(),
                          _SwipeHint(reduce: reduce),
                        ],
                      ),
                    ),
                  ),
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
                child: _HeaderMorph(content: c, progress: _headerProgress),
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
                        native: true,
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
    final inCurve = CurvedAnimation(parent: primary, curve: _kJourneyCurve);
    final inSlide = Tween<Offset>(
      begin: Offset(0, 0.18 * dir),
      end: Offset.zero,
    ).animate(inCurve);
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

  /// 0 = reveal (TO, giữa) · 0.5 = cover/history (VỪA, cao hơn, tên vẫn DƯỚI) ·
  /// 1 = chặng (GỌN ở header, tên NGANG bên phải). Nội suy liên tục theo mốc này
  /// → lúc vào history vật+tên thu nhỏ & trôi lên (0→0.5), vào chặng gọn tiếp
  /// (0.5→1).
  final double progress;
  const _HeaderMorph({required this.content, required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: _kJourneyDur,
      curve: _kJourneyCurve,
      builder: (context, p, _) =>
          LayoutBuilder(builder: (context, cons) => _build(cons, p)),
    );
  }

  Widget _build(BoxConstraints cons, double p) {
    final w = cons.maxWidth;
    final h = cons.maxHeight;
    // HAI PHA: reveal→cover (p 0→0.5) chỉ THU NHỎ NHẸ + TRÔI LÊN, GIỮ CANH GIỮA;
    // cover→chặng (p 0.5→1) mới co gọn + dời sang header trái + tên lật ngang.
    final rise = (p * 2).clamp(0.0, 1.0); // pha 1
    final flip = ((p - 0.5) * 2).clamp(0.0, 1.0); // pha 2
    final dReveal = (h * 0.32).clamp(200.0, 320.0);
    final dCover = (h * 0.24).clamp(180.0, 260.0);
    const dStage = 56.0;
    final d = p <= 0.5
        ? lerpDouble(dReveal, dCover, rise)!
        : lerpDouble(dCover, dStage, flip)!;
    // X: reveal & cover CÙNG canh giữa (cx=w/2 vì flip=0); chỉ dời trái ở pha 2.
    final cx = lerpDouble(w / 2, 64 + dStage / 2, flip)!;
    // Y: reveal (giữa-trên) → cover (trên) → chặng (đỉnh header).
    final cyReveal = h * 0.06 + dReveal / 2;
    final cyCover = 18 + dCover / 2;
    final cy = p <= 0.5
        ? lerpDouble(cyReveal, cyCover, rise)!
        : lerpDouble(cyCover, 6 + dStage / 2, flip)!;
    // Tên: reveal & cover đều CANH GIỮA, DƯỚI cutout, chữ to; chỉ pha 2 mới lật
    // sang NGANG bên phải + co nhỏ.
    final nameFont = p <= 0.5
        ? lerpDouble(35.0, 32.0, rise)!
        : lerpDouble(32.0, 21.0, flip)!;
    final nameLeft = lerpDouble(16.0, 64 + dStage + 12, flip)!;
    final nameRight = lerpDouble(16.0, 56.0, flip)!;
    final nameTop = lerpDouble(
      cy + d / 2 + 10, // ngay DƯỚI cutout, bám theo cutout
      6 + (dStage - nameFont * 1.25) / 2,
      flip,
    )!;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: cx - d / 2,
          top: cy - d / 2,
          width: d,
          height: d,
          // Hero đích của morph từ Rương: sticker vật bay từ Rương vào đây (cover).
          // Mở từ nơi khác (nhật ký/camera) không có nguồn trùng tag → chỉ hiện
          // bình thường, không bay.
          child: Hero(
            tag: collectionObjectHeroTag(content.id),
            child: ObjectAvatar(
              objectId: content.id,
              emoji: content.emoji,
              diameter: d,
              emojiSize: d * 0.42,
              glowOpacity: 0.5,
              sticker: true,
            ),
          ),
        ),
        Positioned(
          left: nameLeft,
          right: nameRight,
          top: nameTop,
          child: _OutlinedName(
            content.name,
            fontSize: nameFont,
            align: flip < 0.5 ? TextAlign.center : TextAlign.left,
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
  const _OutlinedName(
    this.text, {
    required this.fontSize,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    // 1 Text + nhiều shadow trắng lệch quanh → viền trắng die-cut DÀY (chỉ 1
    // widget nên find.text ở test vẫn khớp 1). 12 hướng đều (30°) + blur nhẹ →
    // viền liền mạch, không hở góc kể cả khi chữ to.
    final w = (fontSize * 0.16).clamp(3.5, 9.0);
    const offsets = <Offset>[
      Offset(1, 0),
      Offset(0.866, 0.5),
      Offset(0.5, 0.866),
      Offset(0, 1),
      Offset(-0.5, 0.866),
      Offset(-0.866, 0.5),
      Offset(-1, 0),
      Offset(-0.866, -0.5),
      Offset(-0.5, -0.866),
      Offset(0, -1),
      Offset(0.5, -0.866),
      Offset(0.866, -0.5),
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
            Shadow(color: Colors.white, offset: o * w, blurRadius: w * 0.5),
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
  final Set<int> parking; // node đang có ghost bay lên → render TRỐNG
  final ImageProvider? Function(int stageIndex) imageFor;
  final void Function(int stageIndex) onTapStage;
  final List<GlobalKey> nodeKeys;
  const _StageTrack({
    required this.count,
    required this.current,
    required this.parking,
    required this.imageFor,
    required this.onTapStage,
    required this.nodeKeys,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox(height: 4);
    // Bọc trong PILL Liquid Glass (native iOS 26 khi có) → thanh chặng đọc như
    // một "thành phần tiến độ" bằng kính thật, nổi trên nền chấm bi. Row hug nội
    // dung, canh giữa.
    return SizedBox(
      height: 58,
      child: Center(
        child: GlassSurface(
          tone: GlassTone.light,
          native: true,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var i = 0; i < count; i++) ...<Widget>[
                if (i > 0)
                  AnimatedContainer(
                    duration: WonderTokens.durBase,
                    curve: _kJourneyCurve,
                    width: 16,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= current
                          ? WonderColors.teal
                          : WonderColors.textStrong.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                KeyedSubtree(
                  key: i < nodeKeys.length ? nodeKeys[i] : null,
                  child: _StageNode(
                    image: imageFor(i),
                    number: i + 1,
                    state: i < current
                        ? _NodeState.passed
                        : (i == current
                              ? _NodeState.current
                              : _NodeState.future),
                    // Chỉ node PHÍA SAU chặng đang xem (đã qua) mới có ảnh, và
                    // không đang park. Đang xem = trống; phía trước = chấm rỗng.
                    filled: i < current && !parking.contains(i),
                    onTap: (i < current && !parking.contains(i))
                        ? () => onTapStage(i)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _NodeState { passed, current, future }

class _StageNode extends StatelessWidget {
  final ImageProvider? image;
  final int number;
  final _NodeState state;
  final bool filled; // ảnh đã bay lên node này chưa
  final VoidCallback? onTap;
  const _StageNode({
    required this.image,
    required this.number,
    required this.state,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = state == _NodeState.current;
    final future = state == _NodeState.future;
    // Chỉ hiện ảnh khi ảnh ĐÃ BAY LÊN node này. Node đang xem/chưa tới = TRỐNG →
    // ảnh center "chui vào" thẻ đúng lúc lướt qua chặng đó.
    final showImage = filled && image != null;
    // Chặng chưa tới, chưa có ảnh → CHẤM RỖNG tinh tế (thẻ trong suốt).
    final dot = future && !showImage;
    // Ô CỐ ĐỊNH [_kNodeCell] → vị trí node ổn định khi đổi chặng (ảnh bay đúng ô).
    // Node hiện tại chỉ PHÓNG TO bằng Transform.scale (không ảnh hưởng layout).
    Widget node = AnimatedContainer(
      duration: WonderTokens.durBase,
      curve: _kJourneyCurve,
      width: _kNodeCell,
      height: _kNodeCell,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kNodeCorner),
        color: dot ? Colors.transparent : Colors.white,
        border: dot
            ? null
            : Border.all(
                color: current
                    ? WonderColors.teal
                    : Colors.white.withValues(alpha: 0.9),
                width: current ? 2.5 : 2,
              ),
        boxShadow: dot
            ? null
            : (current
                  ? WonderShadows.glow(WonderColors.teal, opacity: 0.5)
                  : WonderShadows.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: showImage
          ? Image(image: image!, fit: BoxFit.cover, gaplessPlayback: true)
          : Center(
              child: dot
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: WonderColors.teal.withValues(alpha: 0.16),
                        border: Border.all(
                          color: WonderColors.teal.withValues(alpha: 0.34),
                          width: 1.5,
                        ),
                      ),
                    )
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: current
                            ? WonderColors.teal
                            : WonderColors.textSoft,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
            ),
    );
    if (current) {
      // Nổi bật node hiện tại nhưng KHÔNG đổi layout (vị trí ổn định cho ảnh bay).
      node = Transform.scale(scale: 1.12, child: node);
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
    final maxH = MediaQuery.of(context).size.height * 0.34;
    // CHỈ là thẻ history (hint tách ra ngoài, ghim đáy). Bọc kính sáng, canh giữa
    // vùng dưới header → hết khoảng trống lớn.
    return GlassSurface(
      tone: GlassTone.light,
      radius: WonderTokens.radiusXl,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _NarratingChip(reduce: reduce),
          if (history.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: SingleChildScrollView(
                child: Text(
                  history,
                  style: const TextStyle(
                    color: WonderColors.textStrong,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
          .scaleY(
            begin: 0.4,
            end: 1,
            duration: 480.ms,
            curve: Curves.easeInOut,
          );
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 4,
          ),
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
          .shimmer(
            duration: 1400.ms,
            color: Colors.white.withValues(alpha: 0.16),
          );
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
                    GlassButton(
                      label: 'Soi vật khác',
                      icon: PhosphorIconsBold.magnifyingGlass,
                      onTap: onScanMore,
                    ),
                    const SizedBox(height: 10),
                    GlassButton(
                      label: 'Khoe khám phá',
                      icon: PhosphorIconsBold.shareNetwork,
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
    return reduce
        ? view
        : view.animate().fadeIn(duration: WonderTokens.durBase);
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
