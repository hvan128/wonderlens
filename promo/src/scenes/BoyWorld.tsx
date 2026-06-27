import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { Boy } from '../components/Boy';
import { FlipPhone } from '../components/FlipPhone';
import { LensOverlay } from '../components/LensOverlay';
import { ScanBeam } from '../components/ScanBeam';
import { IconCup } from '../components/Icons';

// bố cục: bé bản cũ cầm máy, cam SAU hướng xuống cốc thật đặt trên BÀN tiền cảnh.
const PHONE_W = 286;
const PHONE_H = 524;
const PHONE_CX = 430;
const PHONE_CY = 1280;
const BOY_LEFT = 20;
const BOY_TOP = 380;
const BOY_W = 810;
const BOY_H = 1215;
// camera sau (góc trên-phải lưng máy) = gốc tia quét
const CAM_X = 507;
const CAM_Y = 1086;
// cốc thật trên mặt bàn (tiền cảnh)
const CUP_CX = 762;
const CUP_CY = 1232;
const DESK_TOP = 1356;

export const BoyWorld = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({ frame, fps, config: { damping: 14, mass: 0.8 }, durationInFrames: 32 });
  const enterX = interpolate(enter, [0, 1], [-400, 0]);

  const diveDamp = interpolate(frame, [176, 206], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const bobY = Math.sin(frame / 11) * 7 * diveDamp;

  const blinkPhase = frame % 78;
  const blink = blinkPhase < 6 ? 1 - Math.abs(blinkPhase - 3) / 3 : 0;
  const wow = interpolate(frame, [150, 167], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const beamOpacity = interpolate(frame, [78, 90, 150, 162], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const lock = interpolate(frame, [88, 148], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const locked = frame >= 148;
  const dash = frame * 5;

  const flash = interpolate(frame, [146, 152, 164], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // LẬT máy: 0 = lưng (cam sau) -> 180 = màn hình
  const flipDeg = interpolate(frame, [158, 184], [0, 180], {
    easing: Easing.inOut(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const showResult = interpolate(frame, [150, 182], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const statusText = frame < 84 ? 'Đưa máy vào cốc' : frame < 150 ? 'Đang quét…' : 'Đã nhận ra!';
  const statusOpacity = interpolate(frame, [12, 26, 168, 180], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // lao vào màn hình (sau khi lật)
  const zoom = interpolate(frame, [184, 240], [1, 7], {
    easing: Easing.in(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const worldOpacity = interpolate(frame, [216, 240], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  // parallax: tiền cảnh (bàn + cốc) trôi xuống nhanh hơn khi lao vào
  const foreParallax = interpolate(frame, [184, 240], [0, 520], {
    easing: Easing.in(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const capOpacity = interpolate(frame, [10, 28, 138, 158], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const capY = interpolate(enter, [0, 1], [40, 0]);

  const cupPop = interpolate(frame, [148, 158, 170], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const cupScale = 1 + cupPop * 0.06;

  return (
    <AbsoluteFill>
      {/* caption (không bị zoom) */}
      <div
        style={{
          position: 'absolute',
          top: 150,
          left: 0,
          right: 0,
          textAlign: 'center',
          opacity: capOpacity,
          transform: `translateY(${capY}px)`,
          padding: '0 90px',
        }}
      >
        <span
          style={{
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 64,
            color: COLORS.ink,
            lineHeight: 1.2,
            textShadow: `0 2px 0 ${withAlpha('#FFFFFF', 0.6)}`,
          }}
        >
          Cốc giấy này từ đâu mà ra?
        </span>
      </div>

      <AbsoluteFill
        style={{
          opacity: worldOpacity,
          transform: `scale(${zoom})`,
          transformOrigin: `${PHONE_CX}px ${PHONE_CY}px`,
        }}
      >
        <div style={{ transform: `translateY(${bobY}px)` }}>
          {/* ===== HẬU CẢNH: bé + điện thoại ===== */}
          <div
            style={{
              position: 'absolute',
              left: BOY_LEFT,
              top: BOY_TOP,
              width: BOY_W,
              height: BOY_H,
              transform: `translateX(${enterX}px)`,
            }}
          >
            <Boy blink={blink} wow={wow} />
          </div>

          <div
            style={{
              position: 'absolute',
              left: PHONE_CX - PHONE_W / 2,
              top: PHONE_CY - PHONE_H / 2,
              width: PHONE_W,
              height: PHONE_H,
              transform: `translateX(${enterX}px)`,
            }}
          >
            <FlipPhone width={PHONE_W} height={PHONE_H} flipDeg={flipDeg} flash={flash}>
              <LensOverlay
                scanY={0.5}
                bracketInset={16}
                label=""
                scanning={0}
                showResult={showResult}
                flash={0}
                showBrackets={false}
              />
            </FlipPhone>
          </div>

          {/* ===== TIỀN CẢNH: mặt bàn che chân bé + cốc + bóng ===== */}
          <div style={{ transform: `translateY(${foreParallax}px)` }}>
            {/* bóng bé hắt lên mặt bàn (phía sau cốc) */}
            <div
              style={{
                position: 'absolute',
                left: 250,
                top: DESK_TOP - 26,
                width: 420,
                height: 60,
                borderRadius: '50%',
                background: withAlpha(COLORS.ink, 0.16),
                filter: 'blur(10px)',
              }}
            />
            {/* mặt bàn (tiền cảnh) */}
            <div
              style={{
                position: 'absolute',
                left: -40,
                top: DESK_TOP,
                width: 1160,
                height: 620,
                borderTopLeftRadius: 30,
                borderTopRightRadius: 30,
                background: `linear-gradient(180deg, #F0E2C4 0%, #E2CDA1 30%, #D4BC8A 100%)`,
                boxShadow: `inset 0 4px 0 ${withAlpha('#FFFFFF', 0.7)}, 0 -18px 40px ${withAlpha(COLORS.ink, 0.12)}`,
              }}
            />

            {/* bóng cốc trên mặt bàn */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 110,
                top: DESK_TOP + 4,
                width: 220,
                height: 46,
                borderRadius: '50%',
                background: withAlpha(COLORS.ink, 0.22),
                filter: 'blur(6px)',
              }}
            />
            {/* cốc giấy THẬT (tiền cảnh, to & nét) */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 140,
                top: CUP_CY - 140,
                width: 280,
                height: 280,
                transform: `scale(${cupScale})`,
                transformOrigin: '50% 92%',
                filter: `drop-shadow(0 18px 14px ${withAlpha(COLORS.ink, 0.28)})`,
              }}
            >
              <IconCup size={280} />
            </div>
          </div>

          {/* tia quét + khung lấy nét (overlay trên cùng) */}
          <ScanBeam
            ox={CAM_X}
            oy={CAM_Y}
            tx={CUP_CX}
            ty={CUP_CY - 10}
            size={250}
            lock={lock}
            opacity={beamOpacity}
            dash={dash}
            locked={locked}
          />

          {/* nhãn trạng thái nổi trên cốc */}
          <div
            style={{
              position: 'absolute',
              left: CUP_CX - 160,
              top: CUP_CY - 230,
              width: 320,
              textAlign: 'center',
              opacity: statusOpacity,
            }}
          >
            <span
              style={{
                display: 'inline-block',
                padding: '10px 22px',
                borderRadius: 999,
                background: withAlpha('#06181C', 0.72),
                color: '#EAFBFE',
                fontFamily: BODY,
                fontWeight: 800,
                fontSize: 30,
                whiteSpace: 'nowrap',
                border: `2px solid ${withAlpha(locked ? COLORS.tree : COLORS.teal, 0.7)}`,
              }}
            >
              {statusText}
            </span>
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
