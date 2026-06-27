import type { ReactNode } from 'react';
import { Phone } from './Phone';
import { PhoneBack } from './PhoneBack';

/**
 * Điện thoại lật được: flipDeg 0 = thấy LƯNG (cam sau hướng vào cốc),
 * flipDeg 180 = lật lại thấy MÀN HÌNH.
 */
export const FlipPhone = ({
  width,
  height,
  flipDeg,
  flash = 0,
  children,
}: {
  width: number;
  height: number;
  flipDeg: number;
  flash?: number;
  children: ReactNode;
}) => (
  <div style={{ width, height, perspective: width * 6 }}>
    <div
      style={{
        position: 'relative',
        width,
        height,
        transformStyle: 'preserve-3d',
        transform: `rotateY(${flipDeg}deg)`,
      }}
    >
      {/* mặt lưng (mặc định) */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backfaceVisibility: 'hidden',
          WebkitBackfaceVisibility: 'hidden',
        }}
      >
        <PhoneBack width={width} height={height} flash={flash} />
      </div>
      {/* mặt màn hình (hiện khi lật) */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backfaceVisibility: 'hidden',
          WebkitBackfaceVisibility: 'hidden',
          transform: 'rotateY(180deg)',
        }}
      >
        <Phone width={width} height={height}>
          {children}
        </Phone>
      </div>
    </div>
  </div>
);
