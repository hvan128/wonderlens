/** Bộ "vật văn phòng anh hùng" — danh sách đóng để OpenAI Vision phân loại vào. */
export interface HeroObject {
  id: string;
  displayName: string;
}

export const HERO_OBJECTS: HeroObject[] = [
  { id: 'paper_a4', displayName: 'Tờ giấy A4' },
  { id: 'ball_pen', displayName: 'Bút bi' },
  { id: 'paper_cup', displayName: 'Cốc giấy' },
  { id: 'plastic_bottle', displayName: 'Chai nước nhựa' },
  { id: 'paper_clip', displayName: 'Kẹp giấy' },
  { id: 'pencil', displayName: 'Bút chì' },
  { id: 'sticky_note', displayName: 'Giấy note' },
  { id: 'battery_aa', displayName: 'Pin AA' },
];

export const HERO_IDS = HERO_OBJECTS.map((h) => h.id);

export function displayNameOf(id: string): string {
  return HERO_OBJECTS.find((h) => h.id === id)?.displayName ?? 'Vật bí ẩn';
}
