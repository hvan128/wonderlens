import { AbsoluteFill } from 'remotion';
import { COLORS, withAlpha } from '../theme';

/** Nền giấy ấm + chấm bi mờ, đúng tinh thần "giấy ấm" của app. */
export const BackgroundPaper = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(125% 80% at 50% 16%, ${COLORS.cream} 0%, ${COLORS.paper} 48%, ${COLORS.paperWarm} 100%)`,
    }}
  >
    <AbsoluteFill
      style={{
        backgroundImage: `radial-gradient(${withAlpha(COLORS.teal, 0.07)} 3px, transparent 3px)`,
        backgroundSize: '60px 60px',
        opacity: 0.8,
      }}
    />
  </AbsoluteFill>
);
