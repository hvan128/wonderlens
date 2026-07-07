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
import { glassFill, glassBorder, glassBlur, Specular } from '../components/Glass';
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
  const analyzing = interpolate(frame, [172, 186, 206, 218], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const showResult = interpolate(frame, [214, 232], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

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
            position: 'relative',
            display: 'inline-block',
            padding: '20px 48px',
            borderRadius: 999,
            background: glassFill(0.13),
            border: glassBorder(0.4),
            boxShadow: `0 22px 50px ${withAlpha('#02222B', 0.4)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.4)}`,
            ...glassBlur(16),
            fontFamily: HEADING,
            fontWeight: 800,
            fontSize: 60,
            color: '#FFFFFF',
            lineHeight: 1.2,
            textShadow: `0 2px 12px ${withAlpha('#02222B', 0.5)}`,
          }}
        >
          <Specular radius={999} strength={0.26} />
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
              // tăng saturation nhẹ + rim light teal để bé nổi trên nền đậm
              filter: `saturate(1.14) drop-shadow(-16px -10px 24px ${withAlpha('#41E0F2', 0.55)}) drop-shadow(10px 14px 26px ${withAlpha('#02222B', 0.45)})`,
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
                background: withAlpha('#02222B', 0.3),
                filter: 'blur(10px)',
              }}
            />
            {/* mặt bàn KÍNH (tiền cảnh) — tấm glass mờ, thấy chân bé mờ phía sau */}
            <div
              style={{
                position: 'absolute',
                left: -40,
                top: DESK_TOP,
                width: 1160,
                height: 620,
                borderTopLeftRadius: 30,
                borderTopRightRadius: 30,
                // frosted đậm hơn để vật phía sau chỉ còn là bóng mờ dịu (không thành vệt tối)
                background: `linear-gradient(180deg, ${withAlpha('#C9EFF6', 0.42)} 0%, ${withAlpha('#9BDCE9', 0.34)} 45%, ${withAlpha('#78C4D6', 0.3)} 100%)`,
                borderTop: glassBorder(0.6, 2),
                boxShadow: `inset 0 2px 0 ${withAlpha('#FFFFFF', 0.55)}, 0 -24px 60px ${withAlpha('#02222B', 0.3)}`,
                ...glassBlur(30),
              }}
            />
            {/* specular trên mặt bàn kính — fade dọc để không lộ mép cắt */}
            <div
              style={{
                position: 'absolute',
                left: -40,
                top: DESK_TOP,
                width: 1160,
                height: 220,
                borderTopLeftRadius: 30,
                borderTopRightRadius: 30,
                pointerEvents: 'none',
                background: `linear-gradient(180deg, ${withAlpha('#FFFFFF', 0.24)} 0%, ${withAlpha('#FFFFFF', 0.08)} 45%, transparent 100%)`,
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
                background: withAlpha('#02222B', 0.38),
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
                filter: `drop-shadow(0 18px 14px ${withAlpha('#02222B', 0.45)}) drop-shadow(0 0 20px ${withAlpha(COLORS.teal, 0.25)})`,
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
                background: withAlpha('#0A2A33', 0.55),
                color: '#EAFBFE',
                fontFamily: BODY,
                fontWeight: 800,
                fontSize: 30,
                whiteSpace: 'nowrap',
                border: `1.5px solid ${withAlpha('#FFFFFF', 0.45)}`,
                boxShadow: `inset 0 1px 0 ${withAlpha('#FFFFFF', 0.35)}, 0 0 22px ${withAlpha(locked ? '#7ED957' : COLORS.teal, 0.5)}`,
                ...glassBlur(12),
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
