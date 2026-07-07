import type { ReactNode } from 'react';
import { COLORS, POP, withAlpha, solidShadow } from '../theme';

/** Khung điện thoại pop: viền ink đậm + bóng đặc lệch (children = nội dung màn hình). */
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
  const outline = Math.max(4, Math.round(width * 0.022));
  const deviceRadius = width * 0.17;
  const screenRadius = deviceRadius - bezel - outline * 0.5;
  return (
    <div
      style={{
        width,
        height,
        borderRadius: deviceRadius,
        background: 'linear-gradient(150deg, #1D4C5A 0%, #0F2C34 100%)',
        padding: bezel,
        boxSizing: 'border-box',
        position: 'relative',
        border: `${outline}px solid ${POP.outline}`,
        boxShadow: solidShadow(Math.round(width * 0.04), Math.round(width * 0.045), withAlpha(POP.shadow, 0.4)),
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
          boxShadow: `inset 0 0 0 3px ${withAlpha(POP.outline, 0.9)}`,
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
          width: width * 0.04,
          height: width * 0.04,
          borderRadius: '50%',
          background: '#04090B',
          boxShadow: `inset 0 0 0 2px ${withAlpha(COLORS.teal, 0.7)}`,
        }}
      />
    </div>
  );
};
