import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing } from 'remotion';
import { COLORS, POP, withAlpha, solidShadow } from '../theme';
import { HEADING, BODY } from '../fonts';
import { LogoMark, Burst, Sparkle } from '../components/Icons';
import { Confetti } from '../components/Confetti';

// tâm cụm logo (để đặt nan quạt tia sáng quay)
const RAY_CX = 540;
const RAY_CY = 800;

/** Cảnh E: chốt logo + tagline — bản pop: nan quạt tia quay + starburst + confetti. */
export const LogoScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bgIn = interpolate(frame, [0, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const markPop = spring({ frame: frame - 4, fps, config: { damping: 10, mass: 0.7 }, durationInFrames: 30 });
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

  return (
    <AbsoluteFill
      style={{
        opacity: bgIn,
        background: `radial-gradient(120% 90% at 50% 38%, #2BD9E8 0%, #0BA9BF 55%, #067385 100%)`,
        overflow: 'hidden',
      }}
    >
      {/* nan quạt tia sáng quay chậm (kiểu poster cartoon) */}
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{ position: 'absolute', inset: 0 }}>
        <g transform={`rotate(${frame * 0.35} ${RAY_CX} ${RAY_CY})`}>
          {Array.from({ length: 12 }).map((_, i) => {
            const a0 = ((i * 30) * Math.PI) / 180;
            const a1 = ((i * 30 + 14) * Math.PI) / 180;
            const R = 1500;
            return (
              <path
                key={i}
                d={`M${RAY_CX} ${RAY_CY} L${RAY_CX + Math.cos(a0) * R} ${RAY_CY + Math.sin(a0) * R} L${RAY_CX + Math.cos(a1) * R} ${RAY_CY + Math.sin(a1) * R} Z`}
                fill={withAlpha('#FFFFFF', 0.1)}
              />
            );
          })}
        </g>
      </svg>

      {/* confetti bung ra khi logo nảy vào (nằm DƯỚI chữ để không che tagline) */}
      <Confetti originXRatio={0.5} originYRatio={0.4} startFrame={6} count={80} />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 34,
        }}
      >
        {/* logo trong đĩa sticker trắng + starburst vàng quay phía sau */}
        <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ position: 'absolute', transform: `rotate(${-frame * 0.6}deg) scale(${markPop})` }}>
            <Burst size={560} color={COLORS.badgeGold} spikes={14} innerRatio={0.7} />
          </div>
          <div
            style={{
              position: 'relative',
              width: 310,
              height: 310,
              borderRadius: '50%',
              background: '#FFFFFF',
              border: `7px solid ${POP.outline}`,
              boxSizing: 'border-box',
              boxShadow: solidShadow(12, 12, withAlpha(POP.shadow, 0.5)),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transform: `scale(${markPop})`,
            }}
          >
            <LogoMark size={198} />
          </div>
        </div>

        <div
          style={{
            position: 'relative',
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 124,
            color: '#FFFFFF',
            opacity: wordIn,
            transform: `translateY(${(1 - wordIn) * 26}px) rotate(-1.5deg)`,
            textShadow: `6px 6px 0 ${POP.shadow}`,
          }}
        >
          Wonder<span style={{ color: COLORS.badgeGold }}>Lens</span>
          {/* tia sao lấp lánh quanh wordmark */}
          <div style={{ position: 'absolute', top: -26, right: -58, transform: `scale(${1 + Math.sin(frame / 6) * 0.18})`, opacity: wordIn }}>
            <Sparkle size={54} color={COLORS.badgeGold} />
          </div>
          <div style={{ position: 'absolute', bottom: -6, left: -64, transform: `scale(${1 + Math.sin(frame / 6 + 2.2) * 0.18})`, opacity: wordIn }}>
            <Sparkle size={40} color="#FFFFFF" />
          </div>
        </div>

        {/* tagline trong sticker pill */}
        <div
          style={{
            fontFamily: BODY,
            fontWeight: 800,
            fontSize: 37,
            color: COLORS.ink,
            background: '#FFFFFF',
            border: `5px solid ${POP.outline}`,
            borderRadius: 999,
            padding: '16px 40px',
            boxShadow: solidShadow(8, 8, withAlpha(POP.shadow, 0.5)),
            opacity: tagIn,
            transform: `translateY(${(1 - tagIn) * 20}px) rotate(1.2deg)`,
            textAlign: 'center',
            lineHeight: 1.3,
            whiteSpace: 'nowrap',
          }}
        >
          Chụp đồ vật — Khám phá hành trình tạo ra nó.
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
