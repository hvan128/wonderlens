import { AbsoluteFill, useCurrentFrame, interpolate, Easing } from 'remotion';
import { CINE, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { StageCard } from '../components/StageCard';
import { Confetti } from '../components/Confetti';
import { Badge } from '../components/Badge';
import { IconCup } from '../components/Icons';
import { CUP_STAGES, OBJECT_NAME } from '../content';

const CARD_TOP = 356;
const CARD_GAP = 300;
const CARD_LEFT = 110;
const SPINE_X = 256;

const ease = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

/**
 * Cảnh D: bên trong app — hành trình tạo ra cốc giấy + huy hiệu.
 * Cinema: đêm tan dần thành BÌNH MINH ẤM; mỗi thẻ được rọi spotlight
 * như sân khấu, spine timeline là dải sáng chảy từ teal -> vàng.
 */
export const TimelineScene = () => {
  const frame = useCurrentFrame();

  const sceneOpacity = ease(frame, 0, 20);
  const sceneScale = interpolate(frame, [0, 28], [1.06, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const headerIn = ease(frame, 6, 28);
  const badgeIn = ease(frame, 132, 152);
  const spineGrow = ease(frame, 26, 120);
  const spineH = 3 * CARD_GAP;

  // đêm -> bình minh: lớp đêm mờ dần trong ~3s đầu cảnh
  const nightFade = interpolate(frame, [0, 88], [1, 0], {
    easing: Easing.inOut(Easing.quad),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // mặt trời hửng dần từ đáy khung
  const sunUp = ease(frame, 20, 110);

  // xung sáng chạy dọc spine (loop tất định)
  const pulseY = spineGrow > 0.05 ? ((frame * 9) % (spineH * spineGrow + 120)) - 60 : -999;

  return (
    <AbsoluteFill style={{ opacity: sceneOpacity }}>
      <AbsoluteFill style={{ transform: `scale(${sceneScale})` }}>
        {/* nền bình minh ấm */}
        <AbsoluteFill
          style={{
            background: `linear-gradient(180deg, ${CINE.dawnTop} 0%, ${CINE.dawnIndigo} 26%, ${CINE.dawnRose} 56%, ${CINE.dawnOrange} 79%, ${CINE.dawnGold} 100%)`,
          }}
        />
        {/* lớp đêm phủ trên — tan dần (chuyển cảm xúc lạnh -> ấm) */}
        <AbsoluteFill
          style={{
            background: `linear-gradient(185deg, ${CINE.skyTop} 0%, ${CINE.skyMid} 50%, ${CINE.horizon} 100%)`,
            opacity: nightFade,
          }}
        />
        {/* vầng mặt trời hửng lên từ đáy */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            bottom: -140,
            width: 1100,
            height: 620,
            transform: 'translateX(-50%)',
            background: `radial-gradient(50% 60% at 50% 100%, ${withAlpha('#FFE3A6', 0.75 * sunUp)} 0%, ${withAlpha(CINE.dawnGold, 0.3 * sunUp)} 55%, transparent 78%)`,
            filter: 'blur(8px)',
          }}
        />

        {/* header */}
        <div
          style={{
            position: 'absolute',
            top: 150,
            left: 0,
            right: 0,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 6,
            opacity: headerIn,
            transform: `translateY(${(1 - headerIn) * -24}px)`,
          }}
        >
          <span
            style={{
              fontFamily: BODY,
              fontWeight: 800,
              fontSize: 30,
              letterSpacing: 4,
              color: withAlpha('#FFEEDC', 0.82),
              textShadow: `0 2px 12px ${withAlpha('#0A0A1E', 0.5)}`,
            }}
          >
            HÀNH TRÌNH TẠO RA
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ filter: `drop-shadow(0 0 14px ${withAlpha(CINE.warm, 0.65)})` }}>
              <IconCup size={74} />
            </div>
            <span
              style={{
                fontFamily: HEADING,
                fontWeight: 800,
                fontSize: 86,
                color: '#FFF4E0',
                textShadow: `0 0 34px ${withAlpha(CINE.warm, 0.55)}, 0 4px 18px ${withAlpha('#1A0F2B', 0.6)}`,
              }}
            >
              {OBJECT_NAME}
            </span>
          </div>
        </div>

        {/* đường timeline (spine) — dải sáng chảy teal -> vàng */}
        <div
          style={{
            position: 'absolute',
            left: SPINE_X - 5,
            top: CARD_TOP + 134,
            width: 10,
            height: spineH * spineGrow,
            borderRadius: 5,
            background: `linear-gradient(180deg, ${CINE.neonSoft} 0%, ${CINE.neon} 34%, ${CINE.warm} 78%, ${CINE.warmSoft} 100%)`,
            boxShadow: `0 0 24px ${withAlpha(CINE.warm, 0.55)}, 0 0 8px ${withAlpha('#FFFFFF', 0.5)}`,
            overflow: 'hidden',
          }}
        >
          {/* xung sáng trắng chạy dọc spine */}
          <div
            style={{
              position: 'absolute',
              left: 0,
              right: 0,
              top: pulseY,
              height: 90,
              background: `linear-gradient(180deg, transparent, ${withAlpha('#FFFFFF', 0.95)}, transparent)`,
            }}
          />
        </div>

        {/* 4 thẻ chặng + spotlight sân khấu rọi từng thẻ */}
        {CUP_STAGES.map((stage, i) => {
          const start = 26 + i * 22;
          const enter = ease(frame, start, start + 18);
          return (
            <div key={stage.icon}>
              {/* nón spotlight rọi từ trên xuống thẻ */}
              <div
                style={{
                  position: 'absolute',
                  left: CARD_LEFT + 160,
                  top: CARD_TOP + i * CARD_GAP - 170,
                  width: 560,
                  height: 400,
                  background: `linear-gradient(180deg, ${withAlpha('#FFF2D2', 0)} 0%, ${withAlpha('#FFF2D2', 0.09)} 40%, ${withAlpha('#FFE9B8', 0.32)} 100%)`,
                  clipPath: 'polygon(44% 0%, 56% 0%, 100% 100%, 0% 100%)',
                  filter: 'blur(10px)',
                  opacity: enter,
                }}
              />
              <div style={{ position: 'absolute', left: CARD_LEFT, top: CARD_TOP + i * CARD_GAP }}>
                <StageCard stage={stage} index={i} enter={enter} />
              </div>
            </div>
          );
        })}

        {/* huy hiệu vật liệu */}
        <div
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            top: 1632,
            display: 'flex',
            justifyContent: 'center',
          }}
        >
          <Badge enter={badgeIn} />
        </div>

        {/* confetti khi mở huy hiệu */}
        <Confetti originXRatio={0.5} originYRatio={0.74} startFrame={130} count={90} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
