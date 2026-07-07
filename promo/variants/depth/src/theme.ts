// Brand tokens — bám theo app WonderLens thật (app/lib/theme/app_theme.dart).

export const WIDTH = 1080;
export const HEIGHT = 1920;
export const FPS = 30;
export const DURATION_IN_FRAMES = 16 * FPS; // 480 frame ~ 16s

export const COLORS = {
  teal: '#26C6DA', // seedColor app
  tealDark: '#0E97AD',
  tealDeep: '#0A6675',
  paper: '#FFFDF7', // scaffoldBackgroundColor app
  paperWarm: '#FBF1DD',
  cream: '#FFFFFF',
  ink: '#1F3A43',
  inkSoft: '#5A6E75',

  skin: '#F6C89A',
  skinShade: '#E8AE7C',
  hair: '#3A2A1F',
  shirt: '#26C6DA',
  shirtShade: '#1AA7BA',
  pants: '#37474F',

  // tông cho từng chặng "hành trình"
  tree: '#54B36A',
  treeDark: '#3C8F50',
  trunk: '#9A6A3C',
  pulp: '#C79A5B',
  pulpDark: '#A87C3E',
  sheet: '#EDE6D4',
  cup: '#7FD3E0',
  cupBand: '#26C6DA',

  badgeGold: '#F4B740',
  badgeGoldDark: '#D89417',
  confetti: ['#26C6DA', '#F4B740', '#FF7A8A', '#7ED957', '#A78BFA', '#FF9F45'],
} as const;

/** hex (#rrggbb) + alpha 0..1 -> rgba(). */
export function withAlpha(hex: string, alpha: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

export const RADIUS = { card: 40, chip: 999, phone: 64 };
