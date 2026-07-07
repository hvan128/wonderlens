import type { ReactNode } from 'react';
import { COLORS, withAlpha } from '../theme';

/** Khung điện thoại + khe màn hình — bản "depth": viền kim loại có ánh sáng. */
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
        background: 'linear-gradient(150deg, #1D3E48 0%, #122B32 45%, #0A1B20 100%)',
        padding: bezel,
        boxSizing: 'border-box',
        position: 'relative',
        boxShadow: [
          `0 44px 70px ${withAlpha('#0A2A30', 0.45)}`,
          `0 10px 22px ${withAlpha('#0A2A30', 0.3)}`,
          `inset 0 2px 2px ${withAlpha('#FFFFFF', 0.18)}`,
          `inset 0 0 0 2px ${withAlpha('#FFFFFF', 0.06)}`,
        ].join(', '),
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
          boxShadow: `inset 0 0 18px ${withAlpha('#000000', 0.55)}`,
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
