import { COLORS, withAlpha } from '../theme';

/**
 * Em bé thông minh — bản "depth": gradient da/tóc/áo, rim-light trên-trái,
 * ambient occlusion nhẹ (cổ, nách, dưới cằm), bóng chân blur mềm.
 * Vẽ tĩnh — phần nhún (idle) do scene áp vào cả cụm "bé + điện thoại".
 * viewBox 360x540. Tay nâng máy ở local (120,400) và (240,400).
 * glow: 0..1 — màn hình điện thoại hắt sáng teal lên mặt/tay.
 */
export const Boy = ({
  blink = 0,
  wow = 0,
  glow = 0,
}: {
  blink?: number;
  wow?: number;
  glow?: number;
}) => {
  const eyeRy = (9 + wow * 2.5) * (1 - blink) + 0.6;
  const browY = 126 - wow * 9;

  return (
    <svg viewBox="0 0 360 540" width="100%" height="100%" style={{ overflow: 'visible' }}>
      <defs>
        <radialGradient id="wlBoySkinHead" cx="0.38" cy="0.3" r="1">
          <stop offset="0" stopColor="#FDDCB2" />
          <stop offset="0.6" stopColor={COLORS.skin} />
          <stop offset="1" stopColor="#E2A170" />
        </radialGradient>
        <radialGradient id="wlBoySkinHand" cx="0.35" cy="0.3" r="1">
          <stop offset="0" stopColor="#FAD2A4" />
          <stop offset="1" stopColor={COLORS.skinShade} />
        </radialGradient>
        <linearGradient id="wlBoyHair" x1="0.1" y1="0" x2="0.7" y2="1">
          <stop offset="0" stopColor="#5A422E" />
          <stop offset="0.55" stopColor={COLORS.hair} />
          <stop offset="1" stopColor="#241811" />
        </linearGradient>
        <linearGradient id="wlBoyShirt" x1="0.12" y1="0" x2="0.88" y2="1">
          <stop offset="0" stopColor="#5BDBEA" />
          <stop offset="0.55" stopColor={COLORS.shirt} />
          <stop offset="1" stopColor="#1394A8" />
        </linearGradient>
        <linearGradient id="wlBoyPants" x1="0" y1="0" x2="0.7" y2="1">
          <stop offset="0" stopColor="#4C5D66" />
          <stop offset="1" stopColor="#28343C" />
        </linearGradient>
        <linearGradient id="wlBoyShoe" x1="0" y1="0" x2="0.6" y2="1">
          <stop offset="0" stopColor="#3C4A52" />
          <stop offset="1" stopColor="#1B2429" />
        </linearGradient>
        <filter id="wlBoySoftShadow" x="-60%" y="-60%" width="220%" height="220%">
          <feGaussianBlur stdDeviation="7" />
        </filter>
        <radialGradient id="wlBoyFaceGlow" cx="0.5" cy="0.62" r="0.62">
          <stop offset="0" stopColor="#9FF2FF" stopOpacity="0.5" />
          <stop offset="1" stopColor="#9FF2FF" stopOpacity="0" />
        </radialGradient>
      </defs>

      {/* bóng đổ mềm dưới chân (blur thật thay ellipse bệt) */}
      <ellipse cx="180" cy="526" rx="110" ry="15" fill={withAlpha(COLORS.ink, 0.3)} filter="url(#wlBoySoftShadow)" />

      {/* giày + chân */}
      <ellipse cx="156" cy="522" rx="24" ry="11" fill="url(#wlBoyShoe)" />
      <ellipse cx="204" cy="522" rx="24" ry="11" fill="url(#wlBoyShoe)" />
      <ellipse cx="149" cy="518" rx="9" ry="4" fill={withAlpha('#FFFFFF', 0.22)} />
      <ellipse cx="197" cy="518" rx="9" ry="4" fill={withAlpha('#FFFFFF', 0.22)} />
      <rect x="142" y="424" width="30" height="96" rx="15" fill="url(#wlBoyPants)" />
      <rect x="188" y="424" width="30" height="96" rx="15" fill="url(#wlBoyPants)" />
      {/* rim-light mép trái ống quần */}
      <path d="M146 434 L146 506" stroke={withAlpha('#FFFFFF', 0.16)} strokeWidth="5" strokeLinecap="round" fill="none" />

      {/* cổ (nằm sau áo) + AO sát cằm */}
      <rect x="165" y="196" width="30" height="58" rx="14" fill={COLORS.skinShade} />
      <rect x="165" y="196" width="30" height="22" rx="11" fill="#D08F5C" />

      {/* thân áo */}
      <path
        d="M104 304 Q104 244 180 244 Q256 244 256 304 L262 430 Q262 452 240 452 L120 452 Q98 452 98 430 Z"
        fill="url(#wlBoyShirt)"
      />
      {/* khối tối bên phải (form shadow) */}
      <path
        d="M180 244 Q256 244 256 304 L262 430 Q262 452 240 452 L200 452 Z"
        fill="#0C6E80"
        opacity={0.28}
      />
      {/* AO dưới cằm hắt xuống ngực áo */}
      <ellipse cx="180" cy="252" rx="36" ry="11" fill={withAlpha('#083C46', 0.3)} />
      {/* rim-light vai trái */}
      <path d="M112 292 Q118 254 172 247" fill="none" stroke={withAlpha('#FFFFFF', 0.26)} strokeWidth="6" strokeLinecap="round" />

      {/* AO hõm nách hai bên */}
      <ellipse cx="128" cy="302" rx="10" ry="16" fill={withAlpha('#083C46', 0.22)} />
      <ellipse cx="232" cy="302" rx="10" ry="16" fill={withAlpha('#083C46', 0.22)} />

      {/* hai tay nâng máy (vươn xuống ngực) */}
      <path d="M134 296 Q104 352 120 398" fill="none" stroke="#1FB2C6" strokeWidth="36" strokeLinecap="round" />
      <path d="M226 296 Q256 352 240 398" fill="none" stroke="#17A0B4" strokeWidth="36" strokeLinecap="round" />
      {/* rim-light dọc cánh tay trái (phía nguồn sáng) */}
      <path d="M128 302 Q102 352 116 392" fill="none" stroke={withAlpha('#FFFFFF', 0.18)} strokeWidth="6" strokeLinecap="round" />
      <circle cx="120" cy="400" r="22" fill="url(#wlBoySkinHand)" />
      <circle cx="240" cy="400" r="22" fill="url(#wlBoySkinHand)" />
      <circle cx="114" cy="393" r="7" fill={withAlpha('#FFFFFF', 0.35)} />
      {/* ánh màn hình hắt lên hai tay */}
      <circle cx="120" cy="400" r="22" fill="#9FF2FF" opacity={glow * 0.22} />
      <circle cx="240" cy="400" r="22" fill="#9FF2FF" opacity={glow * 0.22} />

      {/* đầu */}
      <circle cx="124" cy="150" r="13" fill="url(#wlBoySkinHand)" />
      <circle cx="236" cy="150" r="13" fill="url(#wlBoySkinHand)" />
      <circle cx="180" cy="150" r="60" fill="url(#wlBoySkinHead)" />
      {/* AO viền dưới cằm */}
      <path d="M142 190 Q180 216 218 190" fill="none" stroke={withAlpha('#C97F4E', 0.32)} strokeWidth="9" strokeLinecap="round" />

      {/* tóc */}
      <path
        d="M122 142 Q112 78 180 74 Q248 78 238 142 Q224 118 204 122 Q196 100 180 104 Q164 100 156 122 Q136 118 122 142 Z"
        fill="url(#wlBoyHair)"
      />
      {/* rim-light mái tóc trên-trái */}
      <path d="M126 116 Q136 84 178 78" fill="none" stroke={withAlpha('#FFFFFF', 0.28)} strokeWidth="7" strokeLinecap="round" />

      {/* má hồng */}
      <circle cx="146" cy="170" r="12" fill={withAlpha('#FF8A9B', 0.4)} />
      <circle cx="214" cy="170" r="12" fill={withAlpha('#FF8A9B', 0.4)} />

      {/* lông mày */}
      <rect x="150" y={browY} width="26" height="6" rx="3" fill={COLORS.hair} />
      <rect x="184" y={browY} width="26" height="6" rx="3" fill={COLORS.hair} />

      {/* mắt (chớp + mở to khi wow) */}
      <ellipse cx="163" cy="150" rx="8.5" ry={eyeRy} fill="#23303A" />
      <ellipse cx="197" cy="150" rx="8.5" ry={eyeRy} fill="#23303A" />
      <circle cx="166" cy={150 - eyeRy * 0.35} r="2.6" fill="#FFFFFF" opacity={1 - blink} />
      <circle cx="200" cy={150 - eyeRy * 0.35} r="2.6" fill="#FFFFFF" opacity={1 - blink} />

      {/* kính thông minh */}
      <g stroke={COLORS.ink} strokeWidth="4" fill="none">
        <rect x="144" y="136" width="38" height="30" rx="11" fill={withAlpha('#9FE9F2', 0.18)} />
        <rect x="178" y="136" width="38" height="30" rx="11" fill={withAlpha('#9FE9F2', 0.18)} />
        <line x1="182" y1="150" x2="178" y2="150" />
        <line x1="144" y1="146" x2="128" y2="150" />
        <line x1="216" y1="146" x2="232" y2="150" />
      </g>
      {/* lóe sáng chéo trên tròng kính */}
      <path d="M150 160 L166 140" stroke={withAlpha('#FFFFFF', 0.5)} strokeWidth="4" strokeLinecap="round" />
      <path d="M184 160 L200 140" stroke={withAlpha('#FFFFFF', 0.5)} strokeWidth="4" strokeLinecap="round" />

      {/* miệng: cười <-> mở tròn (wow) */}
      <path
        d="M166 184 Q180 198 194 184"
        fill="none"
        stroke="#9A4A3C"
        strokeWidth="5"
        strokeLinecap="round"
        opacity={1 - wow}
      />
      <ellipse cx="180" cy="188" rx="11" ry={9 + wow * 3} fill="#7C3A30" opacity={wow} />

      {/* ánh màn hình hắt lên nửa dưới khuôn mặt */}
      <ellipse cx="180" cy="184" rx="54" ry="38" fill="url(#wlBoyFaceGlow)" opacity={glow} />
    </svg>
  );
};
