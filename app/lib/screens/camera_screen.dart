import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/content_repository.dart';
import '../models/object_content.dart';
import '../services/generate_service.dart';
import '../services/recognition_service.dart';

/// Màn camera: preview + nút chụp. Khi chụp gọi RecognitionService (mock ở P1).
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _busy = false;
  bool _permanentlyDenied = false;
  bool _settingUp = false;
  bool _generating = false;
  String? _error;
  final _service = RecognitionService();
  final _generate = GenerateService();
  final _repo = ContentRepository();

  /// Dưới ngưỡng này thì hỏi xác nhận "Có phải … không?".
  static const double _confidenceThreshold = 0.6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
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
    // Huỷ controller cũ trước khi tạo mới (tránh leak khi lifecycle đổi nhanh).
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
    });
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        setState(() {
          _permanentlyDenied = status.isPermanentlyDenied;
          _error = 'Cần quyền camera để khám phá nhé! 📷';
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
      final result = await _service.recognize(bytes);
      if (!mounted) return;

      // Vật hero có nội dung đóng gói sẵn → hiện ngay.
      ObjectContent? content;
      if (result.objectId != 'unknown') {
        content = await _repo.load(result.objectId);
        if (!mounted) return;
      }
      if (content != null) {
        _showResult(result, content);
        return;
      }

      // Vật lạ/chưa có nội dung → thử AI live (nếu có proxy).
      if (!GenerateService.available) {
        _showMessage('Mình chưa nhận ra món này 🤔',
            'Thử chĩa gần hơn vào một đồ vật rồi chụp lại nhé!');
        return;
      }
      setState(() => _generating = true);
      final live = await _generate.generate(bytes);
      if (!mounted) return;
      setState(() => _generating = false);
      if (live == null) {
        _showMessage('Mình chưa khám phá được món này 🤔',
            'Thử một đồ vật khác nhé!');
      } else {
        context.push('/timeline', extra: live);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chụp chưa được, thử lại nhé! 📸')),
      );
    } finally {
      // Dọn file ảnh tạm để không tích lũy theo mỗi lần chụp.
      if (shot != null) {
        final path = shot.path;
        unawaited(File(path).delete().catchError((_) => File(path)));
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResult(RecognitionResult r, ObjectContent content) {
    HapticFeedback.mediumImpact();
    final confident = r.confidence >= _confidenceThreshold;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 4),
            Text(confident ? 'Tèn ten! 🎉' : 'Hình như là…',
                style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              confident
                  ? 'Đây là ${content.name}'
                  : 'Có phải ${content.name} không?',
              style: Theme.of(sheetContext).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/timeline', extra: content);
              },
              child:
                  Text(confident ? 'Xem hành trình ➡️' : 'Đúng rồi, xem nào ➡️'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Chụp lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: Theme.of(sheetContext).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Chụp lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chĩa vào đồ vật'),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'Bộ sưu tập',
            onPressed: () => context.push('/collection'),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_generating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tìm hiểu món này… 🔍',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_controller != null && !_initializing)
          ? FloatingActionButton.large(
              onPressed: _busy ? null : _capture,
              child: _busy
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.camera_alt, size: 36),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _permanentlyDenied ? openAppSettings : _setup,
                child: Text(_permanentlyDenied ? 'Mở Cài đặt' : 'Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final controller = _controller!;
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }
}
