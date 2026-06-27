import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconMedal } from './Icons';
import { MATERIAL_BADGE } from '../content';

/** Huy hiệu vật liệu — "Vật liệu: Giấy". enter: 0..1 điều khiển bung. */
export const Badge = ({ enter }: { enter: number }) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 18,
      padding: '16px 34px 16px 18px',
      borderRadius: 999,
      background: '#FFFFFF',
      boxShadow: `0 20px 40px ${withAlpha(COLORS.badgeGoldDark, 0.3)}`,
      border: `3px solid ${withAlpha(COLORS.badgeGold, 0.55)}`,
      transform: `scale(${0.6 + enter * 0.4})`,
      opacity: enter,
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
  </div>
);
