import type { ReactNode } from 'react';
import { COLORS, withAlpha } from '../theme';

/** Khung điện thoại kính + khe màn hình (children = nội dung màn hình). */
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
        background: `linear-gradient(150deg, ${withAlpha('#2A5A66', 0.96)} 0%, #123037 55%, #0A2026 100%)`,
        padding: bezel,
        boxSizing: 'border-box',
        position: 'relative',
        border: `1.5px solid ${withAlpha('#FFFFFF', 0.35)}`,
        boxShadow: `0 22px 40px ${withAlpha('#02222B', 0.35)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.35)}, 0 0 44px ${withAlpha(COLORS.teal, 0.22)}`,
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
          boxShadow: `inset 0 0 0 1px ${withAlpha('#FFFFFF', 0.12)}`,
        }}
      >
        {children}
        {/* ánh kính phản chiếu chéo trên mặt màn hình */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            borderRadius: screenRadius,
            pointerEvents: 'none',
            background: `linear-gradient(118deg, ${withAlpha('#FFFFFF', 0.14)} 0%, ${withAlpha('#FFFFFF', 0.03)} 24%, transparent 42%)`,
          }}
        />
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
