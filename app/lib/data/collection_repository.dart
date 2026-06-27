import 'package:hive_flutter/hive_flutter.dart';

import 'hero_catalog.dart';

/// Kết quả khi ghi nhận một lần khám phá.
class DiscoveryResult {
  final bool isNewObject; // lần đầu khám phá vật này
  final String? newBadge; // huy hiệu vật liệu vừa mở (null nếu không mới)

  const DiscoveryResult({required this.isNewObject, this.newBadge});
}

/// Lưu bộ sưu tập + huy hiệu vào Hive (local, bền qua restart, không cần server).
class CollectionRepository {
  static const _boxName = 'wonderlens_collection';
  static const _key = 'discovered';
  static Box? _box;

  /// Gọi 1 lần lúc khởi động app.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  List<String> discoveredIds() =>
      ((_box?.get(_key) as List?)?.cast<String>()) ?? const [];

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
  DiscoveryResult record(String objectId) {
    final box = _box;
    if (box == null) return const DiscoveryResult(isNewObject: false);

    // Chỉ tính vật trong danh mục hero (vật AI-live không vào bộ sưu tập).
    final material = heroById(objectId)?.material;
    if (material == null) return const DiscoveryResult(isNewObject: false);

    final current = discoveredIds();
    final hadBadge = badges().contains(material);
    final isNew = !current.contains(objectId);

    if (isNew) {
      box.put(_key, [...current, objectId]);
    }
    final newBadge = (isNew && !hadBadge) ? material : null;
    return DiscoveryResult(isNewObject: isNew, newBadge: newBadge);
  }
}

/// Tên cấp độ theo số vật đã khám phá.
String levelTitle(int count) {
  if (count >= heroCatalog.length) return 'Bậc thầy vật liệu 🏆';
  if (count >= 5) return 'Nhà khoa học nhí 🔬';
  if (count >= 3) return 'Nhà khám phá 🧭';
  if (count >= 1) return 'Thám tử đồ vật 🔎';
  return 'Người mới tò mò ✨';
}
