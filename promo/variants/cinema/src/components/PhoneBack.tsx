import { COLORS, withAlpha } from '../theme';
import { LogoMark } from './Icons';

/** Mặt lưng điện thoại: cụm camera sau (hướng vào cốc) + đèn flash. */
export const PhoneBack = ({
  width,
  height,
  flash = 0,
}: {
  width: number;
  height: number;
  flash?: number;
}) => {
  const radius = width * 0.17;
  const inset = width * 0.06;
  const mod = width * 0.34;
  const lens = mod * 0.34;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        background: 'linear-gradient(150deg, #1B3A43 0%, #0C2026 70%)',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: `0 40px 70px ${withAlpha('#0A2A30', 0.4)}, inset 0 0 0 2px ${withAlpha('#FFFFFF', 0.05)}`,
      }}
    >
      {/* ánh kim loại chéo */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `linear-gradient(115deg, transparent 40%, ${withAlpha('#FFFFFF', 0.06)} 50%, transparent 60%)`,
        }}
      />

      {/* cụm camera sau (góc trên, hướng về cốc) */}
      <div
        style={{
          position: 'absolute',
          top: inset,
          right: inset,
          width: mod,
          height: mod,
          borderRadius: mod * 0.28,
          background: 'linear-gradient(160deg, #16323A, #060E11)',
          boxShadow: `inset 0 0 0 2px ${withAlpha('#FFFFFF', 0.06)}`,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          placeItems: 'center',
          padding: mod * 0.12,
          boxSizing: 'border-box',
          gap: mod * 0.08,
        }}
      >
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              width: lens,
              height: lens,
              borderRadius: '50%',
              background: 'radial-gradient(circle at 35% 30%, #2C4A52 0%, #060B0D 70%)',
              boxShadow: `inset 0 0 0 2px ${withAlpha(COLORS.teal, 0.35)}`,
            }}
          />
        ))}
        {/* đèn flash (loé khi chụp) */}
        <div
          style={{
            width: lens * 0.6,
            height: lens * 0.6,
            borderRadius: '50%',
            background: '#FFF4CC',
            boxShadow: `0 0 ${10 + flash * 26}px ${4 + flash * 12}px ${withAlpha('#FFE7A0', 0.3 + flash * 0.7)}`,
            opacity: 0.5 + flash * 0.5,
          }}
        />
      </div>

      {/* logo giữa lưng máy */}
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: '50%',
          transform: 'translateY(-50%)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: width * 0.04,
          opacity: 0.92,
        }}
      >
        <LogoMark size={width * 0.34} />
      </div>
    </div>
  );
};
