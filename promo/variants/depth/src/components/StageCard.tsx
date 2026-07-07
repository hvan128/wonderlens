import { Img, staticFile } from 'remotion';
import { COLORS, withAlpha, RADIUS } from '../theme';
import { HEADING } from '../fonts';
import { StageGlyph } from './Icons';
import type { Stage } from '../content';

/**
 * Một chặng trong "hành trình" — bản "depth": thẻ giấy ấm có khối,
 * bóng đổ mềm 2 lớp, ảnh minh hoạ có inner-shadow, số chặng ánh bóng.
 * enter: 0..1 trượt vào + hiện (cho phép overshoot nhẹ từ spring).
 */
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
      background: 'linear-gradient(168deg, #FFFFFF 0%, #FFFDF6 55%, #FAF2E1 100%)',
      boxShadow: [
        `0 26px 50px ${withAlpha(COLORS.ink, 0.16)}`,
        `0 6px 14px ${withAlpha(COLORS.ink, 0.08)}`,
        `0 0 34px ${withAlpha(stage.accent, 0.14)}`,
        `inset 0 2px 0 ${withAlpha('#FFFFFF', 0.95)}`,
      ].join(', '),
      border: `2px solid ${withAlpha(stage.accent, 0.35)}`,
      transform: `translateX(${(1 - enter) * 90}px) scale(${0.94 + enter * 0.06})`,
      opacity: Math.min(1, Math.max(0, enter)),
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
          background: `radial-gradient(120% 120% at 30% 22%, ${withAlpha('#FFFFFF', 0.9)} 0%, ${withAlpha(stage.accent, 0.2)} 100%)`,
          border: `3px solid ${withAlpha(stage.accent, 0.55)}`,
          boxShadow: `0 12px 24px ${withAlpha(stage.accent, 0.32)}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          position: 'relative',
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
        {/* inner shadow + ánh sáng trên cho ảnh có khối */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            borderRadius: 33,
            boxShadow: `inset 0 -14px 24px ${withAlpha('#3A2A10', 0.22)}, inset 0 10px 18px ${withAlpha('#FFFFFF', 0.22)}`,
            pointerEvents: 'none',
          }}
        />
      </div>
      {/* số thứ tự chặng — nút bóng 3D */}
      <div
        style={{
          position: 'absolute',
          top: -12,
          left: -12,
          width: 56,
          height: 56,
          borderRadius: '50%',
          backgroundColor: stage.accent,
          backgroundImage: `radial-gradient(circle at 32% 26%, ${withAlpha('#FFFFFF', 0.55)} 0%, transparent 55%), linear-gradient(160deg, transparent 40%, ${withAlpha('#1F2A08', 0.25)} 100%)`,
          color: '#FFFFFF',
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 32,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: `0 8px 16px ${withAlpha(stage.accent, 0.55)}`,
          border: '3px solid #FFFFFF',
          textShadow: `0 2px 3px ${withAlpha('#000000', 0.25)}`,
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
        textShadow: `0 1px 0 ${withAlpha('#FFFFFF', 0.8)}`,
      }}
    >
      {stage.title}
    </span>
  </div>
);
