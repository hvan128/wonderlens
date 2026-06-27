import type { ReactNode } from 'react';
import { COLORS, withAlpha } from '../theme';

/** Khung điện thoại + khe màn hình (children = nội dung màn hình). */
export const Phone = ({
  width,
  height,
  children,
}: {
  width: number;
  height: number;
  children: ReactNode;
}) => {
  const bezel = Math.round(width * 0.05);
  const deviceRadius = width * 0.17;
  const screenRadius = deviceRadius - bezel;
  return (
    <div
      style={{
        width,
        height,
        borderRadius: deviceRadius,
        background: 'linear-gradient(150deg, #16323A 0%, #0C2026 100%)',
        padding: bezel,
        boxSizing: 'border-box',
        position: 'relative',
        boxShadow: `0 40px 70px ${withAlpha('#0A2A30', 0.4)}, inset 0 0 0 2px ${withAlpha('#FFFFFF', 0.06)}`,
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: screenRadius,
          overflow: 'hidden',
          position: 'relative',
          background: '#0A1417',
        }}
      >
        {children}
      </div>
      {/* chấm camera trước */}
      <div
        style={{
          position: 'absolute',
          top: bezel + width * 0.04,
          left: '50%',
          transform: 'translateX(-50%)',
          width: width * 0.035,
          height: width * 0.035,
          borderRadius: '50%',
          background: '#04090B',
          boxShadow: `inset 0 0 0 2px ${withAlpha(COLORS.teal, 0.5)}`,
        }}
      />
    </div>
  );
};
