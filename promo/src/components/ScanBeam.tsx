import { COLORS, withAlpha } from '../theme';

/**
 * Tia quét + khung lấy nét AR: từ camera điện thoại (ox,oy) chiếu tới
 * vật thật (tx,ty). Vẽ trong SVG phủ toàn khung 1080x1920.
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
      {/* nón sáng mờ từ camera tới vật */}
      <polygon
        points={`${ox},${oy} ${tx - half},${ty - half} ${tx + half},${ty - half}`}
        fill={withAlpha(col, 0.1)}
      />
      {/* hai tia nét đứt */}
      <line
        x1={ox}
        y1={oy}
        x2={tx - half}
        y2={ty - half}
        stroke={withAlpha(col, 0.85)}
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
        stroke={withAlpha(col, 0.85)}
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
      {/* chấm camera */}
      <circle cx={ox} cy={oy} r={9} fill={col} />
      <circle cx={ox} cy={oy} r={16} fill="none" stroke={withAlpha(col, 0.5)} strokeWidth={3} />
    </svg>
  );
};
