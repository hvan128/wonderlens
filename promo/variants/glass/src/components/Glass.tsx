import { withAlpha } from '../theme';

/**
 * Bộ recipe "liquid glass" đồng bộ GlassSurface của app:
 * nền trắng mờ 10–18% (fallback luôn hiển thị, không phụ thuộc backdrop-filter)
 * + viền trắng mờ 1–1.5px + specular highlight chéo góc trên + shadow mềm rộng.
 */

/** Nền kính: gradient trắng mờ — tự nó đã là fallback khi backdrop-filter yếu. */
export const glassFill = (alpha = 0.14) =>
  `linear-gradient(160deg, ${withAlpha('#FFFFFF', Math.min(alpha + 0.1, 0.4))} 0%, ${withAlpha(
    '#FFFFFF',
    alpha,
  )} 42%, ${withAlpha('#FFFFFF', Math.max(alpha - 0.06, 0.04))} 100%)`;

export const glassBorder = (alpha = 0.38, width = 1.5) =>
  `${width}px solid ${withAlpha('#FFFFFF', alpha)}`;

/** Shadow mềm rộng + nét sáng 1px mép trên (kiểu Apple). */
export const glassShadow = (depth = 0.42) =>
  `0 26px 60px ${withAlpha('#02222B', depth)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.4)}`;

export const glassBlur = (px = 20) => ({
  backdropFilter: `blur(${px}px) saturate(1.3)`,
  WebkitBackdropFilter: `blur(${px}px) saturate(1.3)`,
});

/** Specular highlight chéo góc trên — đặt làm con đầu tiên của panel (position:relative). */
export const Specular = ({
  radius,
  strength = 0.3,
}: {
  radius: number | string;
  strength?: number;
}) => (
  <div
    style={{
      position: 'absolute',
      inset: 0,
      borderRadius: radius,
      pointerEvents: 'none',
      background: `linear-gradient(118deg, ${withAlpha('#FFFFFF', strength)} 0%, ${withAlpha(
        '#FFFFFF',
        strength * 0.28,
      )} 26%, transparent 52%)`,
    }}
  />
);
