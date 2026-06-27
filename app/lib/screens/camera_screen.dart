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
import '../data/content_repository.dart';
import '../models/object_content.dart';
import '../services/generate_service.dart';
import '../services/recognition_service.dart';
import '../services/segmentation_service.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';
import '../widgets/object_avatar.dart';

/// Màn khám phá kiểu "Apple lens" cho trẻ: preview camera tràn màn hình + lớp
/// điều khiển liquid-glass. Toàn bộ logic camera/permission/nhận diện giữ nguyên.
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

  ObjectContent? _pendingContent;
  bool _pendingConfident = false;
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

  /// Bị màn khác (timeline) phủ lên → nhả camera để khỏi giữ AVCaptureSession
  /// (tránh xung đột với video player) và để preview không đen khi quay lại.
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
        _present(content, confident: result.confidence >= _confidenceThreshold);
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
        _present(live, confident: true);
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

  void _present(ObjectContent content, {required bool confident}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _pendingContent = content;
      _pendingConfident = confident;
      _msgTitle = null;
      _msgBody = null;
    });
  }

  void _presentMessage(String title, String body) {
    HapticFeedback.lightImpact();
    setState(() {
      _msgTitle = title;
      _msgBody = body;
      _pendingContent = null;
    });
  }

  void _dismissOverlay() {
    setState(() {
      _pendingContent = null;
      _msgTitle = null;
      _msgBody = null;
    });
  }

  void _openJourney(ObjectContent content) {
    setState(() => _pendingContent = null);
    context.push('/timeline', extra: content);
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
    final overlayUp =
        _pendingContent != null || _msgTitle != null || _generating;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildPreview(),
          const _Scrims(),
          SafeArea(
            child: WonderHeader(
              branded: true,
              tone: GlassTone.dark,
              floating: false,
              actions: <WonderHeaderAction>[
                WonderHeaderAction(
                  icon: PhosphorIconsBold.houseSimple,
                  tooltip: 'Về màn hình chính',
                  onTap: () => context.go('/onboarding'),
                ),
              ],
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
                ),
              ),
            ),
          ),
          if (_generating) const _GeneratingOverlay(),
          if (_pendingContent != null)
            _DiscoveryOverlay(
              content: _pendingContent!,
              confident: _pendingConfident,
              onSeeJourney: () => _openJourney(_pendingContent!),
              onRetake: _dismissOverlay,
            ),
          if (_msgTitle != null)
            _MessageOverlay(
              title: _msgTitle!,
              body: _msgBody ?? '',
              onRetake: _dismissOverlay,
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

class _BottomControls extends StatelessWidget {
  final bool busy;
  final bool torch;
  final VoidCallback? onScan;
  final VoidCallback onTorch;
  final VoidCallback onCollection;

  const _BottomControls({
    required this.busy,
    required this.torch,
    required this.onScan,
    required this.onTorch,
    required this.onCollection,
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
            _HintPill(busy: busy),
            const SizedBox(height: 18),
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
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Cử chỉ ẩn: nhấn giữ nhãn để mở Dev panel (Mock ↔ API thật).
              onLongPress: () => showDevPanel(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PhosphorIcon(
                    PhosphorIconsFill.sparkle,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CHẾ ĐỘ KHÁM PHÁ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
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

class _HintPill extends StatelessWidget {
  final bool busy;
  const _HintPill({required this.busy});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: WonderTokens.pill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      tintOpacity: 0.32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(
            busy ? PhosphorIconsBold.magnifyingGlass : PhosphorIconsBold.camera,
            size: 17,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              busy ? 'Đang xem nào…' : 'Chĩa vào đồ vật & chạm để khám phá',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ khám phá bật lên từ đáy với hiệu ứng nảy nhẹ.
class _DiscoveryOverlay extends StatelessWidget {
  final ObjectContent content;
  final bool confident;
  final VoidCallback onSeeJourney;
  final VoidCallback onRetake;

  const _DiscoveryOverlay({
    required this.content,
    required this.confident,
    required this.onSeeJourney,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = content.source == 'live';
    return _OverlayShell(
      child: GlassSurface(
        radius: WonderTokens.radiusXl,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        tintOpacity: 0.42,
        shadows: WonderShadows.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                ObjectAvatar(
                  objectId: content.id,
                  emoji: content.emoji,
                  diameter: 66,
                  emojiSize: 34,
                  glowOpacity: 0.45,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          PhosphorIcon(
                            confident
                                ? PhosphorIconsFill.sealCheck
                                : PhosphorIconsBold.question,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            confident ? 'Tớ thấy rồi!' : 'Hình như là…',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        confident ? content.name : '${content.name}?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (content.materialBadge.isNotEmpty)
                  WonderChip(
                    label: content.materialBadge,
                    icon: PhosphorIconsBold.flask,
                  ),
                WonderChip(
                  label: '${content.stages.length} chặng',
                  icon: PhosphorIconsBold.compass,
                ),
                if (isLive)
                  WonderChip(
                    label: 'Khám phá vui (AI)',
                    icon: PhosphorIconsFill.sparkle,
                    color: WonderColors.sunny,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Cùng xem nó được tạo ra như thế nào nhé!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            WonderButton(
              label: confident ? 'Xem hành trình' : 'Đúng rồi, xem nào',
              trailingIcon: PhosphorIconsBold.arrowRight,
              onTap: onSeeJourney,
            ),
            const SizedBox(height: 4),
            Center(
              child: WonderTextButton(
                label: 'Quét lại',
                color: Colors.white.withValues(alpha: 0.9),
                onTap: onRetake,
              ),
            ),
          ],
        ),
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
              label: 'Quét lại',
              icon: PhosphorIconsBold.arrowClockwise,
              onTap: onRetake,
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung phủ tối + canh đáy + nảy lên cho các thẻ overlay.
class _OverlayShell extends StatelessWidget {
  final Widget child;
  const _OverlayShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
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
        .fadeIn(duration: WonderTokens.durBase)
        .scaleXY(
          begin: 0.92,
          end: 1,
          duration: WonderTokens.durSlow,
          curve: WonderTokens.curveEmphasized,
        );
  }
}

class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.5),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ScanRingButton(busy: true, size: 104),
                SizedBox(height: 22),
                Text(
                  'Đang tìm hiểu món này…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF102036), WonderColors.ink],
        ),
      ),
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
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              if (spinner) ...<Widget>[
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(WonderColors.cyan),
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
