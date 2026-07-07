import { useCurrentFrame, interpolate } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconMedal } from './Icons';
import { MATERIAL_BADGE } from '../content';

/**
 * Huy hiệu vật liệu — bản "depth": viền vàng kim loại gradient,
 * lóe sáng sweep chạy qua định kỳ, glow vàng ấm. enter: 0..1 điều khiển bung.
 */
export const Badge = ({ enter }: { enter: number }) => {
  const frame = useCurrentFrame();
  // vệt lóe kim loại chạy qua pill mỗi ~2.8s (tất định theo frame)
  const sweepX = interpolate(frame % 84, [10, 44], [-140, 560], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <div
      style={{
        padding: 5,
        borderRadius: 999,
        background: `linear-gradient(120deg, #FFE9A8 0%, ${COLORS.badgeGold} 40%, #C9820E 75%, #FFDF8E 100%)`,
        boxShadow: `0 22px 44px ${withAlpha(COLORS.badgeGoldDark, 0.35)}, 0 0 46px ${withAlpha(COLORS.badgeGold, 0.4)}`,
        transform: `scale(${0.6 + enter * 0.4})`,
        opacity: Math.min(1, Math.max(0, enter)),
      }}
    >
      <div
        style={{
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          gap: 18,
          padding: '14px 32px 14px 16px',
          borderRadius: 999,
          background: 'linear-gradient(180deg, #FFFFFF 0%, #FFF6E0 100%)',
        }}
      >
        <IconMedal size={84} />
        <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.15 }}>
          <span style={{ fontFamily: BODY, fontWeight: 700, fontSize: 26, color: COLORS.inkSoft }}>
            Huy hiệu vật liệu
          </span>
          <span style={{ fontFamily: HEADING, fontWeight: 800, fontSize: 46, color: COLORS.badgeGoldDark }}>
            {MATERIAL_BADGE}
          </span>
        </div>
        {/* lóe sáng sweep kim loại */}
        <div
          style={{
            position: 'absolute',
            top: -30,
            bottom: -30,
            left: 0,
            width: 90,
            transform: `translateX(${sweepX}px) rotate(16deg)`,
            background: `linear-gradient(90deg, transparent 0%, ${withAlpha('#FFFFFF', 0.75)} 50%, transparent 100%)`,
            pointerEvents: 'none',
          }}
        />
      </div>
    </div>
  );
};
