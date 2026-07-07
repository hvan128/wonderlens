import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing } from 'remotion';
import { COLORS, CINE, seeded, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { LogoMark } from '../components/Icons';

// hạt sáng lắng xuống (tất định theo index)
const DUST = Array.from({ length: 30 }).map((_, i) => ({
  x: seeded(i * 3 + 1) * 1080,
  y0: seeded(i * 5 + 2) * 1500 - 200,
  fall: 0.6 + seeded(i * 7 + 3) * 1.6,
  r: 2 + seeded(i * 11 + 4) * 4,
  warm: seeded(i * 13 + 5) > 0.65,
  tw: seeded(i * 17 + 6) * Math.PI * 2,
}));

/** Cảnh E: chốt logo + tagline — logo phát sáng, lens flare kín đáo. */
export const LogoScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bgIn = interpolate(frame, [0, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const markPop = spring({ frame: frame - 4, fps, config: { damping: 12, mass: 0.7 }, durationInFrames: 28 });
  const wordIn = interpolate(frame, [12, 28], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const tagIn = interpolate(frame, [18, 34], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // flare loé lên cùng nhịp logo rồi lắng lại
  const flare = interpolate(frame, [8, 22, 44], [0, 1, 0.55], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // glow "thở" rất nhẹ
  const breath = 1 + Math.sin(frame / 16) * 0.06;

  return (
    <AbsoluteFill
      style={{
        opacity: bgIn,
        background: `radial-gradient(120% 90% at 50% 38%, #0F5060 0%, #0A3947 48%, #041E27 82%, #02141B 100%)`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 30,
        overflow: 'hidden',
      }}
    >
      {/* hạt sáng lắng xuống chậm rãi */}
      {DUST.map((d, i) => {
        const y = d.y0 + frame * d.fall;
        const tw = 0.35 + 0.65 * Math.sin(frame / 12 + d.tw) ** 2;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: d.x,
              top: y,
              width: d.r * 2,
              height: d.r * 2,
              borderRadius: '50%',
              background: d.warm ? CINE.warmSoft : CINE.neonSoft,
              boxShadow: `0 0 ${6 + d.r * 3}px ${d.warm ? withAlpha(CINE.warm, 0.8) : withAlpha(CINE.neon, 0.8)}`,
              opacity: 0.5 * tw,
            }}
          />
        );
      })}

      {/* quầng sáng lớn sau logo */}
      <div
        style={{
          position: 'absolute',
          left: '50%',
          top: '38%',
          width: 760,
          height: 760,
          transform: `translate(-50%, -50%) scale(${breath * markPop})`,
          background: `radial-gradient(circle, ${withAlpha(CINE.neon, 0.3)} 0%, ${withAlpha(CINE.neon, 0.08)} 45%, transparent 70%)`,
          filter: 'blur(10px)',
        }}
      />
      {/* lens flare ngang (anamorphic) kín đáo */}
      <div
        style={{
          position: 'absolute',
          left: '50%',
          top: '38%',
          width: 980,
          height: 5,
          transform: 'translate(-50%, -50%)',
          background: `linear-gradient(90deg, transparent 0%, ${withAlpha(CINE.neonSoft, 0.65)} 42%, #FFFFFF 50%, ${withAlpha(CINE.neonSoft, 0.65)} 58%, transparent 100%)`,
          filter: 'blur(3px)',
          opacity: flare,
        }}
      />
      {/* chấm flare phụ dọc trục chéo */}
      {[[0.36, 0.30, 14], [0.62, 0.46, 10], [0.7, 0.52, 20]].map(([fx, fy, fr], i) => (
        <div
          key={`f${i}`}
          style={{
            position: 'absolute',
            left: `${fx * 100}%`,
            top: `${fy * 100}%`,
            width: fr * 2,
            height: fr * 2,
            borderRadius: '50%',
            border: `2px solid ${withAlpha(CINE.neonSoft, 0.5)}`,
            background: withAlpha(CINE.neonSoft, 0.12),
            transform: 'translate(-50%, -50%)',
            opacity: flare * 0.8,
            filter: 'blur(1px)',
          }}
        />
      ))}

      <div
        style={{
          transform: `scale(${markPop})`,
          filter: `drop-shadow(0 0 ${26 * breath}px ${withAlpha(CINE.neon, 0.65)}) drop-shadow(0 18px 30px ${withAlpha('#01161C', 0.6)})`,
        }}
      >
        <LogoMark size={240} />
      </div>

      <div
        style={{
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 120,
          color: '#FFFFFF',
          opacity: wordIn,
          transform: `translateY(${(1 - wordIn) * 26}px)`,
          textShadow: `0 0 30px ${withAlpha(CINE.neon, 0.4)}, 0 4px 0 ${withAlpha('#031A20', 0.3)}`,
        }}
      >
        Wonder
        <span
          style={{
            color: COLORS.badgeGold,
            textShadow: `0 0 30px ${withAlpha(CINE.warm, 0.55)}, 0 4px 0 ${withAlpha('#31200A', 0.35)}`,
          }}
        >
          Lens
        </span>
      </div>

      <div
        style={{
          fontFamily: BODY,
          fontWeight: 700,
          fontSize: 38,
          color: withAlpha('#FFFFFF', 0.95),
          opacity: tagIn,
          transform: `translateY(${(1 - tagIn) * 20}px)`,
          textAlign: 'center',
          padding: '0 40px',
          lineHeight: 1.3,
          whiteSpace: 'nowrap',
          textShadow: `0 0 24px ${withAlpha(CINE.neon, 0.35)}`,
        }}
      >
        Chụp đồ vật — Khám phá hành trình tạo ra nó.
      </div>
    </AbsoluteFill>
  );
};
