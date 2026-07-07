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

const INK = '#17313A';
const MUTED = '#58717A';
const DESK = '#F7EFE0';
const MINT = '#BFEEDB';
const CORAL = '#FF7C74';
const BLUE = '#2F80ED';
const VIOLET = '#7C5CFF';
const GREEN = '#2FB36D';
const YELLOW = '#F5B942';
const WHITE = '#FFFFFF';

const clamp = (value: number, min = 0, max = 1) => Math.max(min, Math.min(max, value));

const fadeIn = (frame: number, from: number, duration: number) =>
  interpolate(frame, [from, from + duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.quad),
  });

const fadeOut = (frame: number, from: number, duration: number) =>
  interpolate(frame, [from, from + duration], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.in(Easing.quad),
  });

const slideY = (frame: number, from: number, duration: number, distance: number) =>
  interpolate(fadeIn(frame, from, duration), [0, 1], [distance, 0]);

const pop = (frame: number, fps: number, delay: number, stiffness = 180) =>
  spring({
    frame: frame - delay,
    fps,
    config: { damping: 16, stiffness, mass: 0.9 },
    durationInFrames: 28,
  });

const cardStyle: CSSProperties = {
  border: `3px solid ${withAlpha(INK, 0.12)}`,
  boxShadow: `0 24px 60px ${withAlpha('#3C2F1B', 0.12)}`,
  background: WHITE,
};

export const ORBIT_DURATION_IN_FRAMES = 40 * 30;

export const WonderLensOrbitPromo = () => (
  <AbsoluteFill
    style={{
      background: DESK,
      color: INK,
      fontFamily: BODY,
      overflow: 'hidden',
    }}
  >
    <PaperDesk />
    <Sequence from={0} durationInFrames={300} premountFor={20}>
      <ProductFlowScene />
    </Sequence>
    <Sequence from={270} durationInFrames={300} premountFor={30}>
      <LensPortalScene />
    </Sequence>
    <Sequence from={540} durationInFrames={270} premountFor={30}>
      <ActiveDiscoveryScene />
    </Sequence>
    <Sequence from={780} durationInFrames={330} premountFor={30}>
      <BottleMakingScene />
    </Sequence>
    <Sequence from={1080} durationInFrames={120} premountFor={30}>
      <FinalMarkScene />
    </Sequence>
  </AbsoluteFill>
);

const PaperDesk = () => {
  const frame = useCurrentFrame();
  const slow = Math.sin(frame / 45);
  const drift = Math.cos(frame / 70);

  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(circle at 18% 16%, rgba(255,255,255,.85) 0 11%, transparent 28%), radial-gradient(circle at 82% 12%, rgba(191,238,219,.55) 0 10%, transparent 30%), radial-gradient(circle at 10% 86%, rgba(255,124,116,.18) 0 14%, transparent 34%), linear-gradient(135deg, #FBF3E6, #F3E5CF)',
        }}
      />
      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        style={{ position: 'absolute', inset: 0 }}
      >
        <defs>
          <pattern id="grid" width="72" height="72" patternUnits="userSpaceOnUse">
            <path d="M 72 0 L 0 0 0 72" fill="none" stroke="rgba(23,49,58,.045)" strokeWidth="2" />
          </pattern>
          <pattern id="dots" width="34" height="34" patternUnits="userSpaceOnUse">
            <circle cx="4" cy="4" r="2" fill="rgba(23,49,58,.055)" />
          </pattern>
        </defs>
        <rect width={WIDTH} height={HEIGHT} fill="url(#grid)" opacity="0.7" />
        <rect width={WIDTH} height={HEIGHT} fill="url(#dots)" opacity="0.45" />
        <path
          d="M-120 420 C180 330 300 520 580 412 C820 318 986 262 1210 334"
          fill="none"
          stroke="rgba(38,198,218,.28)"
          strokeWidth="22"
          strokeLinecap="round"
          style={{ transform: `translate(${slow * 12}px, ${drift * 8}px)` }}
        />
        <path
          d="M-70 1390 C196 1300 402 1488 636 1388 C820 1310 936 1252 1160 1308"
          fill="none"
          stroke="rgba(255,124,116,.20)"
          strokeWidth="28"
          strokeLinecap="round"
          style={{ transform: `translate(${drift * -10}px, ${slow * 12}px)` }}
        />
      </svg>
    </AbsoluteFill>
  );
};

const SceneTitle = ({
  frame,
  kicker,
  title,
  subtitle,
  top = 124,
  align = 'center',
}: {
  frame: number;
  kicker?: string;
  title: string;
  subtitle: string;
  top?: number;
  align?: 'center' | 'left';
}) => {
  const opacity = fadeIn(frame, 4, 18);
  const y = slideY(frame, 4, 18, 22);

  return (
    <div
      style={{
        position: 'absolute',
        top,
        left: align === 'left' ? 78 : 70,
        right: 70,
        textAlign: align,
        opacity,
        transform: `translateY(${y}px)`,
      }}
    >
      {kicker ? (
        <div
          style={{
            display: 'inline-flex',
            padding: '10px 20px',
            borderRadius: 999,
            background: withAlpha(COLORS.teal, 0.16),
            color: COLORS.tealDeep,
            fontSize: 28,
            fontWeight: 900,
            letterSpacing: 0,
            marginBottom: 18,
          }}
        >
          {kicker}
        </div>
      ) : null}
      <div
        style={{
          fontFamily: HEADING,
          fontSize: 76,
          lineHeight: 0.95,
          fontWeight: 800,
          letterSpacing: 0,
        }}
      >
        {title}
      </div>
      <div
        style={{
          marginTop: 18,
          fontSize: 34,
          lineHeight: 1.18,
          fontWeight: 800,
          color: MUTED,
        }}
      >
        {subtitle}
      </div>
    </div>
  );
};

const ProductFlowScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = fadeOut(frame, 260, 30);
  const phone = interpolate(pop(frame, fps, 18, 130), [0, 1], [0.88, 1]);

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <SceneTitle
        frame={frame}
        kicker="WonderLens"
        title="App giúp trẻ khám phá đồ vật"
        subtitle="Chụp một vật thật. App kể nó được tạo ra như thế nào."
      />
      <div
        style={{
          position: 'absolute',
          left: 74,
          top: 462,
          width: 932,
          height: 1080,
          borderRadius: 58,
          ...cardStyle,
          background: `linear-gradient(180deg, ${WHITE}, #F7FFFC)`,
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 58,
            top: 58,
            width: 392,
            height: 760,
            borderRadius: 64,
            background: INK,
            boxShadow: `0 28px 70px ${withAlpha(INK, 0.18)}`,
            transform: `scale(${phone})`,
            transformOrigin: '50% 50%',
          }}
        >
          <div
            style={{
              position: 'absolute',
              inset: 18,
              borderRadius: 50,
              background: `linear-gradient(180deg, #F5FEFF, ${WHITE})`,
              overflow: 'hidden',
            }}
          >
            <div
              style={{
                position: 'absolute',
                left: 34,
                right: 34,
                top: 38,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                color: INK,
                fontWeight: 950,
                fontSize: 20,
              }}
            >
              <span>WonderLens</span>
              <span style={{ color: COLORS.tealDeep }}>98%</span>
            </div>
            <div
              style={{
                position: 'absolute',
                left: 48,
                top: 112,
                width: 260,
                height: 260,
                borderRadius: 82,
                background: withAlpha(COLORS.teal, 0.13),
                display: 'grid',
                placeItems: 'center',
              }}
            >
              <BottleIcon large />
            </div>
            <PhoneChip frame={frame} delay={70} top={420} text="Nhận ra: Chai nhựa" />
            <PhoneChip frame={frame} delay={110} top={504} text="5 chặng tạo ra vật" />
            <PhoneChip frame={frame} delay={150} top={588} text="Nghe kể + huy hiệu" />
          </div>
        </div>
        <div
          style={{
            position: 'absolute',
            left: 492,
            top: 56,
            right: 58,
            display: 'grid',
            gap: 22,
          }}
        >
          <FeatureStep
            frame={frame}
            fps={fps}
            delay={36}
            number="1"
            color={COLORS.teal}
            title="Chụp đồ vật thật"
            text="Bé dùng camera để bắt đầu từ thứ đang ở trước mặt."
            icon={<CameraGlyph />}
          />
          <FeatureStep
            frame={frame}
            fps={fps}
            delay={78}
            number="2"
            color={BLUE}
            title="App nhận ra vật"
            text="Vật quen thuộc chạy offline; vật lạ đi qua proxy an toàn."
            icon={<LensGlyph />}
          />
          <FeatureStep
            frame={frame}
            fps={fps}
            delay={122}
            number="3"
            color={CORAL}
            title="Xem hành trình tạo ra"
            text="Từng chặng vật liệu hiện bằng hình, chữ ngắn và giọng kể."
            icon={<TimelineGlyph />}
          />
          <FeatureStep
            frame={frame}
            fps={fps}
            delay={166}
            number="4"
            color={GREEN}
            title="Tương tác và sưu tập"
            text="Bé đoán, chạm, thử nghiệm nhỏ rồi lưu huy hiệu."
            icon={<BigBadge small />}
          />
        </div>
        <div
          style={{
            position: 'absolute',
            left: 72,
            right: 72,
            bottom: 62,
            padding: '24px 32px',
            borderRadius: 30,
            background: withAlpha(INK, 0.9),
            color: WHITE,
            fontSize: 30,
            lineHeight: 1.18,
            fontWeight: 900,
            textAlign: 'center',
            opacity: fadeIn(frame, 210, 24),
          }}
        >
          Điểm chính: biến đồ vật quen thuộc thành một bài học STEM ngắn, có tương tác.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const PhoneChip = ({ frame, delay, top, text }: { frame: number; delay: number; top: number; text: string }) => (
  <div
    style={{
      position: 'absolute',
      left: 40,
      right: 40,
      top,
      padding: '17px 18px',
      borderRadius: 22,
      background: WHITE,
      border: `3px solid ${withAlpha(COLORS.teal, 0.24)}`,
      boxShadow: `0 10px 24px ${withAlpha(COLORS.tealDeep, 0.09)}`,
      color: INK,
      fontSize: 21,
      lineHeight: 1.05,
      fontWeight: 950,
      opacity: fadeIn(frame, delay, 18),
      transform: `translateY(${slideY(frame, delay, 18, 16)}px)`,
    }}
  >
    {text}
  </div>
);

const FeatureStep = ({
  frame,
  fps,
  delay,
  number,
  color,
  title,
  text,
  icon,
}: {
  frame: number;
  fps: number;
  delay: number;
  number: string;
  color: string;
  title: string;
  text: string;
  icon: React.ReactNode;
}) => {
  const entrance = pop(frame, fps, delay, 140);
  const opacity = fadeIn(frame, delay, 20);

  return (
    <div
      style={{
        borderRadius: 32,
        padding: '22px 24px',
        background: WHITE,
        border: `4px solid ${withAlpha(color, 0.3)}`,
        boxShadow: `0 16px 36px ${withAlpha(color, 0.13)}`,
        display: 'flex',
        gap: 18,
        alignItems: 'center',
        opacity,
        transform: `translateY(${interpolate(entrance, [0, 1], [24, 0])}px)`,
      }}
    >
      <div
        style={{
          width: 88,
          height: 88,
          borderRadius: 26,
          background: withAlpha(color, 0.14),
          display: 'grid',
          placeItems: 'center',
          flex: '0 0 auto',
        }}
      >
        {icon}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 12,
              background: color,
              color: WHITE,
              display: 'grid',
              placeItems: 'center',
              fontFamily: HEADING,
              fontSize: 22,
              fontWeight: 900,
            }}
          >
            {number}
          </div>
          <div style={{ fontFamily: HEADING, fontSize: 31, lineHeight: 0.96, fontWeight: 800 }}>{title}</div>
        </div>
        <div style={{ color: MUTED, fontSize: 22, lineHeight: 1.15, fontWeight: 850 }}>{text}</div>
      </div>
    </div>
  );
};

const DeskMapScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = fadeOut(frame, 132, 22);
  const ringDraw = interpolate(frame, [22, 94], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  const mapScale = interpolate(pop(frame, fps, 12, 120), [0, 1], [0.92, 1]);

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <SceneTitle
        frame={frame}
        kicker="WonderLens"
        title="Mọi đồ vật đều có chuyện kể"
        subtitle="Một bàn học bình thường có thể mở ra cả bản đồ khoa học."
      />
      <div
        style={{
          position: 'absolute',
          left: 72,
          top: 430,
          width: 936,
          height: 1030,
          borderRadius: 52,
          ...cardStyle,
          background:
            'linear-gradient(180deg, rgba(255,255,255,.95), rgba(255,253,247,.92)), radial-gradient(circle at 50% 45%, rgba(38,198,218,.22), transparent 48%)',
          transform: `scale(${mapScale})`,
          transformOrigin: '50% 55%',
          overflow: 'hidden',
        }}
      >
        <svg
          width="936"
          height="1030"
          viewBox="0 0 936 1030"
          style={{ position: 'absolute', inset: 0 }}
        >
          <path
            d="M468 130 C710 184 816 356 744 548 C668 748 530 850 314 782 C138 726 82 498 176 312 C234 198 330 142 468 130Z"
            fill="rgba(191,238,219,.42)"
            stroke="rgba(23,49,58,.08)"
            strokeWidth="5"
          />
          <path
            d="M468 228 C638 262 712 388 662 526 C608 674 502 750 352 702 C230 664 190 496 256 362 C298 278 372 238 468 228Z"
            fill="none"
            stroke={withAlpha(COLORS.teal, 0.52)}
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray={`${ringDraw * 1280} 1280`}
          />
          <path
            d="M468 340 C558 360 608 430 586 504 C560 588 494 626 406 604 C330 584 308 494 348 420 C374 372 414 344 468 340Z"
            fill="none"
            stroke={withAlpha(CORAL, 0.55)}
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray={`${ringDraw * 720} 720`}
          />
          <circle cx="468" cy="484" r="110" fill="rgba(255,255,255,.84)" stroke="rgba(23,49,58,.12)" strokeWidth="5" />
          <path d="M468 384 L504 458 L586 470 L526 528 L540 612 L468 572 L396 612 L410 528 L350 470 L432 458Z" fill={YELLOW} opacity=".95" />
          <text x="468" y="496" textAnchor="middle" fontFamily={HEADING} fontSize="42" fontWeight="800" fill={INK}>
            STEM
          </text>
        </svg>
        <ObjectTile frame={frame} fps={fps} delay={18} x={86} y={128} label="Bút chì" color={YELLOW}>
          <PencilIcon />
        </ObjectTile>
        <ObjectTile frame={frame} fps={fps} delay={28} x={646} y={160} label="Pin" color={GREEN}>
          <BatteryIcon />
        </ObjectTile>
        <ObjectTile frame={frame} fps={fps} delay={38} x={104} y={714} label="Giấy nhớ" color={CORAL}>
          <StickyIcon />
        </ObjectTile>
        <ObjectTile frame={frame} fps={fps} delay={48} x={638} y={690} label="Chai nhựa" color={BLUE}>
          <BottleIcon />
        </ObjectTile>
        <div
          style={{
            position: 'absolute',
            left: 260,
            top: 780,
            width: 420,
            padding: '22px 28px',
            borderRadius: 30,
            background: withAlpha(INK, 0.88),
            color: WHITE,
            textAlign: 'center',
            fontSize: 32,
            lineHeight: 1.15,
            fontWeight: 900,
            opacity: fadeIn(frame, 62, 18),
            transform: `translateY(${slideY(frame, 62, 18, 22)}px)`,
          }}
        >
          Chọn một vật. WonderLens mở chuyện bên trong.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const ObjectTile = ({
  frame,
  fps,
  delay,
  x,
  y,
  label,
  color,
  children,
}: {
  frame: number;
  fps: number;
  delay: number;
  x: number;
  y: number;
  label: string;
  color: string;
  children: React.ReactNode;
}) => {
  const s = interpolate(pop(frame, fps, delay), [0, 1], [0.55, 1]);
  const bob = Math.sin((frame + delay) / 13) * 6;

  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y + bob,
        width: 204,
        height: 230,
        borderRadius: 34,
        background: WHITE,
        border: `4px solid ${withAlpha(color, 0.55)}`,
        boxShadow: `0 18px 36px ${withAlpha(color, 0.2)}`,
        transform: `scale(${s}) rotate(${interpolate(s, [0.55, 1], [-7, 0])}deg)`,
        opacity: fadeIn(frame, delay, 12),
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 22,
          top: 18,
          width: 160,
          height: 136,
          display: 'grid',
          placeItems: 'center',
        }}
      >
        {children}
      </div>
      <div
        style={{
          position: 'absolute',
          left: 18,
          right: 18,
          bottom: 20,
          textAlign: 'center',
          color: INK,
          fontSize: 26,
          fontWeight: 900,
        }}
      >
        {label}
      </div>
    </div>
  );
};

const LensPortalScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const inOpacity = fadeIn(frame, 0, 24);
  const outOpacity = fadeOut(frame, 260, 30);
  const portal = interpolate(pop(frame, fps, 10, 90), [0, 1], [0.72, 1]);
  const shutter = interpolate(frame, [82, 100, 122], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const flash = interpolate(frame, [100, 108, 124], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{ opacity: inOpacity * outOpacity, background: DESK }}>
      <SceneTitle
        frame={frame}
        top={118}
        title="Bước 1: chụp vật thật"
        subtitle="Camera là điểm bắt đầu. Bé không cần gõ từ khóa hay xem video có sẵn."
      />
      <div
        style={{
          position: 'absolute',
          left: 105,
          top: 466,
          width: 870,
          height: 870,
          borderRadius: 435,
          background: `radial-gradient(circle at 50% 50%, ${withAlpha(WHITE, 0.96)} 0 30%, ${withAlpha(MINT, 0.66)} 31% 56%, ${withAlpha(COLORS.teal, 0.17)} 57% 100%)`,
          boxShadow: `0 42px 90px ${withAlpha(COLORS.tealDeep, 0.2)}`,
          transform: `scale(${portal})`,
          overflow: 'hidden',
        }}
      >
        <svg width="870" height="870" viewBox="0 0 870 870" style={{ position: 'absolute', inset: 0 }}>
          <circle cx="435" cy="435" r="324" fill="none" stroke={withAlpha(COLORS.tealDeep, 0.16)} strokeWidth="20" />
          <circle cx="435" cy="435" r="230" fill="none" stroke={withAlpha(COLORS.teal, 0.38)} strokeWidth="8" strokeDasharray="28 30" />
          <g transform={`rotate(${frame * 1.2} 435 435)`}>
            <path d="M435 90 C610 100 754 226 786 396" fill="none" stroke={withAlpha(BLUE, 0.54)} strokeWidth="18" strokeLinecap="round" />
            <path d="M435 780 C260 770 116 644 84 474" fill="none" stroke={withAlpha(CORAL, 0.5)} strokeWidth="18" strokeLinecap="round" />
          </g>
          <circle cx="435" cy="435" r={120 + shutter * 75} fill="none" stroke={withAlpha(WHITE, 0.95)} strokeWidth={10 + shutter * 16} opacity={1 - shutter * 0.4} />
        </svg>
        <div
          style={{
            position: 'absolute',
            left: 292,
            top: 260,
            width: 286,
            height: 360,
            transform: `translateY(${Math.sin(frame / 16) * 8}px) rotate(${interpolate(frame, [0, 180], [-6, 4], { extrapolateRight: 'clamp' })}deg)`,
          }}
        >
          <BottleIcon large />
        </div>
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: WHITE,
            opacity: flash * 0.86,
          }}
        />
      </div>
      <div
        style={{
          position: 'absolute',
          left: 178,
          top: 1322,
          width: 724,
          borderRadius: 40,
          padding: '32px 38px',
          ...cardStyle,
          display: 'flex',
          alignItems: 'center',
          gap: 26,
          opacity: fadeIn(frame, 132, 24),
          transform: `translateY(${slideY(frame, 132, 24, 26)}px)`,
        }}
      >
        <div
          style={{
            width: 96,
            height: 96,
            borderRadius: 30,
            background: withAlpha(COLORS.teal, 0.15),
            display: 'grid',
            placeItems: 'center',
          }}
        >
          <LensGlyph />
        </div>
        <div>
          <div style={{ fontSize: 32, fontWeight: 950, color: INK }}>Nhận ra: Chai nhựa</div>
          <div style={{ marginTop: 6, fontSize: 27, fontWeight: 850, color: MUTED }}>
            Bước 2: mở hành trình vật liệu phù hợp với vật vừa chụp
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

const ActiveDiscoveryScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = fadeOut(frame, 232, 28);
  const river = interpolate(frame, [36, 210], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  return (
    <AbsoluteFill style={{ opacity: out, background: DESK }}>
      <SceneTitle
        frame={frame}
        kicker="Không chỉ xem"
        title="Bước 3: bé tham gia khám phá"
        subtitle="Không phải video thụ động: bé đoán, chạm, thử nghiệm, rồi mới nhận huy hiệu."
      />
      <div
        style={{
          position: 'absolute',
          left: 76,
          top: 434,
          width: 928,
          height: 1092,
          borderRadius: 54,
          background: `linear-gradient(180deg, ${WHITE}, #F7FBF4)`,
          border: `3px solid ${withAlpha(INK, 0.1)}`,
          boxShadow: `0 34px 80px ${withAlpha('#203B34', 0.12)}`,
          overflow: 'hidden',
        }}
      >
        <svg width="928" height="1092" viewBox="0 0 928 1092" style={{ position: 'absolute', inset: 0 }}>
          <path
            d="M142 152 C612 188 732 358 424 472 C176 564 218 722 548 724 C804 726 782 912 500 966"
            fill="none"
            stroke={withAlpha(COLORS.teal, 0.18)}
            strokeWidth="64"
            strokeLinecap="round"
          />
          <path
            d="M142 152 C612 188 732 358 424 472 C176 564 218 722 548 724 C804 726 782 912 500 966"
            fill="none"
            stroke={COLORS.teal}
            strokeWidth="15"
            strokeLinecap="round"
            strokeDasharray={`${river * 1600} 1600`}
          />
        </svg>
        <StepNode
          frame={frame}
          fps={fps}
          delay={34}
          x={80}
          y={82}
          color={VIOLET}
          index="1"
          title="Đoán trước"
          text="Vật này bắt đầu từ đâu?"
        />
        <StepNode
          frame={frame}
          fps={fps}
          delay={106}
          x={468}
          y={380}
          color={CORAL}
          index="2"
          title="Chạm để biến đổi"
          text="Vuốt để thấy vật liệu đổi hình."
        />
        <StepNode
          frame={frame}
          fps={fps}
          delay={174}
          x={148}
          y={748}
          color={GREEN}
          index="3"
          title="Thử nghiệm nhỏ"
          text="Một việc an toàn ngay trên bàn."
        />
        <div
          style={{
            position: 'absolute',
            left: 616,
            top: 850,
            opacity: fadeIn(frame, 190, 18),
            transform: `translate(${Math.sin(frame / 9) * 10}px, ${Math.cos(frame / 12) * 8}px)`,
          }}
        >
          <HandTap />
        </div>
        <div
          style={{
            position: 'absolute',
            left: 88,
            right: 88,
            bottom: 54,
            padding: '24px 34px',
            borderRadius: 30,
            background: withAlpha(INK, 0.9),
            color: WHITE,
            fontSize: 31,
            lineHeight: 1.15,
            fontWeight: 900,
            textAlign: 'center',
            opacity: fadeIn(frame, 204, 18),
          }}
        >
          Phần thưởng xuất hiện sau khi bé hoàn thành hành trình.
        </div>
      </div>
    </AbsoluteFill>
  );
};

const StepNode = ({
  frame,
  fps,
  delay,
  x,
  y,
  color,
  index,
  title,
  text,
}: {
  frame: number;
  fps: number;
  delay: number;
  x: number;
  y: number;
  color: string;
  index: string;
  title: string;
  text: string;
}) => {
  const s = interpolate(pop(frame, fps, delay), [0, 1], [0.7, 1]);
  const pulse = 1 + Math.sin((frame - delay) / 7) * 0.025;

  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: 330,
        borderRadius: 36,
        padding: '28px 28px 30px',
        ...cardStyle,
        transform: `scale(${s * pulse})`,
        opacity: fadeIn(frame, delay, 14),
      }}
    >
      <div
        style={{
          width: 70,
          height: 70,
          borderRadius: 22,
          background: color,
          color: WHITE,
          display: 'grid',
          placeItems: 'center',
          fontFamily: HEADING,
          fontSize: 38,
          fontWeight: 900,
          marginBottom: 16,
        }}
      >
        {index}
      </div>
      <div style={{ fontFamily: HEADING, fontSize: 38, fontWeight: 800, lineHeight: 0.96 }}>{title}</div>
      <div style={{ marginTop: 12, fontSize: 25, lineHeight: 1.15, color: MUTED, fontWeight: 850 }}>{text}</div>
    </div>
  );
};

const BottleMakingScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const inOpacity = fadeIn(frame, 0, 24);
  const out = fadeOut(frame, 292, 28);
  const pathProgress = interpolate(frame, [34, 270], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  return (
    <AbsoluteFill style={{ opacity: inOpacity * out, background: DESK }}>
      <SceneTitle
        frame={frame}
        top={88}
        kicker="Hành trình thật"
        title="Chai nhựa được tạo ra thế nào?"
        subtitle="WonderLens biến câu trả lời thành từng chặng rõ ràng, dễ nhớ."
      />
      <div
        style={{
          position: 'absolute',
          left: 62,
          top: 430,
          width: 956,
          height: 1212,
          borderRadius: 58,
          background: `linear-gradient(180deg, #F9FCFF, ${WHITE})`,
          border: `3px solid ${withAlpha(INK, 0.1)}`,
          boxShadow: `0 38px 90px ${withAlpha(BLUE, 0.13)}`,
          overflow: 'hidden',
        }}
      >
        <svg width="956" height="1212" viewBox="0 0 956 1212" style={{ position: 'absolute', inset: 0 }}>
          <path
            d="M118 132 C224 252 86 376 174 500 C256 616 114 752 212 878 C292 982 406 1030 548 1064"
            fill="none"
            stroke={withAlpha(COLORS.teal, 0.13)}
            strokeWidth="42"
            strokeLinecap="round"
          />
          <path
            d="M118 132 C224 252 86 376 174 500 C256 616 114 752 212 878 C292 982 406 1030 548 1064"
            fill="none"
            stroke={COLORS.teal}
            strokeWidth="12"
            strokeLinecap="round"
            strokeDasharray={`${pathProgress * 1500} 1500`}
          />
        </svg>
        <BottleJourneyStep
          frame={frame}
          fps={fps}
          delay={24}
          x={92}
          y={70}
          number="1"
          color={VIOLET}
          title="Dầu mỏ hoặc khí tự nhiên"
          text="Nhà máy tách ra chất để làm nhựa PET."
          icon={<OilIcon />}
        />
        <BottleJourneyStep
          frame={frame}
          fps={fps}
          delay={82}
          x={282}
          y={270}
          number="2"
          color={BLUE}
          title="Hạt nhựa PET"
          text="Nhựa được nấu chảy rồi ép thành hạt nhỏ."
          icon={<PelletsIcon />}
        />
        <BottleJourneyStep
          frame={frame}
          fps={fps}
          delay={140}
          x={92}
          y={470}
          number="3"
          color={YELLOW}
          title="Đúc thành phôi"
          text="Hạt nóng chảy thành phôi giống ống nghiệm."
          icon={<PreformIcon />}
        />
        <BottleJourneyStep
          frame={frame}
          fps={fps}
          delay={198}
          x={282}
          y={670}
          number="4"
          color={CORAL}
          title="Thổi nóng thành chai"
          text="Phôi mềm được thổi khí để phồng thành chai."
          icon={<BlowMoldIcon />}
        />
        <BottleJourneyStep
          frame={frame}
          fps={fps}
          delay={252}
          x={92}
          y={870}
          number="5"
          color={GREEN}
          title="Rót dùng, rồi thu gom"
          text="Chai sạch được dùng và có thể đem tái chế."
          icon={<RecycleBottleIcon />}
        />
      </div>
    </AbsoluteFill>
  );
};

const BottleJourneyStep = ({
  frame,
  fps,
  delay,
  x,
  y,
  number,
  color,
  title,
  text,
  icon,
}: {
  frame: number;
  fps: number;
  delay: number;
  x: number;
  y: number;
  number: string;
  color: string;
  title: string;
  text: string;
  icon: React.ReactNode;
}) => {
  const entrance = pop(frame, fps, delay, 150);
  const opacity = fadeIn(frame, delay, 18);
  const lift = interpolate(entrance, [0, 1], [26, 0]);
  const active = clamp(interpolate(frame, [delay + 8, delay + 28], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  }));

  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y + lift,
        width: 580,
        minHeight: 154,
        borderRadius: 34,
        background: WHITE,
        border: `4px solid ${withAlpha(color, 0.38 + active * 0.22)}`,
        boxShadow: `0 18px 42px ${withAlpha(color, 0.16 + active * 0.1)}`,
        display: 'flex',
        alignItems: 'center',
        gap: 20,
        padding: '20px 24px',
        color: INK,
        opacity,
        transform: `scale(${interpolate(entrance, [0, 1], [0.92, 1])})`,
      }}
    >
      <div
        style={{
          width: 112,
          height: 112,
          borderRadius: 30,
          background: withAlpha(color, 0.14),
          display: 'grid',
          placeItems: 'center',
          flex: '0 0 auto',
        }}
      >
        {icon}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
          <div
            style={{
              width: 42,
              height: 42,
              borderRadius: 14,
              background: color,
              color: WHITE,
              display: 'grid',
              placeItems: 'center',
              fontFamily: HEADING,
              fontSize: 25,
              fontWeight: 900,
            }}
          >
            {number}
          </div>
          <div style={{ fontFamily: HEADING, fontSize: 34, lineHeight: 0.95, fontWeight: 800 }}>{title}</div>
        </div>
        <div style={{ color: MUTED, fontSize: 25, lineHeight: 1.16, fontWeight: 850 }}>{text}</div>
      </div>
    </div>
  );
};

const FinalMarkScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = pop(frame, fps, 2, 120);
  const rays = interpolate(frame, [8, 44], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  return (
    <AbsoluteFill style={{ background: DESK }}>
      <div
        style={{
          position: 'absolute',
          left: 70,
          top: 170,
          width: 940,
          height: 1260,
          borderRadius: 68,
          background: `linear-gradient(180deg, ${WHITE}, #F7FFFC)`,
          border: `4px solid ${withAlpha(COLORS.teal, 0.2)}`,
          boxShadow: `0 44px 100px ${withAlpha(COLORS.tealDeep, 0.18)}`,
          overflow: 'hidden',
        }}
      >
        <svg width="940" height="1260" viewBox="0 0 940 1260" style={{ position: 'absolute', inset: 0 }}>
          {Array.from({ length: 18 }).map((_, i) => {
            const a = (i / 18) * Math.PI * 2 + frame * 0.006;
            const x1 = 470 + Math.cos(a) * 130;
            const y1 = 430 + Math.sin(a) * 130;
            const x2 = 470 + Math.cos(a) * (130 + rays * 420);
            const y2 = 430 + Math.sin(a) * (130 + rays * 420);
            return (
              <line
                key={i}
                x1={x1}
                y1={y1}
                x2={x2}
                y2={y2}
                stroke={i % 3 === 0 ? withAlpha(CORAL, 0.18) : withAlpha(COLORS.teal, 0.18)}
                strokeWidth="10"
                strokeLinecap="round"
              />
            );
          })}
        </svg>
        <div
          style={{
            position: 'absolute',
            left: 257,
            top: 246,
            width: 426,
            height: 426,
            borderRadius: 142,
            display: 'grid',
            placeItems: 'center',
            transform: `scale(${interpolate(logo, [0, 1], [0.72, 1])})`,
          }}
        >
          <LogoLens />
        </div>
        <div
          style={{
            position: 'absolute',
            left: 70,
            right: 70,
            top: 720,
            textAlign: 'center',
            opacity: fadeIn(frame, 18, 16),
            transform: `translateY(${slideY(frame, 18, 16, 22)}px)`,
          }}
        >
          <div
            style={{
              fontFamily: HEADING,
              fontSize: 104,
              lineHeight: 0.9,
              fontWeight: 800,
              letterSpacing: 0,
              color: INK,
            }}
          >
            WonderLens
          </div>
          <div
            style={{
              marginTop: 24,
              fontSize: 42,
              lineHeight: 1.1,
              color: MUTED,
              fontWeight: 900,
            }}
          >
            Chụp đồ vật. Mở chuyện khoa học.
          </div>
        </div>
        <div
          style={{
            position: 'absolute',
            left: 112,
            right: 112,
            bottom: 108,
            display: 'flex',
            justifyContent: 'center',
            gap: 16,
            flexWrap: 'wrap',
            opacity: fadeIn(frame, 38, 16),
          }}
        >
          <FinalPill text="Cho trẻ 6-10 tuổi" color={COLORS.teal} />
          <FinalPill text="Nội dung an toàn" color={GREEN} />
          <FinalPill text="Khám phá từ vật thật" color={CORAL} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

const FinalPill = ({ text, color }: { text: string; color: string }) => (
  <div
    style={{
      padding: '16px 22px',
      borderRadius: 999,
      background: withAlpha(color, 0.14),
      border: `3px solid ${withAlpha(color, 0.32)}`,
      color: INK,
      fontSize: 24,
      fontWeight: 900,
    }}
  >
    {text}
  </div>
);

const PencilIcon = () => (
  <svg width="150" height="118" viewBox="0 0 150 118">
    <path d="M22 76 L98 16 L132 50 L56 110 Z" fill={YELLOW} stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M98 16 L114 5 L145 34 L132 50 Z" fill={CORAL} stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M22 76 L8 116 L56 110 Z" fill="#F2D6A8" stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M8 116 L28 100 L35 114 Z" fill={INK} />
    <path d="M40 70 L74 104" stroke={withAlpha(INK, 0.28)} strokeWidth="6" strokeLinecap="round" />
  </svg>
);

const BatteryIcon = () => (
  <svg width="132" height="130" viewBox="0 0 132 130">
    <rect x="31" y="16" width="70" height="100" rx="18" fill={GREEN} stroke={INK} strokeWidth="8" />
    <rect x="48" y="4" width="36" height="18" rx="7" fill={INK} />
    <rect x="46" y="42" width="40" height="40" rx="12" fill={WHITE} opacity=".9" />
    <path d="M66 32 V46 M66 78 V94 M52 60 H80" stroke={INK} strokeWidth="7" strokeLinecap="round" />
  </svg>
);

const StickyIcon = () => (
  <svg width="142" height="126" viewBox="0 0 142 126">
    <path d="M20 12 H122 V84 L86 116 H20 Z" fill="#FFE56E" stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M86 116 V84 H122" fill="#F5C84B" stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M40 42 H96 M40 64 H88" stroke={INK} strokeWidth="7" strokeLinecap="round" opacity=".48" />
  </svg>
);

const OilIcon = () => (
  <svg width="84" height="94" viewBox="0 0 84 94">
    <path d="M42 8 C56 28 72 46 72 64 C72 80 60 90 42 90 C24 90 12 80 12 64 C12 46 28 28 42 8Z" fill={VIOLET} stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M34 56 C34 44 46 34 52 26" fill="none" stroke={WHITE} strokeWidth="7" strokeLinecap="round" opacity=".72" />
  </svg>
);

const PelletsIcon = () => (
  <svg width="96" height="96" viewBox="0 0 96 96">
    {[
      { cx: 28, cy: 30, color: BLUE },
      { cx: 52, cy: 22, color: COLORS.teal },
      { cx: 68, cy: 48, color: VIOLET },
      { cx: 34, cy: 62, color: GREEN },
      { cx: 58, cy: 72, color: BLUE },
    ].map(({ cx, cy, color }, index) => (
      <circle key={index} cx={cx} cy={cy} r="14" fill={color} stroke={INK} strokeWidth="6" />
    ))}
  </svg>
);

const PreformIcon = () => (
  <svg width="90" height="110" viewBox="0 0 90 110">
    <rect x="30" y="6" width="30" height="20" rx="7" fill={BLUE} stroke={INK} strokeWidth="6" />
    <path d="M30 22 H60 L66 88 C68 100 58 106 45 106 C32 106 22 100 24 88 Z" fill="#B9E6FF" stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M42 38 C52 50 54 70 48 88" fill="none" stroke={WHITE} strokeWidth="7" strokeLinecap="round" opacity=".72" />
  </svg>
);

const BlowMoldIcon = () => (
  <svg width="116" height="106" viewBox="0 0 116 106">
    <path d="M10 20 H40 V88 H10 Z" fill={withAlpha(CORAL, 0.22)} stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M76 20 H106 V88 H76 Z" fill={withAlpha(CORAL, 0.22)} stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <path d="M52 18 H64 V88 C64 96 52 96 52 88 Z" fill="#B9E6FF" stroke={INK} strokeWidth="6" />
    <path d="M30 54 H82" stroke={CORAL} strokeWidth="9" strokeLinecap="round" strokeDasharray="12 12" />
    <path d="M52 4 H64" stroke={INK} strokeWidth="7" strokeLinecap="round" />
  </svg>
);

const RecycleBottleIcon = () => (
  <svg width="110" height="110" viewBox="0 0 110 110">
    <path d="M42 14 H68 V34 C68 42 86 54 89 76 L93 94 C96 104 86 108 70 108 H40 C24 108 14 104 17 94 L21 76 C24 54 42 42 42 34 Z" fill="#9AD7FF" stroke={INK} strokeWidth="6" strokeLinejoin="round" />
    <rect x="39" y="6" width="32" height="16" rx="6" fill={BLUE} stroke={INK} strokeWidth="6" />
    <path d="M30 70 C42 48 68 46 82 64" fill="none" stroke={GREEN} strokeWidth="8" strokeLinecap="round" />
    <path d="M82 64 L80 48 L94 56 Z" fill={GREEN} stroke={INK} strokeWidth="4" strokeLinejoin="round" />
    <path d="M82 80 C68 100 40 98 28 80" fill="none" stroke={GREEN} strokeWidth="8" strokeLinecap="round" />
    <path d="M28 80 L30 96 L16 88 Z" fill={GREEN} stroke={INK} strokeWidth="4" strokeLinejoin="round" />
  </svg>
);

const BottleIcon = ({ large = false }: { large?: boolean }) => (
  <svg width={large ? 250 : 128} height={large ? 310 : 150} viewBox="0 0 128 150">
    <path d="M49 8 H79 V34 C79 44 100 56 104 82 L110 122 C113 140 101 148 82 148 H46 C27 148 15 140 18 122 L24 82 C28 56 49 44 49 34 Z" fill="#9AD7FF" stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <rect x="45" y="2" width="38" height="18" rx="7" fill={BLUE} stroke={INK} strokeWidth="7" />
    <path d="M34 92 H94 V120 H34 Z" fill={WHITE} opacity=".86" stroke={INK} strokeWidth="6" />
    <path d="M50 70 C62 58 78 60 88 72" fill="none" stroke={WHITE} strokeWidth="7" strokeLinecap="round" opacity=".8" />
  </svg>
);

const CameraGlyph = () => (
  <svg width="66" height="58" viewBox="0 0 66 58">
    <path d="M14 18 H24 L30 10 H40 L46 18 H54 C60 18 63 22 63 28 V46 C63 52 59 55 53 55 H13 C7 55 3 52 3 46 V28 C3 22 8 18 14 18Z" fill={WHITE} stroke={INK} strokeWidth="7" strokeLinejoin="round" />
    <circle cx="33" cy="37" r="12" fill={COLORS.teal} stroke={INK} strokeWidth="6" />
    <path d="M14 29 H22" stroke={CORAL} strokeWidth="6" strokeLinecap="round" />
  </svg>
);

const LensGlyph = () => (
  <svg width="62" height="62" viewBox="0 0 62 62">
    <circle cx="27" cy="27" r="18" fill="none" stroke={COLORS.tealDeep} strokeWidth="8" />
    <path d="M40 40 L56 56" stroke={COLORS.tealDeep} strokeWidth="8" strokeLinecap="round" />
  </svg>
);

const TimelineGlyph = () => (
  <svg width="70" height="70" viewBox="0 0 70 70">
    <path d="M18 12 V58" stroke={COLORS.tealDeep} strokeWidth="7" strokeLinecap="round" />
    <circle cx="18" cy="18" r="9" fill={BLUE} stroke={INK} strokeWidth="5" />
    <circle cx="18" cy="35" r="9" fill={YELLOW} stroke={INK} strokeWidth="5" />
    <circle cx="18" cy="52" r="9" fill={CORAL} stroke={INK} strokeWidth="5" />
    <path d="M32 18 H58 M32 35 H52 M32 52 H60" stroke={INK} strokeWidth="7" strokeLinecap="round" />
  </svg>
);

const HandTap = () => (
  <svg width="190" height="220" viewBox="0 0 190 220">
    <circle cx="92" cy="52" r="42" fill="none" stroke={withAlpha(COLORS.teal, 0.36)} strokeWidth="10" />
    <path
      d="M82 34 C82 18 106 18 106 34 V94 L116 84 C126 74 142 84 134 98 L124 116 L146 108 C160 104 168 122 156 132 L132 152 C124 158 114 164 96 164 H74 C56 164 42 150 42 132 V92 C42 76 66 76 66 92 V108 V34 C66 18 82 18 82 34Z"
      fill="#F6C89A"
      stroke={INK}
      strokeWidth="8"
      strokeLinejoin="round"
    />
    <path d="M66 108 V74 M82 112 V66 M106 94 V76" stroke={withAlpha(INK, 0.34)} strokeWidth="6" strokeLinecap="round" />
  </svg>
);

const BigBadge = ({ small = false }: { small?: boolean }) => (
  <svg width={small ? 70 : 264} height={small ? 70 : 264} viewBox="0 0 264 264">
    <path d="M132 12 L166 58 L222 58 L188 104 L208 158 L132 130 L56 158 L76 104 L42 58 L98 58 Z" fill={YELLOW} stroke={INK} strokeWidth="9" strokeLinejoin="round" />
    <circle cx="132" cy="112" r="54" fill={WHITE} stroke={INK} strokeWidth="8" />
    <path d="M106 112 L124 130 L160 92" fill="none" stroke={GREEN} strokeWidth="13" strokeLinecap="round" strokeLinejoin="round" />
    <path d="M84 156 L64 238 L132 202 L200 238 L180 156" fill={CORAL} stroke={INK} strokeWidth="8" strokeLinejoin="round" />
  </svg>
);

const LogoLens = () => (
  <svg width="426" height="426" viewBox="0 0 426 426">
    <defs>
      <linearGradient id="lensLogo" x1="58" x2="356" y1="48" y2="364" gradientUnits="userSpaceOnUse">
        <stop stopColor={COLORS.teal} />
        <stop offset="0.55" stopColor={BLUE} />
        <stop offset="1" stopColor={VIOLET} />
      </linearGradient>
    </defs>
    <circle cx="190" cy="190" r="138" fill="url(#lensLogo)" stroke={INK} strokeWidth="14" />
    <circle cx="190" cy="190" r="80" fill={WHITE} opacity=".94" />
    <circle cx="166" cy="166" r="30" fill={withAlpha(COLORS.teal, 0.75)} />
    <path d="M292 292 L382 382" stroke={INK} strokeWidth="30" strokeLinecap="round" />
    <path d="M292 292 L382 382" stroke={COLORS.teal} strokeWidth="18" strokeLinecap="round" />
    <path d="M118 128 C152 92 222 88 262 128" fill="none" stroke={WHITE} strokeWidth="18" strokeLinecap="round" opacity=".78" />
  </svg>
);
