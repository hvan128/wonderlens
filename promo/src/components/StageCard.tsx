import { COLORS, withAlpha, RADIUS } from '../theme';
import { HEADING } from '../fonts';
import { StageGlyph } from './Icons';
import type { Stage } from '../content';

/** Một chặng trong "hành trình". enter: 0..1 trượt vào + hiện. */
export const StageCard = ({
  stage,
  index,
  enter,
}: {
  stage: Stage;
  index: number;
  enter: number;
}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 30,
      width: 820,
      padding: '26px 36px',
      borderRadius: RADIUS.card,
      background: '#FFFFFF',
      boxShadow: `0 16px 34px ${withAlpha(COLORS.ink, 0.12)}`,
      border: `2px solid ${withAlpha(stage.accent, 0.35)}`,
      transform: `translateX(${(1 - enter) * 90}px) scale(${0.94 + enter * 0.06})`,
      opacity: enter,
    }}
  >
    <div
      style={{
        position: 'relative',
        width: 118,
        height: 118,
        borderRadius: '50%',
        background: withAlpha(stage.accent, 0.16),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}
    >
      <StageGlyph icon={stage.icon} size={92} />
      <div
        style={{
          position: 'absolute',
          top: -8,
          left: -8,
          width: 44,
          height: 44,
          borderRadius: '50%',
          background: stage.accent,
          color: '#FFFFFF',
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 26,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: `0 6px 14px ${withAlpha(stage.accent, 0.5)}`,
        }}
      >
        {index + 1}
      </div>
    </div>
    <span
      style={{
        fontFamily: HEADING,
        fontWeight: 700,
        fontSize: 44,
        color: COLORS.ink,
        lineHeight: 1.15,
      }}
    >
      {stage.title}
    </span>
  </div>
);
