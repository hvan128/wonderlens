import { COLORS, withAlpha } from '../theme';
import { LogoMark } from './Icons';

/** Vòng lens kiểu Apple: viền kim loại + khắc vạch + thấu kính lồi có highlight. */
const LensRing = ({ size }: { size: number }) => {
  const ticks = Array.from({ length: 24 }).map((_, i) => {
    const a = (i / 24) * Math.PI * 2;
    const r1 = 44;
    const r2 = 48;
    return (
      <line
        key={i}
        x1={50 + Math.cos(a) * r1}
        y1={50 + Math.sin(a) * r1}
        x2={50 + Math.cos(a) * r2}
        y2={50 + Math.sin(a) * r2}
        stroke={withAlpha('#DFF7FB', 0.45)}
        strokeWidth={2}
      />
    );
  });
  return (
    <svg width={size} height={size} viewBox="0 0 100 100">
      {/* viền kim loại ngoài */}
      <circle cx="50" cy="50" r="49" fill="#0A161A" />
      <circle cx="50" cy="50" r="48.5" fill="none" stroke={withAlpha('#CFEFF5', 0.4)} strokeWidth={1.6} />
      {ticks}
      {/* thân lens */}
      <circle cx="50" cy="50" r="38" fill="#0E2228" />
      <circle cx="50" cy="50" r="38" fill="none" stroke={withAlpha(COLORS.teal, 0.5)} strokeWidth={2.4} />
      {/* thấu kính trong */}
      <circle cx="50" cy="50" r="26" fill="#133038" />
      <circle cx="50" cy="50" r="26" fill="none" stroke={withAlpha('#0A6675', 0.8)} strokeWidth={2} />
      {/* highlight lồi */}
      <circle cx="41" cy="40" r="9" fill={withAlpha('#BFF3FA', 0.5)} />
      <circle cx="59" cy="61" r="4" fill={withAlpha('#41E0F2', 0.35)} />
    </svg>
  );
};

/** Mặt lưng điện thoại kính teal: cụm camera kiểu Apple + đèn flash. */
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
  const lens = mod * 0.36;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        background: `linear-gradient(150deg, ${withAlpha('#2A5A66', 0.96)} 0%, #123037 55%, #0A2026 100%)`,
        position: 'relative',
        overflow: 'hidden',
        border: `1.5px solid ${withAlpha('#FFFFFF', 0.35)}`,
        boxShadow: `0 22px 40px ${withAlpha('#02222B', 0.35)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.35)}, 0 0 40px ${withAlpha(COLORS.teal, 0.18)}`,
      }}
    >
      {/* specular kính chéo góc trên */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `linear-gradient(118deg, ${withAlpha('#FFFFFF', 0.22)} 0%, ${withAlpha('#FFFFFF', 0.05)} 30%, transparent 52%, ${withAlpha('#FFFFFF', 0.08)} 78%, transparent 92%)`,
        }}
      />

      {/* cụm camera sau (góc trên, hướng về cốc) — đảo kính mờ */}
      <div
        style={{
          position: 'absolute',
          top: inset,
          right: inset,
          width: mod,
          height: mod,
          borderRadius: mod * 0.3,
          background: `linear-gradient(160deg, ${withAlpha('#FFFFFF', 0.14)}, ${withAlpha('#04141A', 0.6)})`,
          border: `1.5px solid ${withAlpha('#FFFFFF', 0.3)}`,
          boxShadow: `inset 0 1px 0 ${withAlpha('#FFFFFF', 0.3)}, 0 8px 18px ${withAlpha('#02222B', 0.4)}`,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          placeItems: 'center',
          padding: mod * 0.1,
          boxSizing: 'border-box',
          gap: mod * 0.06,
        }}
      >
        {[0, 1, 2].map((i) => (
          <LensRing key={i} size={lens} />
        ))}
        {/* đèn flash (loé khi chụp) */}
        <div
          style={{
            width: lens * 0.55,
            height: lens * 0.55,
            borderRadius: '50%',
            background: '#FFF4CC',
            border: `1px solid ${withAlpha('#FFFFFF', 0.5)}`,
            boxShadow: `0 0 ${10 + flash * 26}px ${4 + flash * 12}px ${withAlpha('#FFE7A0', 0.3 + flash * 0.7)}`,
            opacity: 0.55 + flash * 0.45,
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
