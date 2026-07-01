import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/wonder_material.dart';
import 'hero_catalog.dart';

/// Mạng lưới vật liệu (ADR-007): nạp danh mục thẻ + truy vấn đồ thị
/// object ↔ vật liệu ↔ nguồn gốc.
///
/// - Danh mục thẻ: bundled `assets/content/materials.json` (offline).
/// - Cạnh object → vật liệu: đọc đồng bộ từ [heroCatalog] (chỉ hero; vật
///   AI-live không vào mạng lưới — nhất quán với bộ sưu tập).
/// - Thẻ đã mở **suy ra từ `discoveredIds`**, KHÔNG lưu Hive (giống `badges()`).
///
/// Business logic nằm ở đây, không trong widget (AGENTS.md).
class MaterialCatalog {
  final List<WonderMaterial> _order;
  final Map<String, WonderMaterial> _byId;

  MaterialCatalog._(this._order) : _byId = {for (final m in _order) m.id: m};

  /// Dựng từ chuỗi JSON — dùng cho [init] và cho test (không cần AssetBundle).
  factory MaterialCatalog.fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = ((data['materials'] as List?) ?? const <dynamic>[])
        .map((e) => WonderMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
    return MaterialCatalog._(list);
  }

  // ---- Singleton nạp lúc khởi động (gọi trong main) ----
  static MaterialCatalog? _instance;
  static MaterialCatalog get instance =>
      _instance ?? (throw StateError('MaterialCatalog.init() chưa được gọi'));
  static bool get isReady => _instance != null;

  static Future<void> init() async {
    final raw = await rootBundle.loadString('assets/content/materials.json');
    _instance = MaterialCatalog.fromJsonString(raw);
  }

  // ---- Danh mục ----
  List<WonderMaterial> get all => List<WonderMaterial>.unmodifiable(_order);
  WonderMaterial? byId(String id) => _byId[id];

  // ---- Cạnh object ↔ vật liệu (đồng bộ, từ hero_catalog) ----

  /// Vật liệu một vật được làm từ. Rỗng nếu vật lạ/AI-live (không có trong hero).
  List<String> materialsOf(String objectId) =>
      heroById(objectId)?.materials ?? const <String>[];

  /// Các vật hero dùng vật liệu này — nền cho "mạng lưới".
  List<String> objectsUsing(String materialId) => <String>[
        for (final h in heroCatalog)
          if (h.materials.contains(materialId)) h.id,
      ];

  /// Vật liệu chung của hai vật — nền cho So sánh 2 vật (TASK-010).
  List<String> sharedMaterials(String objectA, String objectB) {
    final inB = materialsOf(objectB).toSet();
    return <String>[
      for (final m in materialsOf(objectA))
        if (inB.contains(m)) m,
    ];
  }

  // ---- Nguồn gốc ----

  /// Chuỗi biến đổi từ nguồn → vật liệu này (vd `[petroleum, plastic]`).
  /// Vật liệu nguồn trả về chính nó.
  List<String> derivationChain(String materialId) {
    final chain = <String>[];
    final seen = <String>{};
    WonderMaterial? current = byId(materialId);
    while (current != null && seen.add(current.id)) {
      chain.insert(0, current.id);
      final parent =
          current.derivedFrom.isEmpty ? null : current.derivedFrom.first;
      current = parent == null ? null : byId(parent);
    }
    return chain;
  }

  /// Thẻ đã mở: mọi vật liệu (gồm cả chuỗi nguồn gốc) của các vật đã khám phá.
  /// Vd khám phá bút bi (nhựa, thép) → mở cả dầu mỏ + quặng sắt.
  Set<String> unlockedCards(Iterable<String> discoveredIds) {
    final unlocked = <String>{};
    for (final id in discoveredIds) {
      for (final mat in materialsOf(id)) {
        unlocked.addAll(derivationChain(mat));
      }
    }
    return unlocked;
  }
}
