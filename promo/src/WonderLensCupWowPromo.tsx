import type { CSSProperties } from 'react';
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
import { COLORS, HEIGHT, WIDTH, withAlpha } from './theme';

export const CUP_WOW_DURATION_IN_FRAMES = 30 * 30;

const INK = '#12313A';
const MUTED = '#557078';
const PAPER = '#FFF9EA';
const PAPER_DEEP = '#E8D7B7';
const PULP = '#D4A65B';
const WOOD = '#7A5530';
const LEAF = '#59B56D';
const COATING = '#47D1E6';
const HEAT = '#FF7A66';
const GOLD = '#F6B93E';
const GREEN = '#36B879';
const VIOLET = '#7357F5';
const WHITE = '#FFFFFF';

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

const fadeIn = (frame: number, from: number, duration: number) =>
  ease(frame, [from, from + duration], [0, 1]);

const fadeOut = (frame: number, from: number, duration: number) =>
  ease(frame, [from, from + duration], [1, 0], Easing.in(Easing.quad));

const between = (frame: number, from: number, to: number, edge = 24) =>
  fadeIn(frame, from, edge) * fadeOut(frame, to - edge, edge);

const progress = (frame: number, from: number, to: number) =>
  ease(frame, [from, to], [0, 1], Easing.inOut(Easing.cubic));

const pop = (frame: number, fps: number, delay: number, duration = 28) =>
  spring({
    frame: frame - delay,
    fps,
    durationInFrames: duration,
    config: { damping: 14, stiffness: 180, mass: 0.85 },
  });

const cupBodyPath =
  'M228 522 C238 468 842 468 852 522 L756 1504 C746 1582 334 1582 324 1504 Z';

const stages = [
  {
    short: 'Sợi giấy',
    title: 'Gỗ thành bột giấy mềm',
    detail: 'Sợi gỗ được nghiền với nước để thành dòng bột mịn.',
    color: LEAF,
  },
  {
    short: 'Phủ mỏng',
    title: 'Một lớp áo chống thấm',
    detail: 'Lớp phủ rất mỏng giúp giấy giữ nước lâu hơn.',
    color: COATING,
  },
  {
    short: 'Cắt cong',
    title: 'Tấm giấy được cắt hình quạt',
    detail: 'Dáng cong này sẽ ôm lại thành thân cốc.',
    color: GOLD,
  },
  {
    short: 'Ép kín',
    title: 'Thân cốc gặp đáy tròn',
    detail: 'Nhiệt ép mép nối và khóa đáy để nước không rò.',
    color: HEAT,
  },
  {
    short: 'Giữ nước',
    title: 'Miệng cuộn, cốc sẵn sàng',
    detail: 'Vành cuộn làm cốc chắc hơn, rồi giọt nước thử rơi vào.',
    color: GREEN,
  },
] as const;

const stageWindows = [
  [28, 164],
  [136, 282],
  [252, 402],
  [370, 518],
  [488, 610],
] as const;

const getActiveStage = (frame: number) => {
  if (frame < 136) return 0;
  if (frame < 252) return 1;
  if (frame < 370) return 2;
  if (frame < 488) return 3;
  return 4;
};

const labelStyle: CSSProperties = {
  fontFamily: BODY,
  fontWeight: 800,
  letterSpacing: 0,
};

export const WonderLensCupWowPromo = () => (
  <AbsoluteFill
    style={{
      background: PAPER,
      color: INK,
      fontFamily: BODY,
      overflow: 'hidden',
    }}
  >
    <CinematicPaperWorld />
    <Sequence from={0} durationInFrames={160} premountFor={20}>
      <OpeningScan />
    </Sequence>
    <Sequence from={118} durationInFrames={620} premountFor={30}>
      <CupWorld />
    </Sequence>
    <Sequence from={696} durationInFrames={118} premountFor={30}>
      <InsightMoment />
    </Sequence>
    <Sequence from={790} durationInFrames={110} premountFor={30}>
      <FinalLogo />
    </Sequence>
  </AbsoluteFill>
);

const CinematicPaperWorld = () => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 86);
  const slow = Math.cos(frame / 120);

  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'linear-gradient(180deg, #FFFDF7 0%, #FFF6E4 58%, #F4E2C0 100%)',
        }}
      />
      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        style={{ position: 'absolute', inset: 0 }}
      >
        <defs>
          <pattern id="paperGridCupWow" width="86" height="86" patternUnits="userSpaceOnUse">
            <path d="M86 0H0V86" fill="none" stroke="rgba(18,49,58,.052)" strokeWidth="2" />
          </pattern>
          <pattern id="paperGrainCupWow" width="44" height="44" patternUnits="userSpaceOnUse">
            <path
              d="M4 12 C15 6 22 19 36 10 M8 34 C16 24 28 40 40 30"
              fill="none"
              stroke="rgba(122,85,48,.055)"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </pattern>
        </defs>
        <rect width={WIDTH} height={HEIGHT} fill="url(#paperGridCupWow)" opacity="0.72" />
        <rect width={WIDTH} height={HEIGHT} fill="url(#paperGrainCupWow)" opacity="0.65" />
        <path
          d="M-120 438 C120 360 296 508 502 410 C760 290 930 374 1210 276"
          fill="none"
          stroke="rgba(71,209,230,.18)"
          strokeWidth="30"
          strokeLinecap="round"
          style={{ transform: `translate(${drift * 16}px, ${slow * 10}px)` }}
        />
        <path
          d="M-100 1480 C170 1394 324 1548 552 1452 C812 1340 970 1434 1210 1332"
          fill="none"
          stroke="rgba(246,185,62,.18)"
          strokeWidth="34"
          strokeLinecap="round"
          style={{ transform: `translate(${slow * -14}px, ${drift * 14}px)` }}
        />
      </svg>
    </AbsoluteFill>
  );
};

const OpeningScan = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = fadeOut(frame, 126, 34);
  const scan = progress(frame, 30, 112);
  const cupLift = spring({
    frame: frame - 22,
    fps,
    durationInFrames: 54,
    config: { damping: 18, stiffness: 95, mass: 1.1 },
  });
  const pulse = 0.5 + 0.5 * Math.sin(frame / 7);

  return (
    <AbsoluteFill
      style={{
        opacity: out,
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 132,
          left: 76,
          right: 76,
          textAlign: 'center',
        }}
      >
        <div
          style={{
            display: 'inline-flex',
            padding: '12px 28px',
            borderRadius: 999,
            background: withAlpha(COATING, 0.14),
            color: COLORS.tealDeep,
            ...labelStyle,
            fontSize: 28,
          }}
        >
          WonderLens đang nhìn vào một vật rất quen
        </div>
        <div
          style={{
            marginTop: 28,
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 82,
            lineHeight: 0.96,
            letterSpacing: 0,
          }}
        >
          Vì sao cốc giấy
          <br />
          giữ được nước?
        </div>
      </div>

      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        style={{ position: 'absolute', inset: 0 }}
      >
        <defs>
          <filter id="openingShadow" x="-40%" y="-40%" width="180%" height="180%">
            <feDropShadow dx="0" dy="34" stdDeviation="26" floodColor="#6E552B" floodOpacity="0.24" />
          </filter>
        </defs>
        <ellipse cx="540" cy="1430" rx="340" ry="62" fill="rgba(76,54,22,.12)" />
        <g
          filter="url(#openingShadow)"
          transform={`translate(0 ${ease(cupLift, [0, 1], [90, 0])}) scale(${ease(
            cupLift,
            [0, 1],
            [0.92, 1],
          )})`}
          style={{ transformOrigin: '540px 1040px' }}
        >
          <path d={cupBodyPath} fill="#FDFBF3" stroke={INK} strokeWidth="10" />
          <path d="M270 560 C350 622 732 622 810 560" fill="none" stroke={withAlpha(COATING, 0.72)} strokeWidth="30" />
          <ellipse cx="540" cy="526" rx="316" ry="72" fill="#FFFDF7" stroke={INK} strokeWidth="10" />
          <ellipse cx="540" cy="526" rx="232" ry="42" fill={withAlpha(COATING, 0.12)} stroke={withAlpha(INK, 0.16)} strokeWidth="4" />
          <path d="M376 802 C454 850 616 868 704 816" fill="none" stroke={withAlpha(GOLD, 0.78)} strokeWidth="18" strokeLinecap="round" />
        </g>
        <g opacity={fadeIn(frame, 46, 20)}>
          <circle
            cx="540"
            cy="846"
            r={ease(scan, [0, 1], [112, 420])}
            fill="none"
            stroke={withAlpha(COATING, 0.34 + pulse * 0.18)}
            strokeWidth={ease(scan, [0, 1], [12, 4])}
          />
          <circle
            cx="540"
            cy="846"
            r={ease(scan, [0, 1], [34, 118])}
            fill="none"
            stroke={withAlpha(WHITE, 0.62)}
            strokeWidth="8"
          />
          <path
            d="M238 846H842 M540 548V1146"
            stroke={withAlpha(INK, 0.16)}
            strokeWidth="5"
            strokeLinecap="round"
            strokeDasharray="18 22"
          />
        </g>
        <g opacity={fadeIn(frame, 86, 18)}>
          <rect x="354" y="1210" width="372" height="86" rx="43" fill={INK} />
          <text
            x="540"
            y="1266"
            textAnchor="middle"
            fontFamily={BODY}
            fontWeight="800"
            fontSize="32"
            fill={WHITE}
          >
            Mở lớp bên trong
          </text>
        </g>
      </svg>
    </AbsoluteFill>
  );
};

const CupWorld = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const entrance = spring({
    frame,
    fps,
    durationInFrames: 74,
    config: { damping: 18, stiffness: 86, mass: 1.2 },
  });
  const active = getActiveStage(frame);
  const titleOut = fadeOut(frame, 48, 24);

  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          opacity: fadeIn(frame, 0, 36) * fadeOut(frame, 548, 34),
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 86,
            left: 70,
            right: 70,
            textAlign: 'center',
            opacity: titleOut,
          }}
        >
          <div
            style={{
              display: 'inline-flex',
              padding: '12px 26px',
              borderRadius: 999,
              background: withAlpha(COATING, 0.14),
              color: COLORS.tealDeep,
              ...labelStyle,
              fontSize: 28,
            }}
          >
            Khoảnh khắc WonderLens
          </div>
          <div
            style={{
              marginTop: 20,
              fontFamily: HEADING,
              fontWeight: 800,
              fontSize: 74,
              lineHeight: 0.98,
              letterSpacing: 0,
            }}
          >
            Nhìn xuyên vào
            <br />
            hành trình của cốc giấy
          </div>
        </div>
        <div
          style={{
            transform: `translateY(${ease(entrance, [0, 1], [154, 0])}px) scale(${ease(
              entrance,
              [0, 1],
              [0.72, 1],
            )})`,
            transformOrigin: '50% 59%',
            opacity: ease(entrance, [0, 1], [0, 1]),
          }}
        >
          <CupWorldSvg frame={frame} />
        </div>
        <StageReadout frame={frame} active={active} />
        <StageRail frame={frame} active={active} />
      </div>
    </AbsoluteFill>
  );
};

const CupWorldSvg = ({ frame }: { frame: number }) => {
  const s1 = between(frame, stageWindows[0][0], stageWindows[0][1], 28);
  const s2 = between(frame, stageWindows[1][0], stageWindows[1][1], 30);
  const s3 = between(frame, stageWindows[2][0], stageWindows[2][1], 30);
  const s4 = between(frame, stageWindows[3][0], stageWindows[3][1], 30);
  const s5 = between(frame, stageWindows[4][0], stageWindows[4][1], 26);
  const glow = 0.52 + Math.sin(frame / 16) * 0.12;

  return (
    <svg
      width={WIDTH}
      height={HEIGHT}
      viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
      style={{ position: 'absolute', inset: 0 }}
    >
      <defs>
        <clipPath id="cupWorldClip">
          <path d={cupBodyPath} />
        </clipPath>
        <linearGradient id="cupGlass" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FFFFFF" />
          <stop offset="62%" stopColor="#FFF8E7" />
          <stop offset="100%" stopColor="#EFE0C1" />
        </linearGradient>
        <linearGradient id="innerSky" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#EFFFF9" />
          <stop offset="44%" stopColor="#FFF8E6" />
          <stop offset="100%" stopColor="#F2DEC0" />
        </linearGradient>
        <radialGradient id="lensLight" cx="50%" cy="22%" r="72%">
          <stop offset="0%" stopColor="rgba(255,255,255,.95)" />
          <stop offset="42%" stopColor="rgba(71,209,230,.26)" />
          <stop offset="100%" stopColor="rgba(255,255,255,0)" />
        </radialGradient>
        <filter id="cupWorldShadow" x="-40%" y="-40%" width="180%" height="180%">
          <feDropShadow dx="0" dy="34" stdDeviation="28" floodColor="#68512B" floodOpacity="0.2" />
        </filter>
        <filter id="cupWorldGlow" x="-60%" y="-60%" width="220%" height="220%">
          <feDropShadow dx="0" dy="0" stdDeviation="16" floodColor="#47D1E6" floodOpacity={String(glow)} />
        </filter>
      </defs>
      <ellipse cx="540" cy="1544" rx="332" ry="76" fill="rgba(83,61,24,.12)" />
      <g filter="url(#cupWorldShadow)">
        <path d={cupBodyPath} fill="url(#innerSky)" stroke="none" />
        <g clipPath="url(#cupWorldClip)">
          <rect x="160" y="456" width="760" height="1120" fill="url(#innerSky)" />
          <WorldFlowLines frame={frame} />
          <g opacity={s1}>
            <PulpStage frame={frame} />
          </g>
          <g opacity={s2}>
            <CoatingStage frame={frame} />
          </g>
          <g opacity={s3}>
            <CutStage frame={frame} />
          </g>
          <g opacity={s4}>
            <AssemblyStage frame={frame} />
          </g>
          <g opacity={s5}>
            <WaterStage frame={frame} />
          </g>
          <rect x="170" y="446" width="740" height="330" fill="url(#lensLight)" opacity="0.72" />
        </g>
        <path d={cupBodyPath} fill="none" stroke={withAlpha(INK, 0.78)} strokeWidth="10" />
        <path d="M270 560 C356 626 724 626 810 560" fill="none" stroke={withAlpha(COATING, 0.84)} strokeWidth="32" strokeLinecap="round" />
        <ellipse cx="540" cy="526" rx="316" ry="72" fill={withAlpha(WHITE, 0.72)} stroke={INK} strokeWidth="10" />
        <ellipse cx="540" cy="526" rx="226" ry="40" fill={withAlpha(COATING, 0.1)} stroke={withAlpha(INK, 0.18)} strokeWidth="4" />
        <path
          d="M358 694 C430 734 626 742 716 694"
          fill="none"
          stroke={withAlpha(WHITE, 0.72)}
          strokeWidth="12"
          strokeLinecap="round"
        />
        <path
          d="M690 582 C650 842 646 1188 706 1442"
          fill="none"
          stroke={withAlpha(WHITE, 0.44)}
          strokeWidth="18"
          strokeLinecap="round"
        />
      </g>
    </svg>
  );
};

const WorldFlowLines = ({ frame }: { frame: number }) => {
  const offset = -frame * 4;
  return (
    <g opacity="0.66">
      {[0, 1, 2].map((i) => (
        <path
          key={i}
          d={`M${238 + i * 128} 468 C${168 + i * 92} 690 ${384 + i * 80} 804 ${294 + i * 104} 1018 C${210 + i * 108} 1220 ${456 + i * 84} 1344 ${382 + i * 110} 1540`}
          fill="none"
          stroke={i === 1 ? withAlpha(COATING, 0.38) : withAlpha(GOLD, 0.24)}
          strokeWidth={i === 1 ? 12 : 8}
          strokeLinecap="round"
          strokeDasharray="52 44"
          strokeDashoffset={offset - i * 42}
        />
      ))}
    </g>
  );
};

const PulpStage = ({ frame }: { frame: number }) => {
  const p = progress(frame, 34, 154);
  const swirl = p * 310;
  const fibers = Array.from({ length: 16 }, (_, i) => {
    const a = i * 0.72;
    const x = 540 + Math.cos(a) * (170 + (i % 4) * 22);
    const y = 980 + Math.sin(a * 1.2) * (210 + (i % 3) * 18);
    return { x, y, a, delay: i * 3 };
  });

  return (
    <g>
      <g transform={`translate(${ease(p, [0, 1], [-120, -12])} 0)`} opacity={fadeOut(frame, 118, 34)}>
        <rect x="210" y="950" width="102" height="354" rx="50" fill={WOOD} />
        <path d="M262 954 C230 840 276 748 238 642" fill="none" stroke={WOOD} strokeWidth="38" strokeLinecap="round" />
        <path d="M272 954 C318 828 446 782 464 672" fill="none" stroke={WOOD} strokeWidth="28" strokeLinecap="round" />
        {[0, 1, 2, 3, 4, 5, 6].map((i) => (
          <circle
            key={i}
            cx={288 + Math.cos(i) * 92 + i * 24}
            cy={664 + Math.sin(i * 1.4) * 96}
            r={58 + (i % 3) * 8}
            fill={i % 2 ? '#7CCB79' : LEAF}
            stroke={withAlpha(INK, 0.18)}
            strokeWidth="5"
          />
        ))}
      </g>
      <g transform={`rotate(${swirl} 540 1010)`}>
        <ellipse cx="540" cy="1010" rx={ease(p, [0, 1], [120, 286])} ry={ease(p, [0, 1], [62, 174])} fill={withAlpha(PULP, 0.26)} />
        <ellipse cx="540" cy="1010" rx={ease(p, [0, 1], [74, 170])} ry={ease(p, [0, 1], [34, 84])} fill={withAlpha(WHITE, 0.42)} />
      </g>
      {fibers.map((fiber, i) => {
        const local = progress(frame, 46 + fiber.delay, 128 + fiber.delay);
        const pullX = ease(local, [0, 1], [fiber.x, 540 + Math.cos(fiber.a + frame / 28) * 120]);
        const pullY = ease(local, [0, 1], [fiber.y - 300, 1010 + Math.sin(fiber.a + frame / 22) * 70]);
        return (
          <path
            key={i}
            d={`M${pullX - 42} ${pullY} C${pullX - 12} ${pullY - 30} ${pullX + 24} ${pullY + 28} ${pullX + 58} ${pullY - 8}`}
            fill="none"
            stroke={i % 3 === 0 ? withAlpha(LEAF, 0.84) : withAlpha(PULP, 0.86)}
            strokeWidth={8 + (i % 3) * 2}
            strokeLinecap="round"
          />
        );
      })}
      <FocusRing cx={540} cy={1010} r={ease(p, [0, 1], [180, 310])} color={LEAF} opacity={fadeIn(frame, 70, 24)} />
    </g>
  );
};

const CoatingStage = ({ frame }: { frame: number }) => {
  const p = progress(frame, 146, 272);
  const roll = frame * 3.2;
  const sheetY = ease(p, [0, 1], [1214, 860]);
  const filmX = ease(p, [0, 1], [-260, 430]);

  return (
    <g>
      <g transform={`translate(0 ${sheetY - 980})`}>
        <rect x="254" y="856" width="572" height="360" rx="38" fill="#F9F1D9" stroke={withAlpha(INK, 0.28)} strokeWidth="8" />
        {[0, 1, 2, 3, 4].map((i) => (
          <path
            key={i}
            d={`M302 ${918 + i * 56} C430 ${876 + i * 50} 558 ${974 + i * 48} 778 ${922 + i * 52}`}
            fill="none"
            stroke={withAlpha(WOOD, 0.12)}
            strokeWidth="5"
            strokeLinecap="round"
          />
        ))}
      </g>
      <g transform={`translate(0 ${ease(p, [0, 1], [70, 0])})`}>
        <circle cx="322" cy="760" r="74" fill="#D5C49E" stroke={INK} strokeWidth="8" />
        <circle cx="322" cy="760" r="30" fill={withAlpha(INK, 0.22)} />
        <circle cx="758" cy="760" r="74" fill="#D5C49E" stroke={INK} strokeWidth="8" />
        <circle cx="758" cy="760" r="30" fill={withAlpha(INK, 0.22)} />
        <path d="M322 760 H758" stroke={withAlpha(INK, 0.5)} strokeWidth="14" strokeLinecap="round" />
        <path
          d="M276 760 H804"
          stroke={withAlpha(WHITE, 0.7)}
          strokeWidth="5"
          strokeLinecap="round"
          strokeDasharray="34 24"
          strokeDashoffset={-roll}
        />
      </g>
      <rect
        x={filmX}
        y="854"
        width="420"
        height="364"
        rx="42"
        fill={withAlpha(COATING, 0.32)}
        stroke={withAlpha(COATING, 0.9)}
        strokeWidth="8"
      />
      <path
        d={`M${filmX + 30} 884 C${filmX + 150} 946 ${filmX + 230} 912 ${filmX + 386} 980`}
        stroke={withAlpha(WHITE, 0.7)}
        strokeWidth="12"
        strokeLinecap="round"
        fill="none"
      />
      <FocusRing cx={540} cy={1006} r={ease(p, [0, 1], [360, 238])} color={COATING} opacity={fadeIn(frame, 176, 18)} />
    </g>
  );
};

const CutStage = ({ frame }: { frame: number }) => {
  const p = progress(frame, 256, 392);
  const cut = progress(frame, 286, 350);
  const blankScale = ease(p, [0, 1], [0.64, 1]);
  const blankRotate = ease(p, [0, 1], [-16, 0]);
  const bladeX = ease(cut, [0, 1], [206, 824]);

  return (
    <g>
      <g transform={`translate(540 996) rotate(${blankRotate}) scale(${blankScale}) translate(-540 -996)`}>
        <path
          d="M280 830 C446 760 638 760 800 830 L742 1194 C604 1150 468 1150 332 1194 Z"
          fill="#FBF0D4"
          stroke={INK}
          strokeWidth="9"
        />
        <path
          d="M322 890 C448 840 624 840 758 890"
          fill="none"
          stroke={withAlpha(COATING, 0.72)}
          strokeWidth="26"
          strokeLinecap="round"
        />
        <path
          d="M318 1160 C462 1112 620 1112 764 1160"
          fill="none"
          stroke={withAlpha(WOOD, 0.17)}
          strokeWidth="8"
          strokeLinecap="round"
        />
        <path
          d="M280 830 C446 760 638 760 800 830 L742 1194 C604 1150 468 1150 332 1194 Z"
          fill="none"
          stroke={withAlpha(GOLD, 0.82)}
          strokeWidth="8"
          strokeDasharray="28 18"
          strokeDashoffset={-frame * 6}
        />
      </g>
      <g transform={`translate(${bladeX} 0)`} opacity={fadeIn(frame, 282, 12) * fadeOut(frame, 366, 20)}>
        <path d="M0 780 L44 846 L0 912 L-44 846 Z" fill={WHITE} stroke={INK} strokeWidth="7" />
        <path d="M-18 846 H18" stroke={HEAT} strokeWidth="8" strokeLinecap="round" />
        {[0, 1, 2, 3].map((i) => (
          <path
            key={i}
            d={`M${-42 + i * 24} ${920 + i * 24} L${-70 + i * 10} ${968 + i * 32}`}
            stroke={withAlpha(GOLD, 0.8)}
            strokeWidth="7"
            strokeLinecap="round"
          />
        ))}
      </g>
      <FocusRing cx={540} cy={998} r={ease(cut, [0, 1], [340, 248])} color={GOLD} opacity={fadeIn(frame, 296, 16)} />
    </g>
  );
};

const AssemblyStage = ({ frame }: { frame: number }) => {
  const p = progress(frame, 382, 510);
  const wrap = progress(frame, 388, 468);
  const bottom = progress(frame, 440, 510);
  const heat = progress(frame, 452, 500);
  const leftX = ease(wrap, [0, 1], [-130, 34]);
  const rightX = ease(wrap, [0, 1], [130, -34]);
  const sideOpacity = fadeIn(frame, 386, 18);

  return (
    <g>
      <g opacity={sideOpacity}>
        <path
          d="M306 710 C430 656 650 656 774 710 L718 1300 C594 1260 488 1260 362 1300 Z"
          fill="#F9EED1"
          stroke={withAlpha(INK, 0.54)}
          strokeWidth="8"
          transform={`translate(${leftX} 0) skewY(${ease(wrap, [0, 1], [8, 0])})`}
        />
        <path
          d="M306 710 C430 656 650 656 774 710 L718 1300 C594 1260 488 1260 362 1300 Z"
          fill="#FFF8DF"
          stroke={withAlpha(INK, 0.54)}
          strokeWidth="8"
          transform={`translate(${rightX} 0) skewY(${ease(wrap, [0, 1], [-8, 0])})`}
        />
        <path
          d="M540 716 C540 890 540 1116 540 1304"
          stroke={withAlpha(HEAT, fadeIn(frame, 430, 18))}
          strokeWidth="18"
          strokeLinecap="round"
          strokeDasharray="28 20"
          strokeDashoffset={-frame * 7}
        />
      </g>
      <ellipse
        cx="540"
        cy={ease(bottom, [0, 1], [1450, 1284])}
        rx={ease(bottom, [0, 1], [246, 168])}
        ry={ease(bottom, [0, 1], [58, 38])}
        fill="#F3E1B8"
        stroke={INK}
        strokeWidth="8"
      />
      <g opacity={fadeIn(frame, 448, 14)}>
        {[0, 1, 2].map((i) => (
          <path
            key={i}
            d={`M${380 + i * 100} ${1280 + Math.sin((frame + i * 12) / 10) * 8} C${450 + i * 38} ${1318} ${560 + i * 36} ${1318} ${656 + i * 24} ${1280}`}
            fill="none"
            stroke={withAlpha(HEAT, 0.34 + heat * 0.36)}
            strokeWidth="12"
            strokeLinecap="round"
          />
        ))}
      </g>
      <FocusRing cx={540} cy={1024} r={ease(p, [0, 1], [370, 262])} color={HEAT} opacity={fadeIn(frame, 424, 18)} />
    </g>
  );
};

const WaterStage = ({ frame }: { frame: number }) => {
  const p = progress(frame, 494, 604);
  const drop = progress(frame, 508, 566);
  const bounce = Math.sin(Math.min(1, drop) * Math.PI);
  const waterY = ease(drop, [0, 1], [666, 972], Easing.in(Easing.quad));
  const cupScale = ease(p, [0, 1], [0.78, 1]);

  return (
    <g>
      <g transform={`translate(540 1026) scale(${cupScale}) translate(-540 -1026)`}>
        <path d="M324 676 C438 628 642 628 756 676 L700 1334 C598 1374 484 1374 380 1334 Z" fill="#FFF8E2" stroke={INK} strokeWidth="10" />
        <path d="M368 770 C456 820 620 828 712 772" fill="none" stroke={withAlpha(COATING, 0.82)} strokeWidth="28" strokeLinecap="round" />
        <ellipse cx="540" cy="676" rx="224" ry="54" fill={WHITE} stroke={INK} strokeWidth="10" />
        <ellipse cx="540" cy="676" rx="156" ry="28" fill={withAlpha(COATING, 0.24)} stroke={withAlpha(INK, 0.18)} strokeWidth="4" />
        <ellipse cx="540" cy="1232" rx="154" ry="36" fill={withAlpha(COATING, 0.3 + p * 0.18)} stroke={withAlpha(COATING, 0.9)} strokeWidth="7" />
        <path
          d="M406 1218 C470 1190 606 1272 676 1216"
          fill="none"
          stroke={withAlpha(WHITE, 0.72)}
          strokeWidth="9"
          strokeLinecap="round"
          strokeDasharray="36 22"
          strokeDashoffset={-frame * 4}
        />
      </g>
      <g opacity={fadeIn(frame, 506, 12)}>
        <path
          d={`M540 ${waterY - 80} C594 ${waterY - 8} 584 ${waterY + 58} 540 ${waterY + 78} C496 ${waterY + 58} 486 ${waterY - 8} 540 ${waterY - 80}Z`}
          fill={withAlpha(COATING, 0.72)}
          stroke={INK}
          strokeWidth="7"
          transform={`scale(${1 + bounce * 0.06})`}
          style={{ transformOrigin: `540px ${waterY}px` }}
        />
        <circle cx="516" cy={waterY - 10} r="12" fill={withAlpha(WHITE, 0.72)} />
      </g>
      <g opacity={fadeIn(frame, 560, 18)}>
        <path
          d="M376 1228 C438 1170 650 1170 704 1228"
          fill="none"
          stroke={withAlpha(GREEN, 0.82)}
          strokeWidth="16"
          strokeLinecap="round"
          strokeDasharray="40 22"
          strokeDashoffset={-frame * 8}
        />
        <text
          x="540"
          y="1436"
          textAnchor="middle"
          fontFamily={HEADING}
          fontWeight="800"
          fontSize="58"
          fill={INK}
        >
          Giấy không rã ngay
        </text>
      </g>
      <FocusRing cx={540} cy={1030} r={ease(p, [0, 1], [382, 292])} color={GREEN} opacity={fadeIn(frame, 526, 16)} />
    </g>
  );
};

const FocusRing = ({
  cx,
  cy,
  r,
  color,
  opacity,
}: {
  cx: number;
  cy: number;
  r: number;
  color: string;
  opacity: number;
}) => (
  <g opacity={opacity}>
    <circle cx={cx} cy={cy} r={r} fill="none" stroke={withAlpha(color, 0.2)} strokeWidth="28" />
    <circle cx={cx} cy={cy} r={r - 24} fill="none" stroke={withAlpha(WHITE, 0.5)} strokeWidth="5" strokeDasharray="28 30" />
  </g>
);

const StageReadout = ({ frame, active }: { frame: number; active: number }) => {
  const stage = stages[active];
  const localStart = stageWindows[active][0];
  const inAnim = pop(frame, 30, localStart + 6, 28);
  const opacity = fadeIn(frame, 18, 24) * fadeOut(frame, 588, 28);

  return (
    <div
      style={{
        position: 'absolute',
        left: 82,
        right: 82,
        top: 296,
        display: 'flex',
        justifyContent: 'center',
        opacity,
        transform: `translateY(${ease(inAnim, [0, 1], [18, 0])}px)`,
      }}
    >
      <div
        style={{
          width: 850,
          minHeight: 142,
          borderRadius: 36,
          background: withAlpha(WHITE, 0.82),
          border: `4px solid ${withAlpha(stage.color, 0.54)}`,
          boxShadow: `0 24px 70px ${withAlpha('#70531C', 0.14)}, inset 0 0 0 2px ${withAlpha(WHITE, 0.72)}`,
          display: 'grid',
          gridTemplateColumns: '92px 1fr',
          alignItems: 'center',
          gap: 22,
          padding: '24px 30px',
          boxSizing: 'border-box',
        }}
      >
        <div
          style={{
            width: 80,
            height: 80,
            borderRadius: 26,
            background: withAlpha(stage.color, 0.14),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: stage.color,
            fontFamily: HEADING,
            fontSize: 44,
            fontWeight: 800,
            boxShadow: `inset 0 0 0 3px ${withAlpha(stage.color, 0.26)}`,
          }}
        >
          {active + 1}
        </div>
        <div>
          <div
            style={{
              fontFamily: HEADING,
              fontWeight: 800,
              fontSize: 42,
              lineHeight: 0.95,
              letterSpacing: 0,
            }}
          >
            {stage.title}
          </div>
          <div
            style={{
              marginTop: 10,
              color: MUTED,
              ...labelStyle,
              fontSize: 26,
              lineHeight: 1.1,
            }}
          >
            {stage.detail}
          </div>
        </div>
      </div>
    </div>
  );
};

const StageRail = ({ frame, active }: { frame: number; active: number }) => {
  const width = 900;
  const left = (WIDTH - width) / 2;
  const railProgress = clamp(ease(frame, [28, 584], [0, 1], Easing.linear));

  return (
    <div
      style={{
        position: 'absolute',
        left,
        bottom: 130,
        width,
        height: 142,
        borderRadius: 42,
        background: withAlpha(WHITE, 0.78),
        border: `3px solid ${withAlpha(INK, 0.1)}`,
        boxShadow: `0 22px 60px ${withAlpha('#614914', 0.12)}`,
        opacity: fadeIn(frame, 44, 24) * fadeOut(frame, 596, 24),
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 76,
          right: 76,
          top: 46,
          height: 10,
          borderRadius: 999,
          background: withAlpha(INK, 0.08),
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            width: `${railProgress * 100}%`,
            height: '100%',
            borderRadius: 999,
            background: `linear-gradient(90deg, ${LEAF}, ${COATING}, ${GOLD}, ${HEAT}, ${GREEN})`,
          }}
        />
      </div>
      {stages.map((stage, i) => {
        const x = 76 + (i / (stages.length - 1)) * (width - 152);
        const isActive = i === active;
        const scale = isActive ? 1.18 : 1;
        return (
          <div
            key={stage.short}
            style={{
              position: 'absolute',
              left: x - 74,
              top: 18,
              width: 148,
              height: 104,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'flex-start',
              transform: `scale(${scale})`,
              transformOrigin: '50% 42px',
            }}
          >
            <div
              style={{
                width: 58,
                height: 58,
                borderRadius: 24,
                background: isActive ? stage.color : WHITE,
                border: `4px solid ${stage.color}`,
                color: isActive ? WHITE : stage.color,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: HEADING,
                fontSize: 28,
                fontWeight: 800,
                boxShadow: isActive ? `0 14px 24px ${withAlpha(stage.color, 0.24)}` : 'none',
              }}
            >
              {i + 1}
            </div>
            <div
              style={{
                marginTop: 12,
                textAlign: 'center',
                ...labelStyle,
                color: isActive ? INK : withAlpha(INK, 0.52),
                fontSize: 20,
                lineHeight: 1,
              }}
            >
              {stage.short}
            </div>
          </div>
        );
      })}
    </div>
  );
};

const InsightMoment = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({
    frame,
    fps,
    durationInFrames: 48,
    config: { damping: 18, stiffness: 104, mass: 1 },
  });
  const shine = progress(frame, 42, 100);

  return (
    <AbsoluteFill style={{ opacity: fadeIn(frame, 0, 22) * fadeOut(frame, 102, 16) }}>
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: 'absolute', inset: 0 }}>
        <rect width={WIDTH} height={HEIGHT} fill={withAlpha(PAPER, 0.72)} />
        <g transform={`translate(0 ${ease(enter, [0, 1], [90, 0])}) scale(${ease(enter, [0, 1], [0.9, 1])})`} style={{ transformOrigin: '540px 940px' }}>
          <path d="M322 636 C438 590 642 590 758 636 L704 1268 C594 1310 486 1310 376 1268 Z" fill="#FFF8E2" stroke={INK} strokeWidth="10" />
          <path d="M370 744 C454 792 626 800 710 744" fill="none" stroke={withAlpha(COATING, 0.88)} strokeWidth="30" strokeLinecap="round" />
          <ellipse cx="540" cy="636" rx="228" ry="54" fill={WHITE} stroke={INK} strokeWidth="10" />
          <ellipse cx="540" cy="636" rx="156" ry="28" fill={withAlpha(COATING, 0.24)} stroke={withAlpha(INK, 0.18)} strokeWidth="4" />
          <path
            d={`M${ease(shine, [0, 1], [250, 790])} 600 L${ease(shine, [0, 1], [126, 666])} 1320`}
            stroke={withAlpha(WHITE, 0.92)}
            strokeWidth="34"
            strokeLinecap="round"
          />
        </g>
        <InsightChip x={114} y={356} color={COATING} title="Lớp phủ mỏng" body="giúp giấy chậm ngấm nước" index={1} frame={frame} delay={18} />
        <InsightChip x={566} y={1158} color={HEAT} title="Đáy ép kín" body="khóa đường rò ở dưới" index={2} frame={frame} delay={36} />
        <InsightChip x={120} y={1334} color={GREEN} title="Miệng cuộn" body="làm cốc chắc và dễ cầm" index={3} frame={frame} delay={52} />
        <path d="M356 480 C430 548 472 590 520 642" fill="none" stroke={withAlpha(COATING, 0.76)} strokeWidth="8" strokeLinecap="round" strokeDasharray="20 18" />
        <path d="M650 1208 C606 1130 586 1034 570 804" fill="none" stroke={withAlpha(HEAT, 0.68)} strokeWidth="8" strokeLinecap="round" strokeDasharray="20 18" />
        <path d="M372 1382 C422 1326 474 1288 520 1240" fill="none" stroke={withAlpha(GREEN, 0.72)} strokeWidth="8" strokeLinecap="round" strokeDasharray="20 18" />
      </svg>
      <div
        style={{
          position: 'absolute',
          top: 116,
          left: 72,
          right: 72,
          textAlign: 'center',
        }}
      >
        <div
          style={{
            fontFamily: HEADING,
            fontSize: 82,
            lineHeight: 0.92,
            fontWeight: 800,
            letterSpacing: 0,
          }}
        >
          App biến “vì sao?”
          <br />
          thành một cảnh nhìn thấy được
        </div>
      </div>
    </AbsoluteFill>
  );
};

const InsightChip = ({
  x,
  y,
  color,
  title,
  body,
  index,
  frame,
  delay,
}: {
  x: number;
  y: number;
  color: string;
  title: string;
  body: string;
  index: number;
  frame: number;
  delay: number;
}) => {
  const { fps } = useVideoConfig();
  const entrance = pop(frame, fps, delay, 26);
  return (
    <g
      opacity={fadeIn(frame, delay, 12)}
      transform={`translate(${x} ${y + ease(entrance, [0, 1], [28, 0])}) scale(${ease(entrance, [0, 1], [0.86, 1])})`}
    >
      <rect width="388" height="126" rx="34" fill={WHITE} stroke={withAlpha(color, 0.74)} strokeWidth="6" />
      <circle cx="62" cy="63" r="34" fill={color} />
      <text x="62" y="74" textAnchor="middle" fontFamily={HEADING} fontWeight="800" fontSize="32" fill={WHITE}>
        {index}
      </text>
      <text x="116" y="54" fontFamily={HEADING} fontWeight="800" fontSize="31" fill={INK}>
        {title}
      </text>
      <text x="116" y="90" fontFamily={BODY} fontWeight="800" fontSize="21" fill={MUTED}>
        {body}
      </text>
    </g>
  );
};

const FinalLogo = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const lens = spring({
    frame: frame - 4,
    fps,
    durationInFrames: 44,
    config: { damping: 16, stiffness: 160, mass: 0.9 },
  });
  const word = fadeIn(frame, 20, 24);

  return (
    <AbsoluteFill style={{ opacity: fadeIn(frame, 0, 18) }}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(circle at 50% 35%, ${withAlpha(WHITE, 0.92)}, ${withAlpha(PAPER, 0.66)} 42%, ${withAlpha(PAPER_DEEP, 0.46)} 100%)`,
        }}
      />
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: 'absolute', inset: 0 }}>
        {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
          const angle = (i / 8) * Math.PI * 2 + frame / 110;
          const r = 360 + Math.sin(frame / 18 + i) * 28;
          return (
            <path
              key={i}
              d={`M540 690 L${540 + Math.cos(angle) * r} ${690 + Math.sin(angle) * r}`}
              stroke={withAlpha(i % 2 ? GOLD : COATING, 0.32)}
              strokeWidth="7"
              strokeLinecap="round"
            />
          );
        })}
        <g transform={`translate(540 690) scale(${ease(lens, [0, 1], [0.65, 1])}) translate(-540 -690)`}>
          <circle cx="540" cy="690" r="126" fill={COATING} stroke={INK} strokeWidth="10" />
          <circle cx="540" cy="690" r="72" fill={WHITE} stroke={INK} strokeWidth="9" />
          <circle cx="560" cy="670" r="28" fill={withAlpha(COATING, 0.65)} />
          <path d="M624 780 L732 888" stroke={INK} strokeWidth="24" strokeLinecap="round" />
          <path d="M624 780 L732 888" stroke={COATING} strokeWidth="10" strokeLinecap="round" />
        </g>
      </svg>
      <div
        style={{
          position: 'absolute',
          top: 876,
          left: 80,
          right: 80,
          textAlign: 'center',
          opacity: word,
          transform: `translateY(${ease(word, [0, 1], [24, 0])}px)`,
        }}
      >
        <div
          style={{
            fontFamily: HEADING,
            fontSize: 96,
            lineHeight: 0.9,
            fontWeight: 800,
            letterSpacing: 0,
          }}
        >
          WonderLens
        </div>
        <div
          style={{
            marginTop: 18,
            color: MUTED,
            ...labelStyle,
            fontSize: 34,
          }}
        >
          Chụp đồ vật. Mở chuyến phiêu lưu bên trong.
        </div>
        <div
          style={{
            margin: '42px auto 0',
            width: 370,
            height: 74,
            borderRadius: 999,
            background: INK,
            color: WHITE,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: BODY,
            fontWeight: 800,
            fontSize: 26,
            boxShadow: `0 20px 44px ${withAlpha(INK, 0.24)}`,
          }}
        >
          Cup Explorer unlocked
        </div>
      </div>
    </AbsoluteFill>
  );
};
