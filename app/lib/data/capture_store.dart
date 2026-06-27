import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show FileImage;
import 'package:path_provider/path_provider.dart';

/// Lưu ảnh "sản phẩm" — cutout (tách nền) của vật trẻ vừa chụp — vào thư mục
/// tài liệu của app, đặt tên theo `objectId` (`captures/{id}.png`).
///
/// Bền qua restart cho vật hero (vật vào bộ sưu tập). Vật AI-live cũng được lưu
/// nhưng không hiện trong lưới bộ sưu tập (chỉ dùng trong phiên — overlay/timeline).
///
/// Dùng pattern static + cache `Set<String>` để widget tra cứu **đồng bộ** lúc
/// dựng. [revision] tăng mỗi lần lưu để UI (avatar/lưới) tự dựng lại tức thì.
class CaptureStore {
  CaptureStore._();
  static final CaptureStore instance = CaptureStore._();

  static Directory? _dir;
  static final Set<String> _ids = <String>{};

  /// Tăng mỗi lần có ảnh mới được lưu → UI lắng nghe để cập nhật ngay.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Gọi 1 lần lúc khởi động app.
  static Future<void> init() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/captures');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _dir = dir;
      _ids.clear();
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.png')) {
          _ids.add(_idFromPath(entity.path));
        }
      }
    } catch (e) {
      debugPrint('CaptureStore init error: $e');
    }
  }

  /// File ảnh cho [objectId] nếu đã có, ngược lại null (gọi viên rớt về emoji).
  File? fileFor(String objectId) {
    final dir = _dir;
    final id = _safeId(objectId);
    if (dir == null || !_ids.contains(id)) return null;
    return File('${dir.path}/$id.png');
  }

  bool has(String objectId) => _ids.contains(_safeId(objectId));

  /// Lưu (ghi đè nếu trùng id) cutout PNG cho [objectId].
  Future<void> save(String objectId, Uint8List png) async {
    final dir = _dir;
    if (dir == null) return;
    final id = _safeId(objectId);
    if (id.isEmpty) return;
    try {
      final file = File('${dir.path}/$id.png');
      await file.writeAsBytes(png, flush: true);
      // Xoá cache ảnh theo đường dẫn để lần chụp mới (cùng id) không hiện ảnh cũ.
      await FileImage(file).evict();
      _ids.add(id);
      revision.value++;
    } catch (e) {
      debugPrint('CaptureStore save error: $e');
    }
  }

  static String _idFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.toLowerCase().endsWith('.png')
        ? name.substring(0, name.length - 4)
        : name;
  }

  /// Chỉ giữ ký tự an toàn cho tên file (id vật là slug như `paper_cup`; vật
  /// AI-live có thể lạ nên cần làm sạch).
  static String _safeId(String objectId) =>
      objectId.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
