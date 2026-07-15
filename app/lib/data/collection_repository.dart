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

  bool get isHero => heroById(id) != null;

  /// Dựng lại nội dung hành trình tối thiểu. Hero nên được mở bằng
  /// [ContentRepository] để lấy content asset đầy đủ.
  ObjectContent toContent() =>
      ObjectContent.fromJson(content, source: isHero ? 'asset' : 'live');
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
  static const _heroJournalKey = 'hero_journal';
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

    final hero = heroById(content.id);
    if (hero == null) return _recordJournal(box, content);

    return _recordHero(box, hero);
  }

  /// Ghi trực tiếp một hero object theo id khi flow không cần load full content
  /// (vd: onboarding seed vật mẫu). Unknown id không ghi gì.
  DiscoveryResult recordHeroId(String id) {
    final box = _box;
    final hero = heroById(id);
    if (box == null || hero == null) {
      return const DiscoveryResult(isNewObject: false);
    }
    return _recordHero(box, hero);
  }

  DiscoveryResult _recordHero(Box box, HeroItem hero) {
    final current = discoveredIds();
    final hadBadge = badges().contains(hero.material);
    final isNew = !current.contains(hero.id);

    if (isNew) {
      box.put(_key, [...current, hero.id]);
    }
    _ensureHeroJournalEntry(box, hero);
    final newBadge = (isNew && !hadBadge) ? hero.material : null;
    return DiscoveryResult(isNewObject: isNew, newBadge: newBadge);
  }

  void _ensureHeroJournalEntry(Box box, HeroItem hero) {
    final raw = _heroJournalRaw(box);
    final exists = _parseJournalRaw(raw).any((e) => e.id == hero.id);
    if (exists) return;
    final entry = JournalEntry(
      id: hero.id,
      name: hero.name,
      emoji: hero.emoji,
      discoveredAt: vnNow(),
      content: _heroEntryContent(hero),
    );
    box.put(_heroJournalKey, <String>[entry.toJsonString(), ...raw]);
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

    final heroRaw = _heroJournalRaw(box);
    final nextHero = <String>[];
    for (final s in heroRaw) {
      var remove = false;
      try {
        remove = JournalEntry.fromJsonString(s).id == id;
      } catch (_) {}
      if (!remove) nextHero.add(s);
    }
    if (nextHero.length != heroRaw.length) {
      box.put(_heroJournalKey, nextHero);
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
    return _parseJournalRaw(_journalRaw(box));
  }

  /// Nhật ký ngày trên trang chủ: gồm hero đã sưu tầm + vật AI-live.
  ///
  /// `journalEntries()` vẫn chỉ trả AI-live để giữ đúng contract rương/AI. Hero
  /// dùng log riêng; dữ liệu cũ chỉ có `discovered` thì synthesize một entry để
  /// trang chủ không bị trống hoặc rớt mất vật đã có.
  List<JournalEntry> discoveryEntries() {
    final box = _box;
    if (box == null) return const [];

    final discovered = discoveredIds();
    final heroEntries = <String, JournalEntry>{
      for (final e in _parseJournalRaw(_heroJournalRaw(box)))
        if (discovered.contains(e.id) && heroById(e.id) != null) e.id: e,
    };
    for (final id in discovered) {
      final hero = heroById(id);
      if (hero == null || heroEntries.containsKey(id)) continue;
      heroEntries[id] = JournalEntry(
        id: hero.id,
        name: hero.name,
        emoji: hero.emoji,
        discoveredAt: vnNow(),
        content: _heroEntryContent(hero),
      );
    }

    final entries = <JournalEntry>[...heroEntries.values, ...journalEntries()]
      ..sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
    return entries;
  }

  static List<String> _journalRaw(Box box) =>
      ((box.get(_journalKey) as List?)?.cast<String>()) ?? const [];

  static List<String> _heroJournalRaw(Box box) =>
      ((box.get(_heroJournalKey) as List?)?.cast<String>()) ?? const [];

  static List<JournalEntry> _parseJournalRaw(List<String> raw) {
    final out = <JournalEntry>[];
    for (final s in raw) {
      try {
        out.add(JournalEntry.fromJsonString(s));
      } catch (e) {
        debugPrint('journal entry parse error: $e');
      }
    }
    return out;
  }

  static Map<String, dynamic> _heroEntryContent(HeroItem hero) => {
    'id': hero.id,
    'name': hero.name,
    'emoji': hero.emoji,
    'material_badge': hero.material,
    'stages': const <Object>[],
  };
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
