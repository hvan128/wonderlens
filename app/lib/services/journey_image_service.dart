import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show AssetImage, ImageProvider, NetworkImage, FileImage;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/app_settings.dart';
import '../models/object_content.dart';

/// Phân giải ảnh minh hoạ cho 1 chặng theo thứ tự ưu tiên:
///   1. [illustration] bundle/URL (hero objects đã pre-gen) — `assets/...` hoặc `http...`
///   2. [liveFile] ảnh AI-live đã tải về máy
///   3. null → tile không hiện ảnh (giữ look cũ)
/// Hàm thuần (không I/O) để test dễ; lỗi tải ảnh do widget `errorBuilder` lo.
ImageProvider? resolveStageImage({String? illustration, File? liveFile}) {
  final ill = illustration?.trim() ?? '';
  if (ill.isNotEmpty) {
    if (ill.startsWith('http')) return NetworkImage(ill);
    return AssetImage(ill);
  }
  if (liveFile != null) return FileImage(liveFile);
  return null;
}

/// Sinh ảnh "đồng nhất bối cảnh" cho từng chặng của vật AI-live qua proxy, rồi
/// cache ra file local (bền qua restart) để mở lại tức thì, không tốn phí lại.
/// Hero objects KHÔNG dùng service này — ảnh đã bundle trong assets.
class JourneyImageService {
  static bool get available => AppSettings.useLiveApi;

  static String get _baseUrl => AppSettings.baseUrl;
  static String get _appToken => AppSettings.appToken;

  /// Trả map `stageIndex → File` ảnh đã sẵn sàng. Vắng key = chặng đó không có
  /// ảnh (lỗi/không cấu hình) → tile rớt về không-ảnh. Trả {} khi đang offline.
  Future<Map<int, File>> generate(ObjectContent content) async {
    if (!AppSettings.useLiveApi) return const {};
    final count =
        content.stages.length < 4 ? content.stages.length : 4; // khớp UI
    if (count == 0) return const {};

    try {
      final dir = await _cacheDir();
      final cached = <int, File>{};
      for (var i = 0; i < count; i++) {
        final f = File('${dir.path}/${content.id}_stage$i.png');
        if (await f.exists()) cached[i] = f;
      }
      // Đủ ảnh cho mọi chặng → dùng cache, khỏi gọi API.
      if (cached.length == count) return cached;

      final fresh = await _fetch(content, count);
      if (fresh.isEmpty) return cached; // lỗi mạng → trả phần đã cache (nếu có)

      final out = <int, File>{...cached};
      for (final entry in fresh.entries) {
        final f = File('${dir.path}/${content.id}_stage${entry.key}.png');
        await f.writeAsBytes(entry.value);
        out[entry.key] = f;
      }
      return out;
    } catch (e) {
      debugPrint('journey image generate error: $e');
      return const {};
    }
  }

  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/journey_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Gọi proxy, trả map `stageIndex → bytes PNG`. {} nếu lỗi.
  Future<Map<int, List<int>>> _fetch(ObjectContent content, int count) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/api/journey-images'),
          headers: {
            'Content-Type': 'application/json',
            'x-app-token': _appToken,
          },
          body: jsonEncode({
            'name': content.name,
            'material_badge': content.materialBadge,
            'stages': content.stages
                .take(count)
                .map((s) => {'title': s.title, 'kid_text': s.kidText})
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      debugPrint('journey-images ${res.statusCode}: ${res.body}');
      return const {};
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['images'] as List?) ?? const [];
    final out = <int, List<int>>{};
    for (final item in list) {
      final m = item as Map<String, dynamic>;
      final idx = (m['stage_index'] as num?)?.toInt();
      final b64 = m['image_base64'] as String?;
      if (idx == null || idx < 0 || idx >= count || b64 == null) continue;
      try {
        out[idx] = base64Decode(b64);
      } catch (_) {
        // ảnh hỏng → bỏ qua chặng đó
      }
    }
    return out;
  }
}
