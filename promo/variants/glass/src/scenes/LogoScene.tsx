import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { BackgroundPaper } from '../components/BackgroundPaper';
import { glassFill, glassBorder, glassBlur, Specular } from '../components/Glass';
import { LogoMark } from '../components/Icons';

/** Cảnh E: chốt logo + tagline — logo đặt trên đĩa kính phát sáng. */
export const LogoScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bgIn = interpolate(frame, [0, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const markPop = spring({ frame: frame - 4, fps, config: { damping: 12, mass: 0.7 }, durationInFrames: 28 });
  const wordIn = interpolate(frame, [8, 22], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const tagIn = interpolate(frame, [14, 30], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // vòng sáng lan toả chậm quanh đĩa kính
  const haloPulse = 1 + Math.sin(frame / 14) * 0.03;

  const DISC = 430;

  return (
    <AbsoluteFill style={{ opacity: bgIn }}>
      <BackgroundPaper />

      {/* quầng sáng teal giữa khung để logo nổi khối */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(56% 32% at 50% 40%, ${withAlpha('#41E0F2', 0.42)} 0%, transparent 70%)`,
        }}
      />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 34,
        }}
      >
        {/* đĩa kính tròn + logo */}
        <div
          style={{
            position: 'relative',
            width: DISC,
            height: DISC,
            transform: `scale(${markPop * haloPulse})`,
          }}
        >
          <div
            style={{
              position: 'absolute',
              inset: 0,
              borderRadius: '50%',
              background: glassFill(0.2),
              border: glassBorder(0.55),
              boxShadow: `0 30px 70px ${withAlpha('#02222B', 0.5)}, 0 0 110px ${withAlpha('#41E0F2', 0.55)}, inset 0 2px 0 ${withAlpha('#FFFFFF', 0.55)}`,
              ...glassBlur(20),
            }}
          />
          <Specular radius="50%" strength={0.32} />
          {/* vạch khắc quanh viền đĩa — chất "Apple lens" */}
          <svg
            width={DISC}
            height={DISC}
            viewBox="0 0 100 100"
            style={{ position: 'absolute', inset: 0 }}
          >
            {Array.from({ length: 48 }).map((_, i) => {
              const a = (i / 48) * Math.PI * 2;
              const r1 = 45.5;
              const r2 = i % 4 === 0 ? 48.5 : 47.2;
              return (
                <line
                  key={i}
                  x1={50 + Math.cos(a) * r1}
                  y1={50 + Math.sin(a) * r1}
                  x2={50 + Math.cos(a) * r2}
                  y2={50 + Math.sin(a) * r2}
                  stroke={withAlpha('#EAFBFE', 0.5)}
                  strokeWidth={0.5}
                />
              );
            })}
          </svg>
          <div
            style={{
              position: 'absolute',
              inset: 0,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              filter: `drop-shadow(0 18px 30px ${withAlpha('#02222B', 0.45)}) drop-shadow(0 0 26px ${withAlpha('#FFFFFF', 0.35)})`,
            }}
          >
            <LogoMark size={250} />
          </div>
        </div>

        <div
          style={{
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 120,
            color: '#FFFFFF',
            opacity: wordIn,
            transform: `translateY(${(1 - wordIn) * 26}px)`,
            textShadow: `0 0 44px ${withAlpha(COLORS.teal, 0.55)}, 0 4px 16px ${withAlpha('#02222B', 0.5)}`,
          }}
        >
          Wonder<span style={{ color: COLORS.badgeGold }}>Lens</span>
        </div>

        {/* tagline trong chip kính */}
        <div
          style={{
            position: 'relative',
            opacity: tagIn,
            transform: `translateY(${(1 - tagIn) * 20}px)`,
            padding: '18px 44px',
            borderRadius: 999,
            background: glassFill(0.12),
            border: glassBorder(0.38),
            boxShadow: `0 18px 44px ${withAlpha('#02222B', 0.4)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.4)}`,
            ...glassBlur(16),
            fontFamily: BODY,
            fontWeight: 700,
            fontSize: 36,
            color: withAlpha('#FFFFFF', 0.98),
            textAlign: 'center',
            lineHeight: 1.3,
            whiteSpace: 'nowrap',
            textShadow: `0 2px 10px ${withAlpha('#02222B', 0.45)}`,
          }}
        >
          <Specular radius={999} strength={0.24} />
          Chụp đồ vật — Khám phá hành trình tạo ra nó.
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
