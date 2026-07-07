import { COLORS, POP, withAlpha } from '../theme';
import { starPoints } from './Icons';

/**
 * Em bé phong cách cartoon pop: đầu to, mắt to nhiều highlight, kính bản lớn,
 * viền ink đậm kiểu sticker. Vẽ tĩnh — phần nhún (idle) do scene áp vào cả cụm
 * "bé + điện thoại" để tay luôn dính máy.
 * viewBox 360x540. Tay nâng máy ở local (120,400) và (240,400).
 */
export const Boy = ({ blink = 0, wow = 0 }: { blink?: number; wow?: number }) => {
  const eyeOpen = 1 - blink;
  const eyeRy = (12 + wow * 3.5) * eyeOpen + 1;
  const browY = 114 - wow * 10;
  const skin = COLORS.skin;
  const ink = POP.outline;

  return (
    <svg viewBox="0 0 360 540" width="100%" height="100%" style={{ overflow: 'visible' }}>
      {/* bóng đặc lệch dưới chân (không blur) */}
      <ellipse cx="192" cy="527" rx="126" ry="16" fill={withAlpha(ink, 0.2)} />

      {/* chân */}
      <rect x="138" y="424" width="34" height="92" rx="17" fill={COLORS.pants} stroke={ink} strokeWidth="5" />
      <rect x="188" y="424" width="34" height="92" rx="17" fill={COLORS.pants} stroke={ink} strokeWidth="5" />
      {/* giày sneaker trắng */}
      <ellipse cx="154" cy="516" rx="29" ry="14" fill="#FFFFFF" stroke={ink} strokeWidth="5" />
      <ellipse cx="206" cy="516" rx="29" ry="14" fill="#FFFFFF" stroke={ink} strokeWidth="5" />
      <circle cx="146" cy="514" r="4" fill={COLORS.teal} />
      <circle cx="198" cy="514" r="4" fill={COLORS.teal} />

      {/* cổ (nằm sau áo) */}
      <rect x="164" y="200" width="32" height="58" rx="15" fill={COLORS.skinShade} stroke={ink} strokeWidth="4" />

      {/* thân áo */}
      <path
        d="M104 304 Q104 244 180 244 Q256 244 256 304 L262 430 Q262 452 240 452 L120 452 Q98 452 98 430 Z"
        fill={COLORS.shirt}
        stroke={ink}
        strokeWidth="6"
        strokeLinejoin="round"
      />
      <path
        d="M180 244 Q256 244 256 304 L262 430 Q262 452 240 452 L200 452 Z"
        fill={COLORS.shirtShade}
        opacity={0.35}
      />
      {/* ngôi sao trước ngực áo */}
      <polygon points={starPoints(180, 340, 5, 26, 11)} fill={COLORS.badgeGold} stroke={ink} strokeWidth="4" strokeLinejoin="round" />

      {/* hai tay nâng máy: viền ink dưới, tay áo màu trên */}
      <path d="M134 296 Q104 352 120 398" fill="none" stroke={ink} strokeWidth="46" strokeLinecap="round" />
      <path d="M226 296 Q256 352 240 398" fill="none" stroke={ink} strokeWidth="46" strokeLinecap="round" />
      <path d="M134 296 Q104 352 120 398" fill="none" stroke={COLORS.shirt} strokeWidth="34" strokeLinecap="round" />
      <path d="M226 296 Q256 352 240 398" fill="none" stroke={COLORS.shirt} strokeWidth="34" strokeLinecap="round" />
      <circle cx="120" cy="400" r="23" fill={skin} stroke={ink} strokeWidth="5" />
      <circle cx="240" cy="400" r="23" fill={skin} stroke={ink} strokeWidth="5" />

      {/* tai */}
      <circle cx="104" cy="150" r="16" fill={skin} stroke={ink} strokeWidth="5" />
      <circle cx="256" cy="150" r="16" fill={skin} stroke={ink} strokeWidth="5" />

      {/* đầu TO kiểu chibi */}
      <circle cx="180" cy="146" r="76" fill={skin} stroke={ink} strokeWidth="6" />

      {/* tóc */}
      <path
        d="M104 138 Q92 48 180 44 Q268 48 256 138 Q236 110 212 116 Q202 84 180 90 Q158 84 148 116 Q124 110 104 138 Z"
        fill={COLORS.hair}
        stroke={ink}
        strokeWidth="5"
        strokeLinejoin="round"
      />
      <path d="M126 78 Q146 60 172 58" fill="none" stroke={withAlpha('#FFFFFF', 0.28)} strokeWidth="7" strokeLinecap="round" />

      {/* má hồng */}
      <circle cx="134" cy="182" r="13" fill={withAlpha('#FF7A9B', 0.55)} />
      <circle cx="226" cy="182" r="13" fill={withAlpha('#FF7A9B', 0.55)} />

      {/* lông mày */}
      <rect x="132" y={browY} width="34" height="9" rx="4.5" fill={COLORS.hair} />
      <rect x="194" y={browY} width="34" height="9" rx="4.5" fill={COLORS.hair} />

      {/* mắt TO lấp lánh (chớp + mở to khi wow) */}
      <ellipse cx="150" cy="146" rx="12.5" ry={eyeRy} fill="#1B2B33" />
      <ellipse cx="210" cy="146" rx="12.5" ry={eyeRy} fill="#1B2B33" />
      <g opacity={eyeOpen}>
        <circle cx="154.5" cy="140" r="4.6" fill="#FFFFFF" />
        <circle cx="145.5" cy="151" r="2.2" fill="#FFFFFF" opacity={0.9} />
        <circle cx="214.5" cy="140" r="4.6" fill="#FFFFFF" />
        <circle cx="205.5" cy="151" r="2.2" fill="#FFFFFF" opacity={0.9} />
      </g>

      {/* kính thông minh BẢN TO */}
      <g stroke={ink} strokeWidth="7" fill="none" strokeLinecap="round">
        <rect x="122" y="120" width="56" height="52" rx="18" fill={withAlpha('#BFF4FB', 0.35)} />
        <rect x="182" y="120" width="56" height="52" rx="18" fill={withAlpha('#BFF4FB', 0.35)} />
        <line x1="178" y1="136" x2="182" y2="136" />
        <line x1="122" y1="142" x2="104" y2="148" />
        <line x1="238" y1="142" x2="256" y2="148" />
      </g>
      {/* ánh kính */}
      <path d="M132 132 L146 126" stroke={withAlpha('#FFFFFF', 0.85)} strokeWidth="6" strokeLinecap="round" />
      <path d="M192 132 L206 126" stroke={withAlpha('#FFFFFF', 0.85)} strokeWidth="6" strokeLinecap="round" />

      {/* miệng: cười rộng <-> há tròn (wow) */}
      <path
        d="M158 188 Q180 210 202 188"
        fill="none"
        stroke="#8F3D30"
        strokeWidth="7"
        strokeLinecap="round"
        opacity={1 - wow}
      />
      <g opacity={wow}>
        <ellipse cx="180" cy="196" rx="13" ry={10 + wow * 5} fill="#7C3A30" stroke={ink} strokeWidth="4" />
        <ellipse cx="180" cy={202 + wow * 3} rx="7" ry="4" fill="#FF7A8A" />
      </g>

      {/* tia sao "wow" quanh đầu */}
      <g opacity={wow}>
        <polygon points={starPoints(106, 76, 4, 17, 5.5)} fill="#FFE45C" stroke={ink} strokeWidth="3.5" strokeLinejoin="round" />
        <polygon points={starPoints(258, 62, 4, 12, 4)} fill="#FFE45C" stroke={ink} strokeWidth="3" strokeLinejoin="round" />
        <polygon points={starPoints(282, 122, 4, 8, 3)} fill="#FFFFFF" stroke={ink} strokeWidth="2.5" strokeLinejoin="round" />
      </g>
    </svg>
  );
};
