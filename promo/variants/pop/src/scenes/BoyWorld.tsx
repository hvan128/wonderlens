import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from 'remotion';
import { COLORS, POP, withAlpha, solidShadow } from '../theme';
import { HEADING, BODY } from '../fonts';
import { Boy } from '../components/Boy';
import { FlipPhone } from '../components/FlipPhone';
import { LensOverlay } from '../components/LensOverlay';
import { ScanBeam } from '../components/ScanBeam';
import { IconCup, Burst } from '../components/Icons';

// bố cục: bé cầm máy, cam SAU hướng xuống cốc thật đặt trên BÀN tiền cảnh.
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

  const enter = spring({ frame, fps, config: { damping: 12, mass: 0.8 }, durationInFrames: 32 });
  const enterX = interpolate(enter, [0, 1], [-420, 0]);

  const diveDamp = interpolate(frame, [236, 266], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  // squash & stretch khi nhún (idle)
  const bobPhase = Math.sin(frame / 11);
  const bobY = bobPhase * 8 * diveDamp;
  const squash = bobPhase * 0.013 * diveDamp;

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
  const analyzing = interpolate(frame, [172, 186, 208, 220], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // kết quả nảy vào có overshoot (comic pop)
  const showResult = interpolate(frame, [218, 240], [0, 1], {
    easing: Easing.out(Easing.back(1.7)),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const resultIn = Math.min(1, Math.max(0, showResult));

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
  // speed lines hội tụ khi lao vào màn hình
  const diveLines =
    interpolate(frame, [246, 258], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }) * worldOpacity;

  const capOpacity = interpolate(frame, [10, 28, 122, 138], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const capY = interpolate(enter, [0, 1], [40, 0]);

  // cốc thật giật nhẹ đúng lúc bấm chụp + lắc lư khi bị quét
  const cupPop = interpolate(frame, [116, 126, 140], [0, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const cupWiggle = Math.sin(frame / 7) * 2.4 * beamOpacity;

  return (
    <AbsoluteFill>
      {/* caption: bong bóng thoại sticker (không bị zoom) */}
      <div
        style={{
          position: 'absolute',
          top: 128,
          left: 0,
          right: 0,
          display: 'flex',
          justifyContent: 'center',
          opacity: capOpacity,
          transform: `translateY(${capY}px)`,
        }}
      >
        <div
          style={{
            position: 'relative',
            transform: 'rotate(-2deg)',
            background: '#FFFFFF',
            border: `6px solid ${POP.outline}`,
            borderRadius: 44,
            padding: '24px 44px',
            boxShadow: solidShadow(10, 10, withAlpha(POP.shadow, 0.3)),
          }}
        >
          <span
            style={{
              fontFamily: HEADING,
              fontWeight: 800,
              fontSize: 60,
              color: COLORS.ink,
              lineHeight: 1.2,
              whiteSpace: 'nowrap',
            }}
          >
            Cốc giấy này từ đâu mà ra?
          </span>
          {/* đuôi bong bóng chỉ xuống bé */}
          <svg
            width={56}
            height={46}
            viewBox="0 0 56 46"
            style={{ position: 'absolute', bottom: -40, left: '22%', overflow: 'visible' }}
          >
            <path d="M4 0 L44 0 L22 40 Z" fill="#FFFFFF" />
            <path d="M4 2 L22 40 L44 2" fill="none" stroke={POP.outline} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
      </div>

      <AbsoluteFill
        style={{
          opacity: worldOpacity,
          transform: `scale(${zoom})`,
          transformOrigin: `${PHONE_CX}px ${FOCUS_CY}px`,
        }}
      >
        <div
          style={{
            transform: `translateY(${bobY}px) scale(${1 - squash}, ${1 + squash})`,
            transformOrigin: '430px 1450px',
          }}
        >
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

          {/* starburst vàng bùng sau máy khi ra kết quả */}
          {resultIn > 0.01 && (
            <div
              style={{
                position: 'absolute',
                left: PHONE_CX - 280,
                top: PHONE_CY - 280,
                width: 560,
                height: 560,
                transform: `rotate(${frame * 0.8}deg) scale(${0.55 + resultIn * 0.45})`,
                opacity: resultIn,
              }}
            >
              <Burst size={560} color={COLORS.badgeGold} spikes={12} innerRatio={0.66} />
            </div>
          )}

          <div
            style={{
              position: 'absolute',
              left: PHONE_CX - PHONE_W / 2,
              top: PHONE_CY - PHONE_H / 2,
              width: PHONE_W,
              height: PHONE_H,
              transform: `translateX(${enterX}px) scale(${1 + flash * 0.05}, ${1 - flash * 0.07})`,
              transformOrigin: '50% 100%',
            }}
          >
            <FlipPhone width={PHONE_W} height={PHONE_H} flipDeg={flipDeg} flash={flash}>
              <LensOverlay captured={captured} analyzing={analyzing} showResult={showResult} flash={0} />
            </FlipPhone>
          </div>

          {/* burst trắng loé ở camera đúng lúc bấm chụp */}
          {flash > 0.01 && (
            <div
              style={{
                position: 'absolute',
                left: CAM_X - 130,
                top: CAM_Y - 130,
                width: 260,
                height: 260,
                transform: `scale(${0.5 + flash * 0.8}) rotate(${frame * 3}deg)`,
                opacity: flash,
              }}
            >
              <Burst size={260} color="#FFF6C9" spikes={8} innerRatio={0.5} />
            </div>
          )}

          {/* ===== TIỀN CẢNH: mặt bàn che chân bé + cốc + bóng ===== */}
          <div style={{ transform: `translateY(${foreParallax}px)` }}>
            {/* bóng bé hắt lên mặt bàn (bóng đặc, không blur) */}
            <div
              style={{
                position: 'absolute',
                left: 250,
                top: DESK_TOP - 22,
                width: 420,
                height: 52,
                borderRadius: '50%',
                background: withAlpha(POP.shadow, 0.15),
              }}
            />
            {/* mặt bàn (tiền cảnh) — khối cam bão hoà + halftone */}
            <div
              style={{
                position: 'absolute',
                left: -40,
                top: DESK_TOP,
                width: 1160,
                height: 620,
                borderTopLeftRadius: 34,
                borderTopRightRadius: 34,
                backgroundColor: POP.orange,
                backgroundImage: `radial-gradient(${withAlpha('#FFFFFF', 0.2)} 6px, transparent 6px)`,
                backgroundSize: '74px 74px',
                borderTop: `7px solid ${POP.outline}`,
                boxSizing: 'border-box',
                boxShadow: `inset 0 10px 0 ${withAlpha('#FFFFFF', 0.35)}`,
              }}
            />

            {/* bóng cốc trên mặt bàn (bóng đặc, ôm sát đáy cốc) */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 86,
                top: CUP_CY + 118,
                width: 180,
                height: 30,
                borderRadius: '50%',
                background: withAlpha(POP.shadow, 0.2),
              }}
            />
            {/* cốc giấy THẬT (tiền cảnh, to & nét, lắc lư khi bị quét) */}
            <div
              style={{
                position: 'absolute',
                left: CUP_CX - 140,
                top: CUP_CY - 140,
                width: 280,
                height: 280,
                transform: `rotate(${cupWiggle}deg) scale(${1 + cupPop * 0.1}, ${1 - cupPop * 0.05})`,
                transformOrigin: '50% 92%',
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

          {/* nhãn trạng thái nổi trên cốc — sticker trắng viền ink */}
          <div
            style={{
              position: 'absolute',
              left: CUP_CX - 180,
              top: CUP_CY - 238,
              width: 360,
              textAlign: 'center',
              opacity: statusOpacity,
            }}
          >
            <span
              style={{
                display: 'inline-block',
                padding: '10px 26px',
                borderRadius: 999,
                background: locked ? '#E4FFDA' : '#FFFFFF',
                color: POP.outline,
                fontFamily: BODY,
                fontWeight: 800,
                fontSize: 31,
                whiteSpace: 'nowrap',
                border: `4px solid ${POP.outline}`,
                boxShadow: solidShadow(5, 5, withAlpha(POP.shadow, 0.35)),
                transform: 'rotate(2deg)',
              }}
            >
              {statusText}
            </span>
          </div>
        </div>
      </AbsoluteFill>

      {/* speed lines comic hội tụ vào màn hình khi lao vào (screen-space) */}
      {diveLines > 0.01 && (
        <AbsoluteFill style={{ opacity: diveLines, pointerEvents: 'none' }}>
          <svg width={1080} height={1920} viewBox="0 0 1080 1920">
            {Array.from({ length: 22 }).map((_, i) => {
              const a = (i / 22) * Math.PI * 2 + frame * 0.06;
              const inner = 430 + ((i * 53 + frame * 34) % 150);
              const outer = inner + 300 + (i % 3) * 120;
              return (
                <line
                  key={i}
                  x1={PHONE_CX + Math.cos(a) * inner}
                  y1={FOCUS_CY + Math.sin(a) * inner}
                  x2={PHONE_CX + Math.cos(a) * outer}
                  y2={FOCUS_CY + Math.sin(a) * outer}
                  stroke={POP.outline}
                  strokeWidth={9 + (i % 3) * 5}
                  strokeLinecap="round"
                  opacity={0.45 + (i % 2) * 0.3}
                />
              );
            })}
          </svg>
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};
