import { Img, staticFile } from 'remotion';
import { COLORS, POP, withAlpha, RADIUS, solidShadow } from '../theme';
import { HEADING } from '../fonts';
import { StageGlyph, Burst } from './Icons';
import type { Stage } from '../content';

/**
 * Một chặng trong "hành trình" — bản pop: thẻ sticker viền ink đậm, bóng đặc
 * lệch, nghiêng nhẹ xen kẽ, số thứ tự nằm trong starburst.
 * enter: 0..1 (spring, có overshoot). wiggle: độ nghiêng phụ theo frame.
 */
export const StageCard = ({
  stage,
  index,
  enter,
  wiggle = 0,
}: {
  stage: Stage;
  index: number;
  enter: number;
  wiggle?: number;
}) => {
  const tilt = (index % 2 === 0 ? -1.6 : 1.5) + wiggle;
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 32,
        width: 860,
        padding: '26px 34px',
        borderRadius: RADIUS.card,
        background: '#FFFFFF',
        border: `5px solid ${POP.outline}`,
        boxShadow: solidShadow(12, 12, POP.outline),
        transform: `translateX(${(1 - enter) * 160}px) rotate(${tilt}deg) scale(${0.85 + enter * 0.15})`,
        opacity: Math.min(1, Math.max(0, enter)),
      }}
    >
      <div style={{ position: 'relative', width: 220, height: 220, flexShrink: 0 }}>
        {/* khung ảnh minh hoạ (bo góc, viền ink) */}
        <div
          style={{
            width: '100%',
            height: '100%',
            borderRadius: 30,
            overflow: 'hidden',
            background: withAlpha(stage.accent, 0.2),
            border: `4px solid ${POP.outline}`,
            boxSizing: 'border-box',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {stage.image ? (
            <Img
              src={staticFile(stage.image)}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          ) : (
            <StageGlyph icon={stage.icon} size={110} />
          )}
        </div>
        {/* số thứ tự chặng trong starburst */}
        <div
          style={{
            position: 'absolute',
            top: -24,
            left: -24,
            width: 84,
            height: 84,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <div style={{ position: 'absolute', inset: 0 }}>
            <Burst size={84} color={stage.accent} spikes={8} innerRatio={0.7} />
          </div>
          <span
            style={{
              position: 'relative',
              fontFamily: HEADING,
              fontWeight: 800,
              fontSize: 36,
              color: '#FFFFFF',
              textShadow: `2px 2px 0 ${POP.outline}`,
            }}
          >
            {index + 1}
          </span>
        </div>
      </div>
      <span
        style={{
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 44,
          color: COLORS.ink,
          lineHeight: 1.15,
        }}
      >
        {stage.title}
      </span>
    </div>
  );
};
