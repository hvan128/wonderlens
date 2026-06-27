import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/object_content.dart';

/// Đọc nội dung "vật hero" đã đóng gói sẵn trong app (offline).
/// Trả null nếu chưa có nội dung cho object_id đó.
class ContentRepository {
  final Map<String, ObjectContent?> _cache = {};

  Future<ObjectContent?> load(String objectId) async {
    if (_cache.containsKey(objectId)) return _cache[objectId];
    try {
      final raw = await rootBundle.loadString('assets/content/$objectId.json');
      final content = ObjectContent.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        source: 'asset',
      );
      _cache[objectId] = content;
      return content;
    } catch (_) {
      _cache[objectId] = null;
      return null;
    }
  }
}
