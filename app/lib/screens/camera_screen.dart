import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_route_observer.dart';
import '../data/capture_store.dart';
import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../models/journey_args.dart';
import '../models/object_content.dart';
import '../services/generate_service.dart';
import '../services/recognition_service.dart';
import '../services/segmentation_service.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';

/// Màn 2 · Khung ngắm. Preview camera tràn màn hình + lớp điều khiển + mascot Tia.
/// Nhận diện qua proxy; tách nền + lưu ảnh sản phẩm (offline) rồi sang màn Xác
/// nhận. Toàn bộ logic camera/permission/nhận diện giữ nguyên. Bám mockup `.s-cam`.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, RouteAware {
  CameraController? _controller;
  bool _initializing = true;
  bool _busy = false;
  bool _permanentlyDenied = false;
  bool _settingUp = false;
  bool _generating = false;
  bool _torch = false;
  String? _error;

  String? _msgTitle;
  String? _msgBody;

  final _service = RecognitionService();
  final _generate = GenerateService();
  final _repo = ContentRepository();
  final _segmentation = SegmentationService();

  static const double _confidenceThreshold = 0.6;

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
    _controller?.dispose();
    super.dispose();
  }

  /// Bị màn khác (confirm/timeline) phủ lên → nhả camera để khỏi giữ
  /// AVCaptureSession (tránh xung đột với video player) và preview không đen.
  @override
  void didPushNext() {
    final c = _controller;
    _controller = null;
    c?.dispose();
    if (mounted) setState(() {});
  }

  /// Quay lại màn camera → mở lại camera.
  @override
  void didPopNext() {
    _setup();
  }

  /// Thu hồi/khởi tạo lại camera theo vòng đời app để tránh preview đen khi
  /// quay lại từ background (OS có thể thu hồi camera).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  Future<void> _setup() async {
    if (_settingUp) return;
    _settingUp = true;
    final old = _controller;
    _controller = null;
    await old?.dispose();
    if (!mounted) {
      _settingUp = false;
      return;
    }
    setState(() {
      _initializing = true;
      _error = null;
      _permanentlyDenied = false;
      _torch = false;
    });
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        setState(() {
          _permanentlyDenied = status.isPermanentlyDenied;
          _error = 'Cần quyền camera để khám phá nhé!';
          _initializing = false;
        });
        return;
      }
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _error = 'Không tìm thấy camera trên thiết bị.';
          _initializing = false;
        });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      debugPrint('Camera setup error: $e');
      if (mounted) {
        setState(() {
          _error = 'Chưa mở được máy ảnh. Bạn thử lại nhé!';
          _initializing = false;
        });
      }
    } finally {
      _settingUp = false;
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    XFile? shot;
    try {
      shot = await controller.takePicture();
      final bytes = await File(shot.path).readAsBytes();
      // Tách nền chạy song song nhận diện (offline, độc lập với mạng). Await ở
      // đây để chắc chắn native đọc xong file trước khi `finally` xoá ảnh tạm.
      final cutoutFuture = _segmentation.cutout(shot.path);
      final result = await _service.recognize(bytes);
      final cutout = await cutoutFuture;
      if (!mounted) return;

      // Lưu "ảnh sản phẩm" cho id vật đã quyết (hero, mock, hoặc AI-live).
      Future<void> saveCapture(String id) async {
        if (cutout == null) return;
        await CaptureStore.instance.save(id, cutout);
      }

      ObjectContent? content;
      if (result.objectId != 'unknown') {
        content = await _repo.load(result.objectId);
        if (!mounted) return;
      }
      if (content != null) {
        await saveCapture(content.id);
        if (!mounted) return;
        _toConfirm(
          content,
          confident: result.confidence >= _confidenceThreshold,
          confidence: result.confidence,
        );
        return;
      }

      if (!GenerateService.available) {
        _presentMessage(
          'Mình chưa nhận ra món này',
          'Thử chĩa gần hơn vào một đồ vật rồi quét lại nhé!',
        );
        return;
      }
      setState(() => _generating = true);
      final live = await _generate.generate(bytes);
      if (!mounted) return;
      setState(() => _generating = false);
      if (live == null) {
        _presentMessage(
          'Mình chưa khám phá được món này',
          'Thử một đồ vật khác nhé!',
        );
      } else {
        await saveCapture(live.id);
        if (!mounted) return;
        _toConfirm(live, confident: true, confidence: null);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (!mounted) return;
      _presentMessage('Quét chưa được', 'Bạn thử lại lần nữa nhé!');
    } finally {
      if (shot != null) {
        final path = shot.path;
        unawaited(File(path).delete().catchError((_) => File(path)));
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toConfirm(
    ObjectContent content, {
    required bool confident,
    required double? confidence,
  }) {
    HapticFeedback.mediumImpact();
    context.push(
      '/confirm',
      extra: JourneyArgs(
        content: content,
        confident: confident,
        confidence: confidence,
      ),
    );
  }

  void _presentMessage(String title, String body) {
    HapticFeedback.lightImpact();
    setState(() {
      _msgTitle = title;
      _msgBody = body;
    });
  }

  void _dismissMessage() {
    setState(() {
      _msgTitle = null;
      _msgBody = null;
    });
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    final next = !_torch;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _torch = next);
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady = _controller != null && !_initializing && _error == null;
    final overlayUp = _msgTitle != null || _generating;
    final discovered = CollectionRepository().discoveredIds().length;
    final total = heroCatalog.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildPreview(),
          const _Scrims(),
          if (cameraReady) const IgnorePointer(child: _Reticle()),
          SafeArea(
            // Ghim hàng điều khiển lên đỉnh; nếu không, Stack(StackFit.expand)
            // ép Row cao full màn hình và canh giữa dọc 2 nút.
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Row(
                  children: <Widget>[
                    GlassIconButton(
                      icon: PhosphorIconsBold.arrowLeft,
                      semanticLabel: 'Về màn hình chính',
                      size: 46,
                      onTap: () => context.go('/onboarding'),
                    ),
                    const Spacer(),
                    _TrophyPill(count: discovered, total: total),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !cameraReady || overlayUp,
              child: AnimatedOpacity(
                opacity: (cameraReady && !overlayUp) ? 1 : 0,
                duration: WonderTokens.durBase,
                child: _BottomControls(
                  busy: _busy,
                  torch: _torch,
                  onScan: _busy ? null : _capture,
                  onTorch: _toggleTorch,
                  onCollection: () => context.push('/collection'),
                  onDevPanel: () => showDevPanel(context),
                ),
              ),
            ),
          ),
          if (_generating) const _GeneratingOverlay(),
          if (_msgTitle != null)
            _MessageOverlay(
              title: _msgTitle!,
              body: _msgBody ?? '',
              onRetake: _dismissMessage,
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const _StatusCard(
        icon: PhosphorIconsDuotone.camera,
        title: 'Đang mở máy ảnh…',
        body: 'Chờ mình một chút nhé!',
        spinner: true,
      );
    }
    if (_error != null) {
      return _StatusCard(
        icon: PhosphorIconsDuotone.lockSimple,
        title: _error!,
        body: _permanentlyDenied
            ? 'Hãy bật quyền camera trong Cài đặt giúp mình nhé.'
            : 'Chạm để thử lại nào!',
        actionLabel: _permanentlyDenied ? 'Mở Cài đặt' : 'Thử lại',
        actionIcon: PhosphorIconsBold.arrowClockwise,
        onAction: _permanentlyDenied ? openAppSettings : _setup,
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
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 330,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.58),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ngắm: 4 góc bạc-hà + quầng sáng nhẹ ở giữa, hơi cao hơn tâm.
class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.18),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x402FD3BC), Color(0x002FD3BC)],
                  stops: <double>[0.0, 0.62],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.92, end: 1.06, duration: 2200.ms, curve: Curves.easeInOut),
            const _Corner(Alignment.topLeft),
            const _Corner(Alignment.topRight),
            const _Corner(Alignment.bottomLeft),
            const _Corner(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment align;
  const _Corner(this.align);

  @override
  Widget build(BuildContext context) {
    final top = align.y < 0;
    final left = align.x < 0;
    return Align(
      alignment: align,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            top: top ? _side : BorderSide.none,
            bottom: top ? BorderSide.none : _side,
            left: left ? _side : BorderSide.none,
            right: left ? BorderSide.none : _side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? _r : Radius.zero,
            topRight: top && !left ? _r : Radius.zero,
            bottomLeft: !top && left ? _r : Radius.zero,
            bottomRight: !top && !left ? _r : Radius.zero,
          ),
        ),
      ),
    );
  }

  static const BorderSide _side = BorderSide(color: WonderColors.mint, width: 4);
  static const Radius _r = Radius.circular(8);
}

/// Pill huy hiệu góc phải: "🏆 Đã có 5/8".
class _TrophyPill extends StatelessWidget {
  final int count;
  final int total;
  const _TrophyPill({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: WonderTokens.radiusSm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      tintOpacity: 0.32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PhosphorIcon(PhosphorIconsFill.trophy, size: 15, color: WonderColors.spark),
          const SizedBox(width: 6),
          Text(
            'Đã có $count/$total',
            style: WonderType.body(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool busy;
  final bool torch;
  final VoidCallback? onScan;
  final VoidCallback onTorch;
  final VoidCallback onCollection;
  final VoidCallback onDevPanel;

  const _BottomControls({
    required this.busy,
    required this.torch,
    required this.onScan,
    required this.onTorch,
    required this.onCollection,
    required this.onDevPanel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Cử chỉ ẩn: nhấn giữ bong bóng gợi ý để mở Dev panel (Mock ↔ API).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onDevPanel,
              child: _HintBubble(busy: busy),
            ),
            const SizedBox(height: 14),
            const _AutoPill(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                GlassIconButton(
                  icon: PhosphorIconsBold.books,
                  semanticLabel: 'Bộ sưu tập',
                  onTap: onCollection,
                ),
                ScanRingButton(busy: busy, onTap: onScan),
                GlassIconButton(
                  icon: torch
                      ? PhosphorIconsFill.lightning
                      : PhosphorIconsBold.flashlight,
                  semanticLabel: torch ? 'Tắt đèn' : 'Bật đèn',
                  active: torch,
                  onTap: onTorch,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bong bóng gợi ý có mascot Tia.
class _HintBubble extends StatelessWidget {
  final bool busy;
  const _HintBubble({required this.busy});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: WonderShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TiaMascot(size: 38, cheeks: false),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              busy
                  ? 'Để Tia xem kỹ nào… 🔍'
                  : 'Giữ yên nào — Tia sẽ kể chuyện đồ vật này! 📸',
              style: WonderType.body(
                color: WonderColors.textStrong,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoPill extends StatelessWidget {
  const _AutoPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: WonderColors.mint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WonderColors.mint.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PhosphorIcon(PhosphorIconsFill.lightning, size: 13, color: WonderColors.mint),
          const SizedBox(width: 5),
          Text(
            'Chạm để khám phá',
            style: WonderType.body(
              color: WonderColors.mint,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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
    return Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.5),
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GlassSurface(
                      radius: WonderTokens.radiusLg,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                      tintOpacity: 0.42,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Center(child: TiaMascot(size: 64, tone: TiaTone.light)),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: WonderType.display(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: WonderType.body(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 18),
                          WonderButton(
                            label: 'Quét lại',
                            icon: PhosphorIconsBold.arrowClockwise,
                            onTap: onRetake,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: WonderTokens.durBase)
        .scaleXY(
          begin: 0.92,
          end: 1,
          duration: WonderTokens.durSlow,
          curve: WonderTokens.curveEmphasized,
        );
  }
}

/// Lớp phủ khi đang "tìm hiểu món lạ" (AI-live sinh nội dung).
class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const TiaMascot(size: 96, tone: TiaTone.light)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -6, end: 6, duration: 1600.ms, curve: Curves.easeInOut),
                const SizedBox(height: 18),
                Text(
                  'Tia đang tìm hiểu món này…',
                  style: WonderType.display(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trạng thái khởi tạo/lỗi camera — vẫn giữ tông kính sang, không phải spinner trơ.
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool spinner;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.spinner = false,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: WonderGradients.camera),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PhosphorIcon(icon, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: WonderType.display(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: WonderType.body(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              if (spinner) ...<Widget>[
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(WonderColors.violet),
                ),
              ],
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: 24),
                WonderButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  expand: false,
                  onTap: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
