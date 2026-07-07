import { useCurrentFrame, useVideoConfig, interpolate } from 'remotion';
import { COLORS, POP } from '../theme';

// random tất định theo index (không dùng Math.random để render lặp lại y hệt).
const rand = (n: number) => {
  const s = Math.sin(n * 12.9898) * 43758.5453;
  return s - Math.floor(s);
};

/** Confetti pop: mảnh TO bản, viền ink sticker, xoay tít. */
export const Confetti = ({
  originXRatio = 0.5,
  originYRatio = 0.42,
  count = 80,
  startFrame = 0,
}: {
  originXRatio?: number;
  originYRatio?: number;
  count?: number;
  startFrame?: number;
}) => {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const t = frame - startFrame;
  if (t < 0) return null;

  const ox = width * originXRatio;
  const oy = height * originYRatio;

  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
      {Array.from({ length: count }).map((_, i) => {
        const angle = rand(i) * Math.PI * 2;
        const speed = 18 + rand(i + 7) * 30;
        const vx = Math.cos(angle) * speed;
        const vy = Math.sin(angle) * speed - 30;
        const g = 1.15;
        const x = ox + vx * t;
        const y = oy + vy * t + 0.5 * g * t * t;
        const life = 70 + rand(i + 3) * 30;
        const opacity = interpolate(t, [0, 6, life - 18, life], [0, 1, 1, 0], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
        });
        if (opacity <= 0) return null;
        const size = 22 + rand(i + 11) * 22;
        const color = COLORS.confetti[i % COLORS.confetti.length];
        const rot = t * (9 + rand(i + 5) * 16) * (rand(i) > 0.5 ? 1 : -1);
        const round = rand(i + 2) > 0.55;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              width: size,
              height: round ? size : size * 0.55,
              background: color,
              border: `3px solid ${POP.outline}`,
              boxSizing: 'border-box',
              borderRadius: round ? '50%' : 5,
              opacity,
              transform: `rotate(${rot}deg)`,
            }}
          />
        );
      })}
    </div>
  );
};
