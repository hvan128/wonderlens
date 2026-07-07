import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { BackgroundPaper } from '../components/BackgroundPaper';
import { StageCard } from '../components/StageCard';
import { Confetti } from '../components/Confetti';
import { Badge } from '../components/Badge';
import { IconCup } from '../components/Icons';
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

/** Cảnh D — bản "depth": thẻ nảy spring, spine phát sáng, header có khối. */
export const TimelineScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneOpacity = ease(frame, 0, 20);
  const sceneScale = interpolate(frame, [0, 28], [1.06, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const headerIn = spring({ frame: frame - 6, fps, config: { damping: 13, mass: 0.7 }, durationInFrames: 26 });
  const badgeIn = spring({ frame: frame - 132, fps, config: { damping: 10, mass: 0.7 }, durationInFrames: 26 });
  const spineGrow = ease(frame, 26, 120);

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity }}>
      <AbsoluteFill style={{ transform: `scale(${sceneScale})` }}>
        <BackgroundPaper />

        {/* header */}
        <div
          style={{
            position: 'absolute',
            top: 150,
            left: 0,
            right: 0,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 6,
            opacity: Math.min(1, headerIn),
            transform: `translateY(${(1 - headerIn) * -24}px)`,
          }}
        >
          <span
            style={{
              fontFamily: BODY,
              fontWeight: 800,
              fontSize: 30,
              letterSpacing: 4,
              color: COLORS.inkSoft,
              textShadow: `0 1px 0 ${withAlpha('#FFFFFF', 0.9)}`,
            }}
          >
            HÀNH TRÌNH TẠO RA
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ filter: `drop-shadow(0 6px 10px ${withAlpha(COLORS.ink, 0.18)})` }}>
              <IconCup size={74} />
            </div>
            <span
              style={{
                fontFamily: HEADING,
                fontWeight: 800,
                fontSize: 86,
                color: COLORS.tealDark,
                textShadow: `0 2px 0 ${withAlpha('#FFFFFF', 0.85)}, 0 12px 26px ${withAlpha(COLORS.teal, 0.3)}`,
              }}
            >
              {OBJECT_NAME}
            </span>
          </div>
        </div>

        {/* đường timeline (spine) — gradient sáng dần + glow teal */}
        <div
          style={{
            position: 'absolute',
            left: SPINE_X - 4,
            top: CARD_TOP + 134,
            width: 8,
            height: (3 * CARD_GAP) * spineGrow,
            borderRadius: 4,
            background: `linear-gradient(180deg, ${withAlpha(COLORS.teal, 0.7)} 0%, ${withAlpha(COLORS.teal, 0.35)} 100%)`,
            boxShadow: `0 0 18px ${withAlpha(COLORS.teal, 0.45)}`,
          }}
        />
        {/* đốm sáng chạy dọc spine khi đang mọc */}
        <div
          style={{
            position: 'absolute',
            left: SPINE_X - 11,
            top: CARD_TOP + 134 + (3 * CARD_GAP) * spineGrow - 11,
            width: 22,
            height: 22,
            borderRadius: '50%',
            background: `radial-gradient(circle, #C9F6FC 0%, ${COLORS.teal} 55%, transparent 75%)`,
            boxShadow: `0 0 20px 6px ${withAlpha(COLORS.teal, 0.5)}`,
            opacity: spineGrow > 0.02 && spineGrow < 0.995 ? 1 : 0,
          }}
        />

        {/* 4 thẻ chặng — vào bằng spring cho độ nảy tự nhiên */}
        {CUP_STAGES.map((stage, i) => {
          const start = 26 + i * 22;
          const enter = spring({
            frame: frame - start,
            fps,
            config: { damping: 13, mass: 0.6 },
            durationInFrames: 24,
          });
          return (
            <div
              key={stage.icon}
              style={{ position: 'absolute', left: CARD_LEFT, top: CARD_TOP + i * CARD_GAP }}
            >
              <StageCard stage={stage} index={i} enter={enter} />
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

        {/* confetti khi mở huy hiệu */}
        <Confetti originXRatio={0.5} originYRatio={0.74} startFrame={130} count={90} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
