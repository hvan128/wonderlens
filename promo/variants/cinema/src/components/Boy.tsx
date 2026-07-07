import { COLORS, CINE, withAlpha } from '../theme';

/**
 * Em bé thông minh, phong cách flat + ánh sáng điện ảnh:
 *  - rim-light teal viền bên phải (nguồn sáng neon từ phía cốc/tia quét)
 *  - mặt & tay hắt sáng ấm từ màn hình điện thoại (thân thiện, không đáng sợ)
 * Vẽ tĩnh — phần nhún (idle) do scene áp vào cả cụm "bé + điện thoại".
 * viewBox 360x540. Tay nâng máy ở local (120,400) và (240,400).
 */
export const Boy = ({ blink = 0, wow = 0 }: { blink?: number; wow?: number }) => {
  const eyeRy = (9 + wow * 2.5) * (1 - blink) + 0.6;
  const browY = 126 - wow * 9;
  const skin = COLORS.skin;

  return (
    <svg viewBox="0 0 360 540" width="100%" height="100%" style={{ overflow: 'visible' }}>
      <defs>
        {/* hắt sáng ấm từ màn hình lên cằm/má */}
        <radialGradient id="boy-face-warm" cx="50%" cy="88%" r="72%">
          <stop offset="0%" stopColor={CINE.warmSoft} stopOpacity="0.5" />
          <stop offset="55%" stopColor={CINE.warmSoft} stopOpacity="0.16" />
          <stop offset="100%" stopColor={CINE.warmSoft} stopOpacity="0" />
        </radialGradient>
        {/* hắt sáng ấm lên bàn tay */}
        <radialGradient id="boy-hand-warm" cx="50%" cy="30%" r="70%">
          <stop offset="0%" stopColor={CINE.warmSoft} stopOpacity="0.45" />
          <stop offset="100%" stopColor={CINE.warmSoft} stopOpacity="0" />
        </radialGradient>
        <filter id="boy-rim-blur" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="4" />
        </filter>
      </defs>

      {/* bóng đổ dưới chân — đêm nên đậm hơn chút */}
      <ellipse cx="180" cy="528" rx="118" ry="20" fill={withAlpha('#02121A', 0.4)} />

      {/* giày + chân */}
      <ellipse cx="156" cy="522" rx="24" ry="11" fill="#1E282E" />
      <ellipse cx="204" cy="522" rx="24" ry="11" fill="#1E282E" />
      <rect x="142" y="424" width="30" height="96" rx="15" fill={COLORS.pants} />
      <rect x="188" y="424" width="30" height="96" rx="15" fill={COLORS.pants} />

      {/* cổ (nằm sau áo) */}
      <rect x="165" y="196" width="30" height="58" rx="14" fill={COLORS.skinShade} />

      {/* thân áo */}
      <path
        d="M104 304 Q104 244 180 244 Q256 244 256 304 L262 430 Q262 452 240 452 L120 452 Q98 452 98 430 Z"
        fill={COLORS.shirt}
      />
      <path
        d="M180 244 Q256 244 256 304 L262 430 Q262 452 240 452 L200 452 Z"
        fill={COLORS.shirtShade}
        opacity={0.3}
      />
      {/* mảng tối môi trường đêm phủ bên trái thân */}
      <path
        d="M104 304 Q104 244 180 244 L180 452 L120 452 Q98 452 98 430 Z"
        fill="#0A2430"
        opacity={0.18}
      />

      {/* hai tay nâng máy (vươn xuống ngực) */}
      <path
        d="M134 296 Q104 352 120 398"
        fill="none"
        stroke={COLORS.shirt}
        strokeWidth="36"
        strokeLinecap="round"
      />
      <path
        d="M226 296 Q256 352 240 398"
        fill="none"
        stroke={COLORS.shirt}
        strokeWidth="36"
        strokeLinecap="round"
      />
      <circle cx="120" cy="400" r="22" fill={skin} />
      <circle cx="240" cy="400" r="22" fill={skin} />
      {/* tay hắt sáng ấm từ màn hình */}
      <circle cx="120" cy="400" r="22" fill="url(#boy-hand-warm)" />
      <circle cx="240" cy="400" r="22" fill="url(#boy-hand-warm)" />

      {/* đầu */}
      <circle cx="124" cy="150" r="13" fill={skin} />
      <circle cx="236" cy="150" r="13" fill={skin} />
      <circle cx="180" cy="150" r="60" fill={skin} />
      {/* hắt sáng ấm từ màn hình lên nửa dưới mặt */}
      <ellipse cx="180" cy="186" rx="50" ry="32" fill="url(#boy-face-warm)" />

      {/* tóc */}
      <path
        d="M122 142 Q112 78 180 74 Q248 78 238 142 Q224 118 204 122 Q196 100 180 104 Q164 100 156 122 Q136 118 122 142 Z"
        fill={COLORS.hair}
      />

      {/* ===== RIM-LIGHT teal bên phải (đầu + vai + tay) ===== */}
      <g opacity={0.85}>
        {/* viền đầu: cung tròn phải, glow mềm + lõi sáng */}
        <path
          d="M216 100 A60 60 0 0 1 239 163"
          fill="none"
          stroke={CINE.neon}
          strokeWidth="9"
          strokeLinecap="round"
          filter="url(#boy-rim-blur)"
          opacity="0.55"
        />
        <path
          d="M216 100 A60 60 0 0 1 239 163"
          fill="none"
          stroke={CINE.neonSoft}
          strokeWidth="3.5"
          strokeLinecap="round"
          opacity="0.8"
        />
        {/* viền vai + sườn phải */}
        <path
          d="M212 250 Q254 258 256 306 L261 424"
          fill="none"
          stroke={CINE.neon}
          strokeWidth="8"
          strokeLinecap="round"
          filter="url(#boy-rim-blur)"
          opacity="0.42"
        />
        <path
          d="M212 250 Q254 258 256 306 L261 424"
          fill="none"
          stroke={CINE.neonSoft}
          strokeWidth="3"
          strokeLinecap="round"
          opacity="0.6"
        />
        {/* viền cánh tay phải */}
        <path
          d="M240 306 Q258 352 246 392"
          fill="none"
          stroke={CINE.neonSoft}
          strokeWidth="3.5"
          strokeLinecap="round"
          filter="url(#boy-rim-blur)"
          opacity="0.65"
        />
      </g>

      {/* má hồng */}
      <circle cx="146" cy="170" r="12" fill={withAlpha('#FF8A9B', 0.45)} />
      <circle cx="214" cy="170" r="12" fill={withAlpha('#FF8A9B', 0.45)} />

      {/* lông mày */}
      <rect x="150" y={browY} width="26" height="6" rx="3" fill={COLORS.hair} />
      <rect x="184" y={browY} width="26" height="6" rx="3" fill={COLORS.hair} />

      {/* mắt (chớp + mở to khi wow) */}
      <ellipse cx="163" cy="150" rx="8.5" ry={eyeRy} fill="#23303A" />
      <ellipse cx="197" cy="150" rx="8.5" ry={eyeRy} fill="#23303A" />
      <circle cx="166" cy={150 - eyeRy * 0.35} r="2.6" fill="#FFFFFF" opacity={1 - blink} />
      <circle cx="200" cy={150 - eyeRy * 0.35} r="2.6" fill="#FFFFFF" opacity={1 - blink} />
      {/* đốm phản chiếu màn hình trong mắt — "phép màu" */}
      <circle cx="161" cy={152 + eyeRy * 0.2} r="1.8" fill={CINE.neonSoft} opacity={(1 - blink) * 0.9} />
      <circle cx="195" cy={152 + eyeRy * 0.2} r="1.8" fill={CINE.neonSoft} opacity={(1 - blink) * 0.9} />

      {/* kính thông minh — tráng gương phản chiếu neon nhẹ */}
      <g stroke={COLORS.ink} strokeWidth="4" fill="none">
        <rect x="144" y="136" width="38" height="30" rx="11" fill={withAlpha('#9FE9F2', 0.2)} />
        <rect x="178" y="136" width="38" height="30" rx="11" fill={withAlpha('#9FE9F2', 0.2)} />
        <line x1="182" y1="150" x2="178" y2="150" />
        <line x1="144" y1="146" x2="128" y2="150" />
        <line x1="216" y1="146" x2="232" y2="150" />
      </g>
      <line x1="150" y1="162" x2="176" y2="140" stroke={withAlpha(CINE.neonSoft, 0.5)} strokeWidth="3" strokeLinecap="round" />
      <line x1="184" y1="162" x2="210" y2="140" stroke={withAlpha(CINE.neonSoft, 0.5)} strokeWidth="3" strokeLinecap="round" />

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
    </svg>
  );
};
