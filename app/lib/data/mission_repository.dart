import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../models/mission.dart';
import 'hero_catalog.dart';
import 'material_catalog.dart';

/// Nhiệm vụ khám phá (D6 / TASK-011 — ADR-008/009).
///
/// - Danh sách nhiệm vụ: bundled `assets/content/missions.json` (offline).
/// - Tiến độ: tính từ `discoveredIds` + thẻ đã mở (mạng lưới vật liệu TASK-008).
/// - Nhiệm vụ ĐÃ HOÀN THÀNH lưu ở Hive box `wonderlens_progress`
///   (key-value đơn giản, KHÔNG cần TypeAdapter/build_runner — DoD).
///
/// Business logic ở đây, không trong widget (AGENTS.md).
class MissionRepository {
  static const _boxName = 'wonderlens_progress';
  static const _completedKey = 'completed_missions';

  static Box? _box;
  static List<Mission> _missions = const <Mission>[];

  /// Gọi lúc khởi động (sau khi Hive đã init bởi CollectionRepository).
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final raw = await rootBundle.loadString('assets/content/missions.json');
    _missions = parseMissions(raw);
  }

  /// Parse + lọc mission hỏng (tham chiếu thiếu/không nhận diện được).
  static List<Mission> parseMissions(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return ((data['missions'] as List?) ?? const <dynamic>[])
        .map((e) => Mission.fromJson(e as Map<String, dynamic>))
        .where((m) => m.isValid)
        .toList();
  }

  // ---- Hook cho test ----
  static set debugBox(Box box) => _box = box;
  static set debugMissions(List<Mission> missions) => _missions = missions;

  List<Mission> get missions => _missions;

  Set<String> completedIds() =>
      ((_box?.get(_completedKey) as List?)?.cast<String>() ?? const <String>[])
          .toSet();

  /// Tiến độ một nhiệm vụ — thuần, suy từ discovered + thẻ đã mở. Không cần Hive.
  /// Truyền [catalog] để ánh xạ vật liệu → nhóm (material_count theo category).
  static MissionProgress progressOf(
    Mission mission, {
    required Set<String> discovered,
    required Set<String> unlockedCards,
    required MaterialCatalog catalog,
  }) {
    final goal = mission.goal;
    switch (goal.type) {
      case MissionType.materialCount:
        final n = discovered
            .where((id) => _objectMatches(id, goal, catalog))
            .length;
        return MissionProgress(n.clamp(0, goal.target), goal.target);
      case MissionType.discoverSet:
        final n = goal.objectIds.where(discovered.contains).length;
        return MissionProgress(n, goal.target);
      case MissionType.collectCard:
        final n = goal.materialIds.where(unlockedCards.contains).length;
        return MissionProgress(n, goal.target);
      case MissionType.unknown:
        return const MissionProgress(0, 0);
    }
  }

  /// Một vật có thoả goal material_count không (theo thẻ cụ thể hoặc nhóm).
  static bool _objectMatches(
    String objectId,
    MissionGoal goal,
    MaterialCatalog catalog,
  ) {
    final mats = heroById(objectId)?.materials ?? const <String>[];
    if (mats.isEmpty) return false;
    if (goal.material != null) return mats.contains(goal.material);
    final category = goal.category;
    if (category == null) return false;
    for (final mid in mats) {
      if (catalog.byId(mid)?.category == category) return true;
    }
    return false;
  }

  /// Quét toàn bộ, ghi nhận nhiệm vụ mới đủ điều kiện (dedup + persist).
  /// Trả về danh sách nhiệm vụ **mới** hoàn thành (để mừng confetti).
  List<Mission> syncCompletions({
    required Set<String> discovered,
    required Set<String> unlockedCards,
    required MaterialCatalog catalog,
  }) {
    final already = completedIds();
    final newly = <Mission>[];
    for (final m in _missions) {
      if (already.contains(m.id)) continue;
      final p = progressOf(
        m,
        discovered: discovered,
        unlockedCards: unlockedCards,
        catalog: catalog,
      );
      if (p.done) newly.add(m);
    }
    if (newly.isNotEmpty && _box != null) {
      _box!.put(_completedKey, <String>[
        ...already,
        ...newly.map((m) => m.id),
      ]);
    }
    return newly;
  }
}
