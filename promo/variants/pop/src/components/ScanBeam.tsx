import { COLORS, POP, withAlpha } from '../theme';
import { starPoints } from './Icons';

/**
 * Tia quét + khung lấy nét AR phong cách comic: nét viền ink dưới nét màu,
 * xung năng lượng chạy dọc tia (speed lines) và starburst khi khoá mục tiêu.
 * Vẽ trong SVG phủ toàn khung 1080x1920.
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
  const ink = POP.outline;
  const arm = 40;
  const corners: Array<[number, number, number, number]> = [
    [tx - half, ty - half, 1, 1],
    [tx + half, ty - half, -1, 1],
    [tx - half, ty + half, 1, -1],
    [tx + half, ty + half, -1, -1],
  ];
  // xung năng lượng chạy dọc trục tia (deterministic theo dash)
  const ex = tx;
  const ey = ty - half;
  const pulses = [0, 1, 2].map((i) => ((dash / 260 + i / 3) % 1));

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
        fill={withAlpha(col, 0.24)}
      />

      {/* starburst bùng ra khi khoá mục tiêu */}
      {locked && (
        <g transform={`rotate(${dash * 0.12} ${tx} ${ty})`}>
          <polygon
            points={starPoints(tx, ty, 10, half * 1.65, half * 1.12)}
            fill={withAlpha('#FFE45C', 0.9)}
            stroke={ink}
            strokeWidth={5}
            strokeLinejoin="round"
          />
        </g>
      )}

      {/* hai tia nét đứt: ink dưới + màu trên (kiểu sticker) */}
      {([-1, 1] as const).map((s) => (
        <g key={s}>
          <line
            x1={ox}
            y1={oy}
            x2={tx + half * s}
            y2={ty - half}
            stroke={ink}
            strokeWidth={11}
            strokeLinecap="round"
            strokeDasharray="20 16"
            strokeDashoffset={-dash}
            opacity={0.9}
          />
          <line
            x1={ox}
            y1={oy}
            x2={tx + half * s}
            y2={ty - half}
            stroke={col}
            strokeWidth={6}
            strokeLinecap="round"
            strokeDasharray="20 16"
            strokeDashoffset={-dash}
          />
        </g>
      ))}

      {/* speed lines: xung trắng lao dọc trục quét */}
      {pulses.map((t, i) => {
        const px = ox + (ex - ox) * t;
        const py = oy + (ey - oy) * t;
        return (
          <line
            key={i}
            x1={px}
            y1={py}
            x2={px + (ex - ox) * 0.08}
            y2={py + (ey - oy) * 0.08}
            stroke="#FFFFFF"
            strokeWidth={10}
            strokeLinecap="round"
            opacity={0.95 * (1 - t)}
          />
        );
      })}

      {/* khung lấy nét 4 góc: ink dưới + màu trên */}
      {corners.map(([cx, cy, sx, sy], i) => (
        <g key={i} fill="none" strokeLinecap="round" strokeLinejoin="round">
          <path d={`M ${cx + arm * sx} ${cy} L ${cx} ${cy} L ${cx} ${cy + arm * sy}`} stroke={ink} strokeWidth={15} />
          <path d={`M ${cx + arm * sx} ${cy} L ${cx} ${cy} L ${cx} ${cy + arm * sy}`} stroke={col} strokeWidth={9} />
        </g>
      ))}

      {/* chấm camera */}
      <circle cx={ox} cy={oy} r={11} fill={col} stroke={ink} strokeWidth={4} />
      <circle cx={ox} cy={oy} r={19} fill="none" stroke={withAlpha(col, 0.6)} strokeWidth={4} />
    </svg>
  );
};
