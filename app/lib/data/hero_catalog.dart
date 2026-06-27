/// Danh mục "vật văn phòng anh hùng" — dùng cho bộ sưu tập + nhóm huy hiệu vật liệu.
class HeroItem {
  final String id;
  final String name;
  final String emoji;
  final String material; // nhóm huy hiệu: Giấy / Nhựa / Kim loại / Gỗ

  const HeroItem(this.id, this.name, this.emoji, this.material);
}

const List<HeroItem> heroCatalog = [
  HeroItem('paper_cup', 'Cốc giấy', '🥤', 'Giấy'),
  HeroItem('ball_pen', 'Bút bi', '🖊️', 'Nhựa'),
  HeroItem('paper_a4', 'Tờ giấy A4', '📄', 'Giấy'),
  HeroItem('plastic_bottle', 'Chai nước nhựa', '💧', 'Nhựa'),
  HeroItem('paper_clip', 'Kẹp giấy', '📎', 'Kim loại'),
  HeroItem('pencil', 'Bút chì', '✏️', 'Gỗ'),
  HeroItem('sticky_note', 'Giấy note', '🗒️', 'Giấy'),
  HeroItem('battery_aa', 'Pin AA', '🔋', 'Kim loại'),
];

/// Tất cả nhóm vật liệu (huy hiệu) theo thứ tự hiển thị.
const List<String> allMaterials = ['Giấy', 'Nhựa', 'Kim loại', 'Gỗ'];

HeroItem? heroById(String id) {
  for (final h in heroCatalog) {
    if (h.id == id) return h;
  }
  return null;
}
