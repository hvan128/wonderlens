import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconMedal } from './Icons';
import { glassBorder, glassBlur, Specular } from './Glass';
import { MATERIAL_BADGE } from '../content';

/** Huy hiệu vật liệu — kính vàng mờ phát sáng. enter: 0..1 điều khiển bung. */
export const Badge = ({ enter }: { enter: number }) => (
  <div
    style={{
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      gap: 18,
      padding: '16px 34px 16px 18px',
      borderRadius: 999,
      background: `linear-gradient(160deg, ${withAlpha('#FFE9B8', 0.34)} 0%, ${withAlpha(
        COLORS.badgeGold,
        0.22,
      )} 55%, ${withAlpha(COLORS.badgeGoldDark, 0.18)} 100%)`,
      border: glassBorder(0.55),
      boxShadow: `0 22px 48px ${withAlpha('#02222B', 0.45)}, 0 0 60px ${withAlpha(
        COLORS.badgeGold,
        0.5,
      )}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.5)}`,
      ...glassBlur(18),
      transform: `scale(${0.6 + enter * 0.4})`,
      opacity: enter,
    }}
  >
    <Specular radius={999} strength={0.3} />
    <div style={{ filter: `drop-shadow(0 0 14px ${withAlpha(COLORS.badgeGold, 0.7)})` }}>
      <IconMedal size={84} />
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.15 }}>
      <span style={{ fontFamily: BODY, fontWeight: 700, fontSize: 26, color: withAlpha('#FFF6DF', 0.9) }}>
        Huy hiệu vật liệu
      </span>
      <span
        style={{
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 46,
          color: '#FFDE8A',
          textShadow: `0 2px 10px ${withAlpha('#02222B', 0.4)}`,
        }}
      >
        {MATERIAL_BADGE}
      </span>
    </div>
  </div>
);
