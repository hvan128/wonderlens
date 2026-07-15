import type { CSSProperties } from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { Badge } from "./components/Badge";
import { Confetti } from "./components/Confetti";
import { BODY, HEADING } from "./fonts";

export const STORY_PROMO_DURATION_IN_FRAMES = 61 * 30;

const COLORS = {
  teal: "#26C6DA",
  tealDeep: "#0E97AC",
  cyan: "#22D3EE",
  sky: "#38BDF8",
  grape: "#B794F4",
  mint: "#5EEAD4",
  sunny: "#FFC857",
  coral: "#FF8A65",
  ink: "#15233B",
  inkSoft: "#54657F",
  canvasTop: "#EAF8FB",
  canvasBottom: "#F4EFFF",
  paper: "#FFFDF7",
  white: "#FFFFFF",
} as const;

const ASSETS = {
  scene: "story/onboarding-scene.jpg",
  cup: "story/paper-cup-cutout.png",
  logo: "story/brand-logo.png",
  stages: [
    "story/paper-cup-stage-0.png",
    "story/paper-cup-stage-1.svg",
    "story/paper-cup-stage-2.png",
    "story/paper-cup-stage-3.svg",
  ],
  objects: [
    { src: "story/ball-pen-cutout.png", label: "Bút bi" },
    { src: "story/plastic-bottle-cutout.png", label: "Chai nước" },
    { src: "story/paper-clip-cutout.png", label: "Kẹp giấy" },
    { src: "story/ruler-cutout.png", label: "Thước kẻ" },
  ],
} as const;

const STAGES = [
  {
    chapter: "Chương 1",
    title: "Từ một thân cây",
    body:
      "Thân gỗ được đưa về nhà máy giấy. Vỏ cây được tách ra, phần gỗ sạch chuẩn bị cho chặng tiếp theo.",
    transformation: "Thân gỗ → Mảnh gỗ",
    accent: "#48B878",
  },
  {
    chapter: "Chương 2",
    title: "Hóa thành bột giấy",
    body:
      "Mảnh gỗ được làm mềm trong bồn kín bằng nhiệt và dung dịch chuyên dụng. Các sợi cellulose tách ra thành bột giấy.",
    transformation: "Mảnh gỗ → Sợi cellulose",
    accent: COLORS.sunny,
  },
  {
    chapter: "Chương 3",
    title: "Thành cuộn giấy lớn",
    body:
      "Bột giấy trải đều trên lưới. Nước được ép ra, rồi trục lăn nóng sấy và cán thành cuộn giấy mỏng, chắc.",
    transformation: "Bột giấy → Cuộn giấy",
    accent: COLORS.sky,
  },
  {
    chapter: "Chương 4",
    title: "Chiếc cốc ra đời",
    body:
      "Giấy được phủ chống thấm, cắt thành thân và đáy. Máy cuộn rồi ép mép — chiếc cốc đã ra đời!",
    transformation: "Cuộn giấy → Cốc giấy",
    accent: COLORS.coral,
  },
] as const;

const clamp = (value: number) => Math.max(0, Math.min(1, value));

const ease = (
  frame: number,
  input: [number, number],
  output: [number, number],
  easing = Easing.out(Easing.cubic),
) =>
  interpolate(frame, input, output, {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

const sceneOpacity = (
  frame: number,
  duration: number,
  fadeIn = 18,
  fadeOut = 22,
) =>
  clamp(
    ease(frame, [0, fadeIn], [0, 1]) *
      ease(
        frame,
        [duration - fadeOut, duration],
        [1, 0],
        Easing.in(Easing.quad),
      ),
  );

const glass: CSSProperties = {
  background: "rgba(255,255,255,.78)",
  border: "1px solid rgba(255,255,255,.82)",
  boxShadow: "0 26px 70px rgba(21,35,59,.16)",
  backdropFilter: "blur(18px)",
};

export const WonderLensStoryPromo = () => (
  <AbsoluteFill
    style={{ background: COLORS.paper, fontFamily: BODY, color: COLORS.ink }}
  >
    <Sequence from={0} durationInFrames={135} premountFor={30}>
      <HookScene duration={135} />
    </Sequence>
    <Sequence from={110} durationInFrames={180} premountFor={30}>
      <ScanScene duration={180} />
    </Sequence>
    <Sequence from={260} durationInFrames={150} premountFor={30}>
      <RevealScene duration={150} />
    </Sequence>
    <Sequence from={380} durationInFrames={960} premountFor={45}>
      <JourneyScene duration={960} />
    </Sequence>
    <Sequence from={1340} durationInFrames={190} premountFor={30}>
      <RewardScene duration={190} />
    </Sequence>
    <Sequence from={1485} durationInFrames={215} premountFor={30}>
      <WorldScene duration={215} />
    </Sequence>
    <Sequence from={1675} durationInFrames={155} premountFor={30}>
      <EndScene />
    </Sequence>
  </AbsoluteFill>
);

const PhotoBackdrop = ({
  frame,
  dark = 0,
}: {
  frame: number;
  dark?: number;
}) => {
  const scale = ease(frame, [0, 180], [1.03, 1.11], Easing.inOut(Easing.quad));
  return (
    <AbsoluteFill>
      <Img
        src={staticFile(ASSETS.scene)}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          transform: `scale(${scale}) translateY(${ease(frame, [0, 180], [0, -18])}px)`,
        }}
      />
      <AbsoluteFill
        style={{
          background: `linear-gradient(180deg, rgba(9,25,31,${0.28 + dark}) 0%, rgba(9,25,31,.02) 43%, rgba(9,25,31,${0.42 + dark}) 100%)`,
        }}
      />
    </AbsoluteFill>
  );
};

const HookScene = ({ duration }: { duration: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({
    frame,
    fps,
    durationInFrames: 36,
    config: { damping: 200 },
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity(frame, duration) }}>
      <PhotoBackdrop frame={frame} />
      <div
        style={{
          position: "absolute",
          top: 120,
          left: 64,
          display: "flex",
          alignItems: "center",
          gap: 14,
          color: COLORS.white,
          fontSize: 31,
          fontWeight: 900,
          opacity: intro,
        }}
      >
        <Img src={staticFile(ASSETS.logo)} style={{ width: 58, height: 58 }} />
        WonderLens
      </div>
      <div
        style={{
          position: "absolute",
          left: 64,
          right: 64,
          top: 240,
          transform: `translateY(${(1 - intro) * 46}px)`,
          opacity: intro,
        }}
      >
        <div
          style={{
            fontFamily: HEADING,
            fontSize: 91,
            fontWeight: 800,
            lineHeight: 0.98,
            color: COLORS.white,
            textShadow: "0 6px 30px rgba(8,29,36,.36)",
          }}
        >
          Một chiếc cốc…
          <br />
          chỉ là một chiếc cốc?
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: 64,
          right: 64,
          bottom: 118,
          padding: "22px 28px",
          borderRadius: 30,
          ...glass,
          color: COLORS.ink,
          fontSize: 30,
          fontWeight: 900,
          textAlign: "center",
          opacity: ease(frame, [45, 75], [0, 1]),
          transform: `translateY(${ease(frame, [45, 75], [24, 0])}px)`,
        }}
      >
        Có một câu chuyện đang chờ được khám phá.
      </div>
    </AbsoluteFill>
  );
};

const ScanScene = ({ duration }: { duration: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const chrome = spring({
    frame,
    fps,
    durationInFrames: 34,
    config: { damping: 22, stiffness: 190 },
  });
  const scanY = ease(frame, [28, 116], [560, 1250], Easing.inOut(Easing.quad));
  const shutter = spring({
    frame: frame - 112,
    fps,
    durationInFrames: 24,
    config: { damping: 16, stiffness: 250 },
  });
  const flash =
    ease(frame, [126, 132], [0, 1]) * ease(frame, [132, 148], [1, 0]);

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity(frame, duration, 22, 18) }}>
      <PhotoBackdrop frame={frame + 30} dark={0.1} />
      <div
        style={{
          position: "absolute",
          top: 112,
          left: 60,
          right: 60,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          opacity: chrome,
          color: COLORS.white,
        }}
      >
        <div style={{ fontSize: 27, fontWeight: 900 }}>Ống kính khám phá</div>
        <div style={{ fontSize: 25, fontWeight: 800, opacity: 0.86 }}>
          Sẵn sàng
        </div>
      </div>
      <svg
        width="1080"
        height="1920"
        viewBox="0 0 1080 1920"
        style={{ position: "absolute", inset: 0, opacity: chrome }}
      >
        <ScanCorners x={190} y={470} width={700} height={900} />
        <rect
          x="220"
          y={scanY}
          width="640"
          height="22"
          rx="11"
          fill="rgba(34,211,238,.72)"
          style={{ filter: "drop-shadow(0 0 22px rgba(34,211,238,.95))" }}
        />
      </svg>
      <div
        style={{
          position: "absolute",
          left: 90,
          right: 90,
          top: 310,
          textAlign: "center",
          color: COLORS.white,
          fontFamily: HEADING,
          fontSize: 58,
          fontWeight: 800,
          lineHeight: 1.03,
          opacity: ease(frame, [8, 32], [0, 1]),
          textShadow: "0 5px 24px rgba(8,29,36,.5)",
        }}
      >
        Đưa WonderLens lên
        <br />
        và nhìn gần hơn
      </div>
      <div
        style={{
          position: "absolute",
          bottom: 120,
          left: "50%",
          width: 156,
          height: 156,
          borderRadius: "50%",
          padding: 13,
          boxSizing: "border-box",
          background:
            "conic-gradient(#22D3EE,#38BDF8,#B794F4,#FFC857,#5EEAD4,#22D3EE)",
          transform: `translateX(-50%) scale(${1 - shutter * 0.13})`,
          boxShadow:
            "0 0 0 7px rgba(255,255,255,.5), 0 16px 40px rgba(5,30,38,.42)",
        }}
      >
        <div
          style={{
            width: "100%",
            height: "100%",
            borderRadius: "50%",
            background: "rgba(255,255,255,.96)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <Img
            src={staticFile(ASSETS.logo)}
            style={{ width: 94, height: 94 }}
          />
        </div>
      </div>
      <AbsoluteFill style={{ background: COLORS.white, opacity: flash }} />
    </AbsoluteFill>
  );
};

const ScanCorners = ({
  x,
  y,
  width,
  height,
}: {
  x: number;
  y: number;
  width: number;
  height: number;
}) => {
  const color = "rgba(255,255,255,.95)";
  return (
    <g fill="none" stroke={color} strokeWidth="12" strokeLinecap="round">
      <path
        d={`M${x} ${y + 100} V${y + 36} Q${x} ${y} ${x + 36} ${y} H${x + 100}`}
      />
      <path
        d={`M${x + width - 100} ${y} H${x + width - 36} Q${x + width} ${y} ${x + width} ${y + 36} V${y + 100}`}
      />
      <path
        d={`M${x} ${y + height - 100} V${y + height - 36} Q${x} ${y + height} ${x + 36} ${y + height} H${x + 100}`}
      />
      <path
        d={`M${x + width - 100} ${y + height} H${x + width - 36} Q${x + width} ${y + height} ${x + width} ${y + height - 36} V${y + height - 100}`}
      />
    </g>
  );
};

const CanvasBackground = () => (
  <AbsoluteFill
    style={{
      background:
        "radial-gradient(circle at 15% 18%, rgba(94,234,212,.28), transparent 25%), radial-gradient(circle at 92% 8%, rgba(183,148,244,.25), transparent 28%), linear-gradient(180deg,#EAF8FB 0%,#F4EFFF 100%)",
    }}
  >
    <AbsoluteFill
      style={{
        opacity: 0.22,
        backgroundImage:
          "radial-gradient(rgba(21,35,59,.34) 1.4px, transparent 1.4px)",
        backgroundSize: "34px 34px",
      }}
    />
  </AbsoluteFill>
);

const RevealScene = ({ duration }: { duration: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const reveal = spring({
    frame,
    fps,
    durationInFrames: 50,
    config: { damping: 16, stiffness: 145 },
  });
  const halo = 1 + Math.sin(frame / 12) * 0.035;

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity(frame, duration) }}>
      <CanvasBackground />
      <div
        style={{
          position: "absolute",
          top: 112,
          left: 0,
          right: 0,
          textAlign: "center",
          color: COLORS.tealDeep,
          fontSize: 28,
          fontWeight: 900,
          letterSpacing: 0.3,
          opacity: ease(frame, [10, 28], [0, 1]),
        }}
      >
        BẮT ĐƯỢC MANH MỐI
      </div>
      <div
        style={{
          position: "absolute",
          top: 182,
          left: 70,
          right: 70,
          textAlign: "center",
          fontFamily: HEADING,
          fontSize: 99,
          fontWeight: 800,
          lineHeight: 1,
          transform: `translateY(${(1 - reveal) * 35}px)`,
          opacity: reveal,
        }}
      >
        Cốc giấy
      </div>
      <div
        style={{
          position: "absolute",
          left: 140,
          right: 140,
          top: 370,
          height: 930,
          borderRadius: 460,
          background:
            "radial-gradient(circle,rgba(38,198,218,.27) 0%,rgba(56,189,248,.08) 52%,transparent 72%)",
          transform: `scale(${halo})`,
        }}
      />
      <Img
        src={staticFile(ASSETS.cup)}
        style={{
          position: "absolute",
          width: 720,
          height: 720,
          left: 180,
          top: 500,
          objectFit: "contain",
          transform: `translateY(${(1 - reveal) * 120}px) scale(${0.72 + reveal * 0.28})`,
          filter:
            "drop-shadow(0 44px 32px rgba(21,35,59,.22)) drop-shadow(0 0 22px rgba(38,198,218,.34))",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: "50%",
          bottom: 195,
          transform: `translateX(-50%) scale(${ease(frame, [46, 75], [0.82, 1])})`,
          opacity: ease(frame, [46, 70], [0, 1]),
          borderRadius: 999,
          padding: "18px 32px",
          ...glass,
          color: COLORS.ink,
          fontSize: 31,
          fontWeight: 900,
          whiteSpace: "nowrap",
        }}
      >
        Vật liệu: Giấy
      </div>
      <div
        style={{
          position: "absolute",
          left: 80,
          right: 80,
          bottom: 92,
          textAlign: "center",
          color: COLORS.inkSoft,
          fontSize: 27,
          fontWeight: 800,
          opacity: ease(frame, [72, 96], [0, 1]),
        }}
      >
        Đồ vật quen thuộc mở ra một hành trình.
      </div>
    </AbsoluteFill>
  );
};

const JourneyScene = ({ duration }: { duration: number }) => {
  const frame = useCurrentFrame();
  const framesPerStage = 240;
  const active = Math.min(
    3,
    Math.max(0, Math.floor(frame / framesPerStage)),
  );

  return (
    <AbsoluteFill style={{ opacity: ease(frame, [0, 20], [0, 1]) }}>
      <CanvasBackground />
      <div
        style={{
          position: "absolute",
          top: 92,
          left: 68,
          right: 68,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div>
          <div
            style={{ fontSize: 24, fontWeight: 900, color: COLORS.tealDeep }}
          >
            HÀNH TRÌNH TẠO RA
          </div>
          <div
            style={{
              fontFamily: HEADING,
              fontSize: 58,
              fontWeight: 800,
              marginTop: -2,
            }}
          >
            Cốc giấy
          </div>
        </div>
        <div
          style={{
            width: 78,
            height: 78,
            borderRadius: "50%",
            background: "rgba(255,255,255,.75)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            boxShadow: "0 12px 34px rgba(21,35,59,.12)",
          }}
        >
          <Img
            src={staticFile(ASSETS.logo)}
            style={{ width: 58, height: 58 }}
          />
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: 68,
          right: 68,
          top: 232,
          display: "flex",
          gap: 12,
        }}
      >
        {STAGES.map((stage, index) => {
          const fill =
            index < active
              ? 1
              : index === active
                ? ease(
                    frame - index * framesPerStage,
                    [0, framesPerStage - 25],
                    [0, 1],
                  )
                : 0;
          return (
            <div
              key={stage.title}
              style={{
                flex: 1,
                height: 13,
                borderRadius: 999,
                overflow: "hidden",
                background: "rgba(21,35,59,.12)",
              }}
            >
              <div
                style={{
                  width: `${fill * 100}%`,
                  height: "100%",
                  borderRadius: 999,
                  background: stage.accent,
                }}
              />
            </div>
          );
        })}
      </div>
      {STAGES.map((stage, index) => {
        const start = index * framesPerStage;
        const local = frame - start;
        const fadeOut =
          index === STAGES.length - 1
            ? 1
            : ease(
                local,
                [framesPerStage - 28, framesPerStage],
                [1, 0],
                Easing.in(Easing.quad),
              );
        const opacity =
          ease(local, [-15, 12], [0, 1]) * fadeOut;
        const shift = ease(local, [-15, 16], [70, 0]);
        return (
          <div
            key={stage.title}
            style={{
              position: "absolute",
              inset: "300px 56px 150px",
              opacity,
              transform: `translateX(${shift}px) scale(${ease(local, [-15, 18], [0.96, 1])})`,
            }}
          >
            <div
              style={{
                position: "relative",
                height: 950,
                borderRadius: 52,
                overflow: "hidden",
                background: COLORS.white,
                border: "1px solid rgba(255,255,255,.9)",
                boxShadow: "0 30px 80px rgba(21,35,59,.16)",
              }}
            >
              <Img
                src={staticFile(ASSETS.stages[index])}
                style={{
                  width: "100%",
                  height: "100%",
                  objectFit: "cover",
                  transform: `scale(${1.03 + ease(local, [0, 100], [0, 0.035])})`,
                }}
              />
              <div
                style={{
                  position: "absolute",
                  inset: "auto 0 0",
                  height: 240,
                  background:
                    "linear-gradient(180deg,transparent,rgba(7,25,31,.8))",
                }}
              />
              <div
                style={{
                  position: "absolute",
                  left: 34,
                  top: 34,
                  borderRadius: 999,
                  padding: "12px 20px",
                  background: stage.accent,
                  color: COLORS.ink,
                  fontWeight: 900,
                  fontSize: 25,
                  boxShadow: "0 12px 30px rgba(21,35,59,.16)",
                }}
              >
                {stage.chapter} / 4
              </div>
            </div>
            <div
              style={{
                marginTop: 30,
                borderRadius: 40,
                padding: "34px 38px 38px",
                ...glass,
              }}
            >
              <div
                style={{
                  fontFamily: HEADING,
                  fontSize: 53,
                  fontWeight: 800,
                  lineHeight: 1.05,
                }}
              >
                {stage.title}
              </div>
              <div
                style={{
                  fontSize: 29,
                  lineHeight: 1.32,
                  color: COLORS.inkSoft,
                  fontWeight: 800,
                  marginTop: 14,
                }}
              >
                {stage.body}
              </div>
              <div
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  marginTop: 20,
                  borderRadius: 999,
                  padding: "11px 18px",
                  background: `${stage.accent}2E`,
                  color: COLORS.ink,
                  fontSize: 23,
                  lineHeight: 1.15,
                  fontWeight: 900,
                }}
              >
                {stage.transformation}
              </div>
            </div>
          </div>
        );
      })}
      <div
        style={{
          position: "absolute",
          left: 150,
          right: 150,
          bottom: 62,
          borderRadius: 999,
          padding: "15px 24px",
          background: "rgba(21,35,59,.88)",
          color: COLORS.white,
          textAlign: "center",
          fontSize: 24,
          fontWeight: 900,
          letterSpacing: 0.1,
        }}
      >
        Từ thân gỗ → chiếc cốc trong tay bé
      </div>
    </AbsoluteFill>
  );
};

const RewardScene = ({ duration }: { duration: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const cupIn = spring({
    frame,
    fps,
    durationInFrames: 42,
    config: { damping: 17, stiffness: 150 },
  });
  const badgeIn = spring({
    frame: frame - 45,
    fps,
    durationInFrames: 38,
    config: { damping: 12, stiffness: 160 },
  });

  return (
    <AbsoluteFill
      style={{
        opacity: ease(
          frame,
          [duration - 24, duration],
          [1, 0],
          Easing.in(Easing.quad),
        ),
      }}
    >
      <CanvasBackground />
      <div
        style={{
          position: "absolute",
          top: 112,
          left: 60,
          right: 60,
          textAlign: "center",
          fontFamily: HEADING,
          fontSize: 82,
          fontWeight: 800,
          lineHeight: 1,
          opacity: ease(frame, [0, 22], [0, 1]),
        }}
      >
        Khám phá xong!
      </div>
      <div
        style={{
          position: "absolute",
          left: 210,
          top: 330,
          width: 660,
          height: 660,
          borderRadius: "50%",
          background:
            "radial-gradient(circle,rgba(255,200,87,.34),rgba(183,148,244,.11) 55%,transparent 72%)",
        }}
      />
      <Img
        src={staticFile(ASSETS.cup)}
        style={{
          position: "absolute",
          width: 620,
          height: 620,
          left: 230,
          top: 350,
          objectFit: "contain",
          transform: `translateY(${(1 - cupIn) * 90}px) scale(${0.78 + cupIn * 0.22})`,
          filter: "drop-shadow(0 38px 30px rgba(21,35,59,.2))",
        }}
      />
      <div
        style={{
          position: "absolute",
          top: 1030,
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "center",
        }}
      >
        <Badge enter={badgeIn} />
      </div>
      <div
        style={{
          position: "absolute",
          left: 78,
          right: 78,
          bottom: 170,
          borderRadius: 38,
          padding: "30px 34px",
          ...glass,
          textAlign: "center",
          opacity: ease(frame, [72, 102], [0, 1]),
          transform: `translateY(${ease(frame, [72, 102], [30, 0])}px)`,
        }}
      >
        <div style={{ fontSize: 35, fontWeight: 900 }}>
          Đã thêm vào Rương khám phá
        </div>
        <div
          style={{
            fontSize: 26,
            color: COLORS.inkSoft,
            fontWeight: 800,
            marginTop: 7,
          }}
        >
          Học khoa học · Gom vật mới · Mở huy hiệu
        </div>
      </div>
      <Confetti
        originXRatio={0.5}
        originYRatio={0.46}
        startFrame={50}
        count={48}
      />
    </AbsoluteFill>
  );
};

const WORLD_POSITIONS = [
  { left: 36, top: 470, width: 310, rotate: -14, delay: 6 },
  { left: 728, top: 440, width: 310, rotate: 12, delay: 17 },
  { left: 38, top: 1110, width: 310, rotate: -10, delay: 28 },
  { left: 730, top: 1090, width: 310, rotate: 11, delay: 39 },
] as const;

const WorldScene = ({ duration }: { duration: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logoIn = spring({
    frame,
    fps,
    durationInFrames: 46,
    config: { damping: 18, stiffness: 145 },
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity(frame, duration, 20, 24) }}>
      <CanvasBackground />
      <div
        style={{
          position: "absolute",
          top: 112,
          left: 55,
          right: 55,
          textAlign: "center",
          fontFamily: HEADING,
          fontSize: 70,
          fontWeight: 800,
          lineHeight: 1.04,
        }}
      >
        Không chỉ một chiếc cốc
      </div>
      <div
        style={{
          position: "absolute",
          left: 338,
          top: 770,
          width: 404,
          height: 404,
          borderRadius: "50%",
          background:
            "radial-gradient(circle,rgba(34,211,238,.26),rgba(183,148,244,.12) 62%,transparent 72%)",
          transform: `scale(${1 + Math.sin(frame / 12) * 0.04})`,
        }}
      />
      <Img
        src={staticFile(ASSETS.logo)}
        style={{
          position: "absolute",
          left: 410,
          top: 842,
          width: 260,
          height: 260,
          transform: `scale(${logoIn}) rotate(${ease(frame, [0, 180], [-12, 8], Easing.inOut(Easing.quad))}deg)`,
          filter: "drop-shadow(0 28px 28px rgba(21,35,59,.18))",
        }}
      />
      {ASSETS.objects.map((object, index) => {
        const position = WORLD_POSITIONS[index];
        const enter = spring({
          frame: frame - position.delay,
          fps,
          durationInFrames: 45,
          config: { damping: 15, stiffness: 155 },
        });
        return (
          <div
            key={object.label}
            style={{
              position: "absolute",
              left: position.left,
              top: position.top,
              width: position.width,
              height: 420,
              transform: `translate(${(1 - enter) * (540 - position.left)}px, ${(1 - enter) * (920 - position.top)}px) scale(${0.35 + enter * 0.65}) rotate(${position.rotate + Math.sin((frame + index * 18) / 16) * 2.2}deg)`,
              opacity: enter,
            }}
          >
            <Img
              src={staticFile(object.src)}
              style={{
                width: "100%",
                height: 340,
                objectFit: "contain",
                filter: "drop-shadow(0 24px 18px rgba(21,35,59,.2))",
              }}
            />
            <div
              style={{
                margin: "-7px auto 0",
                width: "fit-content",
                borderRadius: 999,
                padding: "9px 17px",
                background: "rgba(255,255,255,.84)",
                boxShadow: "0 10px 24px rgba(21,35,59,.12)",
                fontSize: 22,
                fontWeight: 900,
              }}
            >
              {object.label}
            </div>
          </div>
        );
      })}
      <div
        style={{
          position: "absolute",
          left: 70,
          right: 70,
          bottom: 118,
          textAlign: "center",
          fontSize: 37,
          lineHeight: 1.23,
          color: COLORS.inkSoft,
          fontWeight: 900,
          opacity: ease(frame, [68, 104], [0, 1]),
        }}
      >
        Cả thế giới quanh bé
        <br />
        đều chứa đầy khoa học.
      </div>
    </AbsoluteFill>
  );
};

const EndScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({
    frame,
    fps,
    durationInFrames: 42,
    config: { damping: 200 },
  });
  const mark = spring({
    frame: frame - 5,
    fps,
    durationInFrames: 46,
    config: { damping: 16, stiffness: 145 },
  });

  return (
    <AbsoluteFill
      style={{
        opacity: ease(frame, [0, 20], [0, 1]),
        background:
          "radial-gradient(circle at 50% 36%,rgba(255,255,255,.26),transparent 25%), linear-gradient(150deg,#22D3EE 0%,#26C6DA 45%,#0E97AC 100%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        flexDirection: "column",
        color: COLORS.white,
      }}
    >
      <div
        style={{
          width: 340,
          height: 340,
          borderRadius: "50%",
          background: "rgba(255,255,255,.92)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 38px 90px rgba(4,68,80,.3)",
          transform: `scale(${mark})`,
        }}
      >
        <Img
          src={staticFile(ASSETS.logo)}
          style={{ width: 274, height: 274 }}
        />
      </div>
      <div
        style={{
          marginTop: 48,
          fontFamily: HEADING,
          fontSize: 116,
          fontWeight: 800,
          lineHeight: 1,
          opacity: enter,
          transform: `translateY(${(1 - enter) * 30}px)`,
          textShadow: "0 6px 0 rgba(4,68,80,.14)",
        }}
      >
        WonderLens
      </div>
      <div
        style={{
          marginTop: 30,
          fontSize: 40,
          fontWeight: 900,
          lineHeight: 1.3,
          textAlign: "center",
          opacity: ease(frame, [24, 50], [0, 1]),
          transform: `translateY(${ease(frame, [24, 50], [20, 0])}px)`,
        }}
      >
        Soi đồ vật.
        <br />
        Mở chuyện khoa học.
      </div>
      <div
        style={{
          marginTop: 68,
          borderRadius: 999,
          padding: "20px 38px",
          background: "rgba(255,255,255,.95)",
          color: COLORS.tealDeep,
          fontSize: 30,
          fontWeight: 900,
          opacity: ease(frame, [48, 76], [0, 1]),
          boxShadow: "0 20px 45px rgba(4,68,80,.22)",
        }}
      >
        Mở ống kính khám phá
      </div>
    </AbsoluteFill>
  );
};
