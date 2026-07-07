import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { COLORS, withAlpha } from '../theme';

// random tất định theo index (giống Confetti) — render lặp lại y hệt.
const rand = (n: number) => {
  const s = Math.sin(n * 12.9898) * 43758.5453;
  return s - Math.floor(s);
};

const BOKEH_COUNT = 12;

/**
 * Nền "storybook 2.5D": trời ấm nhiều lớp + vệt nắng + bokeh trôi chậm
 * + vignette + grain mịn (feTurbulence) cho chất phim.
 */
export const BackgroundPaper = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(180deg, #FFFFFF 0%, ${COLORS.paper} 34%, ${COLORS.paperWarm} 78%, #F3E2C2 100%)`,
      }}
    >
      {/* quầng nắng ấm trên-trái (nguồn sáng chính của cả clip) */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(75% 46% at 24% 6%, ${withAlpha('#FFF3D0', 0.9)} 0%, ${withAlpha('#FFEDBE', 0.35)} 42%, transparent 70%)`,
        }}
      />
      {/* hơi thở teal rất nhẹ phía dưới-phải để nền không đơn sắc */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(70% 40% at 84% 96%, ${withAlpha(COLORS.teal, 0.1)} 0%, transparent 65%)`,
        }}
      />

      {/* bokeh tròn mờ trôi chậm */}
      {Array.from({ length: BOKEH_COUNT }).map((_, i) => {
        const size = 70 + rand(i + 1) * 190;
        const x = rand(i + 21) * 1080;
        const baseY = rand(i + 41) * 1920;
        const drift = 0.12 + rand(i + 61) * 0.22; // px / frame — trôi lên rất chậm
        const y = (((baseY - frame * drift) % 2200) + 2200) % 2200 - 140;
        const sway = Math.sin(frame / 70 + i * 1.7) * 14;
        const warm = rand(i + 81) > 0.45;
        const tint = warm ? '#FFDFA0' : '#9FE9F2';
        const alpha = 0.1 + rand(i + 5) * 0.12;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x + sway - size / 2,
              top: y - size / 2,
              width: size,
              height: size,
              borderRadius: '50%',
              background: `radial-gradient(circle at 38% 34%, ${withAlpha('#FFFFFF', alpha * 0.9)} 0%, ${withAlpha(tint, alpha)} 45%, transparent 72%)`,
              filter: 'blur(2px)',
            }}
          />
        );
      })}

      {/* chấm bi giấy — giữ ADN cũ nhưng mờ hơn để nhường bokeh */}
      <AbsoluteFill
        style={{
          backgroundImage: `radial-gradient(${withAlpha(COLORS.teal, 0.05)} 3px, transparent 3px)`,
          backgroundSize: '60px 60px',
        }}
      />

      {/* grain mịn chất phim */}
      <svg
        width="100%"
        height="100%"
        style={{ position: 'absolute', inset: 0, opacity: 0.045, mixBlendMode: 'multiply' }}
      >
        <filter id="wlGrain">
          <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7" stitchTiles="stitch" />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect width="100%" height="100%" filter="url(#wlGrain)" />
      </svg>

      {/* vignette nhẹ quanh mép khung */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(120% 100% at 50% 42%, transparent 58%, ${withAlpha('#8A6A3A', 0.12)} 88%, ${withAlpha('#5A4426', 0.2)} 100%)`,
        }}
      />
    </AbsoluteFill>
  );
};
