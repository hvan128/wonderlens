import { AbsoluteFill, useCurrentFrame } from 'remotion';

/**
 * Lớp "grade" điện ảnh phủ trên cùng mọi cảnh:
 *  - vignette đậm 4 góc (tối dần ra mép)
 *  - grain phim nhẹ (feTurbulence, seed đổi theo frame — tất định)
 * Không đụng nội dung cảnh, chỉ overlay.
 */
export const CinematicGrade = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ pointerEvents: 'none' }}>
      {/* vignette */}
      <AbsoluteFill
        style={{
          background:
            'radial-gradient(120% 86% at 50% 46%, transparent 52%, rgba(2, 9, 14, 0.34) 82%, rgba(1, 6, 10, 0.62) 100%)',
        }}
      />
      {/* ánh viền lạnh nhẹ phía trên — cảm giác ống kính anamorphic */}
      <AbsoluteFill
        style={{
          background:
            'linear-gradient(180deg, rgba(3, 12, 18, 0.30) 0%, transparent 12%, transparent 90%, rgba(2, 8, 12, 0.30) 100%)',
        }}
      />
      {/* grain phim nhẹ */}
      <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0 }}>
        <filter id="cine-grain">
          <feTurbulence
            type="fractalNoise"
            baseFrequency="0.82"
            numOctaves={2}
            seed={frame % 47}
            stitchTiles="stitch"
          />
          {/* đổi noise màu thành hạt trắng mờ (chỉ giữ alpha thấp) */}
          <feColorMatrix
            type="matrix"
            values="0 0 0 0 0.92  0 0 0 0 0.95  0 0 0 0 1  0 0 0 0.055 0"
          />
        </filter>
        <rect width="100%" height="100%" filter="url(#cine-grain)" />
      </svg>
    </AbsoluteFill>
  );
};
