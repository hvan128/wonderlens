import { useCurrentFrame } from 'remotion';
import { COLORS, POP, withAlpha, solidShadow } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconCup, Burst } from './Icons';
import {
  OBJECT_NAME,
  CONFIDENCE,
  MATERIAL_BADGE,
  CAPTURED_LABEL,
  ANALYZING_LABEL,
  OBJECT_FACT_EYEBROW,
  OBJECT_FACT,
} from '../content';

/** Bóng đèn nhỏ (gợi "mẹo / điều thú vị") — vẽ bằng SVG, viền ink. */
const Bulb = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={{ overflow: 'visible' }}>
    <g stroke={COLORS.badgeGoldDark} strokeWidth={2} strokeLinecap="round">
      <line x1="12" y1="1.4" x2="12" y2="3.6" />
      <line x1="3.8" y1="4.8" x2="5.4" y2="6.4" />
      <line x1="20.2" y1="4.8" x2="18.6" y2="6.4" />
    </g>
    <circle cx="12" cy="10" r="5.6" fill={COLORS.badgeGold} stroke={POP.outline} strokeWidth="1.4" />
    <circle cx="10" cy="8.3" r="1.7" fill={withAlpha('#FFFFFF', 0.7)} />
    <rect x="9.3" y="14.6" width="5.4" height="2" rx="1" fill={COLORS.badgeGoldDark} />
    <rect x="10.1" y="16.8" width="3.8" height="1.9" rx="0.95" fill={COLORS.badgeGoldDark} />
  </svg>
);

/** Vòng xoay loading (arc quay liên tục). */
const Spinner = ({ size, spin }: { size: number; spin: number }) => {
  const r = size * 0.4;
  const c = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ transform: `rotate(${spin}deg)` }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={withAlpha(COLORS.teal, 0.25)} strokeWidth={size * 0.13} />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke={COLORS.teal}
        strokeWidth={size * 0.13}
        strokeLinecap="round"
        strokeDasharray={`${c * 0.3} ${c}`}
      />
    </svg>
  );
};

/**
 * Nội dung màn hình "lens" — bản pop: nhãn sticker viền ink, thẻ kết quả
 * nghiêng nhẹ + starburst vàng xoay phía sau.
 *   captured  -> hiện ẢNH VỪA CHỤP (khung crop + "Đã chụp")
 *   analyzing -> lớp loading "Đang phân tích…" (AI đọc ảnh)
 *   showResult-> THẺ THÔNG TIN (có thể overshoot >1 để nảy scale)
 */
export const LensOverlay = ({
  captured = 0,
  analyzing = 0,
  showResult = 0,
  flash = 0,
}: {
  captured?: number;
  analyzing?: number;
  showResult?: number;
  flash?: number;
}) => {
  const frame = useCurrentFrame();
  const photoScale = 0.9 + captured * 0.1;
  const resultIn = Math.min(1, Math.max(0, showResult));
  const photoFade = captured * (1 - resultIn); // ảnh nhường chỗ khi popup kết quả lên
  const sweep = (frame % 36) / 36; // vạch quét AI chạy dọc

  return (
    <div style={{ position: 'absolute', inset: 0, fontFamily: BODY, overflow: 'hidden' }}>
      {/* nền camera */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(90% 70% at 50% 44%, #1E4E5A 0%, #10333C 70%, #0A2027 100%)`,
        }}
      />

      {/* ===== ẢNH VỪA CHỤP ===== */}
      <div style={{ position: 'absolute', inset: 0, opacity: photoFade }}>
        {/* cốc trong ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '47%',
            transform: `translate(-50%, -50%) scale(${photoScale})`,
            filter: `drop-shadow(6px 8px 0 ${withAlpha('#000000', 0.4)})`,
          }}
        >
          <IconCup size={104} />
        </div>
        {/* mặt bàn trong ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '12%',
            right: '12%',
            top: '63%',
            height: 5,
            borderRadius: 3,
            background: withAlpha('#FFFFFF', 0.2),
          }}
        />
        {/* khung crop 4 góc */}
        {(['tl', 'tr', 'bl', 'br'] as const).map((corner) => {
          const top = corner[0] === 't';
          const left = corner[1] === 'l';
          const L = 32;
          const thick = 7;
          const base: React.CSSProperties = {
            position: 'absolute',
            [top ? 'top' : 'bottom']: '7%',
            [left ? 'left' : 'right']: '8%',
            background: '#FFFFFF',
            borderRadius: 3,
            boxShadow: `2px 2px 0 ${withAlpha(POP.shadow, 0.6)}`,
          };
          return (
            <div key={corner}>
              <div style={{ ...base, width: L, height: thick }} />
              <div style={{ ...base, width: thick, height: L }} />
            </div>
          );
        })}
        {/* nhãn "Đã chụp" — sticker trắng viền ink */}
        <div
          style={{
            position: 'absolute',
            top: '7%',
            left: '50%',
            transform: 'translateX(-50%) rotate(-2deg)',
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            padding: '5px 14px',
            borderRadius: 999,
            background: '#FFFFFF',
            border: `3px solid ${POP.outline}`,
            boxShadow: solidShadow(3, 3, withAlpha(POP.shadow, 0.7)),
            color: POP.outline,
            fontWeight: 800,
            fontSize: 17,
            whiteSpace: 'nowrap',
          }}
        >
          <svg width={17} height={17} viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="11" fill={COLORS.tree} stroke={POP.outline} strokeWidth="2" />
            <path
              d="M7 12.5 L10.5 16 L17 8.5"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="2.6"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          {CAPTURED_LABEL}
        </div>
      </div>

      {/* ===== LỚP PHÂN TÍCH (loading) ===== */}
      <div style={{ position: 'absolute', inset: 0, opacity: analyzing, pointerEvents: 'none' }}>
        {/* phủ tối nhẹ để nổi loading */}
        <div style={{ position: 'absolute', inset: 0, background: withAlpha('#04090B', 0.3) }} />
        {/* vạch quét AI chạy trên ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '12%',
            right: '12%',
            top: `${20 + sweep * 46}%`,
            height: 6,
            borderRadius: 3,
            background: COLORS.teal,
            boxShadow: `0 0 22px 7px ${withAlpha(COLORS.teal, 0.7)}`,
          }}
        />
        {/* pill loading: spinner nhỏ + chữ — sticker trắng */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '58%',
            transform: 'translateX(-50%) rotate(1.5deg)',
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: '8px 16px 8px 10px',
            borderRadius: 999,
            background: '#FFFFFF',
            border: `3px solid ${POP.outline}`,
            boxShadow: solidShadow(3, 3, withAlpha(POP.shadow, 0.7)),
          }}
        >
          <Spinner size={26} spin={frame * 10} />
          <span style={{ color: POP.outline, fontWeight: 800, fontSize: 19, whiteSpace: 'nowrap' }}>
            {ANALYZING_LABEL}
          </span>
        </div>
      </div>

      {/* ===== THẺ KẾT QUẢ + STARBURST ===== */}
      {resultIn > 0.01 && (
        <>
          {/* starburst vàng xoay sau thẻ */}
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: '40%',
              width: 400,
              height: 400,
              transform: `translate(-50%, -50%) rotate(${frame * 0.9}deg) scale(${resultIn})`,
              opacity: resultIn,
            }}
          >
            <Burst size={400} color={COLORS.badgeGold} spikes={12} innerRatio={0.68} />
          </div>
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: '40%',
              width: '92%',
              transform: `translate(-50%, calc(-50% + ${(1 - resultIn) * 26}px)) scale(${0.7 + showResult * 0.3}) rotate(-1.5deg)`,
              opacity: resultIn,
              background: '#FFFFFF',
              borderRadius: 24,
              border: `5px solid ${POP.outline}`,
              boxShadow: solidShadow(7, 7, withAlpha(POP.shadow, 0.85)),
              padding: 15,
              boxSizing: 'border-box',
            }}
          >
            {/* header: icon + tên + chất liệu + độ khớp */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div
                style={{
                  width: 54,
                  height: 54,
                  flexShrink: 0,
                  borderRadius: '50%',
                  background: withAlpha(COLORS.badgeGold, 0.25),
                  border: `3px solid ${POP.outline}`,
                  boxSizing: 'border-box',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <IconCup size={34} />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minWidth: 0 }}>
                <span
                  style={{
                    fontFamily: HEADING,
                    fontWeight: 800,
                    fontSize: 27,
                    color: COLORS.ink,
                    lineHeight: 1,
                    whiteSpace: 'nowrap',
                  }}
                >
                  {OBJECT_NAME}
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span
                    style={{
                      padding: '2px 10px',
                      borderRadius: 999,
                      background: withAlpha(COLORS.teal, 0.22),
                      border: `2.5px solid ${POP.outline}`,
                      color: COLORS.tealDark,
                      fontWeight: 800,
                      fontSize: 14,
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {MATERIAL_BADGE}
                  </span>
                  <span
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 4,
                      color: COLORS.treeDark,
                      fontWeight: 800,
                      fontSize: 14,
                      whiteSpace: 'nowrap',
                    }}
                  >
                    <svg width={16} height={16} viewBox="0 0 24 24">
                      <circle cx="12" cy="12" r="11" fill={COLORS.tree} stroke={POP.outline} strokeWidth="2" />
                      <path
                        d="M7 12.5 L10.5 16 L17 8.5"
                        fill="none"
                        stroke="#FFFFFF"
                        strokeWidth="2.8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                    {CONFIDENCE}
                  </span>
                </div>
              </div>
            </div>

            {/* ngăn cách */}
            <div style={{ height: 3, borderRadius: 2, background: withAlpha(POP.outline, 0.15), margin: '11px 0' }} />

            {/* "Bạn có biết?" + lịch sử ra đời */}
            <div style={{ display: 'flex', gap: 9 }}>
              <div style={{ flexShrink: 0, marginTop: 1 }}>
                <Bulb size={24} />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <span style={{ color: COLORS.tealDark, fontWeight: 800, fontSize: 13.5 }}>{OBJECT_FACT_EYEBROW}</span>
                <span style={{ color: COLORS.ink, fontWeight: 700, fontSize: 16, lineHeight: 1.28 }}>{OBJECT_FACT}</span>
              </div>
            </div>
          </div>
        </>
      )}

      {/* chớp shutter (khi vừa bấm chụp) */}
      <div style={{ position: 'absolute', inset: 0, background: '#FFFFFF', opacity: flash, pointerEvents: 'none' }} />
    </div>
  );
};
