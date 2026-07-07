import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from 'remotion';
import { CINE, withAlpha } from '../theme';
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
// tâm để "lao vào" — khớp thẻ kết quả (~42% màn hình, nằm trên mép bàn)
const FOCUS_CY = 1240;

export const BoyWorld = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({ frame, fps, config: { damping: 14, mass: 0.8 }, durationInFrames: 32 });
  const enterX = interpolate(enter, [0, 1], [-400, 0]);

  const diveDamp = interpolate(frame, [236, 266], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const bobY = Math.sin(frame / 11) * 7 * diveDamp;

  const blinkPhase = frame % 78;
  const blink = blinkPhase < 6 ? 1 - Math.abs(blinkPhase - 3) / 3 : 0;
  // "wow" bật lên ngay khi chụp được, giữ tới lúc lao vào
  const wow = interpolate(frame, [118, 140], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // NGẮM & QUÉT: cam sau chĩa vào cốc, tia quét khoá mục tiêu
  const beamOpacity = interpolate(frame, [58, 72, 120, 134], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const lock = interpolate(frame, [70, 116], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const locked = frame >= 116;
  const dash = frame * 5;

  // CHỤP: loé flash đèn cam sau
  const flash = interpolate(frame, [116, 126, 140], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // LẬT máy lại để xem màn hình: 0 = lưng (cam sau) -> 180 = màn hình
  const flipDeg = interpolate(frame, [132, 158], [0, 180], {
    easing: Easing.inOut(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // 3 trạng thái màn hình sau khi lật: ảnh vừa chụp -> AI phân tích -> kết quả
  const captured = interpolate(frame, [150, 164], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const analyzing = interpolate(frame, [172, 186, 214, 228], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const showResult = interpolate(frame, [224, 246], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const statusText = frame < 84 ? 'Đưa máy vào cốc' : frame < 116 ? 'Đang quét…' : 'Đã chụp!';
  const statusOpacity = interpolate(frame, [12, 26, 130, 144], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // lao vào màn hình (sau khi có kết quả)
  const zoom = interpolate(frame, [244, 280], [1, 7], {
    easing: Easing.in(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const worldOpacity = interpolate(frame, [262, 280], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  // parallax: tiền cảnh (bàn + cốc) trôi xuống nhanh hơn khi lao vào
  const foreParallax = interpolate(frame, [244, 280], [0, 520], {
    easing: Easing.in(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const capOpacity = interpolate(frame, [10, 28, 122, 138], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const capY = interpolate(enter, [0, 1], [40, 0]);

  // cốc thật giật nhẹ đúng lúc bấm chụp
  const cupPop = interpolate(frame, [116, 126, 140], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const cupScale = 1 + cupPop * 0.06;

  // spotlight ấm "thở" nhẹ theo frame — sân khấu sống
  const breath = 1 + Math.sin(frame / 24) * 0.04;
  // màn hình sáng lên khi lật xong -> hắt sáng teal quanh máy
  const screenGlow = interpolate(flipDeg, [120, 180], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill>
      {/* caption (không bị zoom) — chữ sáng trên nền đêm */}
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
            color: CINE.textLight,
            lineHeight: 1.2,
            textShadow: `0 0 32px ${withAlpha(CINE.neon, 0.45)}, 0 4px 20px ${withAlpha('#000000', 0.55)}`,
          }}
        >
          Cốc giấy này từ đâu mà ra?
        </span>
      </div>

      <AbsoluteFill
        style={{
          opacity: worldOpacity,
          transform: `scale(${zoom})`,
          transformOrigin: `${PHONE_CX}px ${FOCUS_CY}px`,
        }}
      >
        <div style={{ transform: `translateY(${bobY}px)` }}>
          {/* ===== SPOTLIGHT ấm rọi xuống cốc (sau lưng nhân vật) ===== */}
          <div
            style={{
              position: 'absolute',
              left: CUP_CX - 300,
              top: 320,
              width: 600,
              height: DESK_TOP - 290,
              transform: `scaleX(${breath})`,
              transformOrigin: '50% 100%',
              background: `linear-gradient(180deg, ${withAlpha(CINE.warmSoft, 0)} 0%, ${withAlpha(CINE.warmSoft, 0.05)} 42%, ${withAlpha(CINE.warm, 0.14)} 100%)`,
              clipPath: 'polygon(41% 0%, 59% 0%, 100% 100%, 0% 100%)',
              filter: 'blur(14px)',
            }}
          />

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

          {/* quầng sáng teal hắt ra từ màn hình khi lật xong */}
          <div
            style={{
              position: 'absolute',
              left: PHONE_CX - PHONE_W,
              top: PHONE_CY - PHONE_H,
              width: PHONE_W * 2,
              height: PHONE_H * 2,
              borderRadius: '50%',
              background: `radial-gradient(circle, ${withAlpha(CINE.neon, 0.22)} 0%, transparent 62%)`,
              opacity: screenGlow,
              filter: 'blur(10px)',
            }}
          />

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
              <LensOverlay captured={captured} analyzing={analyzing} showResult={showResult} flash={0} />
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
                background: withAlpha('#01090D', 0.4),
                filter: 'blur(10px)',
              }}
            />
            {/* mặt bàn (tiền cảnh) — gỗ tối trong đêm */}
            <div
              style={{
                position: 'absolute',
                left: -40,
                top: DESK_TOP,
                width: 1160,
                height: 620,
                borderTopLeftRadius: 30,
                borderTopRightRadius: 30,
                background: `linear-gradient(180deg, #274652 0%, #1A323C 34%, #101F27 100%)`,
                boxShadow: `inset 0 3px 0 ${withAlpha(CINE.neonSoft, 0.22)}, 0 -18px 40px ${withAlpha('#000A10', 0.5)}`,
              }}
            />
            {/* vũng sáng spotlight ấm trên mặt bàn quanh cốc */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 330,
                top: DESK_TOP - 8,
                width: 660,
                height: 260,
                background: `radial-gradient(50% 42% at 50% 26%, ${withAlpha(CINE.warm, 0.5)} 0%, ${withAlpha(CINE.warm, 0.16)} 52%, transparent 76%)`,
                transform: `scaleX(${breath})`,
                filter: 'blur(6px)',
              }}
            />

            {/* bóng cốc trên mặt bàn — contact shadow mềm, không át vũng sáng */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 92,
                top: DESK_TOP + 6,
                width: 184,
                height: 34,
                borderRadius: '50%',
                background: withAlpha('#02141B', 0.32),
                filter: 'blur(11px)',
              }}
            />
            {/* cốc giấy THẬT (tiền cảnh, to & nét) — "nhân vật chính" trong vũng sáng */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 140,
                top: CUP_CY - 140,
                width: 280,
                height: 280,
                transform: `scale(${cupScale})`,
                transformOrigin: '50% 92%',
                filter: `drop-shadow(0 18px 14px ${withAlpha('#01090D', 0.6)}) drop-shadow(0 0 26px ${withAlpha(CINE.warm, 0.5)})`,
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

          {/* nhãn trạng thái nổi trên cốc — pill HUD phát sáng */}
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
                background: withAlpha('#03141A', 0.78),
                color: CINE.textLight,
                fontFamily: BODY,
                fontWeight: 800,
                fontSize: 30,
                whiteSpace: 'nowrap',
                border: `2px solid ${withAlpha(locked ? '#5CE6A1' : CINE.neon, 0.85)}`,
                boxShadow: `0 0 22px ${withAlpha(locked ? '#5CE6A1' : CINE.neon, 0.45)}`,
                textShadow: `0 0 12px ${withAlpha(locked ? '#5CE6A1' : CINE.neon, 0.6)}`,
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
