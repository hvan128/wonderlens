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
  HeroItem('chopsticks', 'Đũa', '🥢', 'Gỗ'),
  HeroItem('metal_spoon', 'Thìa inox', '🥄', 'Kim loại'),
  HeroItem('eraser', 'Cục tẩy', '🧽', 'Nhựa'),
  HeroItem('ruler', 'Thước kẻ', '📏', 'Nhựa'),
  HeroItem('paper_straw', 'Ống hút giấy', '🧃', 'Giấy'),
  HeroItem('popsicle_stick', 'Que kem gỗ', '🍦', 'Gỗ'),
];

/// Tất cả nhóm vật liệu (huy hiệu) theo thứ tự hiển thị.
const List<String> allMaterials = ['Giấy', 'Nhựa', 'Kim loại', 'Gỗ'];

/// Vật đã có bộ giọng đọc đóng gói (Tuyết Trâm): lời cover/lịch sử
/// (`{id}_history.mp3`) và onboarding prompt/reveal (`{id}_onboarding_*.mp3`).
/// Chỉ vật trong set này mới trỏ tới asset audio bundle; vật khác rớt về TTS
/// máy để tránh cố nạp asset không tồn tại.
const Set<String> heroesWithBundledAudio = {
  'paper_cup',
  'chopsticks',
  'metal_spoon',
  'eraser',
  'ruler',
  'paper_straw',
  'popsicle_stick',
};

HeroItem? heroById(String id) {
  for (final h in heroCatalog) {
    if (h.id == id) return h;
  }
  return null;
}

/// Bundled object cutout for curated hero visuals.
///
/// UI that needs to show a hero object as an image should use this first, then
/// fall back to a locally captured cutout if available. Emoji is legacy content
/// identity, not the visual for hero objects.
String? heroCutoutAssetForId(String id) {
  if (id == 'paper_cup') return 'assets/images/paper_cup_cutout.png';
  if (heroById(id) == null) return null;
  return 'assets/images/mission_${id}_cutout.png';
}
