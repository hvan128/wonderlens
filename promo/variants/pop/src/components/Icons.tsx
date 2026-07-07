// Bộ icon vẽ tay bằng SVG — biến thể pop: viền ink đậm kiểu sticker.
import { COLORS, POP, withAlpha } from '../theme';
import type { StageIcon } from '../content';

type IconProps = { size?: number };

/** Toạ độ các đỉnh ngôi sao (spikes cánh) quanh tâm (cx,cy). */
export function starPoints(
  cx: number,
  cy: number,
  spikes: number,
  outer: number,
  inner: number,
): string {
  const pts: string[] = [];
  const step = Math.PI / spikes;
  let rot = -Math.PI / 2;
  for (let i = 0; i < spikes; i++) {
    pts.push(`${cx + Math.cos(rot) * outer},${cy + Math.sin(rot) * outer}`);
    rot += step;
    pts.push(`${cx + Math.cos(rot) * inner},${cy + Math.sin(rot) * inner}`);
    rot += step;
  }
  return pts.join(' ');
}

/** Starburst comic — dùng làm nền "bùng nổ" khi ra kết quả / nhận huy hiệu. */
export const Burst = ({
  size = 100,
  color = COLORS.badgeGold,
  spikes = 12,
  innerRatio = 0.64,
  outline = true,
}: {
  size?: number;
  color?: string;
  spikes?: number;
  innerRatio?: number;
  outline?: boolean;
}) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ display: 'block', overflow: 'visible' }}>
    <polygon
      points={starPoints(50, 50, spikes, 50, 50 * innerRatio)}
      fill={color}
      stroke={outline ? POP.outline : 'none'}
      strokeWidth={outline ? 2 : 0}
      strokeLinejoin="round"
    />
  </svg>
);

/** Tia sao 4 cánh lấp lánh. */
export const Sparkle = ({ size = 40, color = '#FFFFFF' }: { size?: number; color?: string }) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ display: 'block', overflow: 'visible' }}>
    <polygon
      points={starPoints(50, 50, 4, 48, 15)}
      fill={color}
      stroke={POP.outline}
      strokeWidth={4}
      strokeLinejoin="round"
    />
  </svg>
);

export const IconTree = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ overflow: 'visible' }}>
    <rect x="43" y="54" width="14" height="38" rx="7" fill={COLORS.trunk} stroke={POP.outline} strokeWidth="4" />
    <circle cx="33" cy="50" r="20" fill={COLORS.treeDark} stroke={POP.outline} strokeWidth="4" />
    <circle cx="67" cy="50" r="20" fill={COLORS.treeDark} stroke={POP.outline} strokeWidth="4" />
    <circle cx="50" cy="38" r="27" fill={COLORS.tree} stroke={POP.outline} strokeWidth="4" />
    <circle cx="42" cy="31" r="7" fill={withAlpha('#FFFFFF', 0.5)} />
  </svg>
);

export const IconPulp = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ overflow: 'visible' }}>
    <path d="M24 30 Q28 18 22 12" fill="none" stroke={withAlpha(POP.outline, 0.4)} strokeWidth="5" strokeLinecap="round" />
    <path d="M50 28 Q54 16 48 10" fill="none" stroke={withAlpha(POP.outline, 0.4)} strokeWidth="5" strokeLinecap="round" />
    <path d="M76 30 Q80 18 74 12" fill="none" stroke={withAlpha(POP.outline, 0.4)} strokeWidth="5" strokeLinecap="round" />
    <path d="M26 50 L74 50 L67 86 Q65 92 59 92 L41 92 Q35 92 33 86 Z" fill="#7A5A3A" stroke={POP.outline} strokeWidth="4" strokeLinejoin="round" />
    <ellipse cx="50" cy="50" rx="24" ry="8" fill={COLORS.pulp} stroke={POP.outline} strokeWidth="4" />
    <ellipse cx="50" cy="49" rx="16" ry="4" fill={withAlpha('#FFFFFF', 0.4)} />
    <circle cx="43" cy="50" r="3" fill={COLORS.pulpDark} />
    <circle cx="58" cy="51" r="2.4" fill={COLORS.pulpDark} />
  </svg>
);

export const IconSheet = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ overflow: 'visible' }}>
    <rect x="26" y="16" width="48" height="68" rx="7" fill="#FFFFFF" stroke={POP.outline} strokeWidth="4" />
    <path d="M60 16 L74 30 L60 30 Z" fill={COLORS.sheet} stroke={POP.outline} strokeWidth="3" strokeLinejoin="round" />
    <g fill={withAlpha(POP.outline, 0.35)}>
      <rect x="34" y="40" width="32" height="5" rx="2.5" />
      <rect x="34" y="52" width="32" height="5" rx="2.5" />
      <rect x="34" y="64" width="20" height="5" rx="2.5" />
    </g>
  </svg>
);

export const IconCup = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ overflow: 'visible' }}>
    <path
      d="M30 28 L70 28 L62 86 Q61 90 57 90 L43 90 Q39 90 38 86 Z"
      fill="#FFFFFF"
      stroke={POP.outline}
      strokeWidth="5"
      strokeLinejoin="round"
    />
    {/* nét bo khối bên phải cho có chiều sâu comic */}
    <path d="M64.5 34 L61.5 56" stroke={withAlpha(POP.outline, 0.16)} strokeWidth="5" strokeLinecap="round" />
    <path d="M33.8 50 L66.2 50 L63.8 67 L36.2 67 Z" fill={COLORS.cupBand} stroke={POP.outline} strokeWidth="3.5" strokeLinejoin="round" />
    <ellipse cx="50" cy="28" rx="20" ry="6" fill="#FFFFFF" stroke={POP.outline} strokeWidth="5" />
    <ellipse cx="50" cy="28" rx="13.5" ry="3.6" fill={COLORS.cup} stroke={POP.outline} strokeWidth="2.5" />
  </svg>
);

export const IconMedal = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ overflow: 'visible' }}>
    <path d="M36 14 L48 50 L40 54 L28 22 Z" fill={COLORS.cupBand} stroke={POP.outline} strokeWidth="4" strokeLinejoin="round" />
    <path d="M64 14 L72 22 L60 54 L52 50 Z" fill={POP.pink} stroke={POP.outline} strokeWidth="4" strokeLinejoin="round" />
    <circle cx="50" cy="62" r="26" fill={COLORS.badgeGold} stroke={POP.outline} strokeWidth="5" />
    <circle cx="50" cy="62" r="19" fill="none" stroke={COLORS.badgeGoldDark} strokeWidth="3" />
    <polygon points={starPoints(50, 62, 5, 14, 6)} fill="#FFFFFF" stroke={POP.outline} strokeWidth="2.5" strokeLinejoin="round" />
    <circle cx="41" cy="52" r="4.5" fill={withAlpha('#FFFFFF', 0.55)} />
  </svg>
);

export const LogoMark = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size} style={{ overflow: 'visible' }}>
    {/* cán kính lúp: viền ink dưới, màu trên */}
    <line x1="58" y1="58" x2="84" y2="84" stroke={POP.outline} strokeWidth="18" strokeLinecap="round" />
    <line x1="58" y1="58" x2="84" y2="84" stroke={COLORS.tealDeep} strokeWidth="11" strokeLinecap="round" />
    <circle cx="44" cy="44" r="28" fill="#FFFFFF" />
    <circle cx="44" cy="44" r="33.5" fill="none" stroke={POP.outline} strokeWidth="3.5" />
    <circle cx="44" cy="44" r="28" fill="none" stroke={COLORS.teal} strokeWidth="11" />
    <circle cx="44" cy="44" r="22.5" fill="none" stroke={POP.outline} strokeWidth="3.5" />
    <circle cx="36" cy="36" r="7" fill={withAlpha('#FFFFFF', 0.95)} />
    <polygon points={starPoints(80, 24, 4, 13, 4.5)} fill={COLORS.badgeGold} stroke={POP.outline} strokeWidth="3" strokeLinejoin="round" />
    <polygon points={starPoints(24, 78, 4, 8, 3)} fill={COLORS.teal} stroke={POP.outline} strokeWidth="2.5" strokeLinejoin="round" />
  </svg>
);

export const StageGlyph = ({ icon, size }: { icon: StageIcon; size?: number }) => {
  switch (icon) {
    case 'tree':
      return <IconTree size={size} />;
    case 'pulp':
      return <IconPulp size={size} />;
    case 'sheet':
      return <IconSheet size={size} />;
    case 'cup':
      return <IconCup size={size} />;
  }
};
