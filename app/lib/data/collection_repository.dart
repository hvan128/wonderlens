import 'package:hive_flutter/hive_flutter.dart';

import '../models/object_content.dart';
import 'hero_catalog.dart';

/// Kết quả khi ghi nhận một lần khám phá.
class DiscoveryResult {
  final bool isNewObject; // lần đầu khám phá vật này
  final String? newBadge; // huy hiệu vật liệu vừa mở (null nếu không mới)
  final bool isAi; // huy hiệu thuộc track "khám phá AI" (vật lạ, nhãn vui-AI)

  const DiscoveryResult({
    required this.isNewObject,
    this.newBadge,
    this.isAi = false,
  });
}

/// Một vật lạ (AI-live) đã khám phá — lưu đủ để hiển thị mà không có trong
/// `heroCatalog`. Xem `ADR-011`.
class AiDiscovery {
  final String id;
  final String name;
  final String emoji;
  final String material;

  const AiDiscovery({
    required this.id,
    required this.name,
    required this.emoji,
    required this.material,
  });
}

/// Lưu bộ sưu tập + huy hiệu vào Hive (local, bền qua restart, không cần server).
///
/// Hai track tách biệt (xem `ADR-011`):
///  • **lõi verified**: hero objects (`_key`) → 4 huy hiệu vật liệu cố định.
///  • **khám phá AI**: vật AI-live (`_aiKey`) → huy hiệu động, nhãn "vui (AI)".
class CollectionRepository {
  static const _boxName = 'wonderlens_collection';
  static const _key = 'discovered'; // List<String> id hero
  static const _aiKey = 'ai_discovered'; // List<Map> {id,name,emoji,material}
  static Box? _box;

  /// Gọi 1 lần lúc khởi động app.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // ---------- Track lõi verified (hero) ----------

  List<String> discoveredIds() =>
      ((_box?.get(_key) as List?)?.cast<String>()) ?? const [];

  /// Các nhóm vật liệu (huy hiệu) lõi đã mở — chỉ từ hero verified.
  Set<String> badges() {
    final mats = <String>{};
    for (final id in discoveredIds()) {
      final m = heroById(id)?.material;
      if (m != null) mats.add(m);
    }
    return mats;
  }

  // ---------- Track khám phá AI (vật lạ) ----------

  List<Map<String, dynamic>> _aiRaw() {
    final raw = _box?.get(_aiKey) as List?;
    if (raw == null) return const [];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  /// Vật AI-live đã khám phá (track riêng, có nhãn "vui AI" ở UI).
  List<AiDiscovery> aiDiscoveries() => _aiRaw()
      .map((m) => AiDiscovery(
            id: (m['id'] ?? '') as String,
            name: (m['name'] ?? 'Vật bí ẩn') as String,
            emoji: (m['emoji'] ?? '✨') as String,
            material: (m['material'] ?? '') as String,
          ))
      .toList(growable: false);

  /// Huy hiệu vật liệu động (từ vật AI). Tách khỏi [badges] lõi.
  Set<String> aiBadges() {
    final mats = <String>{};
    for (final m in _aiRaw()) {
      final mat = (m['material'] ?? '') as String;
      if (mat.isNotEmpty) mats.add(mat);
    }
    return mats;
  }

  // ---------- Ghi nhận khám phá ----------

  /// Ghi nhận khám phá một vật. Hero → track lõi; AI-live → track AI (huy hiệu
  /// động). Trả về có phải vật mới + huy hiệu mới (kèm cờ [DiscoveryResult.isAi]).
  DiscoveryResult record(ObjectContent content) {
    final box = _box;
    if (box == null) return const DiscoveryResult(isNewObject: false);

    // --- Track lõi: hero verified ---
    final heroMat = heroById(content.id)?.material;
    if (heroMat != null) {
      final current = discoveredIds();
      final hadBadge = badges().contains(heroMat);
      final isNew = !current.contains(content.id);
      if (isNew) box.put(_key, <String>[...current, content.id]);
      return DiscoveryResult(
        isNewObject: isNew,
        newBadge: (isNew && !hadBadge) ? heroMat : null,
      );
    }

    // --- Track AI: vật lạ (live) → huy hiệu động ---
    if (content.source == 'live') {
      final material = normalizeMaterial(content.materialBadge);
      if (material.isEmpty) return const DiscoveryResult(isNewObject: false);
      final current = _aiRaw();
      final hadBadge = aiBadges().contains(material);
      final isNew = !current.any((m) => m['id'] == content.id);
      if (isNew) {
        box.put(_aiKey, <Map<String, dynamic>>[
          ...current,
          <String, dynamic>{
            'id': content.id,
            'name': content.name,
            'emoji': content.emoji,
            'material': material,
          },
        ]);
      }
      return DiscoveryResult(
        isNewObject: isNew,
        newBadge: (isNew && !hadBadge) ? material : null,
        isAi: true,
      );
    }

    return const DiscoveryResult(isNewObject: false);
  }
}

/// Tên cấp độ theo số vật đã khám phá (chỉ tính hero verified — AI là bonus).
String levelTitle(int count) {
  if (count >= heroCatalog.length) return 'Bậc thầy vật liệu 🏆';
  if (count >= 5) return 'Nhà khoa học nhí 🔬';
  if (count >= 3) return 'Nhà khám phá 🧭';
  if (count >= 1) return 'Thám tử đồ vật 🔎';
  return 'Người mới tò mò ✨';
}

/// Chuẩn hoá tên vật liệu AI về một tập canonical (đồng nghĩa → 1 tên). Tên lạ
/// giữ nguyên nhưng title-case nhẹ. Rỗng/space → ''.
String normalizeMaterial(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.isEmpty) return '';
  const synonyms = <String, String>{
    'nhựa': 'Nhựa', 'chất dẻo': 'Nhựa', 'plastic': 'Nhựa',
    'nilon': 'Nhựa', 'ni lông': 'Nhựa', 'nylon': 'Nhựa',
    'giấy': 'Giấy', 'bìa': 'Giấy', 'carton': 'Giấy',
    'các tông': 'Giấy', 'paper': 'Giấy',
    'kim loại': 'Kim loại', 'sắt': 'Kim loại', 'thép': 'Kim loại',
    'nhôm': 'Kim loại', 'inox': 'Kim loại', 'đồng': 'Kim loại', 'metal': 'Kim loại',
    'gỗ': 'Gỗ', 'tre': 'Gỗ', 'wood': 'Gỗ',
    'thuỷ tinh': 'Thuỷ tinh', 'thủy tinh': 'Thuỷ tinh',
    'kính': 'Thuỷ tinh', 'glass': 'Thuỷ tinh',
    'cao su': 'Cao su', 'rubber': 'Cao su',
    'vải': 'Vải', 'sợi': 'Vải', 'cotton': 'Vải', 'fabric': 'Vải',
    'gốm': 'Gốm', 'sứ': 'Gốm', 'ceramic': 'Gốm',
    'da': 'Da', 'leather': 'Da',
  };
  final hit = synonyms[t];
  if (hit != null) return hit;
  return raw
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
