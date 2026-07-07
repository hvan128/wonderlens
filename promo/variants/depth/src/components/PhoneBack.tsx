import { COLORS, withAlpha } from '../theme';
import { LogoMark } from './Icons';

/** Mặt lưng điện thoại — bản "depth": kim loại bóng, ống kính có specular, flash bùng glow. */
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
        background: 'linear-gradient(150deg, #234750 0%, #142F37 45%, #0A1C21 100%)',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: [
          `0 44px 70px ${withAlpha('#0A2A30', 0.45)}`,
          `0 10px 22px ${withAlpha('#0A2A30', 0.3)}`,
          `inset 0 2px 2px ${withAlpha('#FFFFFF', 0.16)}`,
          `inset 0 0 0 2px ${withAlpha('#FFFFFF', 0.05)}`,
        ].join(', '),
      }}
    >
      {/* ánh kim loại chéo (2 dải) */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `linear-gradient(115deg, transparent 34%, ${withAlpha('#FFFFFF', 0.1)} 44%, transparent 54%, transparent 62%, ${withAlpha('#FFFFFF', 0.04)} 70%, transparent 78%)`,
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
          background: 'linear-gradient(160deg, #1B3A43, #050C0F)',
          boxShadow: `inset 0 1px 1px ${withAlpha('#FFFFFF', 0.14)}, inset 0 0 0 2px ${withAlpha('#FFFFFF', 0.06)}, 0 6px 12px ${withAlpha('#000000', 0.4)}`,
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
              background: 'radial-gradient(circle at 33% 28%, #3D5F68 0%, #12242A 45%, #04080A 75%)',
              boxShadow: `inset 0 0 0 2px ${withAlpha(COLORS.teal, 0.35)}, inset 0 -2px 4px ${withAlpha('#000000', 0.6)}`,
              position: 'relative',
            }}
          >
            {/* specular nhỏ trên tròng kính */}
            <div
              style={{
                position: 'absolute',
                top: '18%',
                left: '22%',
                width: '26%',
                height: '26%',
                borderRadius: '50%',
                background: withAlpha('#BFEFF8', 0.65),
                filter: 'blur(1px)',
              }}
            />
          </div>
        ))}
        {/* đèn flash (loé khi chụp) */}
        <div
          style={{
            width: lens * 0.6,
            height: lens * 0.6,
            borderRadius: '50%',
            background: `radial-gradient(circle at 40% 35%, #FFFFFF 0%, #FFF4CC 60%, #F0DA9C 100%)`,
            boxShadow: `0 0 ${10 + flash * 40}px ${4 + flash * 20}px ${withAlpha('#FFE7A0', 0.3 + flash * 0.7)}`,
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
