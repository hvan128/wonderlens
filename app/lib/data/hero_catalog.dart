/// Danh mục "vật văn phòng anh hùng" — dùng cho bộ sưu tập + nhóm huy hiệu vật liệu.
class HeroItem {
  final String id;
  final String name;
  final String emoji;
  final String material; // nhóm huy hiệu: Giấy / Nhựa / Kim loại / Gỗ
  final List<String> materials; // id thẻ vật liệu (ADR-012); mirror content JSON

  const HeroItem(
    this.id,
    this.name,
    this.emoji,
    this.material, {
    this.materials = const <String>[],
  });
}

const List<HeroItem> heroCatalog = [
  HeroItem('paper_cup', 'Cốc giấy', '🥤', 'Giấy',
      materials: <String>['paper_pulp', 'plastic']),
  HeroItem('ball_pen', 'Bút bi', '🖊️', 'Nhựa',
      materials: <String>['plastic', 'steel']),
  HeroItem('paper_a4', 'Tờ giấy A4', '📄', 'Giấy',
      materials: <String>['paper_pulp']),
  HeroItem('plastic_bottle', 'Chai nước nhựa', '💧', 'Nhựa',
      materials: <String>['plastic']),
  HeroItem('paper_clip', 'Kẹp giấy', '📎', 'Kim loại',
      materials: <String>['steel']),
  HeroItem('pencil', 'Bút chì', '✏️', 'Gỗ',
      materials: <String>['wood', 'graphite']),
  HeroItem('sticky_note', 'Giấy note', '🗒️', 'Giấy',
      materials: <String>['paper_pulp']),
  HeroItem('battery_aa', 'Pin AA', '🔋', 'Kim loại',
      materials: <String>['steel']),
];

/// Tất cả nhóm vật liệu (huy hiệu) theo thứ tự hiển thị.
const List<String> allMaterials = ['Giấy', 'Nhựa', 'Kim loại', 'Gỗ'];

HeroItem? heroById(String id) {
  for (final h in heroCatalog) {
    if (h.id == id) return h;
  }
  return null;
}
