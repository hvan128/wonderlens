import { Img, staticFile } from 'remotion';
import { COLORS, withAlpha, RADIUS } from '../theme';
import { HEADING } from '../fonts';
import { StageGlyph } from './Icons';
import { glassFill, glassBorder, glassShadow, glassBlur, Specular } from './Glass';
import type { Stage } from '../content';

/** Một chặng trong "hành trình": thẻ kính + ảnh minh hoạ AI + tiêu đề. enter: 0..1. */
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
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      gap: 34,
      width: 860,
      padding: '26px 38px',
      borderRadius: RADIUS.card,
      background: glassFill(0.13),
      border: glassBorder(0.4),
      boxShadow: `${glassShadow(0.4)}, 0 0 46px ${withAlpha(stage.accent, 0.18)}`,
      ...glassBlur(20),
      transform: `translateX(${(1 - enter) * 90}px) scale(${0.94 + enter * 0.06})`,
      opacity: enter,
    }}
  >
    <Specular radius={RADIUS.card} strength={0.24} />
    <div style={{ position: 'relative', width: 220, height: 220, flexShrink: 0 }}>
      {/* khung ảnh minh hoạ (bo góc, viền kính + glow accent) */}
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: 36,
          overflow: 'hidden',
          background: withAlpha(stage.accent, 0.28),
          border: `2px solid ${withAlpha('#FFFFFF', 0.5)}`,
          boxShadow: `0 10px 26px ${withAlpha('#02222B', 0.4)}, 0 0 24px ${withAlpha(stage.accent, 0.35)}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {stage.image ? (
          <Img
            src={staticFile(stage.image)}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              filter: 'saturate(1.12)',
            }}
          />
        ) : (
          <StageGlyph icon={stage.icon} size={92} />
        )}
      </div>
      {/* số thứ tự chặng — nút kính màu accent phát sáng */}
      <div
        style={{
          position: 'absolute',
          top: -12,
          left: -12,
          width: 56,
          height: 56,
          borderRadius: '50%',
          background: `linear-gradient(150deg, ${withAlpha('#FFFFFF', 0.45)} 0%, ${stage.accent} 45%)`,
          color: '#FFFFFF',
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 32,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: `0 6px 16px ${withAlpha('#02222B', 0.45)}, 0 0 20px ${withAlpha(stage.accent, 0.65)}`,
          border: `2px solid ${withAlpha('#FFFFFF', 0.85)}`,
          textShadow: `0 1px 2px ${withAlpha('#02222B', 0.35)}`,
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
        color: '#FFFFFF',
        lineHeight: 1.15,
        textShadow: `0 2px 10px ${withAlpha('#02222B', 0.45)}`,
      }}
    >
      {stage.title}
    </span>
  </div>
);
