import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/app_settings.dart';
import '../data/capture_store.dart';
import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/onboarding_mission.dart';
import '../models/object_content.dart';
import '../services/narration_service.dart';
import '../ui/ui.dart';
import 'timeline_screen.dart';

/// Onboarding "chụp thử" kiểu CapWords — đi ĐÚNG luồng chụp thật của app,
/// chỉ thay camera bằng ảnh cốc giấy bundled:
///   ngắm (khung 4 góc + câu đố) → chạm nút khẩu độ (chụp tức thì như camera)
///   → [CaptureDissolve] thật: nền tan biến bằng shader, nhịp "đang dựng
///   chuyện" → tên vật + 3 nút tròn → ✓ mở [TimelineScreen] thật với hành
///   trình cốc giấy offline → thoát hành trình = xong onboarding, về home.
/// Có "Bỏ qua", chỉ hiện đúng một lần (cờ trong AppSettings).
class OnboardingScreen extends StatefulWidget {
  final OnboardingMission mission;

  /// First-run thì đóng cờ `onboarding_seen`; mission từ notification chỉ là
  /// một capsule khám phá, không ảnh hưởng quyền hiện onboarding lần đầu.
  final bool markOnboardingSeen;

  /// Giọng kể tiêm từ ngoài (test) — null thì tự tạo khi cần, như flow thật.
  final NarrationService? narration;

  /// Nhịp "AI đang dựng chuyện" — flow thật giữ hiệu ứng tối thiểu 1500ms
  /// (minShow ở camera) dù AI trả nhanh; nội dung ở đây bundled có ngay nên
  /// giữ nhịp tương đương cho cảm giác y hệt. Test truyền Duration.zero.
  final Duration buildBeat;

  const OnboardingScreen({
    super.key,
    this.mission = OnboardingMission.firstRun,
    this.markOnboardingSeen = true,
    this.narration,
    this.buildBeat = const Duration(milliseconds: 1700),
  });

  factory OnboardingScreen.mission({
    Key? key,
    required String objectId,
    NarrationService? narration,
    Duration buildBeat = const Duration(milliseconds: 1700),
  }) => OnboardingScreen(
    key: key,
    mission: OnboardingMission.forObjectId(objectId),
    markOnboardingSeen: false,
    narration: narration,
    buildBeat: buildBeat,
  );

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;
  // Ảnh cho hiệu ứng tan biến (CaptureDissolve sở hữu & tự giải phóng).
  ui.Image? _dissolveFrame;
  ui.Image? _dissolveMask;
  // null = đang dựng chuyện; có giá trị = hiện tên + nút như flow thật.
  String? _dissolveTitle;
  ObjectContent? _content;
  bool _journeyStarted = false;
  NarrationService? _narration;

  final ContentRepository _repo = ContentRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nạp sẵn ảnh cảnh để viewfinder giả hiện tức thì.
    precacheImage(AssetImage(widget.mission.sceneAsset), context);
  }

  @override
  void dispose() {
    _narration?.dispose();
    super.dispose();
  }

  /// Giải mã asset → `ui.Image` (mirror `_decodeImage` của camera_screen).
  Future<ui.Image> _decodeAsset(String key, {String? fallback}) async {
    ByteData data;
    try {
      data = await rootBundle.load(key);
    } catch (_) {
      final fb = fallback;
      if (fb == null || fb == key) rethrow;
      data = await rootBundle.load(fb);
    }
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// Mirror `_capture` của camera_screen: chụp tức thì → vào hiệu ứng tan
  /// biến ngay → "AI dựng chuyện" (ở đây: nội dung hero bundled + nhịp chờ).
  Future<void> _capture() async {
    if (_busy || _dissolveFrame != null) return;
    _stopNarration();
    setState(() => _busy = true);
    try {
      final ui.Image frame = await _decodeAsset(
        widget.mission.sceneAsset,
        fallback: OnboardingMission.firstRun.sceneAsset,
      );
      final ui.Image mask;
      try {
        mask = await _decodeAsset(
          widget.mission.cutoutAsset,
          fallback: OnboardingMission.firstRun.cutoutAsset,
        );
      } catch (_) {
        // Chưa bàn giao quyền sở hữu cho CaptureDissolve → tự dọn frame.
        frame.dispose();
        rethrow;
      }
      if (!mounted) {
        frame.dispose();
        mask.dispose();
        return;
      }
      setState(() {
        _dissolveFrame = frame;
        _dissolveMask = mask;
        _dissolveTitle = null;
      });

      final ObjectContent? content = await _repo.load(widget.mission.objectId);
      await Future<void>.delayed(widget.buildBeat);
      // Bé có thể đã bấm Huỷ trong lúc "đang dựng" → đừng bung kết quả.
      if (!mounted || _dissolveFrame == null) return;
      WonderHaptics.success();
      setState(() {
        _content = content;
        _dissolveTitle = content?.name ?? widget.mission.name;
      });
    } catch (e) {
      debugPrint('Onboarding capture error: $e');
      if (mounted) _dismissOverlay();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _dismissOverlay() {
    _stopNarration();
    setState(() {
      _dissolveFrame = null;
      _dissolveMask = null;
      _dissolveTitle = null;
      _content = null;
    });
  }

  NarrationService _narrator() =>
      widget.narration ?? (_narration ??= NarrationService());

  void _stopNarration() {
    widget.narration?.stop();
    _narration?.stop();
  }

  void _speakPrompt() {
    if (!mounted || _journeyStarted || _dissolveFrame != null) return;
    _narrator().speakAsset(
      widget.mission.promptAudio,
      '${widget.mission.promptText} ${widget.mission.promptHint}',
    );
  }

  void _speak(String name) {
    WonderHaptics.selection();
    // Khởi tạo lười — chỉ chạm loa mới đụng plugin TTS/audio.
    _narrator().speakAsset(widget.mission.resultAudio, name);
  }

  /// Nút ✓ — mở hành trình thật ngay trong overlay (same-screen như camera).
  void _openJourney() {
    if (_content == null) {
      // Nội dung hero lỗi (hiếm): đừng kẹt bé lại — coi như xong onboarding.
      _finish();
      return;
    }
    WonderHaptics.primary();
    _stopNarration();
    setState(() => _journeyStarted = true);
  }

  void _finish() {
    unawaited(
      CaptureStore.instance.seedAsset(
        widget.mission.objectId,
        widget.mission.stickerAsset,
      ),
    );
    CollectionRepository().recordHeroId(widget.mission.objectId);
    if (widget.markOnboardingSeen) AppSettings.markOnboardingSeen();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final overlayUp = _dissolveFrame != null;
    final showChrome = !overlayUp;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Cảnh mẫu — đóng vai preview camera. Thiếu asset thì nền tối, flow
          // vẫn chạy (không bao giờ crash vì media).
          Image.asset(
            widget.mission.sceneAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Image.asset(
              OnboardingMission.firstRun.sceneAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: WonderColors.ink),
            ),
          ),
          const _Scrims(),
          // Khung ngắm + câu đố — mờ đi khi overlay lên (như camera).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: _AimChrome(busy: _busy, mission: widget.mission),
              ),
            ),
          ),
          // Thương hiệu (trái) + Bỏ qua (phải) trên scrim đỉnh.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              ignoring: !showChrome,
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const WonderLogo(size: 22, spin: false),
                            const SizedBox(width: 8),
                            Text(
                              'WonderLens',
                              style: WonderType.title.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                                shadows: const <Shadow>[
                                  Shadow(color: Colors.black45, blurRadius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                        GlassSurface(
                          tone: GlassTone.dark,
                          radius: WonderTokens.pill,
                          blur: 0,
                          tintOpacity: 0.35,
                          // vertical 12 → tổng cao ~46px, đạt touch target
                          // ≥44px (DESIGN.md §4) cho ngón tay trẻ.
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onTap: _finish,
                          child: Text(
                            'Bỏ qua',
                            style: WonderType.textButton.copyWith(
                              color: Colors.white,
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
          // Đáy lúc ngắm: đúng nút khẩu độ của màn camera (chụp tức thì,
          // hiệu ứng tan biến lo phần sau — ADR-012).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !showChrome,
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: _CaptureTapCue(
                        active: !_busy,
                        buttonSize: WonderTokens.scanSize,
                        child: ApertureCaptureButton(
                          size: WonderTokens.scanSize,
                          busy: _busy,
                          showGuide: false,
                          animateOnTap: false,
                          onCapture: _busy ? null : _capture,
                          semanticLabel: 'Chụp thử ${widget.mission.name}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay tan biến / hành trình — same-screen như camera_screen.
          AnimatedSwitcher(
            duration: WonderTokens.durBase,
            reverseDuration: WonderTokens.durBase,
            switchInCurve: WonderTokens.curveStandard,
            switchOutCurve: WonderTokens.curveStandard,
            child: _buildOverlay(),
          ),
        ],
      ),
    );
  }

  /// Mirror `_buildOverlay` của camera_screen: tan biến → kết quả → hành
  /// trình, tất cả crossfade trong một AnimatedSwitcher.
  Widget _buildOverlay() {
    if (_journeyStarted && _content != null) {
      return TimelineScreen(
        key: const ValueKey<String>('journey'),
        content: _content,
        narration: widget.narration,
        // Xem xong (hoặc đóng) hành trình = onboarding trọn vẹn → về home.
        onExit: _finish,
      );
    }
    final frame = _dissolveFrame;
    final mask = _dissolveMask;
    if (frame != null && mask != null) {
      final title = _dissolveTitle;
      return CaptureDissolve(
        key: const ValueKey<String>('dissolve'),
        frame: frame,
        mask: mask,
        title: title,
        // Tâm cốc trong ảnh — glow/halftone toả đúng quanh vật.
        center: const Offset(0.5, _AimChrome.subjectCenterFrac),
        onOpen: _openJourney,
        onRetake: _dismissOverlay,
        onSpeak: title != null ? () => _speak(title) : null,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Cue hình ảnh "bấm vào đây" cho nút capture: vòng pulse + dấu chạm nhỏ.
/// Không dùng chữ để tránh cạnh tranh với câu đố và giữ onboarding dưới 10s.
class _CaptureTapCue extends StatefulWidget {
  final bool active;
  final double buttonSize;
  final Widget child;

  const _CaptureTapCue({
    required this.active,
    required this.buttonSize,
    required this.child,
  });

  @override
  State<_CaptureTapCue> createState() => _CaptureTapCueState();
}

class _CaptureTapCueState extends State<_CaptureTapCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _CaptureTapCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    final boxSize = widget.buttonSize * 1.48;
    final cue = RepaintBoundary(
      child: CustomPaint(
        painter: _CaptureTapCuePainter(
          progress: reduce || !widget.active ? 0.58 : _pulse.value,
          buttonSize: widget.buttonSize,
          active: widget.active,
        ),
      ),
    );

    return SizedBox.square(
      dimension: boxSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: IgnorePointer(child: cue)),
          widget.child,
        ],
      ),
    );
  }
}

class _CaptureTapCuePainter extends CustomPainter {
  final double progress;
  final double buttonSize;
  final bool active;

  const _CaptureTapCuePainter({
    required this.progress,
    required this.buttonSize,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = buttonSize / 2;
    final p = progress.clamp(0.0, 1.0);
    final pulse = Curves.easeOutCubic.transform(p);
    final contact = (1 - ((p - 0.50).abs() / 0.18).clamp(0.0, 1.0));

    final outer = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = Colors.white.withValues(
        alpha: active ? 0.28 * (1 - pulse) : 0.22,
      );
    canvas.drawCircle(c, r * (1.04 + 0.24 * pulse), outer);

    final inner = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = WonderColors.mint.withValues(
        alpha: active ? 0.55 * contact : 0.38,
      );
    canvas.drawCircle(c, r * (0.74 + 0.10 * contact), inner);

    final arcPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2
      ..color = Colors.white.withValues(alpha: active ? 0.70 : 0.48);
    final rect = Rect.fromCircle(center: c, radius: r * 0.98);
    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 0.18, false, arcPaint);
    canvas.drawArc(rect, -math.pi * 0.18, math.pi * 0.18, false, arcPaint);

    final start = c + Offset(r * 0.72, -r * 0.78);
    final end = c + Offset(r * 0.28, -r * 0.30);
    final approach = p < 0.52
        ? Curves.easeOutCubic.transform(p / 0.52)
        : Curves.easeInOut.transform(((1 - p) / 0.48).clamp(0.0, 1.0));
    final tip = Offset.lerp(start, end, approach)!;

    final shadow = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawCircle(tip + const Offset(0, 2), 13, shadow);

    final finger = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: active ? 0.95 : 0.75);
    canvas.drawCircle(tip, 12, finger);

    final nail = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = WonderColors.coral.withValues(alpha: 0.58);
    canvas.drawArc(
      Rect.fromCircle(center: tip.translate(-1, -1), radius: 7),
      -math.pi * 0.85,
      math.pi * 0.58,
      false,
      nail,
    );

    if (contact > 0) {
      final spark = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.58 * contact);
      canvas.drawCircle(end, 18 + 10 * (1 - contact), spark);
    }
  }

  @override
  bool shouldRepaint(covariant _CaptureTapCuePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.buttonSize != buttonSize ||
      oldDelegate.active != active;
}

/// Khung ngắm 4 góc + câu đố mời chụp — dáng góc đồng bộ `_CornersPainter`
/// của camera_screen.dart. Khác camera thật (khung căn giữa, người dùng tự
/// lia máy cho vật vào khung): cảnh ở đây cố định nên khung tự hạ xuống ôm
/// chiếc cốc, còn câu đố nằm TRÊN khung trong hộp kính tối — vùng giữa ảnh
/// sáng màu, chữ trắng trần không đủ tương phản.
class _AimChrome extends StatelessWidget {
  final bool busy;
  final OnboardingMission mission;

  const _AimChrome({required this.busy, required this.mission});

  /// Tâm chủ thể theo trục dọc của ảnh scene (đo từ bbox alpha của cutout).
  /// Màn dọc cover chỉ crop chiều ngang nên tỉ lệ dọc giữ nguyên mọi phone.
  static const double subjectCenterFrac = 0.615;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final side = math.min(w * 0.74, h * 0.46);
        // Chừa 120px hai đầu cho hàng thương hiệu (trên) và nút chụp (dưới).
        final frameTop = (h * subjectCenterFrac - side / 2)
            .clamp(120.0, math.max(120.0, h - side - 120.0))
            .toDouble();
        return Stack(
          children: <Widget>[
            Positioned(
              top: frameTop,
              left: (w - side) / 2,
              width: side,
              height: side,
              child: CustomPaint(painter: _CornersPainter()),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: h - frameTop + 14,
              child: Center(
                child: GlassSurface(
                  tone: GlassTone.dark,
                  radius: WonderTokens.radiusLg,
                  blur: 0,
                  tintOpacity: 0.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        busy ? 'Đang soi manh mối…' : mission.promptText,
                        textAlign: TextAlign.center,
                        style: WonderType.body.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (!busy) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          mission.promptHint,
                          textAlign: TextAlign.center,
                          style: WonderType.heading.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Scrim tối 2 đầu màn — cùng thông số với `_Scrims` của camera_screen.dart.
class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: <Widget>[
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.42),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bản sao dáng `_CornersPainter` (camera_screen.dart) — 4 góc trắng bo mềm.
class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final m = math.min(size.width, size.height);
    final len = m * 0.26;
    final r = m * 0.1;
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    void corner(Offset o, Offset h, Offset v) {
      final cross = h.dx * v.dy - h.dy * v.dx;
      final path = Path()
        ..moveTo(o.dx + h.dx * len, o.dy + h.dy * len)
        ..lineTo(o.dx + h.dx * r, o.dy + h.dy * r)
        ..arcToPoint(
          Offset(o.dx + v.dx * r, o.dy + v.dy * r),
          radius: Radius.circular(r),
          clockwise: cross < 0,
        )
        ..lineTo(o.dx + v.dx * len, o.dy + v.dy * len);
      canvas.drawPath(path, shadow);
      canvas.drawPath(path, line);
    }

    final w = size.width;
    final h = size.height;
    corner(Offset.zero, const Offset(1, 0), const Offset(0, 1));
    corner(Offset(w, 0), const Offset(-1, 0), const Offset(0, 1));
    corner(Offset(0, h), const Offset(1, 0), const Offset(0, -1));
    corner(Offset(w, h), const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) => false;
}
