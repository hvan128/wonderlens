import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { COLORS, withAlpha } from '../theme';

/**
 * Nền "WonderBackground" liquid-glass đồng bộ app: gradient teal đậm→nhạt
 * nhiều lớp + blob màu pastel lớn blur mạnh trôi rất chậm (thuần hàm theo frame).
 */
const Blob = ({
  x,
  y,
  size,
  color,
  opacity,
}: {
  x: number;
  y: number;
  size: number;
  color: string;
  opacity: number;
}) => (
  <div
    style={{
      position: 'absolute',
      left: x - size / 2,
      top: y - size / 2,
      width: size,
      height: size,
      borderRadius: '50%',
      background: `radial-gradient(circle at 50% 50%, ${color} 0%, transparent 70%)`,
      filter: 'blur(70px)',
      opacity,
    }}
  />
);

export const BackgroundPaper = () => {
  const frame = useCurrentFrame();
  const t = frame / 30; // giây — blob trôi rất chậm

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(180deg, #063540 0%, ${COLORS.tealDeep} 34%, #0B7A8D 68%, ${COLORS.tealDark} 100%)`,
        overflow: 'hidden',
      }}
    >
      {/* blob teal sáng — trên trái */}
      <Blob
        x={230 + Math.sin(t * 0.23) * 70}
        y={430 + Math.cos(t * 0.17) * 55}
        size={980}
        color={withAlpha('#41E0F2', 0.6)}
        opacity={0.55}
      />
      {/* blob vàng ấm — giữa phải */}
      <Blob
        x={930 + Math.cos(t * 0.19 + 2) * 65}
        y={1010 + Math.sin(t * 0.14 + 1) * 70}
        size={900}
        color={withAlpha(COLORS.badgeGold, 0.5)}
        opacity={0.4}
      />
      {/* blob hồng pastel — dưới trái */}
      <Blob
        x={170 + Math.sin(t * 0.16 + 4) * 60}
        y={1660 + Math.cos(t * 0.21 + 3) * 50}
        size={820}
        color={withAlpha('#FF9FB2', 0.5)}
        opacity={0.38}
      />

      {/* hạt sáng li ti rất mờ — chất "magic" */}
      <AbsoluteFill
        style={{
          backgroundImage: `radial-gradient(${withAlpha('#EAFBFE', 0.1)} 2.5px, transparent 2.5px)`,
          backgroundSize: '84px 84px',
          opacity: 0.5,
        }}
      />

      {/* vignette nhẹ giữ tập trung vào giữa khung */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(130% 95% at 50% 42%, transparent 55%, ${withAlpha('#032128', 0.55)} 100%)`,
        }}
      />
    </AbsoluteFill>
  );
};
