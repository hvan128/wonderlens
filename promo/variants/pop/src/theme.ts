// Brand tokens — biến thể "pop": cartoon năng lượng cao, màu bão hoà mạnh,
// viền ink đậm kiểu sticker + bóng đặc lệch (offset solid shadow) kiểu comic.

export const WIDTH = 1080;
export const HEIGHT = 1920;
export const FPS = 30;
export const DURATION_IN_FRAMES = 16 * FPS; // 480 frame ~ 16s

export const COLORS = {
  teal: '#00C9DE', // bão hoà hơn seedColor gốc
  tealDark: '#0794A9',
  tealDeep: '#075E6E',
  paper: '#FFF8E1',
  paperWarm: '#FFE9B3',
  cream: '#FFFFFF',
  ink: '#16323E',
  inkSoft: '#3E5A64',

  skin: '#FFC98F',
  skinShade: '#F0AC6E',
  hair: '#2C1E14',
  shirt: '#00C9DE',
  shirtShade: '#00A7BD',
  pants: '#2E4B57',

  // tông cho từng chặng "hành trình"
  tree: '#3ECF63',
  treeDark: '#27A548',
  trunk: '#A5672E',
  pulp: '#E0A44E',
  pulpDark: '#B97F2C',
  sheet: '#F2E9CF',
  cup: '#7FE3F0',
  cupBand: '#00C9DE',

  badgeGold: '#FFC229',
  badgeGoldDark: '#E09A00',
  confetti: ['#00C9DE', '#FFC229', '#FF5D8F', '#6FE04E', '#9D7BFF', '#FF8A3D'],
} as const;

/** Tông riêng của biến thể pop: nền khối táo bạo + viền/bóng comic. */
export const POP = {
  bgYellow: '#FFD84D',
  bgYellowDeep: '#FFC93A',
  bgYellowLight: '#FFE375',
  bgDot: '#F0A82A',
  orange: '#FF8A3D',
  orangeDeep: '#E56F1F',
  pink: '#FF5D8F',
  outline: '#16323E', // viền ink sticker
  shadow: '#0E2530', // bóng đặc comic
} as const;

/** Bóng đặc lệch kiểu print/comic — KHÔNG blur. */
export function solidShadow(dx: number, dy: number, color: string): string {
  return `${dx}px ${dy}px 0 ${color}`;
}

/** hex (#rrggbb) + alpha 0..1 -> rgba(). */
export function withAlpha(hex: string, alpha: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

export const RADIUS = { card: 40, chip: 999, phone: 64 };
