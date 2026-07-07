import { COLORS, POP, withAlpha, solidShadow } from '../theme';
import { LogoMark } from './Icons';

/** Mặt lưng điện thoại pop: viền ink sticker + cụm camera sau + đèn flash. */
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
  const outline = Math.max(4, Math.round(width * 0.022));
  const inset = width * 0.06;
  const mod = width * 0.34;
  const lens = mod * 0.34;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        background: 'linear-gradient(150deg, #1F5262 0%, #0F2C34 75%)',
        position: 'relative',
        overflow: 'hidden',
        boxSizing: 'border-box',
        border: `${outline}px solid ${POP.outline}`,
        boxShadow: solidShadow(Math.round(width * 0.04), Math.round(width * 0.045), withAlpha(POP.shadow, 0.4)),
      }}
    >
      {/* ánh sáng chéo comic */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `linear-gradient(115deg, transparent 38%, ${withAlpha('#FFFFFF', 0.12)} 48%, transparent 58%)`,
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
          background: 'linear-gradient(160deg, #173A44, #060E11)',
          border: `${Math.max(3, Math.round(width * 0.014))}px solid ${POP.outline}`,
          boxSizing: 'border-box',
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          placeItems: 'center',
          padding: mod * 0.1,
          gap: mod * 0.06,
        }}
      >
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              width: lens,
              height: lens,
              borderRadius: '50%',
              background: 'radial-gradient(circle at 35% 30%, #2C5560 0%, #060B0D 70%)',
              boxShadow: `inset 0 0 0 3px ${withAlpha(COLORS.teal, 0.6)}`,
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
        }}
      >
        <LogoMark size={width * 0.34} />
      </div>
    </div>
  );
};
