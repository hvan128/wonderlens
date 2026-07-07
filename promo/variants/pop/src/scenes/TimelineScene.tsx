import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing } from 'remotion';
import { COLORS, POP, withAlpha, solidShadow } from '../theme';
import { HEADING, BODY } from '../fonts';
import { StageCard } from '../components/StageCard';
import { Confetti } from '../components/Confetti';
import { Badge } from '../components/Badge';
import { IconCup, Sparkle } from '../components/Icons';
import { CUP_STAGES, OBJECT_NAME } from '../content';

const CARD_TOP = 356;
const CARD_GAP = 300;
const CARD_LEFT = 110;
const SPINE_X = 256;

const ease = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

/** Nền pop teal: khối màu bão hoà + halftone trắng + sọc chéo mờ. */
const PopTealBackground = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(130% 90% at 50% 10%, #35DCEB 0%, #14C3D4 55%, #08A4B8 100%)`,
    }}
  >
    <AbsoluteFill
      style={{
        backgroundImage: `radial-gradient(${withAlpha('#FFFFFF', 0.16)} 7px, transparent 7px)`,
        backgroundSize: '92px 92px',
      }}
    />
    <AbsoluteFill
      style={{
        backgroundImage: `repeating-linear-gradient(-24deg, ${withAlpha('#FFFFFF', 0.07)} 0 30px, transparent 30px 112px)`,
      }}
    />
  </AbsoluteFill>
);

/** Cảnh D: bên trong app — hành trình tạo ra cốc giấy + huy hiệu. Bản pop. */
export const TimelineScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneOpacity = ease(frame, 0, 20);
  const sceneScale = interpolate(frame, [0, 28], [1.06, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const headerIn = ease(frame, 6, 28);
  const badgeIn = spring({ frame: frame - 132, fps, config: { damping: 9, stiffness: 110, mass: 0.9 } });
  const spineGrow = ease(frame, 22, 116);

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity }}>
      <AbsoluteFill style={{ transform: `scale(${sceneScale})` }}>
        <PopTealBackground />

        {/* header sticker */}
        <div
          style={{
            position: 'absolute',
            top: 128,
            left: 0,
            right: 0,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 16,
            opacity: headerIn,
            transform: `translateY(${(1 - headerIn) * -24}px)`,
          }}
        >
          <span
            style={{
              padding: '10px 28px',
              borderRadius: 999,
              background: POP.outline,
              color: '#FFFFFF',
              fontFamily: BODY,
              fontWeight: 800,
              fontSize: 29,
              letterSpacing: 5,
              transform: 'rotate(-1deg)',
            }}
          >
            HÀNH TRÌNH TẠO RA
          </span>
          <div
            style={{
              position: 'relative',
              display: 'flex',
              alignItems: 'center',
              gap: 16,
              background: '#FFFFFF',
              border: `6px solid ${POP.outline}`,
              borderRadius: 34,
              padding: '8px 40px 12px 30px',
              boxShadow: solidShadow(10, 10, withAlpha(POP.shadow, 0.45)),
              transform: 'rotate(-2deg)',
            }}
          >
            <div style={{ transform: `rotate(${Math.sin(frame / 12) * 4}deg)` }}>
              <IconCup size={78} />
            </div>
            <span style={{ fontFamily: HEADING, fontWeight: 800, fontSize: 86, color: COLORS.tealDark }}>
              {OBJECT_NAME}
            </span>
            {/* tia sao lấp lánh quanh tiêu đề */}
            <div style={{ position: 'absolute', top: -34, right: -30, transform: `scale(${1 + Math.sin(frame / 7) * 0.15})` }}>
              <Sparkle size={52} color={COLORS.badgeGold} />
            </div>
            <div style={{ position: 'absolute', bottom: -26, left: -34, transform: `scale(${1 + Math.sin(frame / 7 + 2) * 0.15})` }}>
              <Sparkle size={38} color="#FFFFFF" />
            </div>
          </div>
        </div>

        {/* đường timeline (spine) — thanh trắng viền ink */}
        <div
          style={{
            position: 'absolute',
            left: SPINE_X - 9,
            top: CARD_TOP + 134,
            width: 18,
            height: 3 * CARD_GAP * spineGrow,
            borderRadius: 12,
            background: '#FFFFFF',
            border: `4px solid ${POP.outline}`,
            boxSizing: 'border-box',
          }}
        />

        {/* 4 thẻ chặng — spring nảy overshoot + wiggle nhẹ */}
        {CUP_STAGES.map((stage, i) => {
          const start = 18 + i * 17;
          const enter = spring({
            frame: frame - start,
            fps,
            config: { damping: 12, stiffness: 130, mass: 0.9 },
          });
          const wiggle = Math.sin((frame + i * 17) / 15) * 0.5;
          return (
            <div
              key={stage.icon}
              style={{ position: 'absolute', left: CARD_LEFT, top: CARD_TOP + i * CARD_GAP }}
            >
              <StageCard stage={stage} index={i} enter={enter} wiggle={wiggle} />
            </div>
          );
        })}

        {/* huy hiệu vật liệu */}
        <div
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            top: 1632,
            display: 'flex',
            justifyContent: 'center',
          }}
        >
          <Badge enter={badgeIn} />
        </div>

        {/* confetti to bản xoay tít khi mở huy hiệu */}
        <Confetti originXRatio={0.5} originYRatio={0.74} startFrame={130} count={110} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
