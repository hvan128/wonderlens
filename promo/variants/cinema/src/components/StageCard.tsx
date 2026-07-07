import { Img, staticFile } from 'remotion';
import { COLORS, withAlpha, RADIUS } from '../theme';
import { HEADING } from '../fonts';
import { StageGlyph } from './Icons';
import type { Stage } from '../content';

/** Một chặng trong "hành trình": ảnh minh hoạ AI + tiêu đề. enter: 0..1 trượt vào + hiện. */
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
      gap: 34,
      width: 860,
      padding: '26px 38px',
      borderRadius: RADIUS.card,
      background: 'linear-gradient(170deg, #FFFCF3 0%, #FFF3DC 100%)',
      boxShadow: `0 0 ${enter * 46}px ${withAlpha('#FFC46B', 0.4 * enter)}, 0 18px 40px ${withAlpha('#140A22', 0.45)}`,
      border: `2px solid ${withAlpha(stage.accent, 0.5)}`,
      transform: `translateX(${(1 - enter) * 90}px) scale(${0.94 + enter * 0.06})`,
      opacity: enter,
    }}
  >
    <div style={{ position: 'relative', width: 220, height: 220, flexShrink: 0 }}>
      {/* khung ảnh minh hoạ (bo góc) */}
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: 36,
          overflow: 'hidden',
          background: withAlpha(stage.accent, 0.16),
          border: `3px solid ${withAlpha(stage.accent, 0.55)}`,
          boxShadow: `0 8px 18px ${withAlpha(stage.accent, 0.3)}`,
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
          <StageGlyph icon={stage.icon} size={92} />
        )}
      </div>
      {/* số thứ tự chặng */}
      <div
        style={{
          position: 'absolute',
          top: -12,
          left: -12,
          width: 56,
          height: 56,
          borderRadius: '50%',
          background: stage.accent,
          color: '#FFFFFF',
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 32,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: `0 6px 14px ${withAlpha(stage.accent, 0.5)}`,
          border: '3px solid #FFFFFF',
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
