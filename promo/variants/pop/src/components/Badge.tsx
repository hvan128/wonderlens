import { useCurrentFrame } from 'remotion';
import { COLORS, POP, withAlpha, solidShadow } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconMedal, Burst } from './Icons';
import { MATERIAL_BADGE } from '../content';

/** Huy hiệu vật liệu pop — pill sticker + starburst vàng xoay phía sau. enter: 0..1 (spring). */
export const Badge = ({ enter }: { enter: number }) => {
  const frame = useCurrentFrame();
  const e = Math.min(1, Math.max(0, enter));
  return (
    <div
      style={{
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transform: `scale(${Math.max(0.001, 0.5 + enter * 0.5)}) rotate(${(1 - e) * -8}deg)`,
        opacity: e,
      }}
    >
      {/* starburst xoay phía sau */}
      <div
        style={{
          position: 'absolute',
          width: 520,
          height: 520,
          transform: `rotate(${frame * 0.7}deg)`,
        }}
      >
        <Burst size={520} color={withAlpha(COLORS.badgeGold, 0.6)} spikes={14} innerRatio={0.74} outline={false} />
      </div>
      <div
        style={{
          position: 'absolute',
          width: 380,
          height: 380,
          transform: `rotate(${-frame * 0.5}deg)`,
        }}
      >
        <Burst size={380} color={withAlpha('#FFFFFF', 0.5)} spikes={10} innerRatio={0.78} outline={false} />
      </div>

      {/* pill huy hiệu */}
      <div
        style={{
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          gap: 18,
          padding: '16px 36px 16px 20px',
          borderRadius: 999,
          background: '#FFFFFF',
          border: `5px solid ${POP.outline}`,
          boxShadow: solidShadow(9, 9, POP.outline),
          transform: 'rotate(-1.5deg)',
        }}
      >
        <IconMedal size={88} />
        <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.15 }}>
          <span style={{ fontFamily: BODY, fontWeight: 800, fontSize: 26, color: COLORS.inkSoft }}>
            Huy hiệu vật liệu
          </span>
          <span style={{ fontFamily: HEADING, fontWeight: 800, fontSize: 48, color: COLORS.badgeGoldDark }}>
            {MATERIAL_BADGE}
          </span>
        </div>
      </div>
    </div>
  );
};
