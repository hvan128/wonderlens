import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Nạp sẵn [CameraController] để khi bé chạm nút chụp ở trang chủ, máy ảnh khởi
/// động NGAY trong lúc vòng khẩu độ đang xoay — tới màn camera là preview sẵn
/// sàng, khỏi cần màn "Đang bật ống kính". Singleton vì controller sống xuyên
/// điều hướng (home → camera). Màn camera mượn controller ở đây, không tự tạo.
class CameraWarmup {
  CameraWarmup._();
  static final CameraWarmup instance = CameraWarmup._();

  CameraController? _controller;
  Future<void>? _pending;
  String? _error;
  bool _permanentlyDenied = false;
  // Tăng mỗi lần release để _init đang chạy biết mình đã bị huỷ giữa chừng.
  int _generation = 0;

  CameraController? get controller => _controller;
  String? get error => _error;
  bool get permanentlyDenied => _permanentlyDenied;
  bool get isReady => _controller?.value.isInitialized ?? false;

  /// Bắt đầu (hoặc dùng lại) tiến trình nạp camera. Idempotent: đang nạp thì
  /// chờ chung một future; đã sẵn sàng thì trả về ngay.
  ///
  /// ⚠️ Có thể BẬT HỘP THOẠI XIN QUYỀN gốc của iOS (lần đầu chưa cấp). Vì thế
  /// chỉ gọi trong màn camera — nơi dialog xuất hiện đúng ngữ cảnh (App Store
  /// 5.1.1(iv)). Trang chủ/rương dùng [prewarmIfGranted] để KHÔNG bật dialog
  /// lạc chỗ.
  Future<void> prewarm() {
    if (isReady) return Future<void>.value();
    return _pending ??= _init();
  }

  /// Nạp camera NGẦM — chỉ khi quyền đã được cấp; KHÔNG bao giờ bật hộp thoại
  /// xin quyền. Dùng cho nút chụp ở trang chủ/rương để hâm nóng ống kính trong
  /// lúc chuyển màn (người đã cấp quyền → tới màn camera là preview sẵn), còn
  /// người CHƯA cấp thì im lặng no-op — việc xin quyền để màn camera lo, đúng
  /// ngữ cảnh. [Permission.camera.status] chỉ đọc trạng thái, không hiện UI.
  Future<void> prewarmIfGranted() async {
    if (isReady) return;
    if (await Permission.camera.isGranted) {
      await prewarm();
    }
  }

  Future<void> _init() async {
    final int gen = _generation;
    _error = null;
    _permanentlyDenied = false;
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          _error = 'Ống kính trên thiết bị đang đi vắng rồi.';
        } else {
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
          if (gen != _generation) {
            // Đã release trong lúc đang nạp → bỏ controller vừa tạo.
            await controller.dispose();
            return;
          }
          _controller = controller;
        }
      } else {
        _permanentlyDenied = status.isPermanentlyDenied;
        _error = 'Bé mở quyền camera để soi đồ vật nhé!';
      }
    } catch (e) {
      debugPrint('Camera warmup error: $e');
      if (gen == _generation) _error = 'Ống kính chưa sẵn sàng. Bé thử lại nhé!';
    } finally {
      if (gen == _generation) _pending = null;
    }
  }

  /// Nhả camera (màn khác phủ lên / app pause / rời màn camera).
  Future<void> release() async {
    _generation++;
    final c = _controller;
    _controller = null;
    _pending = null;
    await c?.dispose();
  }

  /// Thử lại sau lỗi.
  Future<void> retry() {
    return release().then((_) => prewarm());
  }
}
