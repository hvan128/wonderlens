import { useCurrentFrame, useVideoConfig, interpolate } from 'remotion';
import { COLORS } from '../theme';

// random tất định theo index (không dùng Math.random để render lặp lại y hệt).
const rand = (n: number) => {
  const s = Math.sin(n * 12.9898) * 43758.5453;
  return s - Math.floor(s);
};

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
        const speed = 16 + rand(i + 7) * 26;
        const vx = Math.cos(angle) * speed;
        const vy = Math.sin(angle) * speed - 26;
        const g = 1.1;
        const x = ox + vx * t;
        const y = oy + vy * t + 0.5 * g * t * t;
        const life = 70 + rand(i + 3) * 30;
        const opacity = interpolate(t, [0, 6, life - 18, life], [0, 1, 1, 0], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
        });
        if (opacity <= 0) return null;
        const size = 14 + rand(i + 11) * 16;
        const color = COLORS.confetti[i % COLORS.confetti.length];
        const rot = t * (4 + rand(i + 5) * 8) * (rand(i) > 0.5 ? 1 : -1);
        const round = rand(i + 2) > 0.55;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              width: size,
              height: round ? size : size * 0.5,
              background: color,
              borderRadius: round ? '50%' : 3,
              opacity,
              transform: `rotate(${rot}deg)`,
            }}
          />
        );
      })}
    </div>
  );
};
