import { COLORS, withAlpha } from '../theme';

/**
 * Tia quét + khung lấy nét AR neon: từ camera điện thoại (ox,oy) chiếu tới
 * vật thật (tx,ty). Glow bằng SVG filter (headless Chrome render tốt),
 * kèm lớp nét sắc đè lên trên để không bị nhoè chữ ký hình.
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
  const col = locked ? '#7ED957' : COLORS.teal;
  const arm = 34;
  const corners: Array<[number, number, number, number]> = [
    [tx - half, ty - half, 1, 1],
    [tx + half, ty - half, -1, 1],
    [tx - half, ty + half, 1, -1],
    [tx + half, ty + half, -1, -1],
  ];

  const beams = (
    <g>
      <line
        x1={ox}
        y1={oy}
        x2={tx - half}
        y2={ty - half}
        stroke={withAlpha(col, 0.95)}
        strokeWidth={5}
        strokeLinecap="round"
        strokeDasharray="16 13"
        strokeDashoffset={-dash}
      />
      <line
        x1={ox}
        y1={oy}
        x2={tx + half}
        y2={ty - half}
        stroke={withAlpha(col, 0.95)}
        strokeWidth={5}
        strokeLinecap="round"
        strokeDasharray="16 13"
        strokeDashoffset={-dash}
      />
      {corners.map(([cx, cy, sx, sy], i) => (
        <g key={i} stroke={col} strokeWidth={7} strokeLinecap="round" fill="none">
          <line x1={cx} y1={cy} x2={cx + arm * sx} y2={cy} />
          <line x1={cx} y1={cy} x2={cx} y2={cy + arm * sy} />
        </g>
      ))}
    </g>
  );

  return (
    <svg
      width={1080}
      height={1920}
      viewBox="0 0 1080 1920"
      style={{ position: 'absolute', inset: 0, opacity }}
    >
      <defs>
        <filter id="beam-glow" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="9" />
        </filter>
        <linearGradient id="beam-cone" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={withAlpha(col, 0.04)} />
          <stop offset="100%" stopColor={withAlpha(col, 0.32)} />
        </linearGradient>
      </defs>

      {/* nón sáng mờ từ camera tới vật (đậm dần về phía vật) */}
      <polygon
        points={`${ox},${oy} ${tx - half},${ty - half} ${tx + half},${ty - half}`}
        fill="url(#beam-cone)"
      />

      {/* lớp glow neon phía dưới */}
      <g filter="url(#beam-glow)" opacity={0.9}>
        {beams}
      </g>
      {/* lớp nét sắc phía trên */}
      {beams}

      {/* vầng sáng quanh vật khi khoá nét */}
      <circle
        cx={tx}
        cy={ty}
        r={half * 1.18}
        fill="none"
        stroke={withAlpha(col, 0.35 * lock)}
        strokeWidth={3}
      />

      {/* chấm camera + flare nhỏ */}
      <circle cx={ox} cy={oy} r={18} fill={withAlpha(col, 0.35)} filter="url(#beam-glow)" />
      <circle cx={ox} cy={oy} r={9} fill={col} />
      <circle cx={ox} cy={oy} r={16} fill="none" stroke={withAlpha('#FFFFFF', 0.6)} strokeWidth={2} />
      <g stroke={withAlpha('#FFFFFF', 0.85)} strokeWidth={3} strokeLinecap="round">
        <line x1={ox - 30} y1={oy} x2={ox - 20} y2={oy} />
        <line x1={ox + 20} y1={oy} x2={ox + 30} y2={oy} />
        <line x1={ox} y1={oy - 30} x2={ox} y2={oy - 20} />
        <line x1={ox} y1={oy + 20} x2={ox} y2={oy + 30} />
      </g>
    </svg>
  );
};
