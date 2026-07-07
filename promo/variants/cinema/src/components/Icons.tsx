// Bộ icon vẽ tay bằng SVG (không dùng emoji để render headless luôn ổn định).
import { COLORS, withAlpha } from '../theme';
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

export const IconTree = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <rect x="44" y="56" width="12" height="36" rx="6" fill={COLORS.trunk} />
    <circle cx="33" cy="50" r="20" fill={COLORS.treeDark} />
    <circle cx="67" cy="50" r="20" fill={COLORS.treeDark} />
    <circle cx="50" cy="38" r="27" fill={COLORS.tree} />
    <circle cx="42" cy="31" r="7" fill={withAlpha('#FFFFFF', 0.28)} />
  </svg>
);

export const IconPulp = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <path
      d="M24 30 Q28 18 22 12"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.22)}
      strokeWidth="4"
      strokeLinecap="round"
    />
    <path
      d="M50 28 Q54 16 48 10"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.22)}
      strokeWidth="4"
      strokeLinecap="round"
    />
    <path
      d="M76 30 Q80 18 74 12"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.22)}
      strokeWidth="4"
      strokeLinecap="round"
    />
    <path
      d="M26 50 L74 50 L67 86 Q65 92 59 92 L41 92 Q35 92 33 86 Z"
      fill="#7A5A3A"
    />
    <ellipse cx="50" cy="50" rx="24" ry="8" fill={COLORS.pulp} />
    <ellipse cx="50" cy="49" rx="17" ry="4.5" fill={withAlpha('#FFFFFF', 0.3)} />
    <circle cx="43" cy="50" r="3" fill={COLORS.pulpDark} />
    <circle cx="58" cy="51" r="2.4" fill={COLORS.pulpDark} />
  </svg>
);

export const IconSheet = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <rect x="26" y="16" width="48" height="68" rx="7" fill="#FFFFFF" />
    <rect
      x="26"
      y="16"
      width="48"
      height="68"
      rx="7"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.14)}
      strokeWidth="2.5"
    />
    <path d="M60 16 L74 30 L60 30 Z" fill={COLORS.sheet} />
    <g fill={withAlpha(COLORS.ink, 0.2)}>
      <rect x="34" y="40" width="32" height="5" rx="2.5" />
      <rect x="34" y="52" width="32" height="5" rx="2.5" />
      <rect x="34" y="64" width="20" height="5" rx="2.5" />
    </g>
  </svg>
);

export const IconCup = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <path
      d="M30 28 L70 28 L62 86 Q61 90 57 90 L43 90 Q39 90 38 86 Z"
      fill="#FFFFFF"
    />
    <path
      d="M30 28 L70 28 L62 86 Q61 90 57 90 L43 90 Q39 90 38 86 Z"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.12)}
      strokeWidth="2.5"
    />
    <path d="M33.4 50 L66.6 50 L64.2 67 L35.8 67 Z" fill={COLORS.cupBand} />
    <ellipse cx="50" cy="28" rx="20" ry="6" fill="#FFFFFF" />
    <ellipse
      cx="50"
      cy="28"
      rx="20"
      ry="6"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.14)}
      strokeWidth="2.5"
    />
    <ellipse cx="50" cy="28" rx="15" ry="4" fill={COLORS.cup} />
  </svg>
);

export const IconMedal = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <path d="M36 14 L48 50 L40 54 L28 22 Z" fill={COLORS.cupBand} />
    <path d="M64 14 L72 22 L60 54 L52 50 Z" fill="#FF7A8A" />
    <circle cx="50" cy="62" r="26" fill={COLORS.badgeGold} />
    <circle cx="50" cy="62" r="26" fill="none" stroke={COLORS.badgeGoldDark} strokeWidth="3" />
    <circle cx="50" cy="62" r="19" fill={withAlpha('#FFFFFF', 0.22)} />
    <polygon
      points={starPoints(50, 62, 5, 14, 6)}
      fill="#FFFFFF"
    />
  </svg>
);

export const LogoMark = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <line
      x1="58"
      y1="58"
      x2="84"
      y2="84"
      stroke={COLORS.tealDeep}
      strokeWidth="13"
      strokeLinecap="round"
    />
    <circle cx="44" cy="44" r="28" fill="#FFFFFF" />
    <circle cx="44" cy="44" r="28" fill="none" stroke={COLORS.teal} strokeWidth="11" />
    <circle cx="36" cy="36" r="7" fill={withAlpha('#FFFFFF', 0.9)} />
    <polygon points={starPoints(80, 24, 4, 13, 4.5)} fill={COLORS.badgeGold} />
    <polygon points={starPoints(24, 78, 4, 8, 3)} fill={COLORS.teal} />
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
