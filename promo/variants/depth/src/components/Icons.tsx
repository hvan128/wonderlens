// Bộ icon vẽ tay bằng SVG — bản "depth": gradient + highlight thay màu bệt.
// (Không dùng emoji để render headless luôn ổn định.)
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
    <defs>
      <linearGradient id="wlTreeTrunk" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#B58050" />
        <stop offset="1" stopColor="#7C5330" />
      </linearGradient>
      <radialGradient id="wlTreeLeafDark" cx="0.35" cy="0.28" r="0.95">
        <stop offset="0" stopColor="#54B36A" />
        <stop offset="1" stopColor="#2E7B41" />
      </radialGradient>
      <radialGradient id="wlTreeLeaf" cx="0.35" cy="0.28" r="0.95">
        <stop offset="0" stopColor="#83D796" />
        <stop offset="0.55" stopColor={COLORS.tree} />
        <stop offset="1" stopColor="#3B9450" />
      </radialGradient>
      <filter id="wlTreeSoft" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="2.4" />
      </filter>
    </defs>
    <ellipse cx="50" cy="92" rx="25" ry="5" fill={withAlpha(COLORS.ink, 0.22)} filter="url(#wlTreeSoft)" />
    <rect x="44" y="56" width="12" height="36" rx="6" fill="url(#wlTreeTrunk)" />
    <circle cx="33" cy="50" r="20" fill="url(#wlTreeLeafDark)" />
    <circle cx="67" cy="50" r="20" fill="url(#wlTreeLeafDark)" />
    <circle cx="50" cy="38" r="27" fill="url(#wlTreeLeaf)" />
    {/* rim-light trên-trái */}
    <path d="M30 27 Q40 13 56 14" fill="none" stroke={withAlpha('#FFFFFF', 0.55)} strokeWidth="4.5" strokeLinecap="round" />
    <circle cx="41" cy="30" r="7.5" fill={withAlpha('#FFFFFF', 0.32)} />
  </svg>
);

export const IconPulp = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <defs>
      <linearGradient id="wlPulpPot" x1="0" y1="0" x2="1" y2="0.25">
        <stop offset="0" stopColor="#96714A" />
        <stop offset="0.5" stopColor="#7A5A3A" />
        <stop offset="1" stopColor="#5D4128" />
      </linearGradient>
      <radialGradient id="wlPulpTop" cx="0.4" cy="0.35" r="0.9">
        <stop offset="0" stopColor="#E2B878" />
        <stop offset="1" stopColor="#A87C3E" />
      </radialGradient>
      <filter id="wlPulpSoft" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="2.2" />
      </filter>
    </defs>
    <ellipse cx="50" cy="93" rx="24" ry="4.5" fill={withAlpha(COLORS.ink, 0.22)} filter="url(#wlPulpSoft)" />
    <path d="M24 30 Q28 18 22 12" fill="none" stroke={withAlpha(COLORS.ink, 0.22)} strokeWidth="4" strokeLinecap="round" />
    <path d="M50 28 Q54 16 48 10" fill="none" stroke={withAlpha(COLORS.ink, 0.22)} strokeWidth="4" strokeLinecap="round" />
    <path d="M76 30 Q80 18 74 12" fill="none" stroke={withAlpha(COLORS.ink, 0.22)} strokeWidth="4" strokeLinecap="round" />
    <path d="M26 50 L74 50 L67 86 Q65 92 59 92 L41 92 Q35 92 33 86 Z" fill="url(#wlPulpPot)" />
    {/* rim-light mép trái nồi */}
    <path d="M30 54 L35 84" fill="none" stroke={withAlpha('#FFFFFF', 0.3)} strokeWidth="3.5" strokeLinecap="round" />
    <ellipse cx="50" cy="50" rx="24" ry="8" fill="url(#wlPulpTop)" />
    <ellipse cx="47" cy="48.6" rx="15" ry="4" fill={withAlpha('#FFFFFF', 0.35)} />
    <circle cx="43" cy="50" r="3" fill={COLORS.pulpDark} />
    <circle cx="58" cy="51" r="2.4" fill={COLORS.pulpDark} />
  </svg>
);

export const IconSheet = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <defs>
      <linearGradient id="wlSheetBody" x1="0" y1="0" x2="0.8" y2="1">
        <stop offset="0" stopColor="#FFFFFF" />
        <stop offset="0.7" stopColor="#FAF6EC" />
        <stop offset="1" stopColor="#EBE2CE" />
      </linearGradient>
      <filter id="wlSheetSoft" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="2.6" />
      </filter>
    </defs>
    <rect x="29" y="20" width="48" height="68" rx="7" fill={withAlpha(COLORS.ink, 0.2)} filter="url(#wlSheetSoft)" />
    <rect x="26" y="16" width="48" height="68" rx="7" fill="url(#wlSheetBody)" />
    <rect x="26" y="16" width="48" height="68" rx="7" fill="none" stroke={withAlpha(COLORS.ink, 0.14)} strokeWidth="2.5" />
    <path d="M60 16 L74 30 L60 30 Z" fill="#E3D8BE" />
    <path d="M60 16 L74 30" stroke={withAlpha(COLORS.ink, 0.16)} strokeWidth="2" />
    <g fill={withAlpha(COLORS.ink, 0.2)}>
      <rect x="34" y="40" width="32" height="5" rx="2.5" />
      <rect x="34" y="52" width="32" height="5" rx="2.5" />
      <rect x="34" y="64" width="20" height="5" rx="2.5" />
    </g>
  </svg>
);

export const IconCup = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <defs>
      <linearGradient id="wlCupBody" x1="0" y1="0" x2="1" y2="0.1">
        <stop offset="0" stopColor="#FFFFFF" />
        <stop offset="0.5" stopColor="#FDFAF2" />
        <stop offset="0.82" stopColor="#EFE6D2" />
        <stop offset="1" stopColor="#DECFB2" />
      </linearGradient>
      <linearGradient id="wlCupBand" x1="0" y1="0" x2="1" y2="0.1">
        <stop offset="0" stopColor="#67DAE9" />
        <stop offset="0.55" stopColor={COLORS.cupBand} />
        <stop offset="1" stopColor="#0E8FA4" />
      </linearGradient>
      <radialGradient id="wlCupInside" cx="0.5" cy="0.38" r="0.85">
        <stop offset="0" stopColor="#A9E7F0" />
        <stop offset="1" stopColor="#4FA9B8" />
      </radialGradient>
      <linearGradient id="wlCupRim" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#FFFFFF" />
        <stop offset="1" stopColor="#E8DEC8" />
      </linearGradient>
    </defs>
    <path d="M30 28 L70 28 L62 86 Q61 90 57 90 L43 90 Q39 90 38 86 Z" fill="url(#wlCupBody)" />
    <path
      d="M30 28 L70 28 L62 86 Q61 90 57 90 L43 90 Q39 90 38 86 Z"
      fill="none"
      stroke={withAlpha(COLORS.ink, 0.12)}
      strokeWidth="2.5"
    />
    <path d="M33.4 50 L66.6 50 L64.2 67 L35.8 67 Z" fill="url(#wlCupBand)" />
    {/* rim-light dọc mép trái thân cốc */}
    <path d="M34.6 34 L40 84" fill="none" stroke={withAlpha('#FFFFFF', 0.75)} strokeWidth="3.2" strokeLinecap="round" />
    <ellipse cx="50" cy="28" rx="20" ry="6" fill="url(#wlCupRim)" />
    <ellipse cx="50" cy="28" rx="20" ry="6" fill="none" stroke={withAlpha(COLORS.ink, 0.14)} strokeWidth="2.5" />
    <ellipse cx="50" cy="28" rx="15" ry="4" fill="url(#wlCupInside)" />
  </svg>
);

export const IconMedal = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <defs>
      <linearGradient id="wlMedalRibT" x1="0" y1="0" x2="0.6" y2="1">
        <stop offset="0" stopColor="#5FD6E6" />
        <stop offset="1" stopColor="#0E97AD" />
      </linearGradient>
      <linearGradient id="wlMedalRibP" x1="0" y1="0" x2="0.6" y2="1">
        <stop offset="0" stopColor="#FF9AA8" />
        <stop offset="1" stopColor="#E75A6C" />
      </linearGradient>
      <linearGradient id="wlMedalGold" x1="0.1" y1="0" x2="0.9" y2="1">
        <stop offset="0" stopColor="#FFE9A8" />
        <stop offset="0.45" stopColor={COLORS.badgeGold} />
        <stop offset="1" stopColor="#C9820E" />
      </linearGradient>
      <filter id="wlMedalSoft" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="2.4" />
      </filter>
    </defs>
    <path d="M36 14 L48 50 L40 54 L28 22 Z" fill="url(#wlMedalRibT)" />
    <path d="M64 14 L72 22 L60 54 L52 50 Z" fill="url(#wlMedalRibP)" />
    <circle cx="52" cy="66" r="26" fill={withAlpha(COLORS.ink, 0.25)} filter="url(#wlMedalSoft)" />
    <circle cx="50" cy="62" r="26" fill="url(#wlMedalGold)" />
    <circle cx="50" cy="62" r="26" fill="none" stroke={COLORS.badgeGoldDark} strokeWidth="3" />
    <circle cx="50" cy="62" r="19" fill={withAlpha('#FFFFFF', 0.2)} />
    {/* lóe kim loại trên-trái */}
    <path d="M33 51 Q39 41 50 39" fill="none" stroke={withAlpha('#FFFFFF', 0.75)} strokeWidth="4" strokeLinecap="round" />
    <polygon points={starPoints(50, 62, 5, 14, 6)} fill="#FFFFFF" />
  </svg>
);

export const LogoMark = ({ size = 100 }: IconProps) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <defs>
      <linearGradient id="wlLogoRing" x1="0.1" y1="0" x2="0.9" y2="1">
        <stop offset="0" stopColor="#6FE0EE" />
        <stop offset="0.55" stopColor={COLORS.teal} />
        <stop offset="1" stopColor={COLORS.tealDark} />
      </linearGradient>
      <radialGradient id="wlLogoGlass" cx="0.36" cy="0.32" r="0.95">
        <stop offset="0" stopColor="#FFFFFF" />
        <stop offset="1" stopColor="#DDF6FA" />
      </radialGradient>
      <linearGradient id="wlLogoStar" x1="0" y1="0" x2="0.7" y2="1">
        <stop offset="0" stopColor="#FFE9A8" />
        <stop offset="1" stopColor="#E9A21F" />
      </linearGradient>
    </defs>
    <line x1="58" y1="58" x2="84" y2="84" stroke={COLORS.tealDeep} strokeWidth="13" strokeLinecap="round" />
    <circle cx="44" cy="44" r="28" fill="url(#wlLogoGlass)" />
    <circle cx="44" cy="44" r="28" fill="none" stroke="url(#wlLogoRing)" strokeWidth="11" />
    <circle cx="36" cy="36" r="7" fill={withAlpha('#FFFFFF', 0.95)} />
    <polygon points={starPoints(80, 24, 4, 13, 4.5)} fill="url(#wlLogoStar)" />
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
