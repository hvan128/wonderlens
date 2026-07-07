import type { CSSProperties, ReactNode } from 'react';
import {
  AbsoluteFill,
  Easing,
  Sequence,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { BODY, HEADING } from './fonts';
import { HEIGHT, WIDTH, withAlpha } from './theme';

export const CUP_JOURNEY_DURATION_IN_FRAMES = 36 * 30;

const INK = '#14313A';
const INK_2 = '#0B2228';
const TEXT = '#1C3C45';
const MUTED = '#607A83';
const SURFACE = '#FFFDF7';
const PAPER = '#F8EDD2';
const TABLE = '#F4E1BC';
const TEAL = '#26C6DA';
const TEAL_DARK = '#0A91A8';
const GOLD = '#F2B643';
const GREEN = '#38B979';
const CORAL = '#FF7868';
const BLUE = '#3D8BFF';
const VIOLET = '#7862F2';
const WHITE = '#FFFFFF';

const journeyStages = [
  {
    short: 'Gỗ',
    title: 'Gỗ được tách thành sợi giấy',
    body: 'Cây được thu hoạch có kiểm soát, phần thân gỗ được tách thành nhiều sợi nhỏ.',
    color: GREEN,
    accent: '#DBF5E6',
  },
  {
    short: 'Bột',
    title: 'Sợi được nghiền thành bột giấy',
    body: 'Sợi gỗ trộn với nước, khuấy thành dòng bột mịn để chuẩn bị cán giấy.',
    color: GOLD,
    accent: '#FFF1C8',
  },
  {
    short: 'Phủ',
    title: 'Tấm giấy được phủ lớp chống thấm',
    body: 'Một lớp phủ rất mỏng giúp nước chậm ngấm vào giấy.',
    color: TEAL,
    accent: '#DDF8FB',
  },
  {
    short: 'Cắt',
    title: 'Cắt thành mảnh hình quạt',
    body: 'Tấm giấy được cắt cong để khi cuốn lại sẽ thành thân cốc.',
    color: BLUE,
    accent: '#E5F0FF',
  },
  {
    short: 'Ép',
    title: 'Cuốn thân và ép kín đáy',
    body: 'Mép thân và đáy tròn được ép nhiệt để giảm rò nước.',
    color: CORAL,
    accent: '#FFE6E1',
  },
  {
    short: 'Thử',
    title: 'Cuộn miệng rồi thử nước',
    body: 'Vành cốc được cuộn chắc hơn, sau đó kiểm tra bằng giọt nước thật.',
    color: VIOLET,
    accent: '#EEE9FF',
  },
] as const;

const clamp = (value: number, min = 0, max = 1) => Math.max(min, Math.min(max, value));

const ease = (
  frame: number,
  input: [number, number],
  output: [number, number],
  easing = Easing.out(Easing.quad),
) =>
  interpolate(frame, input, output, {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing,
  });

const fadeIn = (frame: number, from: number, duration: number) => ease(frame, [from, from + duration], [0, 1]);
const fadeOut = (frame: number, from: number, duration: number) =>
  ease(frame, [from, from + duration], [1, 0], Easing.in(Easing.quad));
const progress = (frame: number, from: number, to: number) =>
  ease(frame, [from, to], [0, 1], Easing.inOut(Easing.cubic));

const pop = (frame: number, fps: number, delay: number, duration = 30) =>
  spring({
    frame: frame - delay,
    fps,
    durationInFrames: duration,
    config: { damping: 17, stiffness: 165, mass: 0.9 },
  });

const labelStyle: CSSProperties = {
  fontFamily: BODY,
  fontWeight: 800,
  letterSpacing: 0,
};

const activeStageIndex = (frame: number) => {
  if (frame < 116) return 0;
  if (frame < 230) return 1;
  if (frame < 344) return 2;
  if (frame < 458) return 3;
  if (frame < 572) return 4;
  return 5;
};

export const WonderLensCupJourneyPromo = () => (
  <AbsoluteFill
    style={{
      background: TABLE,
      color: INK,
      fontFamily: BODY,
      overflow: 'hidden',
    }}
  >
    <PremiumDesk />
    <Sequence from={0} durationInFrames={190} premountFor={20}>
      <ScanPrelude />
    </Sequence>
    <Sequence from={118} durationInFrames={780} premountFor={30}>
      <JourneyConsole />
    </Sequence>
    <Sequence from={850} durationInFrames={230} premountFor={30}>
      <FinalFrame />
    </Sequence>
  </AbsoluteFill>
);

const PremiumDesk = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(circle at 18% 8%, rgba(255,255,255,.92), transparent 25%), radial-gradient(circle at 92% 4%, rgba(38,198,218,.20), transparent 30%), linear-gradient(180deg, #FFF9EA 0%, #F3DFB7 100%)',
        }}
      />
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: 'absolute', inset: 0 }}>
        <defs>
          <pattern id="journeyDeskLines" width="112" height="112" patternUnits="userSpaceOnUse">
            <path
              d="M0 28 C34 8 72 44 112 22 M0 84 C38 64 72 104 112 78"
              fill="none"
              stroke="rgba(91,62,22,.065)"
              strokeWidth="3"
              strokeLinecap="round"
            />
          </pattern>
        </defs>
        <rect width={WIDTH} height={HEIGHT} fill="url(#journeyDeskLines)" opacity="0.78" />
        <path
          d="M-100 460 C130 360 286 520 520 424 C780 318 930 392 1200 294"
          fill="none"
          stroke="rgba(38,198,218,.18)"
          strokeWidth="36"
          strokeLinecap="round"
          style={{ transform: `translate(${Math.sin(frame / 90) * 18}px, ${Math.cos(frame / 115) * 10}px)` }}
        />
        <path
          d="M-120 1500 C128 1410 322 1552 546 1460 C800 1354 970 1440 1220 1332"
          fill="none"
          stroke="rgba(242,182,67,.20)"
          strokeWidth="38"
          strokeLinecap="round"
          style={{ transform: `translate(${Math.cos(frame / 110) * -14}px, ${Math.sin(frame / 92) * 10}px)` }}
        />
      </svg>
    </AbsoluteFill>
  );
};

const ScanPrelude = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = pop(frame, fps, 8, 52);
  const scan = progress(frame, 58, 142);
  const out = fadeOut(frame, 144, 34);

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <div style={{ position: 'absolute', top: 104, left: 76, right: 76 }}>
        <div style={{ ...labelStyle, color: TEAL_DARK, fontSize: 27 }}>WonderLens quét vật thật</div>
        <div
          style={{
            marginTop: 16,
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 82,
            lineHeight: 0.92,
            letterSpacing: 0,
          }}
        >
          Mở hành trình
          <br />
          của cốc giấy
        </div>
      </div>
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: 'absolute', inset: 0 }}>
        <ellipse cx="540" cy="1380" rx="298" ry="68" fill="rgba(77,52,18,.15)" />
        <g
          transform={`translate(0 ${ease(enter, [0, 1], [72, 0])}) scale(${ease(enter, [0, 1], [0.9, 1])})`}
          style={{ transformOrigin: '540px 930px' }}
        >
          <CupDrawing x={330} y={428} scale={1.12} />
        </g>
        <rect
          x="230"
          y="420"
          width="620"
          height="790"
          rx="62"
          fill="none"
          stroke={withAlpha(WHITE, 0.72)}
          strokeWidth="5"
          strokeDasharray="28 22"
        />
        <rect
          x="258"
          y={450 + scan * 680}
          width="564"
          height="46"
          rx="23"
          fill={withAlpha(TEAL, 0.26)}
        />
        <ScanCorners x={230} y={420} width={620} height={790} />
      </svg>
    </AbsoluteFill>
  );
};

const ScanCorners = ({ x, y, width, height }: { x: number; y: number; width: number; height: number }) => (
  <g>
    <path d={`M${x} ${y + 84} V${y + 30} C${x} ${y + 12} ${x + 12} ${y} ${x + 30} ${y} H${x + 90}`} fill="none" stroke={TEAL} strokeWidth="12" strokeLinecap="round" />
    <path d={`M${x + width} ${y + 84} V${y + 30} C${x + width} ${y + 12} ${x + width - 12} ${y} ${x + width - 30} ${y} H${x + width - 90}`} fill="none" stroke={TEAL} strokeWidth="12" strokeLinecap="round" />
    <path d={`M${x} ${y + height - 84} V${y + height - 30} C${x} ${y + height - 12} ${x + 12} ${y + height} ${x + 30} ${y + height} H${x + 90}`} fill="none" stroke={TEAL} strokeWidth="12" strokeLinecap="round" />
    <path d={`M${x + width} ${y + height - 84} V${y + height - 30} C${x + width} ${y + height - 12} ${x + width - 12} ${y + height} ${x + width - 30} ${y + height} H${x + width - 90}`} fill="none" stroke={TEAL} strokeWidth="12" strokeLinecap="round" />
  </g>
);

const JourneyConsole = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = pop(frame, fps, 0, 56);
  const active = activeStageIndex(frame);
  const deckBurst = fadeIn(frame, 90, 28) * fadeOut(frame, 126, 26);

  return (
    <AbsoluteFill style={{ opacity: fadeIn(frame, 0, 24) * fadeOut(frame, 736, 44) }}>
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 82,
          display: 'flex',
          justifyContent: 'center',
          transform: `translateY(${ease(enter, [0, 1], [230, 0])}px) scale(${ease(enter, [0, 1], [0.78, 1])}) rotate(${ease(
            enter,
            [0, 1],
            [5, 0],
          )}deg)`,
          transformOrigin: '50% 74%',
        }}
      >
        <PhoneShell>
          <JourneyScreen frame={frame} active={active} />
        </PhoneShell>
      </div>
      <OrbitingStageBadges frame={frame} active={active} opacity={deckBurst} />
      <div
        style={{
          position: 'absolute',
          left: 78,
          right: 78,
          bottom: 86,
          opacity: fadeIn(frame, 150, 30),
        }}
      >
        <div
          style={{
            padding: '22px 28px',
            borderRadius: 34,
            background: withAlpha(WHITE, 0.86),
            border: `1px solid ${withAlpha(INK, 0.08)}`,
            boxShadow: `0 18px 46px ${withAlpha('#6B4E18', 0.13)}`,
            textAlign: 'center',
            ...labelStyle,
            color: TEXT,
            fontSize: 27,
            lineHeight: 1.15,
          }}
        >
          Đủ 6 chặng, mỗi chặng có hình minh họa và câu giải thích ngắn để trẻ hiểu ngay.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const PhoneShell = ({ children }: { children: ReactNode }) => (
  <div
    style={{
      width: 760,
      height: 1500,
      borderRadius: 84,
      padding: 18,
      background: 'linear-gradient(145deg, #213F48 0%, #071419 100%)',
      boxSizing: 'border-box',
      boxShadow: `0 76px 130px ${withAlpha('#503411', 0.3)}, inset 0 0 0 2px ${withAlpha(WHITE, 0.08)}`,
      position: 'relative',
    }}
  >
    <div
      style={{
        width: '100%',
        height: '100%',
        borderRadius: 66,
        overflow: 'hidden',
        background: SURFACE,
        position: 'relative',
      }}
    >
      {children}
    </div>
    <div
      style={{
        position: 'absolute',
        top: 30,
        left: '50%',
        transform: 'translateX(-50%)',
        width: 142,
        height: 32,
        borderRadius: 999,
        background: '#071419',
      }}
    />
  </div>
);

const JourneyScreen = ({ frame, active }: { frame: number; active: number }) => {
  const stage = journeyStages[active];
  const local = frame - active * 114;
  const reveal = fadeIn(frame, 36, 26);

  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'linear-gradient(180deg, #FFFDF8 0%, #F9F1DD 52%, #EFE2C6 100%)',
        }}
      />
      <StatusBar />
      <TopBar />
      <HeroConsole frame={frame} />
      <StageViewport stageIndex={active} localFrame={local} />
      <StageTextPanel stage={stage} localFrame={local} />
      <FullJourneyRail active={active} frame={frame} />
      <div
        style={{
          position: 'absolute',
          left: 32,
          right: 32,
          bottom: 38,
          height: 88,
          borderRadius: 34,
          background: INK_2,
          color: WHITE,
          display: 'grid',
          gridTemplateColumns: '1fr 150px',
          alignItems: 'center',
          padding: '0 24px 0 28px',
          boxSizing: 'border-box',
          opacity: reveal,
          boxShadow: `0 20px 44px ${withAlpha(INK_2, 0.22)}`,
        }}
      >
        <div>
          <div style={{ ...labelStyle, fontSize: 22, color: withAlpha(WHITE, 0.66) }}>Bước tiếp theo</div>
          <div style={{ ...labelStyle, fontSize: 27 }}>Nghe WonderLens kể</div>
        </div>
        <div
          style={{
            height: 52,
            borderRadius: 20,
            background: stage.color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            ...labelStyle,
            fontSize: 21,
          }}
        >
          Nghe
        </div>
      </div>
    </div>
  );
};

const StatusBar = () => (
  <div
    style={{
      position: 'absolute',
      left: 34,
      right: 34,
      top: 26,
      height: 30,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      ...labelStyle,
      color: INK,
      fontSize: 20,
      zIndex: 20,
    }}
  >
    <span>9:41</span>
    <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
      <div style={{ width: 28, height: 13, borderRadius: 4, border: `2px solid ${INK}` }} />
      <div style={{ width: 4, height: 8, borderRadius: 2, background: INK }} />
    </div>
  </div>
);

const TopBar = () => (
  <div
    style={{
      position: 'absolute',
      left: 32,
      right: 32,
      top: 72,
      height: 54,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      zIndex: 12,
    }}
  >
    <IconButton>
      <path d="M14 7 L7 14 L14 21" fill="none" stroke={INK} strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round" />
    </IconButton>
    <div style={{ ...labelStyle, fontSize: 24 }}>Hành trình cốc giấy</div>
    <IconButton accent>
      <circle cx="12" cy="12" r="6" fill="none" stroke={TEAL_DARK} strokeWidth="3" />
      <path d="M17 17 L23 23" stroke={TEAL_DARK} strokeWidth="3" strokeLinecap="round" />
    </IconButton>
  </div>
);

const IconButton = ({ children, accent = false }: { children: ReactNode; accent?: boolean }) => (
  <div
    style={{
      width: 54,
      height: 54,
      borderRadius: 20,
      background: accent ? withAlpha(TEAL, 0.14) : withAlpha(INK, 0.07),
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    <svg width="28" height="28" viewBox="0 0 28 28">
      {children}
    </svg>
  </div>
);

const HeroConsole = ({ frame }: { frame: number }) => {
  const reveal = fadeIn(frame, 34, 28);
  return (
    <div
      style={{
        position: 'absolute',
        left: 32,
        right: 32,
        top: 146,
        height: 218,
        borderRadius: 42,
        background: 'linear-gradient(145deg, #16323A 0%, #10272E 100%)',
        color: WHITE,
        padding: '28px 32px',
        boxSizing: 'border-box',
        overflow: 'hidden',
        opacity: reveal,
        transform: `translateY(${ease(reveal, [0, 1], [32, 0])}px)`,
        boxShadow: `0 24px 60px ${withAlpha('#10272E', 0.22)}`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          right: -60,
          top: -80,
          width: 280,
          height: 280,
          borderRadius: '50%',
          background: withAlpha(TEAL, 0.22),
        }}
      />
      <div style={{ ...labelStyle, color: withAlpha(WHITE, 0.64), fontSize: 20 }}>WonderLens đã nhận diện</div>
      <div
        style={{
          marginTop: 10,
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 50,
          lineHeight: 0.92,
          letterSpacing: 0,
          maxWidth: 420,
        }}
      >
        Cốc giấy được tạo ra thế nào?
      </div>
      <div
        style={{
          marginTop: 18,
          display: 'inline-flex',
          alignItems: 'center',
          gap: 10,
          borderRadius: 18,
          padding: '9px 14px',
          background: withAlpha(WHITE, 0.12),
          ...labelStyle,
          fontSize: 18,
        }}
      >
        <span style={{ width: 10, height: 10, borderRadius: '50%', background: GREEN }} />
        đầy đủ 6 chặng
      </div>
    </div>
  );
};

const StageViewport = ({ stageIndex, localFrame }: { stageIndex: number; localFrame: number }) => {
  const stage = journeyStages[stageIndex];
  const entrance = fadeIn(localFrame, 0, 22);
  return (
    <div
      style={{
        position: 'absolute',
        left: 32,
        right: 32,
        top: 392,
        height: 452,
        borderRadius: 44,
        background: WHITE,
        boxShadow: `0 22px 60px ${withAlpha('#6A4D19', 0.14)}`,
        border: `1px solid ${withAlpha(INK, 0.08)}`,
        overflow: 'hidden',
        opacity: fadeIn(localFrame, 0, 18),
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(circle at 50% 28%, ${withAlpha(stage.color, 0.18)}, transparent 44%), linear-gradient(180deg, ${stage.accent} 0%, #FFFDF7 100%)`,
        }}
      />
      <svg width="100%" height="100%" viewBox="0 0 656 452" style={{ position: 'absolute', inset: 0 }}>
        <StageIllustration index={stageIndex} frame={localFrame} color={stage.color} />
      </svg>
      <StageSweep localFrame={localFrame} color={stage.color} />
      <div
        style={{
          position: 'absolute',
          top: 24,
          left: 24,
          padding: '10px 16px',
          borderRadius: 18,
          background: withAlpha(WHITE, 0.82),
          border: `2px solid ${withAlpha(stage.color, 0.5)}`,
          color: stage.color,
          ...labelStyle,
          fontSize: 18,
          opacity: entrance,
        }}
      >
        Chặng {stageIndex + 1} / 6
      </div>
    </div>
  );
};

const StageSweep = ({ localFrame, color }: { localFrame: number; color: string }) => {
  const sweep = progress(localFrame, 8, 58);
  const opacity = fadeIn(localFrame, 8, 10) * fadeOut(localFrame, 58, 18);

  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        overflow: 'hidden',
        opacity,
        pointerEvents: 'none',
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: -80,
          left: -180 + sweep * 860,
          width: 128,
          height: 620,
          transform: 'rotate(18deg)',
          background: `linear-gradient(90deg, transparent, ${withAlpha(WHITE, 0.82)}, ${withAlpha(color, 0.34)}, transparent)`,
          filter: 'blur(2px)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          inset: 22,
          borderRadius: 32,
          border: `3px solid ${withAlpha(color, 0.38)}`,
        }}
      />
    </div>
  );
};

const StageIllustration = ({ index, frame, color }: { index: number; frame: number; color: string }) => {
  const p = progress(frame, 8, 82);
  const wave = Math.sin(frame / 10);

  if (index === 0) {
    return (
      <g>
        <rect x="82" y="276" width="492" height="28" rx="14" fill="rgba(20,49,58,.08)" />
        <path d="M250 304 V164 C250 128 280 104 326 104 C374 104 404 132 404 170 V304" fill="#8B6335" stroke={INK} strokeWidth="8" />
        {[0, 1, 2, 3, 4, 5].map((i) => (
          <circle
            key={i}
            cx={190 + i * 58 + Math.sin(i) * 24}
            cy={132 + Math.cos(i) * 54}
            r={54 + (i % 2) * 12}
            fill={i % 2 ? '#78CE7F' : GREEN}
            stroke={withAlpha(INK, 0.16)}
            strokeWidth="5"
            opacity={ease(p, [0, 1], [0.3, 1])}
          />
        ))}
        {Array.from({ length: 10 }, (_, i) => (
          <path
            key={i}
            d={`M${426 + i * 16} ${130 + Math.sin(i) * 20} C${376 + i * 8} ${182 + i * 6} ${360 - i * 8} ${226 + i * 5} ${310 + i * 4} ${280}`}
            fill="none"
            stroke={withAlpha(GOLD, 0.75)}
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray="18 14"
            strokeDashoffset={-frame * 4}
          />
        ))}
      </g>
    );
  }

  if (index === 1) {
    return (
      <g>
        <ellipse cx="328" cy="242" rx={210 + p * 28} ry={98 + p * 20} fill={withAlpha(GOLD, 0.26)} />
        <ellipse cx="328" cy="242" rx={128 + p * 30} ry={56 + p * 14} fill={withAlpha(WHITE, 0.48)} />
        {Array.from({ length: 18 }, (_, i) => {
          const a = i * 0.72 + frame / 22;
          return (
            <path
              key={i}
              d={`M${328 + Math.cos(a) * (92 + (i % 3) * 22) - 28} ${242 + Math.sin(a) * (48 + (i % 4) * 8)} C${320 +
                Math.cos(a) * 96} ${216 + Math.sin(a) * 60} ${340 + Math.cos(a) * 114} ${268 + Math.sin(a) * 60} ${328 +
                Math.cos(a) * 130} ${242 + Math.sin(a) * 54}`}
              fill="none"
              stroke={i % 2 ? withAlpha(GREEN, 0.78) : withAlpha(GOLD, 0.86)}
              strokeWidth="8"
              strokeLinecap="round"
            />
          );
        })}
      </g>
    );
  }

  if (index === 2) {
    const filmX = ease(p, [0, 1], [80, 390]);
    return (
      <g>
        <rect x="116" y="146" width="424" height="190" rx="34" fill={PAPER} stroke={INK} strokeWidth="7" />
        {[0, 1, 2, 3].map((i) => (
          <path key={i} d={`M154 ${190 + i * 36} C260 ${160 + i * 36} 374 ${220 + i * 34} 504 ${186 + i * 34}`} stroke="rgba(20,49,58,.12)" strokeWidth="5" fill="none" strokeLinecap="round" />
        ))}
        <rect x={filmX - 180} y="140" width="260" height="202" rx="36" fill={withAlpha(TEAL, 0.32)} stroke={TEAL} strokeWidth="8" />
        <circle cx="134" cy="110" r="54" fill="#D9C59F" stroke={INK} strokeWidth="7" />
        <circle cx="522" cy="110" r="54" fill="#D9C59F" stroke={INK} strokeWidth="7" />
        <path d="M134 110 H522" stroke={withAlpha(INK, 0.46)} strokeWidth="12" strokeLinecap="round" />
      </g>
    );
  }

  if (index === 3) {
    const bladeX = ease(p, [0, 1], [154, 500]);
    return (
      <g>
        <path d="M164 136 C286 88 412 88 494 136 L462 336 C354 304 272 304 194 336 Z" fill={PAPER} stroke={INK} strokeWidth="8" />
        <path d="M186 176 C286 140 396 140 476 176" stroke={TEAL} strokeWidth="18" strokeLinecap="round" fill="none" />
        <path d="M164 136 C286 88 412 88 494 136 L462 336 C354 304 272 304 194 336 Z" fill="none" stroke={GOLD} strokeWidth="7" strokeDasharray="20 15" strokeDashoffset={-frame * 5} />
        <g transform={`translate(${bladeX} 0)`}>
          <path d="M0 124 L42 190 L0 256 L-42 190 Z" fill={WHITE} stroke={INK} strokeWidth="7" />
          <path d="M-16 190 H18" stroke={CORAL} strokeWidth="7" strokeLinecap="round" />
        </g>
      </g>
    );
  }

  if (index === 4) {
    const wrap = progress(frame, 6, 86);
    return (
      <g>
        <path d="M190 110 C268 84 388 84 466 110 L434 330 C354 360 284 360 220 330 Z" fill={PAPER} stroke={INK} strokeWidth="8" transform={`translate(${ease(wrap, [0, 1], [-70, 0])} 0)`} />
        <path d="M190 110 C268 84 388 84 466 110 L434 330 C354 360 284 360 220 330 Z" fill={withAlpha(WHITE, 0.5)} stroke={INK} strokeWidth="8" transform={`translate(${ease(wrap, [0, 1], [70, 0])} 0)`} />
        <path d="M328 108 C328 176 328 274 328 338" stroke={CORAL} strokeWidth="14" strokeLinecap="round" strokeDasharray="22 18" strokeDashoffset={-frame * 6} />
        <ellipse cx="328" cy={ease(wrap, [0, 1], [390, 332])} rx="128" ry="34" fill="#EAD6AA" stroke={INK} strokeWidth="8" />
        <path d="M218 334 C286 386 390 386 454 334" stroke={withAlpha(CORAL, 0.42)} strokeWidth="14" strokeLinecap="round" fill="none" />
      </g>
    );
  }

  const drop = progress(frame, 12, 76);
  return (
    <g>
      <g transform="translate(178 76) scale(.72)">
        <CupDrawing x={0} y={0} scale={1} />
      </g>
      <path d="M246 130 C298 164 392 166 444 132" stroke={TEAL} strokeWidth="18" strokeLinecap="round" fill="none" />
      <path d="M244 318 C300 350 390 350 446 318" stroke={VIOLET} strokeWidth="13" strokeLinecap="round" strokeDasharray="24 18" fill="none" />
      <path
        d={`M328 ${ease(drop, [0, 1], [82, 230]) - 48} C366 ${ease(drop, [0, 1], [82, 230])} 358 ${ease(drop, [0, 1], [82, 230]) + 44} 328 ${ease(drop, [0, 1], [82, 230]) + 58} C298 ${ease(drop, [0, 1], [82, 230]) + 44} 290 ${ease(drop, [0, 1], [82, 230])} 328 ${ease(drop, [0, 1], [82, 230]) - 48}Z`}
        fill={withAlpha(TEAL, 0.62)}
        stroke={INK}
        strokeWidth="6"
      />
      <path d={`M238 ${318 + wave * 4} C292 288 366 356 430 ${318 + wave * 4}`} stroke={withAlpha(TEAL, 0.7)} strokeWidth="9" strokeLinecap="round" fill="none" />
    </g>
  );
};

const StageTextPanel = ({ stage, localFrame }: { stage: (typeof journeyStages)[number]; localFrame: number }) => {
  const enter = fadeIn(localFrame, 0, 18);
  return (
    <div
      style={{
        position: 'absolute',
        left: 32,
        right: 32,
        top: 870,
        minHeight: 190,
        borderRadius: 38,
        background: withAlpha(WHITE, 0.94),
        border: `2px solid ${withAlpha(stage.color, 0.22)}`,
        boxShadow: `0 20px 50px ${withAlpha('#6A4D19', 0.12)}`,
        padding: '26px 28px',
        boxSizing: 'border-box',
        opacity: enter,
        transform: `translateY(${ease(enter, [0, 1], [28, 0])}px)`,
      }}
    >
      <div
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 10,
          color: stage.color,
          ...labelStyle,
          fontSize: 21,
        }}
      >
        <span style={{ width: 12, height: 12, borderRadius: '50%', background: stage.color }} />
        {stage.short}
      </div>
      <div
        style={{
          marginTop: 10,
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 40,
          lineHeight: 0.94,
          letterSpacing: 0,
        }}
      >
        {stage.title}
      </div>
      <div style={{ marginTop: 12, ...labelStyle, color: MUTED, fontSize: 24, lineHeight: 1.16 }}>{stage.body}</div>
    </div>
  );
};

const FullJourneyRail = ({ active, frame }: { active: number; frame: number }) => {
  const railProgress = clamp(ease(frame, [38, 686], [0, 1], Easing.linear));
  return (
    <div
      style={{
        position: 'absolute',
        left: 32,
        right: 32,
        top: 1090,
        height: 156,
        borderRadius: 40,
        background: withAlpha(WHITE, 0.76),
        border: `1px solid ${withAlpha(INK, 0.08)}`,
        boxShadow: `0 18px 44px ${withAlpha('#6A4D19', 0.1)}`,
        padding: '20px 24px',
        boxSizing: 'border-box',
      }}
    >
      <div style={{ position: 'absolute', left: 58, right: 58, top: 49, height: 9, borderRadius: 999, background: withAlpha(INK, 0.08), overflow: 'hidden' }}>
        <div
          style={{
            width: `${railProgress * 100}%`,
            height: '100%',
            background: `linear-gradient(90deg, ${GREEN}, ${GOLD}, ${TEAL}, ${BLUE}, ${CORAL}, ${VIOLET})`,
            borderRadius: 999,
          }}
        />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 4 }}>
        {journeyStages.map((stage, index) => {
          const isActive = index === active;
          return (
            <div key={stage.short} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <div
                style={{
                  width: isActive ? 62 : 50,
                  height: isActive ? 62 : 50,
                  borderRadius: isActive ? 24 : 20,
                  background: isActive ? stage.color : WHITE,
                  color: isActive ? WHITE : stage.color,
                  border: `4px solid ${stage.color}`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontFamily: HEADING,
                  fontWeight: 800,
                  fontSize: isActive ? 30 : 25,
                  zIndex: 2,
                }}
              >
                {index + 1}
              </div>
              <div
                style={{
                  marginTop: 14,
                  ...labelStyle,
                  color: isActive ? INK : withAlpha(INK, 0.54),
                  fontSize: 18,
                }}
              >
                {stage.short}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

const OrbitingStageBadges = ({ frame, active, opacity }: { frame: number; active: number; opacity: number }) => (
  <div style={{ position: 'absolute', inset: 0, opacity, pointerEvents: 'none' }}>
    {journeyStages.map((stage, index) => {
      const angle = -1.65 + index * 0.67;
      const radius = 458;
      const activeLift = index === active ? -24 : 0;
      const x = 540 + Math.cos(angle) * radius - 66;
      const y = 910 + Math.sin(angle) * radius + activeLift;
      return (
        <div
          key={stage.short}
          style={{
            position: 'absolute',
            left: x,
            top: y,
            width: 132,
            height: 88,
            borderRadius: 28,
            background: index === active ? stage.color : withAlpha(WHITE, 0.82),
            color: index === active ? WHITE : stage.color,
            border: `2px solid ${withAlpha(stage.color, 0.42)}`,
            boxShadow: `0 20px 38px ${withAlpha('#6A4D19', 0.13)}`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            ...labelStyle,
            fontSize: 21,
            transform: `translateY(${Math.sin(frame / 16 + index) * 6}px) scale(${index === active ? 1.08 : 1})`,
          }}
        >
          {stage.short}
        </div>
      );
    })}
  </div>
);

const FinalFrame = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const mark = pop(frame, fps, 0, 46);
  return (
    <AbsoluteFill style={{ opacity: fadeIn(frame, 0, 22) }}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(circle at 50% 34%, ${withAlpha(WHITE, 0.94)}, ${withAlpha(TABLE, 0.72)} 58%, #E8CE9F 100%)`,
        }}
      />
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: 'absolute', inset: 0 }}>
        {[0, 1, 2, 3, 4, 5].map((i) => {
          const a = (i / 6) * Math.PI * 2 + frame / 100;
          return (
            <path
              key={i}
              d={`M540 650 L${540 + Math.cos(a) * 330} ${650 + Math.sin(a) * 330}`}
              stroke={withAlpha(journeyStages[i].color, 0.34)}
              strokeWidth="7"
              strokeLinecap="round"
            />
          );
        })}
        <g transform={`translate(540 650) scale(${ease(mark, [0, 1], [0.62, 1])}) translate(-540 -650)`}>
          <circle cx="540" cy="650" r="124" fill={TEAL} stroke={INK} strokeWidth="10" />
          <circle cx="540" cy="650" r="70" fill={WHITE} stroke={INK} strokeWidth="9" />
          <circle cx="564" cy="628" r="27" fill={withAlpha(TEAL, 0.58)} />
          <path d="M622 738 L730 846" stroke={INK} strokeWidth="24" strokeLinecap="round" />
          <path d="M622 738 L730 846" stroke={TEAL} strokeWidth="10" strokeLinecap="round" />
        </g>
      </svg>
      <div
        style={{
          position: 'absolute',
          top: 828,
          left: 78,
          right: 78,
          textAlign: 'center',
          opacity: fadeIn(frame, 20, 24),
        }}
      >
        <div style={{ fontFamily: HEADING, fontSize: 98, fontWeight: 800, lineHeight: 0.9 }}>WonderLens</div>
        <div style={{ marginTop: 18, ...labelStyle, color: MUTED, fontSize: 34 }}>
          Không chỉ nhận diện. Mở cả hành trình.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const CupDrawing = ({ x, y, scale = 1 }: { x: number; y: number; scale?: number }) => (
  <g transform={`translate(${x} ${y}) scale(${scale})`}>
    <path d="M64 114 C88 84 344 84 368 114 L326 650 C312 700 120 700 106 650 Z" fill={PAPER} stroke={INK} strokeWidth="8" />
    <path d="M64 114 C88 84 344 84 368 114 L326 650 C312 700 120 700 106 650 Z" fill="rgba(255,255,255,.28)" />
    <ellipse cx="216" cy="114" rx="156" ry="44" fill={WHITE} stroke={INK} strokeWidth="8" />
    <ellipse cx="216" cy="114" rx="104" ry="25" fill={withAlpha(TEAL, 0.16)} stroke={withAlpha(INK, 0.18)} strokeWidth="3" />
    <path d="M110 202 C166 236 270 240 324 204" fill="none" stroke={TEAL} strokeWidth="20" strokeLinecap="round" />
    <path d="M132 560 C186 592 248 592 304 560" fill="none" stroke={withAlpha(INK, 0.2)} strokeWidth="5" strokeLinecap="round" />
    <path d="M306 178 C280 304 280 482 306 634" fill="none" stroke={withAlpha(WHITE, 0.72)} strokeWidth="15" strokeLinecap="round" />
  </g>
);
