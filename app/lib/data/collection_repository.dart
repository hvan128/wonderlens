import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/object_content.dart';
import '../util/vn_time.dart';
import 'hero_catalog.dart';

/// Kết quả khi ghi nhận một lần khám phá.
class DiscoveryResult {
  final bool isNewObject; // lần đầu khám phá vật này
  final String? newBadge; // huy hiệu vật liệu vừa mở (null nếu không mới)

  const DiscoveryResult({required this.isNewObject, this.newBadge});
}

/// Một mục nhật ký "Khám phá thêm (AI)" — vật ngoài bộ hero mà bé đã khám phá.
/// [content] là JSON đầy đủ của [ObjectContent] để mở lại timeline offline.
class JournalEntry {
  final String id;
  final String name;
  final String emoji;
  final DateTime discoveredAt;
  final Map<String, dynamic> content;

  const JournalEntry({
    required this.id,
    required this.name,
    required this.emoji,
    required this.discoveredAt,
    required this.content,
  });

  factory JournalEntry.fromJsonString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return JournalEntry(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? 'Vật bí ẩn') as String,
      emoji: (json['emoji'] ?? '✨') as String,
      discoveredAt:
          DateTime.tryParse((json['discovered_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      content: (json['content'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  String toJsonString() => jsonEncode({
    'id': id,
    'name': name,
    'emoji': emoji,
    'discovered_at': discoveredAt.toIso8601String(),
    'content': content,
  });

  /// Dựng lại nội dung hành trình để mở timeline — luôn nguồn 'live' (nhãn AI).
  ObjectContent toContent() => ObjectContent.fromJson(content, source: 'live');
}

/// Lưu bộ sưu tập + huy hiệu vào Hive (local, bền qua restart, không cần server).
///
/// Hai tầng (xem `specs/domains.md` — Domain 3):
/// - Hero: danh sách `discovered` → lưới chính + level + huy hiệu vật liệu.
/// - Vật AI-live: nhật ký `journal` (kèm nội dung journey để mở lại offline),
///   KHÔNG tính level/huy hiệu vì nội dung AI chưa red-team.
class CollectionRepository {
  static const _boxName = 'wonderlens_collection';
  static const _key = 'discovered';
  static const _journalKey = 'journal';
  static Box? _box;

  /// Gọi 1 lần lúc khởi động app.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Cho test: gán box đã mở sẵn (Hive.init(tempDir), không cần Flutter binding).
  @visibleForTesting
  static void debugSetBox(Box? box) => _box = box;

  List<String> discoveredIds() =>
      ((_box?.get(_key) as List?)?.cast<String>()) ?? const [];

  /// Vật đang nằm trong rương hay nhật ký khám phá.
  bool containsObject(String id) =>
      discoveredIds().contains(id) || journalEntries().any((e) => e.id == id);

  /// Các nhóm vật liệu (huy hiệu) đã mở.
  Set<String> badges() {
    final mats = <String>{};
    for (final id in discoveredIds()) {
      final m = heroById(id)?.material;
      if (m != null) mats.add(m);
    }
    return mats;
  }

  /// Ghi nhận khám phá một vật. Trả về có phải vật mới + huy hiệu mới hay không.
  ///
  /// Hero → `discovered` (mở level/huy hiệu). Vật khác (AI-live) → nhật ký
  /// "Khám phá thêm (AI)": vẫn là "vật mới" (confetti) nhưng không có huy hiệu.
  DiscoveryResult record(ObjectContent content) {
    final box = _box;
    if (box == null) return const DiscoveryResult(isNewObject: false);

    final material = heroById(content.id)?.material;
    if (material == null) return _recordJournal(box, content);

    final current = discoveredIds();
    final hadBadge = badges().contains(material);
    final isNew = !current.contains(content.id);

    if (isNew) {
      box.put(_key, [...current, content.id]);
    }
    final newBadge = (isNew && !hadBadge) ? material : null;
    return DiscoveryResult(isNewObject: isNew, newBadge: newBadge);
  }

  /// Xoá một vật khỏi rương/journal local. Ảnh cutout do [CaptureStore] quản lý
  /// được xoá ở tầng UI để repository không phụ thuộc chéo Domain 1.
  bool remove(String id) {
    final box = _box;
    if (box == null) return false;

    var changed = false;
    final discovered = discoveredIds();
    if (discovered.contains(id)) {
      box.put(_key, [
        for (final x in discovered)
          if (x != id) x,
      ]);
      changed = true;
    }

    final raw = _journalRaw(box);
    final next = <String>[];
    for (final s in raw) {
      var remove = false;
      try {
        remove = JournalEntry.fromJsonString(s).id == id;
      } catch (_) {
        // Giữ lại mục hỏng như journalEntries(): đọc bỏ qua nhưng không tự xoá.
      }
      if (!remove) next.add(s);
    }
    if (next.length != raw.length) {
      box.put(_journalKey, next);
      changed = true;
    }
    return changed;
  }

  DiscoveryResult _recordJournal(Box box, ObjectContent content) {
    final id = content.id.trim();
    if (id.isEmpty || id == 'unknown') {
      return const DiscoveryResult(isNewObject: false);
    }
    // Dedup theo id — giữ lần khám phá đầu tiên.
    final raw = _journalRaw(box);
    if (journalEntries().any((e) => e.id == id)) {
      return const DiscoveryResult(isNewObject: false);
    }
    final entry = JournalEntry(
      id: id,
      name: content.name,
      emoji: content.emoji,
      discoveredAt: vnNow(),
      content: content.toJson(),
    );
    // Mới nhất đứng đầu; giữ nguyên các chuỗi cũ (kể cả mục parse hỏng).
    box.put(_journalKey, <String>[entry.toJsonString(), ...raw]);
    return const DiscoveryResult(isNewObject: true);
  }

  /// Nhật ký "Khám phá thêm (AI)", mới nhất đứng đầu. Mục hỏng bị bỏ qua khi
  /// đọc (không crash, không xoá — phòng schema đổi giữa các bản app).
  List<JournalEntry> journalEntries() {
    final box = _box;
    if (box == null) return const [];
    final out = <JournalEntry>[];
    for (final s in _journalRaw(box)) {
      try {
        out.add(JournalEntry.fromJsonString(s));
      } catch (e) {
        debugPrint('journal entry parse error: $e');
      }
    }
    return out;
  }

  static List<String> _journalRaw(Box box) =>
      ((box.get(_journalKey) as List?)?.cast<String>()) ?? const [];
}

/// Tên cấp độ theo số vật đã khám phá.
// Không kèm emoji: DESIGN.md chỉ cho emoji làm định danh vật thể,
// không làm hoạ tiết trong chữ UI (icon cúp đã có sẵn cạnh tiêu đề).
String levelTitle(int count) {
  if (count >= heroCatalog.length) return 'Bậc thầy chất liệu';
  if (count >= 5) return 'Nhà khoa học nhí';
  if (count >= 3) return 'Thám tử manh mối';
  if (count >= 1) return 'Tân binh đồ vật';
  return 'Mầm tò mò';
}
