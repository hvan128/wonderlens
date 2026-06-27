import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { LogoMark } from '../components/Icons';

/** Cảnh E: chốt logo + tagline. */
export const LogoScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bgIn = interpolate(frame, [0, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const markPop = spring({ frame: frame - 4, fps, config: { damping: 12, mass: 0.7 }, durationInFrames: 28 });
  const wordIn = interpolate(frame, [12, 28], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const tagIn = interpolate(frame, [22, 40], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        opacity: bgIn,
        background: `radial-gradient(120% 90% at 50% 38%, ${COLORS.teal} 0%, ${COLORS.tealDark} 55%, ${COLORS.tealDeep} 100%)`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 30,
      }}
    >
      <div
        style={{
          transform: `scale(${markPop})`,
          filter: `drop-shadow(0 18px 30px ${withAlpha('#04363F', 0.45)})`,
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
          opacity: wordIn,
          transform: `translateY(${(1 - wordIn) * 26}px)`,
          textShadow: `0 4px 0 ${withAlpha('#04363F', 0.25)}`,
        }}
      >
        Wonder<span style={{ color: COLORS.badgeGold }}>Lens</span>
      </div>

      <div
        style={{
          fontFamily: BODY,
          fontWeight: 700,
          fontSize: 42,
          color: withAlpha('#FFFFFF', 0.95),
          opacity: tagIn,
          transform: `translateY(${(1 - tagIn) * 20}px)`,
          textAlign: 'center',
          padding: '0 90px',
          lineHeight: 1.3,
        }}
      >
        Chụp đồ vật — Khám phá hành trình tạo ra nó.
      </div>
    </AbsoluteFill>
  );
};
