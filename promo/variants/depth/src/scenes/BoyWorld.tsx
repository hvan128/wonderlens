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
  // "wow" nảy lên bằng spring ngay khi chụp được, giữ tới lúc lao vào
  const wow = spring({ frame: frame - 118, fps, config: { damping: 11, mass: 0.6 }, durationInFrames: 26 });

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
  // kết quả bật lên có độ nảy (spring) thay easing tuyến tính
  const showResult = spring({ frame: frame - 224, fps, config: { damping: 13, mass: 0.7 }, durationInFrames: 24 });

  // ánh màn hình hắt lên mặt bé sau khi lật xong (mạnh hơn khi có kết quả)
  const screenGlow =
    interpolate(frame, [152, 170], [0, 0.65], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }) +
    interpolate(frame, [224, 242], [0, 0.35], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

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

  // cốc thật nảy nhẹ đúng lúc bấm chụp (spring cho cảm giác vật lý, nhả mượt)
  const cupPop = spring({ frame: frame - 116, fps, config: { damping: 9, mass: 0.5 }, durationInFrames: 22 });
  const cupRelease = interpolate(frame, [134, 154], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const cupScale = 1 + cupPop * 0.06 * cupRelease;

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
            textShadow: `0 2px 0 ${withAlpha('#FFFFFF', 0.8)}, 0 10px 26px ${withAlpha('#8A6A3A', 0.22)}`,
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
            <Boy blink={blink} wow={wow} glow={screenGlow} />
          </div>

          {/* hào quang màn hình hắt ra không gian (sau khi lật máy) */}
          <div
            style={{
              position: 'absolute',
              left: PHONE_CX - 330,
              top: PHONE_CY - 400,
              width: 660,
              height: 660,
              borderRadius: '50%',
              background: `radial-gradient(circle, ${withAlpha('#9FF2FF', 0.32)} 0%, ${withAlpha(COLORS.teal, 0.1)} 45%, transparent 70%)`,
              opacity: screenGlow,
              mixBlendMode: 'screen',
              transform: `translateX(${enterX}px)`,
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

          {/* bùng sáng flash tại camera sau lúc bấm chụp */}
          <div
            style={{
              position: 'absolute',
              left: CAM_X - 220,
              top: CAM_Y - 220,
              width: 440,
              height: 440,
              borderRadius: '50%',
              background: `radial-gradient(circle, ${withAlpha('#FFFCEE', 0.95)} 0%, ${withAlpha('#FFE7A0', 0.45)} 40%, transparent 70%)`,
              opacity: flash,
              mixBlendMode: 'screen',
              pointerEvents: 'none',
            }}
          />

          {/* ===== TIỀN CẢNH: mặt bàn che chân bé + cốc + bóng ===== */}
          <div style={{ transform: `translateY(${foreParallax}px)` }}>
            {/* bóng bé hắt lên mặt bàn (phía sau cốc) — dài & mềm theo hướng nắng */}
            <div
              style={{
                position: 'absolute',
                left: 250,
                top: DESK_TOP - 26,
                width: 460,
                height: 64,
                borderRadius: '50%',
                background: `radial-gradient(50% 50% at 42% 50%, ${withAlpha(COLORS.ink, 0.22)} 0%, transparent 75%)`,
                filter: 'blur(12px)',
                transform: 'rotate(-2deg)',
              }}
            />
            {/* mặt bàn (tiền cảnh) — gỗ ấm + sáng dần về nguồn nắng trên-trái */}
            <div
              style={{
                position: 'absolute',
                left: -40,
                top: DESK_TOP,
                width: 1160,
                height: 620,
                borderTopLeftRadius: 30,
                borderTopRightRadius: 30,
                background: `linear-gradient(180deg, #F5E7C9 0%, #E4CFA3 26%, #D2B987 62%, #C0A672 100%)`,
                boxShadow: `inset 0 4px 0 ${withAlpha('#FFFFFF', 0.75)}, inset 0 30px 60px ${withAlpha('#FFF6DE', 0.5)}, 0 -18px 40px ${withAlpha(COLORS.ink, 0.12)}`,
              }}
            />
            {/* vệt nắng ấm loang trên mặt bàn quanh cốc */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 320,
                top: DESK_TOP - 20,
                width: 640,
                height: 260,
                background: `radial-gradient(50% 45% at 50% 30%, ${withAlpha('#FFF3CC', 0.55)} 0%, transparent 70%)`,
              }}
            />

            {/* bóng cốc trên mặt bàn — mềm, lệch phải theo nguồn sáng trái */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 96,
                top: DESK_TOP + 2,
                width: 250,
                height: 50,
                borderRadius: '50%',
                background: `radial-gradient(50% 50% at 42% 50%, ${withAlpha(COLORS.ink, 0.3)} 0%, ${withAlpha(COLORS.ink, 0.12)} 55%, transparent 78%)`,
                filter: 'blur(7px)',
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
                boxShadow: `0 0 22px ${withAlpha(locked ? COLORS.tree : COLORS.teal, 0.35)}`,
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
