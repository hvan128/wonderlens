import { AbsoluteFill } from 'remotion';
import { POP, withAlpha } from '../theme';

/** Nền pop: vàng kem bão hoà + chấm halftone cam + sọc chéo trắng mờ. */
export const BackgroundPaper = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(130% 90% at 50% 12%, ${POP.bgYellowLight} 0%, ${POP.bgYellow} 55%, ${POP.bgYellowDeep} 100%)`,
    }}
  >
    {/* lưới halftone chính */}
    <AbsoluteFill
      style={{
        backgroundImage: `radial-gradient(${withAlpha(POP.bgDot, 0.4)} 7px, transparent 7px)`,
        backgroundSize: '92px 92px',
      }}
    />
    {/* lưới halftone phụ (lệch nửa ô, chấm nhỏ) */}
    <AbsoluteFill
      style={{
        backgroundImage: `radial-gradient(${withAlpha(POP.bgDot, 0.28)} 4px, transparent 4px)`,
        backgroundSize: '92px 92px',
        backgroundPosition: '46px 46px',
      }}
    />
    {/* sọc chéo trắng rất mờ */}
    <AbsoluteFill
      style={{
        backgroundImage: `repeating-linear-gradient(-24deg, ${withAlpha('#FFFFFF', 0.1)} 0 26px, transparent 26px 104px)`,
      }}
    />
  </AbsoluteFill>
);
