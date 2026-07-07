import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { LogoMark } from '../components/Icons';

// random tất định theo index (không dùng Math.random).
const rand = (n: number) => {
  const s = Math.sin(n * 12.9898) * 43758.5453;
  return s - Math.floor(s);
};

const RAY_COUNT = 10;
const SPARK_COUNT = 16;

/** Cảnh E — bản "depth": logo trên nền teal sâu, tia sáng xoay chậm, hạt sáng bay lên. */
export const LogoScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bgIn = interpolate(frame, [0, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const markPop = spring({ frame: frame - 4, fps, config: { damping: 12, mass: 0.7 }, durationInFrames: 28 });
  const wordIn = spring({ frame: frame - 12, fps, config: { damping: 13, mass: 0.7 }, durationInFrames: 22 });
  const tagIn = spring({ frame: frame - 22, fps, config: { damping: 14, mass: 0.7 }, durationInFrames: 22 });
  const rayRot = frame * 0.25;

  return (
    <AbsoluteFill
      style={{
        opacity: bgIn,
        background: `radial-gradient(120% 90% at 50% 38%, #35D2E5 0%, ${COLORS.tealDark} 52%, #07515D 82%, #043B45 100%)`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 30,
        overflow: 'hidden',
      }}
    >
      {/* tia sáng god-ray xoay chậm sau logo */}
      <svg
        width={1080}
        height={1920}
        viewBox="0 0 1080 1920"
        style={{ position: 'absolute', inset: 0 }}
      >
        <g transform={`rotate(${rayRot} 540 760)`} opacity={0.5 * markPop}>
          {Array.from({ length: RAY_COUNT }).map((_, i) => {
            const a = (i / RAY_COUNT) * 360;
            return (
              <polygon
                key={i}
                points="540,760 460,-500 620,-500"
                fill={withAlpha('#BFF6FF', 0.07)}
                transform={`rotate(${a} 540 760)`}
              />
            );
          })}
        </g>
      </svg>

      {/* quầng sáng ấm sau logo */}
      <div
        style={{
          position: 'absolute',
          left: 540 - 420,
          top: 760 - 420,
          width: 840,
          height: 840,
          borderRadius: '50%',
          background: `radial-gradient(circle, ${withAlpha('#DFFBFF', 0.4)} 0%, ${withAlpha('#9FF2FF', 0.14)} 45%, transparent 70%)`,
          opacity: markPop,
          mixBlendMode: 'screen',
        }}
      />

      {/* hạt sáng nhỏ bay lên chậm (bụi tiên) */}
      {Array.from({ length: SPARK_COUNT }).map((_, i) => {
        const x = rand(i + 3) * 1000 + 40;
        const baseY = rand(i + 13) * 1920;
        const speed = 1.1 + rand(i + 23) * 1.6;
        const y = (((baseY - frame * speed) % 2000) + 2000) % 2000 - 40;
        const size = 5 + rand(i + 33) * 9;
        const tw = 0.45 + Math.sin(frame / 9 + i * 2.1) * 0.35;
        const gold = rand(i + 43) > 0.72;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              width: size,
              height: size,
              borderRadius: '50%',
              background: gold ? '#FFE9A8' : '#D9FAFF',
              boxShadow: `0 0 ${size * 1.6}px ${withAlpha(gold ? '#FFD86B' : '#9FF2FF', 0.8)}`,
              opacity: tw * bgIn,
            }}
          />
        );
      })}

      <div
        style={{
          transform: `scale(${markPop})`,
          filter: `drop-shadow(0 18px 30px ${withAlpha('#04363F', 0.5)}) drop-shadow(0 0 26px ${withAlpha('#BFF6FF', 0.35)})`,
        }}
      >
        <LogoMark size={240} />
      </div>

      <div
        style={{
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 120,
          color: '#FFFFFF',
          opacity: Math.min(1, wordIn),
          transform: `translateY(${(1 - wordIn) * 26}px)`,
          textShadow: `0 4px 0 ${withAlpha('#04363F', 0.3)}, 0 18px 40px ${withAlpha('#021C22', 0.45)}`,
        }}
      >
        Wonder
        <span
          style={{
            color: COLORS.badgeGold,
            textShadow: `0 4px 0 ${withAlpha('#7A5200', 0.35)}, 0 0 34px ${withAlpha('#FFD86B', 0.55)}`,
          }}
        >
          Lens
        </span>
      </div>

      <div
        style={{
          fontFamily: BODY,
          fontWeight: 700,
          fontSize: 37,
          color: withAlpha('#FFFFFF', 0.95),
          opacity: Math.min(1, tagIn),
          transform: `translateY(${(1 - tagIn) * 20}px)`,
          textAlign: 'center',
          whiteSpace: 'nowrap',
          lineHeight: 1.3,
          textShadow: `0 3px 14px ${withAlpha('#021C22', 0.5)}`,
        }}
      >
        Chụp đồ vật — Khám phá hành trình tạo ra nó.
      </div>

      {/* vignette tối nhẹ quanh mép cho khối sân khấu */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(115% 95% at 50% 42%, transparent 55%, ${withAlpha('#02222A', 0.35)} 100%)`,
          pointerEvents: 'none',
        }}
      />
    </AbsoluteFill>
  );
};
