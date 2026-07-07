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
import { COLORS, HEIGHT, WIDTH, withAlpha } from './theme';

export const CUP_UI_DURATION_IN_FRAMES = 28 * 30;

const INK = '#14313A';
const TEXT = '#1D3B44';
const MUTED = '#617780';
const SURFACE = '#FFFDF7';
const TABLE = '#F5E5C8';
const TABLE_DARK = '#DCC59E';
const TEAL = '#26C6DA';
const TEAL_DARK = '#0E97AD';
const GOLD = '#F2B441';
const GREEN = '#3ABF7C';
const CORAL = '#FF7668';
const PAPER = '#F8EFD7';
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
    config: { damping: 18, stiffness: 170, mass: 0.9 },
  });

const labelStyle: CSSProperties = {
  fontFamily: BODY,
  fontWeight: 800,
  letterSpacing: 0,
};

export const WonderLensCupUiPromo = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill
      style={{
        background: TABLE,
        color: INK,
        fontFamily: BODY,
        overflow: 'hidden',
      }}
    >
      <DeskBackground />
      <Sequence from={0} durationInFrames={210} premountFor={20}>
        <RealObjectMoment />
      </Sequence>
      <Sequence from={92} durationInFrames={640} premountFor={30}>
        <PhoneShowcase globalFrame={frame} />
      </Sequence>
      <Sequence from={700} durationInFrames={140} premountFor={30}>
        <FinalMark />
      </Sequence>
    </AbsoluteFill>
  );
};

const DeskBackground = () => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 92);
  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(circle at 22% 12%, rgba(255,255,255,.72), transparent 24%), radial-gradient(circle at 86% 6%, rgba(38,198,218,.16), transparent 26%), linear-gradient(180deg, #FFF9EA 0%, #F6E5C5 70%, #EBD3AA 100%)',
        }}
      />
      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        style={{ position: 'absolute', inset: 0 }}
      >
        <defs>
          <pattern id="cupUiWood" width="108" height="108" patternUnits="userSpaceOnUse">
            <path
              d="M0 24 C30 10 66 38 108 22 M0 78 C38 60 72 94 108 72"
              fill="none"
              stroke="rgba(97,71,30,.07)"
              strokeWidth="3"
              strokeLinecap="round"
            />
          </pattern>
        </defs>
        <rect width={WIDTH} height={HEIGHT} fill="url(#cupUiWood)" opacity="0.75" />
        <path
          d="M-120 420 C160 354 292 502 540 412 C780 326 934 368 1210 292"
          fill="none"
          stroke="rgba(38,198,218,.16)"
          strokeWidth="34"
          strokeLinecap="round"
          style={{ transform: `translate(${drift * 18}px, ${Math.cos(frame / 120) * 10}px)` }}
        />
      </svg>
    </AbsoluteFill>
  );
};

const RealObjectMoment = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = fadeOut(frame, 122, 30);
  const cup = spring({
    frame: frame - 10,
    fps,
    durationInFrames: 52,
    config: { damping: 18, stiffness: 96, mass: 1.1 },
  });
  const scan = progress(frame, 58, 138);
  const shimmer = 0.5 + Math.sin(frame / 7) * 0.5;

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <div
        style={{
          position: 'absolute',
          top: 110,
          left: 76,
          right: 76,
        }}
      >
        <div
          style={{
            ...labelStyle,
            fontSize: 26,
            color: TEAL_DARK,
          }}
        >
          WonderLens nhận ra đồ vật thật
        </div>
        <div
          style={{
            marginTop: 16,
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 78,
            lineHeight: 0.94,
            letterSpacing: 0,
          }}
        >
          Cốc giấy này
          <br />
          có bí mật gì?
        </div>
      </div>
      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        style={{ position: 'absolute', inset: 0 }}
      >
        <ellipse cx="540" cy="1396" rx="306" ry="72" fill="rgba(80,55,20,.15)" />
        <g
          transform={`translate(0 ${ease(cup, [0, 1], [70, 0])}) scale(${ease(cup, [0, 1], [0.92, 1])})`}
          style={{ transformOrigin: '540px 1020px' }}
        >
          <PaperCupSvg x={294} y={474} scale={1.08} />
        </g>
        <g opacity={fadeIn(frame, 48, 18)}>
          <rect
            x="222"
            y="446"
            width="636"
            height="770"
            rx="54"
            fill="none"
            stroke={withAlpha(WHITE, 0.7)}
            strokeWidth="5"
            strokeDasharray="28 22"
          />
          <rect
            x="222"
            y={446 + scan * 720}
            width="636"
            height="46"
            rx="23"
            fill={withAlpha(TEAL, 0.16 + shimmer * 0.18)}
          />
          <ScanCorner x={222} y={446} />
          <ScanCorner x={858} y={446} flipX />
          <ScanCorner x={222} y={1216} flipY />
          <ScanCorner x={858} y={1216} flipX flipY />
        </g>
        <g opacity={fadeIn(frame, 108, 18)}>
          <rect x="324" y="1276" width="432" height="86" rx="43" fill={INK} />
          <text x="540" y="1332" textAnchor="middle" fontFamily={BODY} fontWeight="800" fontSize="31" fill={WHITE}>
            Tạo story từ vật này
          </text>
        </g>
      </svg>
    </AbsoluteFill>
  );
};

const ScanCorner = ({
  x,
  y,
  flipX = false,
  flipY = false,
}: {
  x: number;
  y: number;
  flipX?: boolean;
  flipY?: boolean;
}) => (
  <g transform={`translate(${x} ${y}) scale(${flipX ? -1 : 1} ${flipY ? -1 : 1})`}>
    <path d="M0 78 V24 C0 10 10 0 24 0 H78" fill="none" stroke={TEAL} strokeWidth="12" strokeLinecap="round" />
  </g>
);

const PhoneShowcase = ({ globalFrame }: { globalFrame: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({
    frame,
    fps,
    durationInFrames: 56,
    config: { damping: 18, stiffness: 96, mass: 1.05 },
  });
  const phase = globalFrame < 238 ? 'camera' : globalFrame < 520 ? 'story' : 'detail';
  const tilt = ease(frame, [0, 88], [6, 0], Easing.out(Easing.cubic));
  const y = ease(enter, [0, 1], [250, 0]);
  const scale = ease(enter, [0, 1], [0.78, 1]);

  return (
    <AbsoluteFill
      style={{
        opacity: fadeIn(frame, 0, 26) * fadeOut(frame, 610, 36),
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 110,
          left: 0,
          width: WIDTH,
          display: 'flex',
          justifyContent: 'center',
          transform: `translateY(${y}px) rotate(${tilt}deg) scale(${scale})`,
          transformOrigin: '50% 75%',
        }}
      >
        <PremiumPhone>
          <PhoneScreen phase={phase} frame={globalFrame} />
        </PremiumPhone>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 78,
          right: 78,
          bottom: 112,
          opacity: between(globalFrame, 250, 676, 30),
        }}
      >
        <PromoCaption frame={globalFrame} />
      </div>
    </AbsoluteFill>
  );
};

const PremiumPhone = ({ children }: { children: ReactNode }) => (
  <div
    style={{
      width: 748,
      height: 1518,
      borderRadius: 82,
      padding: 18,
      background: 'linear-gradient(145deg, #1B333B 0%, #071418 100%)',
      boxSizing: 'border-box',
      boxShadow: `0 70px 120px ${withAlpha('#4E3211', 0.28)}, inset 0 0 0 2px ${withAlpha(WHITE, 0.08)}`,
      position: 'relative',
    }}
  >
    <div
      style={{
        width: '100%',
        height: '100%',
        borderRadius: 66,
        overflow: 'hidden',
        position: 'relative',
        background: SURFACE,
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
        background: '#071418',
        boxShadow: `inset 0 0 0 2px ${withAlpha(WHITE, 0.06)}`,
      }}
    />
  </div>
);

const PhoneScreen = ({ phase, frame }: { phase: 'camera' | 'story' | 'detail'; frame: number }) => {
  const cameraOpacity = phase === 'camera' ? 1 : fadeOut(frame, 210, 22);
  const storyOpacity = phase === 'story' ? fadeIn(frame, 222, 24) : phase === 'detail' ? fadeOut(frame, 516, 22) : 0;
  const detailOpacity = phase === 'detail' ? fadeIn(frame, 516, 24) : 0;

  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'linear-gradient(180deg, #FFFDF8 0%, #F7F0DF 54%, #EFE1C6 100%)',
        }}
      />
      <div style={{ opacity: cameraOpacity, position: 'absolute', inset: 0 }}>
        <CameraUi frame={frame} />
      </div>
      <div style={{ opacity: storyOpacity, position: 'absolute', inset: 0 }}>
        <StoryBoardUi frame={frame} />
      </div>
      <div style={{ opacity: detailOpacity, position: 'absolute', inset: 0 }}>
        <DetailUi frame={frame} />
      </div>
    </div>
  );
};

const StatusBar = ({ dark = true }: { dark?: boolean }) => (
  <div
    style={{
      position: 'absolute',
      top: 26,
      left: 32,
      right: 32,
      height: 30,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      color: dark ? INK : WHITE,
      ...labelStyle,
      fontSize: 20,
      zIndex: 20,
    }}
  >
    <span>9:41</span>
    <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
      <div style={{ width: 28, height: 13, borderRadius: 4, border: `2px solid ${dark ? INK : WHITE}` }} />
      <div style={{ width: 4, height: 8, borderRadius: 2, background: dark ? INK : WHITE }} />
    </div>
  </div>
);

const CameraUi = ({ frame }: { frame: number }) => {
  const scan = progress(frame, 120, 208);
  const found = fadeIn(frame, 172, 18);
  const pulse = 0.5 + Math.sin(frame / 6) * 0.5;

  return (
    <>
      <StatusBar dark={false} />
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(circle at 50% 34%, rgba(255,255,255,.12), transparent 32%), linear-gradient(180deg, #203A42 0%, #314C51 45%, #D9C49D 100%)',
        }}
      />
      <svg width="100%" height="100%" viewBox="0 0 712 1482" style={{ position: 'absolute', inset: 0 }}>
        <ellipse cx="356" cy="1038" rx="238" ry="48" fill="rgba(0,0,0,.18)" />
        <PaperCupSvg x={178} y={390} scale={0.64} />
        <rect x="86" y="302" width="540" height="690" rx="40" fill="none" stroke="rgba(255,255,255,.44)" strokeWidth="4" strokeDasharray="26 18" />
        <rect x="112" y={326 + scan * 610} width="488" height="38" rx="19" fill={`rgba(38,198,218,${0.18 + pulse * 0.16})`} />
        <path d="M94 390 V326 C94 312 104 302 118 302 H182" fill="none" stroke={TEAL} strokeWidth="8" strokeLinecap="round" />
        <path d="M618 390 V326 C618 312 608 302 594 302 H530" fill="none" stroke={TEAL} strokeWidth="8" strokeLinecap="round" />
        <path d="M94 904 V968 C94 982 104 992 118 992 H182" fill="none" stroke={TEAL} strokeWidth="8" strokeLinecap="round" />
        <path d="M618 904 V968 C618 982 608 992 594 992 H530" fill="none" stroke={TEAL} strokeWidth="8" strokeLinecap="round" />
      </svg>
      <div
        style={{
          position: 'absolute',
          top: 84,
          left: 28,
          right: 28,
          height: 56,
          borderRadius: 28,
          background: withAlpha('#071418', 0.32),
          color: WHITE,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 18px',
          boxSizing: 'border-box',
          backdropFilter: 'blur(14px)',
        }}
      >
        <span style={{ ...labelStyle, fontSize: 22 }}>WonderLens Camera</span>
        <span style={{ ...labelStyle, color: withAlpha(WHITE, 0.74), fontSize: 18 }}>kid-safe</span>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 42,
          right: 42,
          bottom: 44,
          height: 224,
          borderRadius: 42,
          background: withAlpha(WHITE, 0.92),
          boxShadow: `0 24px 60px ${withAlpha('#09191D', 0.28)}`,
          border: `1px solid ${withAlpha(WHITE, 0.74)}`,
          padding: 24,
          boxSizing: 'border-box',
          transform: `translateY(${ease(found, [0, 1], [86, 0])}px)`,
          opacity: found,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          <div
            style={{
              width: 70,
              height: 70,
              borderRadius: 24,
              background: withAlpha(TEAL, 0.15),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <SmallCupIcon />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: HEADING, fontSize: 34, fontWeight: 800, lineHeight: 0.95 }}>
              Cốc giấy
            </div>
            <div style={{ ...labelStyle, fontSize: 21, color: MUTED, marginTop: 6 }}>
              3 bí mật giúp giấy giữ nước
            </div>
          </div>
          <div
            style={{
              width: 84,
              height: 46,
              borderRadius: 23,
              background: INK,
              color: WHITE,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              ...labelStyle,
              fontSize: 18,
            }}
          >
            Mở
          </div>
        </div>
        <div
          style={{
            marginTop: 22,
            height: 12,
            borderRadius: 999,
            background: withAlpha(INK, 0.08),
            overflow: 'hidden',
          }}
        >
          <div
            style={{
              width: `${ease(frame, [180, 218], [18, 100])}%`,
              height: '100%',
              borderRadius: 999,
              background: `linear-gradient(90deg, ${TEAL}, ${GOLD})`,
            }}
          />
        </div>
      </div>
    </>
  );
};

const StoryBoardUi = ({ frame }: { frame: number }) => {
  const { fps } = useVideoConfig();
  const hero = pop(frame, fps, 232, 34);
  const cards = [
    { title: 'Lớp phủ mỏng', body: 'Giấy chậm ngấm nước', color: TEAL, delay: 284 },
    { title: 'Thân cốc cuốn', body: 'Tấm giấy ôm thành hình', color: GOLD, delay: 318 },
    { title: 'Đáy ép nhiệt', body: 'Khóa điểm dễ rò nhất', color: CORAL, delay: 352 },
  ];

  return (
    <>
      <StatusBar />
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'linear-gradient(180deg, #FFFDF8 0%, #F8F1E1 100%)',
        }}
      />
      <TopNav title="Hành trình đồ vật" />
      <div
        style={{
          position: 'absolute',
          top: 128,
          left: 30,
          right: 30,
          height: 282,
          borderRadius: 42,
          background: 'linear-gradient(145deg, #16323A 0%, #0F252B 100%)',
          color: WHITE,
          padding: '32px 34px',
          boxSizing: 'border-box',
          overflow: 'hidden',
          boxShadow: `0 22px 55px ${withAlpha('#10262C', 0.22)}`,
          transform: `translateY(${ease(hero, [0, 1], [42, 0])}px) scale(${ease(hero, [0, 1], [0.96, 1])})`,
          opacity: ease(hero, [0, 1], [0, 1]),
        }}
      >
        <div
          style={{
            position: 'absolute',
            width: 320,
            height: 320,
            borderRadius: '50%',
            right: -88,
            top: -86,
            background: withAlpha(TEAL, 0.24),
          }}
        />
        <div style={{ ...labelStyle, fontSize: 20, color: withAlpha(WHITE, 0.68) }}>
          WonderLens tạo story
        </div>
        <div
          style={{
            marginTop: 12,
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 54,
            lineHeight: 0.92,
            letterSpacing: 0,
            maxWidth: 430,
          }}
        >
          Vì sao cốc giấy giữ được nước?
        </div>
        <div
          style={{
            marginTop: 22,
            display: 'inline-flex',
            gap: 8,
            alignItems: 'center',
            padding: '10px 16px',
            borderRadius: 18,
            background: withAlpha(WHITE, 0.12),
            ...labelStyle,
            fontSize: 18,
          }}
        >
          <span style={{ width: 10, height: 10, borderRadius: '50%', background: GREEN }} />
          phù hợp trẻ 6-10 tuổi
        </div>
        <div style={{ position: 'absolute', right: 28, bottom: 22, transform: 'scale(.58)' }}>
          <PaperCupSvg x={0} y={0} scale={1} />
        </div>
      </div>

      <div style={{ position: 'absolute', top: 444, left: 30, right: 30 }}>
        <LayerDiagram frame={frame} />
      </div>

      <div
        style={{
          position: 'absolute',
          left: 30,
          right: 30,
          bottom: 48,
          display: 'grid',
          gap: 14,
        }}
      >
        {cards.map((card, index) => (
          <StoryCard
            key={card.title}
            index={index + 1}
            title={card.title}
            body={card.body}
            color={card.color}
            frame={frame}
            delay={card.delay}
          />
        ))}
      </div>
    </>
  );
};

const DetailUi = ({ frame }: { frame: number }) => {
  const { fps } = useVideoConfig();
  const sheet = pop(frame, fps, 532, 36);
  const answer = pop(frame, fps, 584, 34);
  const badge = pop(frame, fps, 634, 34);

  return (
    <>
      <StatusBar />
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: 'linear-gradient(180deg, #FFFDF8 0%, #F4E7CD 100%)',
        }}
      />
      <TopNav title="Cốc giấy" />
      <div
        style={{
          position: 'absolute',
          top: 122,
          left: 30,
          right: 30,
          height: 602,
          borderRadius: 46,
          background: WHITE,
          boxShadow: `0 26px 70px ${withAlpha('#6A4D19', 0.16)}`,
          overflow: 'hidden',
          border: `1px solid ${withAlpha(INK, 0.08)}`,
        }}
      >
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background:
              'radial-gradient(circle at 50% 26%, rgba(38,198,218,.18), transparent 40%)',
          }}
        />
        <svg width="100%" height="100%" viewBox="0 0 652 602" style={{ position: 'absolute', inset: 0 }}>
          <g transform="translate(196 82) scale(.72)">
            <PaperCupSvg x={0} y={0} scale={1} />
          </g>
          <path d="M178 188 C260 254 382 254 472 188" stroke={TEAL} strokeWidth="16" strokeLinecap="round" fill="none" />
          <path d="M164 498 C266 556 390 556 494 500" stroke={CORAL} strokeWidth="14" strokeLinecap="round" strokeDasharray="22 18" fill="none" />
          <path d="M156 208 C86 260 74 326 104 398" stroke={GREEN} strokeWidth="10" strokeLinecap="round" strokeDasharray="18 16" fill="none" />
        </svg>
        <CalloutBubble x={36} y={84} color={TEAL} label="lớp phủ" />
        <CalloutBubble x={360} y={434} color={CORAL} label="đáy ép kín" />
        <CalloutBubble x={34} y={424} color={GREEN} label="vành cuộn" />
      </div>

      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: 684,
          borderTopLeftRadius: 54,
          borderTopRightRadius: 54,
          background: withAlpha(WHITE, 0.96),
          boxShadow: `0 -28px 70px ${withAlpha('#6A4D19', 0.2)}`,
          padding: '28px 34px',
          boxSizing: 'border-box',
          transform: `translateY(${ease(sheet, [0, 1], [260, 0])}px)`,
        }}
      >
        <div
          style={{
            width: 82,
            height: 7,
            borderRadius: 999,
            background: withAlpha(INK, 0.16),
            margin: '0 auto 30px',
          }}
        />
        <div
          style={{
            ...labelStyle,
            color: TEAL_DARK,
            fontSize: 22,
          }}
        >
          Câu trả lời của WonderLens
        </div>
        <div
          style={{
            marginTop: 12,
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 52,
            lineHeight: 0.95,
            letterSpacing: 0,
          }}
        >
          Giấy không tự giữ nước.
          <br />
          Nó được “mặc áo”.
        </div>
        <div
          style={{
            marginTop: 24,
            borderRadius: 34,
            background: '#F7FBFA',
            border: `2px solid ${withAlpha(TEAL, 0.22)}`,
            padding: 24,
            boxSizing: 'border-box',
            opacity: fadeIn(frame, 574, 16),
            transform: `translateY(${ease(answer, [0, 1], [28, 0])}px)`,
          }}
        >
          <div style={{ ...labelStyle, color: TEXT, fontSize: 28, lineHeight: 1.18 }}>
            Một lớp phủ rất mỏng làm nước chậm thấm vào giấy. Đáy cốc được ép kín để nước không rò ra ngoài.
          </div>
        </div>
        <div
          style={{
            marginTop: 24,
            display: 'flex',
            gap: 14,
            opacity: fadeIn(frame, 624, 16),
            transform: `translateY(${ease(badge, [0, 1], [24, 0])}px)`,
          }}
        >
          <MiniAction color={INK} label="Nghe kể" />
          <MiniAction color={GOLD} label="Lưu huy hiệu" darkText />
        </div>
      </div>
    </>
  );
};

const TopNav = ({ title }: { title: string }) => (
  <div
    style={{
      position: 'absolute',
      top: 70,
      left: 30,
      right: 30,
      height: 46,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      zIndex: 10,
    }}
  >
    <div
      style={{
        width: 46,
        height: 46,
        borderRadius: 18,
        background: withAlpha(INK, 0.07),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <svg width="20" height="20" viewBox="0 0 20 20">
        <path d="M12.5 4 L6.5 10 L12.5 16" fill="none" stroke={INK} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </div>
    <div style={{ ...labelStyle, fontSize: 23, color: TEXT }}>{title}</div>
    <div
      style={{
        width: 46,
        height: 46,
        borderRadius: 18,
        background: withAlpha(TEAL, 0.13),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <svg width="21" height="21" viewBox="0 0 21 21">
        <circle cx="9" cy="9" r="6" fill="none" stroke={TEAL_DARK} strokeWidth="3" />
        <path d="M14 14 L19 19" stroke={TEAL_DARK} strokeWidth="3" strokeLinecap="round" />
      </svg>
    </div>
  </div>
);

const LayerDiagram = ({ frame }: { frame: number }) => {
  const diagram = pop(frame, 30, 260, 34);
  const shine = progress(frame, 292, 410);

  return (
    <div
      style={{
        height: 402,
        borderRadius: 42,
        background: withAlpha(WHITE, 0.92),
        boxShadow: `0 20px 60px ${withAlpha('#6A4D19', 0.14)}`,
        border: `1px solid ${withAlpha(INK, 0.08)}`,
        overflow: 'hidden',
        position: 'relative',
        transform: `translateY(${ease(diagram, [0, 1], [46, 0])}px)`,
        opacity: ease(diagram, [0, 1], [0, 1]),
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 22,
          left: 24,
          right: 24,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <div style={{ fontFamily: HEADING, fontSize: 34, fontWeight: 800, lineHeight: 0.95 }}>
          Story board
        </div>
        <div
          style={{
            padding: '9px 14px',
            borderRadius: 16,
            background: withAlpha(GREEN, 0.13),
            color: '#1F8E5C',
            ...labelStyle,
            fontSize: 17,
          }}
        >
          đã tạo
        </div>
      </div>
      <svg width="100%" height="100%" viewBox="0 0 652 402" style={{ position: 'absolute', inset: 0 }}>
        <g transform="translate(52 94)">
          <rect x="0" y="36" width="548" height="220" rx="34" fill="#FFF7DF" stroke={withAlpha(INK, 0.14)} strokeWidth="3" />
          <rect x="34" y="72" width="480" height="28" rx="14" fill={withAlpha(TEAL, 0.2)} />
          <rect x="34" y="126" width="480" height="28" rx="14" fill={withAlpha(GOLD, 0.22)} />
          <rect x="34" y="180" width="480" height="28" rx="14" fill={withAlpha(CORAL, 0.18)} />
          <path
            d={`M${ease(shine, [0, 1], [30, 520])} 50 L${ease(shine, [0, 1], [-120, 370])} 250`}
            stroke={withAlpha(WHITE, 0.82)}
            strokeWidth="34"
            strokeLinecap="round"
          />
        </g>
        <path d="M122 330 C238 286 420 286 538 330" fill="none" stroke={withAlpha(INK, 0.22)} strokeWidth="6" strokeLinecap="round" />
      </svg>
      <div
        style={{
          position: 'absolute',
          left: 26,
          right: 26,
          bottom: 22,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr 1fr',
          gap: 10,
        }}
      >
        <LayerPill label="phủ" color={TEAL} />
        <LayerPill label="cuốn" color={GOLD} />
        <LayerPill label="ép" color={CORAL} />
      </div>
    </div>
  );
};

const LayerPill = ({ label, color }: { label: string; color: string }) => (
  <div
    style={{
      height: 50,
      borderRadius: 18,
      background: withAlpha(color, 0.13),
      color,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      ...labelStyle,
      fontSize: 19,
    }}
  >
    {label}
  </div>
);

const StoryCard = ({
  index,
  title,
  body,
  color,
  frame,
  delay,
}: {
  index: number;
  title: string;
  body: string;
  color: string;
  frame: number;
  delay: number;
}) => {
  const { fps } = useVideoConfig();
  const entrance = pop(frame, fps, delay, 30);

  return (
    <div
      style={{
        minHeight: 112,
        borderRadius: 32,
        background: WHITE,
        border: `1px solid ${withAlpha(INK, 0.08)}`,
        boxShadow: `0 18px 46px ${withAlpha('#6A4D19', 0.1)}`,
        display: 'grid',
        gridTemplateColumns: '76px 1fr 34px',
        alignItems: 'center',
        gap: 16,
        padding: '18px 22px',
        boxSizing: 'border-box',
        opacity: fadeIn(frame, delay, 16),
        transform: `translateY(${ease(entrance, [0, 1], [36, 0])}px)`,
      }}
    >
      <div
        style={{
          width: 64,
          height: 64,
          borderRadius: 24,
          background: withAlpha(color, 0.14),
          color,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: HEADING,
          fontWeight: 800,
          fontSize: 34,
        }}
      >
        {index}
      </div>
      <div>
        <div style={{ fontFamily: HEADING, fontSize: 31, fontWeight: 800, lineHeight: 0.95 }}>
          {title}
        </div>
        <div style={{ ...labelStyle, color: MUTED, fontSize: 20, marginTop: 5 }}>{body}</div>
      </div>
      <svg width="28" height="28" viewBox="0 0 28 28">
        <path d="M10 6 L18 14 L10 22" fill="none" stroke={withAlpha(INK, 0.36)} strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </div>
  );
};

const CalloutBubble = ({ x, y, color, label }: { x: number; y: number; color: string; label: string }) => (
  <div
    style={{
      position: 'absolute',
      left: x,
      top: y,
      padding: '12px 17px',
      borderRadius: 22,
      background: WHITE,
      border: `3px solid ${withAlpha(color, 0.78)}`,
      boxShadow: `0 14px 30px ${withAlpha('#6A4D19', 0.12)}`,
      color,
      ...labelStyle,
      fontSize: 19,
    }}
  >
    {label}
  </div>
);

const MiniAction = ({ color, label, darkText = false }: { color: string; label: string; darkText?: boolean }) => (
  <div
    style={{
      flex: 1,
      height: 72,
      borderRadius: 28,
      background: color,
      color: darkText ? INK : WHITE,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      ...labelStyle,
      fontSize: 23,
      boxShadow: `0 16px 34px ${withAlpha(color, 0.22)}`,
    }}
  >
    {label}
  </div>
);

const PromoCaption = ({ frame }: { frame: number }) => {
  const text =
    frame < 430
      ? 'Không cần giải thích dài. WonderLens biến vật thật thành một màn hình học được ngay.'
      : 'Ít chữ hơn, nhiều tương tác hơn: trẻ thấy lý do, chạm vào từng bí mật và nhớ lâu hơn.';

  return (
    <div
      style={{
        borderRadius: 34,
        background: withAlpha(WHITE, 0.82),
        border: `1px solid ${withAlpha(INK, 0.08)}`,
        boxShadow: `0 18px 46px ${withAlpha('#6A4D19', 0.12)}`,
        padding: '22px 26px',
        boxSizing: 'border-box',
        textAlign: 'center',
        color: TEXT,
        ...labelStyle,
        fontSize: 28,
        lineHeight: 1.15,
      }}
    >
      {text}
    </div>
  );
};

const FinalMark = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const mark = spring({
    frame,
    fps,
    durationInFrames: 42,
    config: { damping: 18, stiffness: 160, mass: 0.9 },
  });

  return (
    <AbsoluteFill style={{ opacity: fadeIn(frame, 0, 22) }}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(circle at 50% 32%, ${withAlpha(WHITE, 0.92)}, ${withAlpha(TABLE, 0.72)} 54%, ${withAlpha(TABLE_DARK, 0.52)} 100%)`,
        }}
      />
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: 'absolute', inset: 0 }}>
        {[0, 1, 2, 3, 4, 5].map((i) => {
          const angle = (i / 6) * Math.PI * 2 + frame / 92;
          const r = 300 + Math.sin(frame / 16 + i) * 24;
          return (
            <path
              key={i}
              d={`M540 650 L${540 + Math.cos(angle) * r} ${650 + Math.sin(angle) * r}`}
              stroke={withAlpha(i % 2 ? GOLD : TEAL, 0.34)}
              strokeWidth="7"
              strokeLinecap="round"
            />
          );
        })}
        <g transform={`translate(540 650) scale(${ease(mark, [0, 1], [0.66, 1])}) translate(-540 -650)`}>
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
          left: 80,
          right: 80,
          textAlign: 'center',
          opacity: fadeIn(frame, 18, 24),
        }}
      >
        <div style={{ fontFamily: HEADING, fontSize: 98, fontWeight: 800, lineHeight: 0.9 }}>
          WonderLens
        </div>
        <div style={{ marginTop: 18, ...labelStyle, color: MUTED, fontSize: 34 }}>
          Chụp một vật. Mở ra câu chuyện của nó.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const PaperCupSvg = ({ x, y, scale = 1 }: { x: number; y: number; scale?: number }) => (
  <g transform={`translate(${x} ${y}) scale(${scale})`}>
    <defs>
      <linearGradient id="cupUiPaper" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stopColor="#FFFDF5" />
        <stop offset="58%" stopColor="#F8EFD7" />
        <stop offset="100%" stopColor="#E7D5AE" />
      </linearGradient>
      <linearGradient id="cupUiShade" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0%" stopColor="rgba(255,255,255,.72)" />
        <stop offset="56%" stopColor="rgba(255,255,255,0)" />
        <stop offset="100%" stopColor="rgba(20,49,58,.12)" />
      </linearGradient>
    </defs>
    <path d="M64 114 C88 84 344 84 368 114 L326 650 C312 700 120 700 106 650 Z" fill="url(#cupUiPaper)" stroke={INK} strokeWidth="8" />
    <path d="M64 114 C88 84 344 84 368 114 L326 650 C312 700 120 700 106 650 Z" fill="url(#cupUiShade)" />
    <ellipse cx="216" cy="114" rx="156" ry="44" fill={WHITE} stroke={INK} strokeWidth="8" />
    <ellipse cx="216" cy="114" rx="104" ry="25" fill={withAlpha(TEAL, 0.16)} stroke={withAlpha(INK, 0.18)} strokeWidth="3" />
    <path d="M110 202 C166 236 270 240 324 204" fill="none" stroke={TEAL} strokeWidth="20" strokeLinecap="round" />
    <path d="M132 560 C186 592 248 592 304 560" fill="none" stroke={withAlpha(INK, 0.2)} strokeWidth="5" strokeLinecap="round" />
    <path d="M306 178 C280 304 280 482 306 634" fill="none" stroke={withAlpha(WHITE, 0.72)} strokeWidth="15" strokeLinecap="round" />
  </g>
);

const SmallCupIcon = () => (
  <svg width="42" height="48" viewBox="0 0 42 48">
    <path d="M8 7 C11 4 31 4 34 7 L30 40 C29 44 13 44 12 40 Z" fill={PAPER} stroke={INK} strokeWidth="3" />
    <ellipse cx="21" cy="7" rx="13" ry="4" fill={WHITE} stroke={INK} strokeWidth="3" />
    <path d="M12 18 C18 21 25 21 31 18" stroke={TEAL} strokeWidth="4" strokeLinecap="round" fill="none" />
  </svg>
);
