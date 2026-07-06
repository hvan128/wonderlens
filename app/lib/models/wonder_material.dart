/// Một "thẻ vật liệu" — node trong mạng lưới object ↔ vật liệu ↔ nguồn gốc.
///
/// Xem [ADR-007](../../adrs/ADR-007-material-graph-model.md) +
/// `specs/materials.md`. Dữ liệu bundled offline (`assets/content/materials.json`).
///
/// Đặt tên `WonderMaterial` (không phải `Material`) để tránh đụng widget
/// `Material` của Flutter.
class WonderMaterial {
  final String id;
  final String name;
  final String emoji;

  /// `source` = vật liệu thô (dầu mỏ, gỗ…); `derived` = chế biến (nhựa, thép…).
  final String kind;

  /// Nhóm tương thích huy hiệu thô cũ: Giấy / Nhựa / Kim loại / Gỗ / Thuỷ tinh.
  final String category;

  /// Id vật liệu nguồn (thường 0–1 phần tử) — dựng chuỗi biến đổi.
  final List<String> derivedFrom;

  final String blurb;
  final List<String> funFacts;

  const WonderMaterial({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kind,
    required this.category,
    this.derivedFrom = const <String>[],
    this.blurb = '',
    this.funFacts = const <String>[],
  });

  bool get isSource => kind == 'source';

  factory WonderMaterial.fromJson(Map<String, dynamic> json) => WonderMaterial(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        emoji: (json['emoji'] ?? '✨') as String,
        kind: (json['kind'] ?? 'source') as String,
        category: (json['category'] ?? '') as String,
        derivedFrom: ((json['derived_from'] as List?) ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(),
        blurb: (json['blurb'] ?? '') as String,
        funFacts: ((json['fun_facts'] as List?) ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(),
      );
}
