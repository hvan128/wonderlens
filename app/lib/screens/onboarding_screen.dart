import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/app_settings.dart';
import '../data/content_repository.dart';
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
  /// Giọng kể tiêm từ ngoài (test) — null thì tự tạo khi cần, như flow thật.
  final NarrationService? narration;

  /// Nhịp "AI đang dựng chuyện" — flow thật giữ hiệu ứng tối thiểu 1500ms
  /// (minShow ở camera) dù AI trả nhanh; nội dung ở đây bundled có ngay nên
  /// giữ nhịp tương đương cho cảm giác y hệt. Test truyền Duration.zero.
  final Duration buildBeat;

  const OnboardingScreen({
    super.key,
    this.narration,
    this.buildBeat = const Duration(milliseconds: 1700),
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _heroId = 'paper_cup';
  static const String _sceneAsset = 'assets/images/onboarding_scene.jpg';
  static const String _cutoutAsset = 'assets/images/onboarding_cutout.png';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nạp sẵn ảnh cảnh để viewfinder giả hiện tức thì.
    precacheImage(const AssetImage(_sceneAsset), context);
  }

  @override
  void dispose() {
    _narration?.dispose();
    super.dispose();
  }

  /// Giải mã asset → `ui.Image` (mirror `_decodeImage` của camera_screen).
  Future<ui.Image> _decodeAsset(String key) async {
    final ByteData data = await rootBundle.load(key);
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
    setState(() => _busy = true);
    try {
      final ui.Image frame = await _decodeAsset(_sceneAsset);
      final ui.Image mask;
      try {
        mask = await _decodeAsset(_cutoutAsset);
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

      final ObjectContent? content = await _repo.load(_heroId);
      await Future<void>.delayed(widget.buildBeat);
      // Bé có thể đã bấm Huỷ trong lúc "đang dựng" → đừng bung kết quả.
      if (!mounted || _dissolveFrame == null) return;
      WonderHaptics.success();
      setState(() {
        _content = content;
        _dissolveTitle = content?.name ?? 'Cốc giấy';
      });
    } catch (e) {
      debugPrint('Onboarding capture error: $e');
      if (mounted) _dismissOverlay();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _dismissOverlay() {
    _narration?.stop();
    setState(() {
      _dissolveFrame = null;
      _dissolveMask = null;
      _dissolveTitle = null;
      _content = null;
    });
  }

  void _speak(String name) {
    WonderHaptics.selection();
    // Khởi tạo lười — chỉ chạm loa mới đụng plugin TTS/audio.
    (widget.narration ?? (_narration ??= NarrationService())).speak(name);
  }

  /// Nút ✓ — mở hành trình thật ngay trong overlay (same-screen như camera).
  void _openJourney() {
    if (_content == null) {
      // Nội dung hero lỗi (hiếm): đừng kẹt bé lại — coi như xong onboarding.
      _finish();
      return;
    }
    WonderHaptics.primary();
    _narration?.stop();
    setState(() => _journeyStarted = true);
  }

  void _finish() {
    AppSettings.markOnboardingSeen();
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
            _sceneAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: WonderColors.ink),
          ),
          const _Scrims(),
          // Khung ngắm + câu đố — mờ đi khi overlay lên (như camera).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: _AimChrome(busy: _busy),
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
                      child: ApertureCaptureButton(
                        size: WonderTokens.scanSize,
                        busy: _busy,
                        showGuide: false,
                        animateOnTap: false,
                        onCapture: _busy ? null : _capture,
                        semanticLabel: 'Chụp thử chiếc cốc',
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

/// Khung ngắm 4 góc + câu đố mời chụp — dáng góc đồng bộ `_CornersPainter`
/// của camera_screen.dart. Khác camera thật (khung căn giữa, người dùng tự
/// lia máy cho vật vào khung): cảnh ở đây cố định nên khung tự hạ xuống ôm
/// chiếc cốc, còn câu đố nằm TRÊN khung trong hộp kính tối — vùng giữa ảnh
/// sáng màu, chữ trắng trần không đủ tương phản.
class _AimChrome extends StatelessWidget {
  final bool busy;
  const _AimChrome({required this.busy});

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
                        busy
                            ? 'Đang soi manh mối…'
                            : 'Đố bé biết chiếc cốc này từ đâu tới?',
                        textAlign: TextAlign.center,
                        style: WonderType.body.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (!busy) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          'Chạm nút tròn bên dưới để chụp thử nhé!',
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
