import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_route_observer.dart';
import '../data/capture_store.dart';
import '../data/content_repository.dart';
import '../services/camera_warmup.dart';
import '../models/object_content.dart';
import '../services/generate_service.dart';
import '../services/image_cutout.dart';
import '../services/journey_warmup.dart';
import '../services/narration_service.dart';
import '../services/recognition_service.dart';
import '../services/segmentation_service.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';
import 'timeline_screen.dart';

/// Màn khám phá tối giản kiểu CapWords: preview camera tràn màn hình + 4 góc
/// ngắm, một dòng gợi ý và nút quét cầu vồng. Chụp xong → nền ảnh **tan biến**
/// và **viền chủ thể được vẽ dần** (fragment shader) trong lúc AI dựng chuyện.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _busy = false;

  // Controller + trạng thái lỗi lấy từ CameraWarmup (đã nạp sẵn từ trang chủ).
  CameraController? get _controller => CameraWarmup.instance.controller;
  String? get _error => CameraWarmup.instance.error;
  bool get _permanentlyDenied => CameraWarmup.instance.permanentlyDenied;

  String? _msgTitle;
  String? _msgBody;

  // Ảnh cho hiệu ứng tan biến (widget CaptureDissolve sở hữu & tự giải phóng).
  ui.Image? _dissolveFrame;
  ui.Image? _dissolveMask;
  // Kết quả AI: null lúc đang dựng → set khi xong để hiện tên + nút NGAY trên
  // màn tách-nền (không modal, không quay về camera).
  ObjectContent? _dissolveContent;
  // Same-screen: ấn ✓ → bật hành trình NGAY trong overlay (không điều hướng).
  bool _journeyStarted = false;

  final _service = RecognitionService();
  final _generate = GenerateService();
  final _repo = ContentRepository();
  final _segmentation = SegmentationService();
  final _narration = NarrationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _narration.dispose();
    // Rời màn camera → nhả AVCaptureSession (đừng giữ máy ảnh khi về home).
    unawaited(CameraWarmup.instance.release());
    super.dispose();
  }

  /// Bị màn khác (timeline) phủ lên → nhả camera để khỏi giữ AVCaptureSession
  /// (tránh xung đột với video player) và để preview không đen khi quay lại.
  @override
  void didPushNext() {
    unawaited(CameraWarmup.instance.release());
    if (mounted) setState(() {});
  }

  /// Quay lại màn camera → dọn overlay khám phá (được giữ lại làm nguồn hero
  /// trong lúc chuyển màn) rồi mở lại camera.
  @override
  void didPopNext() {
    _msgTitle = null;
    _msgBody = null;
    _dissolveFrame = null;
    _dissolveMask = null;
    _dissolveContent = null;
    _setup();
  }

  /// Thu hồi/khởi tạo lại camera theo vòng đời app để tránh preview đen khi
  /// quay lại từ background (OS có thể thu hồi camera).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (CameraWarmup.instance.isReady) {
        unawaited(CameraWarmup.instance.release());
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  /// Đảm bảo camera sẵn sàng — thường đã được trang chủ nạp sẵn trong lúc vòng
  /// khẩu độ xoay, nên hầu như trả về ngay. Idempotent.
  Future<void> _setup() async {
    await CameraWarmup.instance.prewarm();
    if (mounted) setState(() {});
  }

  /// Thử lại sau lỗi (quyền/thiết bị).
  Future<void> _retry() async {
    await CameraWarmup.instance.retry();
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    WonderHaptics.primary();
    setState(() => _busy = true);
    XFile? shot;
    try {
      shot = await controller.takePicture();
      final Uint8List bytes = await File(shot.path).readAsBytes();

      // LUÔN để AI sinh hành trình cho MỌI vật. Cần proxy + token; offline/lỗi
      // → báo thân thiện, không vào hiệu ứng.
      if (!GenerateService.available) {
        _presentMessage(
          'Cần kết nối để AI kể chuyện',
          'Bé bật wifi rồi quét lại nhé!',
        );
        return;
      }

      // Tách nền (offline) MỘT lần: foreground toàn khung dùng cho hiệu ứng tan
      // biến, đồng thời cắt sát để lưu cutout vào bộ sưu tập.
      final Uint8List? raw = await _segmentation.foreground(shot.path);
      if (!mounted) return;

      // Flutter tự áp EXIF khi decode (kiểm chứng trên máy) → frame đã dựng đứng,
      // khớp mask native (cũng đã dựng đứng). KHÔNG tự xoay thêm ở Dart, kẻo
      // xoay chồng thành ảnh nằm ngang.
      final ui.Image frameImage = await _decodeImage(bytes);
      final ui.Image maskImage;
      try {
        maskImage = await _resolveMask(raw, frameImage);
      } catch (_) {
        // Chưa bàn giao quyền sở hữu cho CaptureDissolve → tự dọn frameImage.
        frameImage.dispose();
        rethrow;
      }
      if (!mounted) {
        frameImage.dispose();
        maskImage.dispose();
        return;
      }

      // Vào hiệu ứng tan biến + chạy AI song song. minShow đảm bảo hiệu ứng
      // luôn được chạy trọn dù AI trả về nhanh.
      _showDissolve(frameImage, maskImage);
      final Future<void> minShow =
          Future<void>.delayed(const Duration(milliseconds: 1500));
      ObjectContent? content = await _generate.generate(bytes);
      if (!mounted) return;

      // AI lỗi/hết quota → rớt về vật hero (dữ liệu đóng gói) để không kẹt
      // "bí ẩn" và vẫn dựng đủ hành trình cho việc test UI offline / hết credit.
      content ??= await _repo.load(_service.mockOffline().objectId);
      if (!mounted) return;
      if (content == null) {
        _presentMessage(
          'Món này còn hơi bí ẩn',
          'Bé thử đổi góc chụp hoặc quét lại nhé!',
        );
        return;
      }
      final ObjectContent live = content;
      // Sinh ngầm MỌI thứ (ảnh chặng + giọng đọc + phim) NGAY khi có nội dung —
      // để lúc bé vào timeline đã có sẵn, không phải chờ.
      JourneyWarmup.instance.start(live);
      if (raw != null) {
        final Uint8List? cut = await tightCropTransparentPng(raw);
        if (cut != null) await CaptureStore.instance.save(live.id, cut);
      }
      await minShow;
      // Bé có thể đã bấm "Huỷ" lúc đang dựng (overlay đã dọn) → đừng bung kết quả.
      if (!mounted || _dissolveFrame == null) return;
      // Hiện kết quả NGAY trên màn tách-nền: tên + nút mở hành trình.
      WonderHaptics.success();
      setState(() => _dissolveContent = live);
    } catch (e) {
      debugPrint('Capture error: $e');
      if (!mounted) return;
      _presentMessage('Ống kính chưa bắt kịp', 'Bé thử quét lại lần nữa nhé!');
    } finally {
      if (shot != null) {
        final path = shot.path;
        unawaited(File(path).delete().catchError((_) => File(path)));
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runMockDiscovery() async {
    if (_busy) return;
    WonderHaptics.selection();
    setState(() => _busy = true);
    try {
      final result = _service.mockOffline();
      final content = await _repo.load(result.objectId);
      if (!mounted) return;
      if (content == null) {
        _presentMessage(
          'Demo chưa có nội dung',
          'Mình chưa tìm thấy dữ liệu cho ${result.displayName}.',
        );
        return;
      }
      // Mock không có ảnh chụp → vào thẳng hành trình (demo simulator).
      _openJourney(content);
    } catch (e) {
      debugPrint('Mock discovery error: $e');
      if (!mounted) return;
      _presentMessage('Demo chưa sẵn sàng', 'Bé thử bấm lại lần nữa nhé!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Giải mã bytes ảnh → `ui.Image` (Flutter tự áp EXIF orientation).
  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// Mask cho hiệu ứng tan biến: chỉ dùng foreground native khi **cùng tỉ lệ
  /// khung** với ảnh gốc (đảm bảo chủ thể khớp toạ độ). Lệch tỉ lệ (native cắt
  /// sát bbox / xoay 90°) hoặc không tách được → mask 1x1 trong suốt: cả khung
  /// tan biến — không bao giờ xoá nền sai chỗ chủ thể.
  Future<ui.Image> _resolveMask(Uint8List? raw, ui.Image frame) async {
    if (raw == null) return _transparentPixel();
    final ui.Image decoded = await _decodeImage(raw);
    if (_aspectClose(decoded, frame)) return decoded;
    debugPrint(
      'Dissolve mask lệch khung (${decoded.width}x${decoded.height} vs '
      '${frame.width}x${frame.height}) → tan biến cả khung.',
    );
    decoded.dispose();
    return _transparentPixel();
  }

  /// Hai ảnh coi là cùng khung khi tỉ lệ w/h sai lệch ≤ 4%.
  static bool _aspectClose(ui.Image a, ui.Image b) {
    if (a.width == 0 || a.height == 0 || b.width == 0 || b.height == 0) {
      return false;
    }
    final double ar = a.width / a.height;
    final double br = b.width / b.height;
    return (ar - br).abs() <= br * 0.04;
  }

  /// Mask 1x1 trong suốt khi không tách được chủ thể → cả khung ảnh tan biến.
  Future<ui.Image> _transparentPixel() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas(recorder);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(1, 1);
    picture.dispose();
    return img;
  }

  void _showDissolve(ui.Image frame, ui.Image mask) {
    setState(() {
      _dissolveFrame = frame;
      _dissolveMask = mask;
      _dissolveContent = null;
      _msgTitle = null;
      _msgBody = null;
    });
  }

  void _presentMessage(String title, String body) {
    WonderHaptics.tick();
    setState(() {
      _msgTitle = title;
      _msgBody = body;
      _dissolveFrame = null;
      _dissolveMask = null;
      _dissolveContent = null;
    });
  }

  void _dismissOverlay() {
    _narration.stop();
    setState(() {
      _msgTitle = null;
      _msgBody = null;
      _dissolveFrame = null;
      _dissolveMask = null;
      _dissolveContent = null;
    });
  }

  void _speak(String name) {
    WonderHaptics.selection();
    _narration.speak(name);
  }

  void _openJourney(ObjectContent content) {
    // SAME-SCREEN: không điều hướng — bật hành trình NGAY trong overlay. Cùng
    // AnimatedSwitcher đang bọc _buildOverlay() sẽ crossfade CaptureDissolve →
    // TimelineScreen (liền mạch, không "nhảy sang màn khác").
    WonderHaptics.primary();
    _narration.stop();
    // Nhả camera khi đang xem hành trình (overlay phủ kín preview).
    unawaited(CameraWarmup.instance.release());
    setState(() => _journeyStarted = true);
  }

  /// Đóng hành trình → quay lại chụp: dọn overlay + mở lại camera.
  void _closeJourney() {
    setState(() {
      _journeyStarted = false;
      _dissolveFrame = null;
      _dissolveMask = null;
      _dissolveContent = null;
      _msgTitle = null;
      _msgBody = null;
    });
    _setup();
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        (_controller?.value.isInitialized ?? false) && _error == null;
    final overlayUp = _msgTitle != null || _dissolveFrame != null;
    final showChrome = cameraReady && !overlayUp;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildPreview(),
          const _Scrims(),
          // 4 góc ngắm canh giữa — mờ đi khi có overlay/chưa sẵn sàng.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: const _FramingCorners(),
              ),
            ),
          ),
          // Thanh trên: ngày + nút về phòng khám phá.
          SafeArea(
            child: IgnorePointer(
              ignoring: !showChrome,
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: _TopBar(
                  onHome: () => context.go('/home'),
                  onSecret: () => showDevPanel(context),
                ),
              ),
            ),
          ),
          // Đáy: gợi ý + nút quét cầu vồng + nút rương.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !showChrome,
              child: AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: WonderTokens.durBase,
                child: _BottomBar(
                  busy: _busy,
                  onScan: _busy ? null : _capture,
                  onCollection: () => context.push('/collection'),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: WonderTokens.durBase,
            reverseDuration: WonderTokens.durFast,
            switchInCurve: WonderTokens.curveStandard,
            switchOutCurve: WonderTokens.curveStandard,
            child: _buildOverlay(),
          ),
        ],
      ),
    );
  }

  /// Lớp phủ hiện hành (tan biến+kết quả / thông báo) qua một AnimatedSwitcher
  /// chung: vào crossfade, ra mờ nhanh hơn vào. Kết quả AI hiện NGAY trong
  /// [CaptureDissolve] (đổi từ loading sang tên+nút) — không modal riêng.
  Widget _buildOverlay() {
    if (_msgTitle != null) {
      return _MessageOverlay(
        title: _msgTitle!,
        body: _msgBody ?? '',
        onRetake: _dismissOverlay,
      );
    }
    // Same-screen: hành trình nhúng thẳng (crossfade từ CaptureDissolve).
    if (_journeyStarted && _dissolveContent != null) {
      return TimelineScreen(
        key: const ValueKey<String>('journey'),
        content: _dissolveContent,
        onExit: _closeJourney,
      );
    }
    final frame = _dissolveFrame;
    final mask = _dissolveMask;
    if (frame != null && mask != null) {
      final content = _dissolveContent;
      return CaptureDissolve(
        key: const ValueKey<String>('dissolve'),
        frame: frame,
        mask: mask,
        title: content?.name,
        onOpen: () {
          if (content != null) _openJourney(content);
        },
        onRetake: _dismissOverlay,
        onSpeak: content != null ? () => _speak(content.name) : null,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPreview() {
    // Không còn card "Đang bật ống kính": máy ảnh đã nạp sẵn từ trang chủ
    // trong lúc vòng khẩu độ xoay. Chưa kịp sẵn sàng → nền đen thoáng qua.
    if (_error != null) {
      final demoMode = !_permanentlyDenied && !kReleaseMode;
      return _StatusCard(
        icon: demoMode
            ? PhosphorIconsFill.sparkle
            : PhosphorIconsDuotone.lockSimple,
        kicker: demoMode ? 'Demo trên simulator' : null,
        title: demoMode ? 'Simulator chưa có camera thật' : _error!,
        body: demoMode
            ? 'Bé vẫn có thể chạy một màn quét mẫu để đi trọn hành trình WonderLens.'
            : _permanentlyDenied
            ? 'Vào Cài đặt bật camera để bé tiếp tục hành trình nhé.'
            : 'Chạm để khởi động lại ống kính nào!',
        accent: demoMode ? WonderColors.grape : WonderColors.cyan,
        actionLabel: _permanentlyDenied ? 'Mở Cài đặt' : 'Thử lại ống kính',
        actionIcon: PhosphorIconsBold.arrowClockwise,
        onAction: _permanentlyDenied ? openAppSettings : _retry,
        secondaryActionLabel: demoMode ? 'Chạy demo mock' : null,
        secondaryActionIcon: PhosphorIconsFill.sparkle,
        onSecondaryAction: demoMode ? _runMockDiscovery : null,
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return _CoverPreview(controller: controller);
  }
}

/// Preview camera phủ kín màn hình (cover) — Transform.scale để không viền đen.
class _CoverPreview extends StatelessWidget {
  final CameraController controller;
  const _CoverPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceRatio = constraints.maxWidth / constraints.maxHeight;
        var scale = controller.value.aspectRatio * deviceRatio;
        if (scale < 1) scale = 1 / scale;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(child: CameraPreview(controller)),
          ),
        );
      },
    );
  }
}

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

/// Thanh trên tối giản: ngày (nhấn giữ = mở Dev panel) + nút về phòng khám phá.
class _TopBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onSecret;

  const _TopBar({required this.onHome, required this.onSecret});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onSecret,
              child: Text(
                _friendlyDate(),
                style: WonderType.display.copyWith(
                  color: Colors.white,
                  fontSize: 25,
                  shadows: const <Shadow>[
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GlassIconButton(
            icon: PhosphorIconsBold.houseSimple,
            size: 44,
            blur: 0,
            semanticLabel: 'Về phòng khám phá',
            onTap: onHome,
          ),
        ],
      ),
    );
  }
}

/// Đáy: dòng gợi ý + nút quét cầu vồng canh giữa, nút rương nổi bên phải.
class _BottomBar extends StatelessWidget {
  final bool busy;
  final VoidCallback? onScan;
  final VoidCallback onCollection;

  const _BottomBar({
    required this.busy,
    required this.onScan,
    required this.onCollection,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _HintText(busy: busy),
            const SizedBox(height: 20),
            SizedBox(
              height: WonderTokens.scanSize + 6,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Center(
                    child: ApertureCaptureButton(
                      size: WonderTokens.scanSize,
                      busy: busy,
                      showGuide: false,
                      animateOnTap: false,
                      onCapture: onScan,
                      semanticLabel: 'Chụp để soi đồ vật',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GlassIconButton(
                        icon: PhosphorIconsFill.image,
                        size: 52,
                        blur: 0,
                        semanticLabel: 'Rương khám phá',
                        onTap: onCollection,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final bool busy;
  const _HintText({required this.busy});

  static const List<Shadow> _shadow = <Shadow>[
    Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Text(
        'Đang soi manh mối…',
        textAlign: TextAlign.center,
        style: WonderType.body.copyWith(color: Colors.white, shadows: _shadow),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Món này là gì nhỉ?',
          textAlign: TextAlign.center,
          style: WonderType.body.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
            shadows: _shadow,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          const TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'Chạm để '),
              TextSpan(
                text: 'mở hành trình!',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: WonderType.body.copyWith(color: Colors.white, shadows: _shadow),
        ),
      ],
    );
  }
}

/// 4 góc ngắm canh giữa kiểu CapWords — vẽ bằng CustomPaint cho nét gọn.
class _FramingCorners extends StatelessWidget {
  const _FramingCorners();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth * 0.74,
          constraints.maxHeight * 0.46,
        );
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: CustomPaint(painter: _CornersPainter()),
          ),
        );
      },
    );
  }
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final len = math.min(size.width, size.height) * 0.18;
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    void corner(Offset o, Offset h, Offset v) {
      final path = Path()
        ..moveTo(o.dx + h.dx * len, o.dy + h.dy * len)
        ..lineTo(o.dx, o.dy)
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

/// Ngày thân thiện cho trẻ, ví dụ "7 tháng 7".
String _friendlyDate() {
  final d = DateTime.now();
  return '${d.day} tháng ${d.month}';
}

class _MessageOverlay extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onRetake;

  const _MessageOverlay({
    required this.title,
    required this.body,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      child: GlassSurface(
        radius: WonderTokens.radiusLg,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        tintOpacity: 0.42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Center(
              child: PhosphorIcon(
                PhosphorIconsDuotone.binoculars,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            WonderButton(
              label: 'Soi lại',
              icon: PhosphorIconsBold.arrowClockwise,
              onTap: onRetake,
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung phủ tối + canh đáy + nảy lên cho các thẻ overlay. Không Positioned
/// để sống được trong AnimatedSwitcher (fade vào/ra do switcher đảm nhiệm,
/// ở đây chỉ giữ cú nảy scale lúc vào).
class _OverlayShell extends StatelessWidget {
  final Widget child;
  const _OverlayShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.45),
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .scaleXY(
          begin: 0.92,
          end: 1,
          duration: WonderTokens.durSlow,
          curve: WonderTokens.curveEmphasized,
        );
  }
}

/// Trạng thái khởi tạo/lỗi camera — vẫn giữ tông kính sang, không phải spinner trơ.
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String? kicker;
  final String title;
  final String body;
  final Color accent;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  const _StatusCard({
    required this.icon,
    this.kicker,
    required this.title,
    required this.body,
    this.accent = WonderColors.cyan,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF102036), WonderColors.ink],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -130,
            right: -80,
            child: _StatusGlow(color: WonderColors.sky.withValues(alpha: 0.62)),
          ),
          Positioned(
            bottom: -150,
            left: -90,
            child: _StatusGlow(
              color: WonderColors.grape.withValues(alpha: 0.58),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: GlassSurface(
                  tone: GlassTone.dark,
                  radius: WonderTokens.radiusXl,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  blur: 0,
                  tintOpacity: 0.42,
                  shadows: WonderShadows.glow(accent, opacity: 0.20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: _StatusOrb(icon: icon, accent: accent),
                      ),
                      if (kicker != null) ...<Widget>[
                        const SizedBox(height: 18),
                        Center(
                          child: WonderChip(
                            label: kicker!,
                            icon: PhosphorIconsFill.sparkle,
                            color: accent,
                          ),
                        ),
                      ] else
                        const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: WonderType.title.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: WonderType.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          height: 1.36,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...<Widget>[
                        const SizedBox(height: 24),
                        Center(
                          child: WonderButton(
                            label: actionLabel!,
                            icon: actionIcon,
                            expand: false,
                            onTap: onAction,
                          ),
                        ),
                      ],
                      if (secondaryActionLabel != null &&
                          onSecondaryAction != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Center(
                          child: WonderButton(
                            label: secondaryActionLabel!,
                            icon: secondaryActionIcon,
                            expand: false,
                            gradient: const LinearGradient(
                              colors: <Color>[
                                WonderColors.grape,
                                WonderColors.indigo,
                              ],
                            ),
                            onTap: onSecondaryAction,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGlow extends StatelessWidget {
  final Color color;

  const _StatusGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.42),
              color.withValues(alpha: 0.12),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.46, 1],
          ),
        ),
      ),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _StatusOrb({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: WonderGradients.ring),
              boxShadow: WonderShadows.glow(accent, opacity: 0.32),
            ),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WonderColors.inkSoft.withValues(alpha: 0.94),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
            ),
            child: Center(
              child: PhosphorIcon(icon, size: 42, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
