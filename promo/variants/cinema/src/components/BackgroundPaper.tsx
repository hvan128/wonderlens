import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { CINE, seeded, withAlpha } from '../theme';

// vị trí bokeh cố định (tất định theo index) — chấm sáng xa mờ trong đêm
const BOKEH = Array.from({ length: 16 }).map((_, i) => ({
  x: seeded(i * 3 + 1) * 1080,
  y: 90 + seeded(i * 5 + 2) * 1150,
  r: 7 + seeded(i * 7 + 3) * 24,
  warm: seeded(i * 11 + 4) > 0.72,
  blur: 5 + seeded(i * 13 + 5) * 12,
  tw: 0.5 + seeded(i * 17 + 6) * 0.5, // pha nhấp nháy
}));

/**
 * Biến thể cinema: nền ĐÊM xanh thẫm — deep navy/teal gradient,
 * bokeh xa mờ + god-rays chéo từ trên. (Thay cho nền "giấy ấm" bản gốc.)
 */
export const BackgroundPaper = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(185deg, ${CINE.skyTop} 0%, ${CINE.skyMid} 46%, ${CINE.skyLow} 74%, ${CINE.horizon} 100%)`,
        overflow: 'hidden',
      }}
    >
      {/* quầng sáng teal mờ giữa khung — không gian có chiều sâu */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(70% 46% at 62% 60%, ${withAlpha(CINE.neonDim, 0.14)} 0%, transparent 70%)`,
        }}
      />

      {/* bokeh xa mờ, nhấp nháy chậm */}
      {BOKEH.map((b, i) => {
        const twinkle = 0.5 + 0.5 * Math.sin(frame / 34 + b.tw * Math.PI * 2 + i);
        const drift = Math.sin(frame / 80 + i * 1.7) * 8;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: b.x - b.r,
              top: b.y - b.r + drift,
              width: b.r * 2,
              height: b.r * 2,
              borderRadius: '50%',
              background: b.warm ? CINE.warm : CINE.neonSoft,
              opacity: 0.06 + twinkle * 0.14,
              filter: `blur(${b.blur}px)`,
            }}
          />
        );
      })}

      {/* god-rays chéo mờ từ góc trên trái */}
      <div
        style={{
          position: 'absolute',
          left: -420,
          top: -560,
          width: 1500,
          height: 2100,
          transform: 'rotate(24deg)',
          transformOrigin: '50% 0%',
          background: `repeating-linear-gradient(90deg,
            transparent 0px,
            transparent 130px,
            ${withAlpha(CINE.neonSoft, 0.075)} 210px,
            transparent 300px,
            transparent 390px)`,
          filter: 'blur(26px)',
          opacity: 0.9,
        }}
      />
      {/* một dải ray ấm nhẹ (nguồn sáng spotlight) */}
      <div
        style={{
          position: 'absolute',
          left: 330,
          top: -420,
          width: 460,
          height: 2000,
          transform: 'rotate(18deg)',
          transformOrigin: '50% 0%',
          background: `linear-gradient(90deg, transparent 0%, ${withAlpha(CINE.warmSoft, 0.07)} 50%, transparent 100%)`,
          filter: 'blur(30px)',
        }}
      />
    </AbsoluteFill>
  );
};
