import { CINE, seeded, withAlpha } from '../theme';

/**
 * Tia quét neon điện ảnh + khung lấy nét AR + hạt sáng bay quanh vật:
 * từ camera điện thoại (ox,oy) chiếu tới vật thật (tx,ty).
 * Glow = nhiều lớp stroke chồng nhau (blur to -> lõi sáng trắng).
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
  dash: number; // offset chạy của nét đứt (= frame * 5)
  locked: boolean; // đã nhận diện xong -> xanh lá
}) => {
  const frame = dash / 5; // khôi phục frame để chạy hạt sáng (tất định)
  const half = (size / 2) * (1 - lock * 0.16);
  const col = locked ? '#5CE6A1' : CINE.neon;
  const core = locked ? '#D9FFE9' : '#EAFDFF';
  const arm = 34;
  const corners: Array<[number, number, number, number]> = [
    [tx - half, ty - half, 1, 1],
    [tx + half, ty - half, -1, 1],
    [tx - half, ty + half, 1, -1],
    [tx + half, ty + half, -1, -1],
  ];

  // hạt sáng li ti bay quanh cốc khi quét (quỹ đạo tất định theo index)
  const particles = Array.from({ length: 18 }).map((_, i) => {
    const baseAngle = seeded(i * 3 + 2) * Math.PI * 2;
    const speed = 0.02 + seeded(i * 5 + 1) * 0.03;
    const angle = baseAngle + frame * speed * (seeded(i) > 0.5 ? 1 : -1);
    const rx = half * (0.7 + seeded(i * 7 + 4) * 0.75);
    const ry = half * (0.5 + seeded(i * 11 + 6) * 0.6);
    const px = tx + Math.cos(angle) * rx;
    const py = ty - 20 + Math.sin(angle) * ry - Math.sin(frame / 26 + i) * 14;
    const r = 2.2 + seeded(i * 13 + 3) * 3.4;
    const tw = 0.45 + 0.55 * Math.sin(frame / 7 + i * 1.9) ** 2;
    return { px, py, r, tw };
  });

  const beam = (x2: number, y2: number, key: string) => (
    <g key={key}>
      {/* lớp glow ngoài cùng */}
      <line
        x1={ox} y1={oy} x2={x2} y2={y2}
        stroke={withAlpha(col, 0.55)} strokeWidth={16} strokeLinecap="round"
        filter="url(#beam-glow-big)"
      />
      {/* lớp glow giữa */}
      <line
        x1={ox} y1={oy} x2={x2} y2={y2}
        stroke={withAlpha(col, 0.8)} strokeWidth={7} strokeLinecap="round"
        filter="url(#beam-glow-small)"
      />
      {/* lõi sáng — nét đứt chạy */}
      <line
        x1={ox} y1={oy} x2={x2} y2={y2}
        stroke={core} strokeWidth={3.5} strokeLinecap="round"
        strokeDasharray="16 13" strokeDashoffset={-dash}
      />
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
        <filter id="beam-glow-big" x="-60%" y="-60%" width="220%" height="220%">
          <feGaussianBlur stdDeviation="14" />
        </filter>
        <filter id="beam-glow-small" x="-60%" y="-60%" width="220%" height="220%">
          <feGaussianBlur stdDeviation="5" />
        </filter>
        <linearGradient id="beam-cone" x1={ox} y1={oy} x2={tx} y2={ty} gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor={withAlpha(col, 0.34)} />
          <stop offset="70%" stopColor={withAlpha(col, 0.1)} />
          <stop offset="100%" stopColor={withAlpha(col, 0.02)} />
        </linearGradient>
        <radialGradient id="beam-pool" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={withAlpha(col, 0.34)} />
          <stop offset="100%" stopColor={withAlpha(col, 0)} />
        </radialGradient>
      </defs>

      {/* nón sáng volumetric từ camera tới vật */}
      <polygon
        points={`${ox},${oy} ${tx - half},${ty - half} ${tx + half},${ty - half}`}
        fill="url(#beam-cone)"
        filter="url(#beam-glow-small)"
      />
      {/* vũng sáng neon nơi vật đứng */}
      <ellipse cx={tx} cy={ty + half * 0.72} rx={half * 1.5} ry={half * 0.42} fill="url(#beam-pool)" />

      {/* hai tia neon nhiều lớp */}
      {beam(tx - half, ty - half, 'L')}
      {beam(tx + half, ty - half, 'R')}

      {/* khung lấy nét 4 góc — glow + lõi */}
      {corners.map(([cx, cy, sx, sy], i) => (
        <g key={i}>
          <g stroke={withAlpha(col, 0.75)} strokeWidth={12} strokeLinecap="round" fill="none" filter="url(#beam-glow-small)">
            <line x1={cx} y1={cy} x2={cx + arm * sx} y2={cy} />
            <line x1={cx} y1={cy} x2={cx} y2={cy + arm * sy} />
          </g>
          <g stroke={core} strokeWidth={5} strokeLinecap="round" fill="none">
            <line x1={cx} y1={cy} x2={cx + arm * sx} y2={cy} />
            <line x1={cx} y1={cy} x2={cx} y2={cy + arm * sy} />
          </g>
        </g>
      ))}

      {/* hạt sáng li ti bay quanh vật */}
      {particles.map((p, i) => (
        <g key={`p${i}`} opacity={p.tw}>
          <circle cx={p.px} cy={p.py} r={p.r * 2.4} fill={withAlpha(col, 0.35)} filter="url(#beam-glow-small)" />
          <circle cx={p.px} cy={p.py} r={p.r} fill={core} />
        </g>
      ))}

      {/* chấm camera phát sáng */}
      <circle cx={ox} cy={oy} r={20} fill={withAlpha(col, 0.5)} filter="url(#beam-glow-big)" />
      <circle cx={ox} cy={oy} r={9} fill={core} />
      <circle cx={ox} cy={oy} r={16} fill="none" stroke={withAlpha(col, 0.6)} strokeWidth={3} />
    </svg>
  );
};
