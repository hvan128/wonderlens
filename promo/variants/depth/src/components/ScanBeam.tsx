import { COLORS, withAlpha } from '../theme';

/**
 * Tia quét + khung lấy nét AR — bản "depth": tia phát sáng glow
 * (feGaussianBlur), nón sáng gradient tắt dần theo khoảng cách,
 * quầng sáng mềm quanh vật thể. Vẽ trong SVG phủ toàn khung 1080x1920.
 */
export const ScanBeam = ({
  ox,
  oy,
  tx,
  ty,
  size,
  lock,
  opacity,
  dash,
  locked,
}: {
  ox: number;
  oy: number;
  tx: number;
  ty: number;
  size: number;
  lock: number; // 0..1 khung siết lại khi khoá nét
  opacity: number; // 0..1
  dash: number; // offset chạy của nét đứt
  locked: boolean; // đã nhận diện xong -> xanh lá
}) => {
  const half = (size / 2) * (1 - lock * 0.16);
  const col = locked ? COLORS.tree : COLORS.teal;
  const arm = 34;
  const pulse = 0.75 + Math.sin(dash / 26) * 0.25; // nhịp thở của glow (tất định theo dash)
  const corners: Array<[number, number, number, number]> = [
    [tx - half, ty - half, 1, 1],
    [tx + half, ty - half, -1, 1],
    [tx - half, ty + half, 1, -1],
    [tx + half, ty + half, -1, -1],
  ];

  return (
    <svg
      width={1080}
      height={1920}
      viewBox="0 0 1080 1920"
      style={{ position: 'absolute', inset: 0, opacity }}
    >
      <defs>
        <linearGradient id="wlBeamCone" gradientUnits="userSpaceOnUse" x1={ox} y1={oy} x2={tx} y2={ty}>
          <stop offset="0" stopColor={withAlpha(col, 0.4)} />
          <stop offset="1" stopColor={withAlpha(col, 0.05)} />
        </linearGradient>
        <radialGradient id="wlBeamHalo" cx="0.5" cy="0.5" r="0.5">
          <stop offset="0" stopColor={withAlpha(col, 0.28)} />
          <stop offset="0.7" stopColor={withAlpha(col, 0.1)} />
          <stop offset="1" stopColor={withAlpha(col, 0)} />
        </radialGradient>
        <filter id="wlBeamGlow" x="-80%" y="-80%" width="260%" height="260%">
          <feGaussianBlur stdDeviation="9" />
        </filter>
      </defs>

      {/* nón sáng volumetric từ camera tới vật (gradient tắt dần) */}
      <polygon
        points={`${ox},${oy} ${tx - half},${ty - half} ${tx + half},${ty - half}`}
        fill="url(#wlBeamCone)"
      />

      {/* quầng sáng mềm ôm quanh vật đang quét */}
      <circle cx={tx} cy={ty} r={half * 1.25} fill="url(#wlBeamHalo)" opacity={pulse} />

      {/* LỚP GLOW: tia + khung nhoè phát sáng phía sau */}
      <g filter="url(#wlBeamGlow)" opacity={0.85 * pulse}>
        <line x1={ox} y1={oy} x2={tx - half} y2={ty - half} stroke={col} strokeWidth={9} strokeLinecap="round" />
        <line x1={ox} y1={oy} x2={tx + half} y2={ty - half} stroke={col} strokeWidth={9} strokeLinecap="round" />
        {corners.map(([cx, cy, sx, sy], i) => (
          <g key={i} stroke={col} strokeWidth={11} strokeLinecap="round" fill="none">
            <line x1={cx} y1={cy} x2={cx + arm * sx} y2={cy} />
            <line x1={cx} y1={cy} x2={cx} y2={cy + arm * sy} />
          </g>
        ))}
        <circle cx={ox} cy={oy} r={13} fill={col} />
      </g>

      {/* LỚP NÉT: hai tia nét đứt chạy */}
      <line
        x1={ox}
        y1={oy}
        x2={tx - half}
        y2={ty - half}
        stroke={withAlpha('#FFFFFF', 0.9)}
        strokeWidth={4}
        strokeLinecap="round"
        strokeDasharray="16 13"
        strokeDashoffset={-dash}
      />
      <line
        x1={ox}
        y1={oy}
        x2={tx + half}
        y2={ty - half}
        stroke={withAlpha('#FFFFFF', 0.9)}
        strokeWidth={4}
        strokeLinecap="round"
        strokeDasharray="16 13"
        strokeDashoffset={-dash}
      />
      {/* khung lấy nét 4 góc bao quanh vật thật */}
      {corners.map(([cx, cy, sx, sy], i) => (
        <g key={i} stroke={col} strokeWidth={7} strokeLinecap="round" fill="none">
          <line x1={cx} y1={cy} x2={cx + arm * sx} y2={cy} />
          <line x1={cx} y1={cy} x2={cx} y2={cy + arm * sy} />
        </g>
      ))}
      {/* chấm camera + vòng năng lượng */}
      <circle cx={ox} cy={oy} r={9} fill="#FFFFFF" />
      <circle cx={ox} cy={oy} r={9} fill={withAlpha(col, 0.55)} />
      <circle cx={ox} cy={oy} r={16 + pulse * 4} fill="none" stroke={withAlpha(col, 0.5)} strokeWidth={3} />
    </svg>
  );
};
