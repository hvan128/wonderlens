import { AbsoluteFill, useCurrentFrame, interpolate, Easing } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { BackgroundPaper } from '../components/BackgroundPaper';
import { StageCard } from '../components/StageCard';
import { Confetti } from '../components/Confetti';
import { Badge } from '../components/Badge';
import { IconCup } from '../components/Icons';
import { CUP_STAGES, OBJECT_NAME } from '../content';

const CARD_TOP = 392;
const CARD_GAP = 188;
const SPINE_X = 225;

const ease = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

/** Cảnh D: bên trong app — hành trình tạo ra cốc giấy + huy hiệu. */
export const TimelineScene = () => {
  const frame = useCurrentFrame();

  const sceneOpacity = ease(frame, 0, 20);
  const sceneScale = interpolate(frame, [0, 28], [1.06, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const headerIn = ease(frame, 6, 28);
  const badgeIn = ease(frame, 132, 152);
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
            opacity: headerIn,
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
            }}
          >
            HÀNH TRÌNH TẠO RA
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <IconCup size={74} />
            <span style={{ fontFamily: HEADING, fontWeight: 800, fontSize: 86, color: COLORS.tealDark }}>
              {OBJECT_NAME}
            </span>
          </div>
        </div>

        {/* đường timeline (spine) */}
        <div
          style={{
            position: 'absolute',
            left: SPINE_X - 4,
            top: CARD_TOP + 88,
            width: 8,
            height: (3 * CARD_GAP) * spineGrow,
            borderRadius: 4,
            background: withAlpha(COLORS.teal, 0.4),
          }}
        />

        {/* 4 thẻ chặng */}
        {CUP_STAGES.map((stage, i) => {
          const start = 26 + i * 22;
          const enter = ease(frame, start, start + 18);
          return (
            <div
              key={stage.icon}
              style={{ position: 'absolute', left: 130, top: CARD_TOP + i * CARD_GAP }}
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
            top: 1230,
            display: 'flex',
            justifyContent: 'center',
          }}
        >
          <Badge enter={badgeIn} />
        </div>

        {/* confetti khi mở huy hiệu */}
        <Confetti originXRatio={0.5} originYRatio={0.62} startFrame={130} count={90} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
