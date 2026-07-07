import { useCurrentFrame } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconCup } from './Icons';
import {
  OBJECT_NAME,
  CONFIDENCE,
  MATERIAL_BADGE,
  CAPTURED_LABEL,
  ANALYZING_LABEL,
  OBJECT_FACT_EYEBROW,
  OBJECT_FACT,
} from '../content';

/** Bóng đèn nhỏ (gợi "mẹo / điều thú vị") — vẽ bằng SVG. */
const Bulb = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <defs>
      <radialGradient id="wlBulbGold" cx="0.38" cy="0.32" r="0.95">
        <stop offset="0" stopColor="#FFE9A8" />
        <stop offset="1" stopColor={COLORS.badgeGoldDark} />
      </radialGradient>
    </defs>
    <g stroke={COLORS.badgeGold} strokeWidth={1.7} strokeLinecap="round">
      <line x1="12" y1="1.4" x2="12" y2="3.6" />
      <line x1="3.8" y1="4.8" x2="5.4" y2="6.4" />
      <line x1="20.2" y1="4.8" x2="18.6" y2="6.4" />
    </g>
    <circle cx="12" cy="10" r="5.6" fill="url(#wlBulbGold)" />
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
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={withAlpha(COLORS.teal, 0.18)} strokeWidth={size * 0.1} />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke={COLORS.teal}
        strokeWidth={size * 0.1}
        strokeLinecap="round"
        strokeDasharray={`${c * 0.3} ${c}`}
      />
    </svg>
  );
};

/**
 * Nội dung màn hình "lens" — bản "depth": nền camera có vignette,
 * vạch quét AI glow mạnh, thẻ kết quả giấy ấm có ánh sáng.
 *   captured  -> hiện ẢNH VỪA CHỤP (khung crop + "Đã chụp")
 *   analyzing -> lớp loading "Đang phân tích…" (AI đọc ảnh)
 *   showResult-> THẺ THÔNG TIN: tên + chất liệu + độ khớp + "Bạn có biết?"
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
  const photoFade = captured * (1 - showResult); // ảnh nhường chỗ khi popup kết quả lên
  const sweep = (frame % 36) / 36; // vạch quét AI chạy dọc

  return (
    <div style={{ position: 'absolute', inset: 0, fontFamily: BODY, overflow: 'hidden' }}>
      {/* nền camera + vignette ống kính */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(90% 70% at 50% 44%, #26505B 0%, #12292F 62%, #060F12 100%)`,
        }}
      />

      {/* ===== ẢNH VỪA CHỤP ===== */}
      <div style={{ position: 'absolute', inset: 0, opacity: photoFade }}>
        {/* vũng sáng dưới cốc trong ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '47%',
            width: 180,
            height: 180,
            transform: 'translate(-50%, -50%)',
            borderRadius: '50%',
            background: `radial-gradient(circle, ${withAlpha(COLORS.teal, 0.22)} 0%, transparent 65%)`,
          }}
        />
        {/* cốc trong ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '47%',
            transform: `translate(-50%, -50%) scale(${photoScale})`,
            filter: `drop-shadow(0 18px 16px ${withAlpha('#000000', 0.45)})`,
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
            height: 4,
            borderRadius: 2,
            background: withAlpha('#FFFFFF', 0.16),
          }}
        />
        {/* khung crop 4 góc */}
        {(['tl', 'tr', 'bl', 'br'] as const).map((corner) => {
          const top = corner[0] === 't';
          const left = corner[1] === 'l';
          const L = 30;
          const thick = 5;
          const base: React.CSSProperties = {
            position: 'absolute',
            [top ? 'top' : 'bottom']: '7%',
            [left ? 'left' : 'right']: '8%',
            background: withAlpha('#FFFFFF', 0.85),
            borderRadius: 3,
            boxShadow: `0 0 10px ${withAlpha(COLORS.teal, 0.6)}`,
          };
          return (
            <div key={corner}>
              <div style={{ ...base, width: L, height: thick }} />
              <div style={{ ...base, width: thick, height: L }} />
            </div>
          );
        })}
        {/* nhãn "Đã chụp" */}
        <div
          style={{
            position: 'absolute',
            top: '7%',
            left: '50%',
            transform: 'translateX(-50%)',
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            padding: '5px 13px',
            borderRadius: 999,
            background: withAlpha('#06181C', 0.7),
            border: `2px solid ${withAlpha(COLORS.teal, 0.55)}`,
            boxShadow: `0 0 18px ${withAlpha(COLORS.teal, 0.35)}`,
            color: '#EAFBFE',
            fontWeight: 800,
            fontSize: 17,
            whiteSpace: 'nowrap',
          }}
        >
          <svg width={16} height={16} viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="11" fill={COLORS.tree} />
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
        {/* vạch quét AI chạy trên ảnh — glow 2 lớp */}
        <div
          style={{
            position: 'absolute',
            left: '12%',
            right: '12%',
            top: `${20 + sweep * 46}%`,
            height: 26,
            transform: 'translateY(-11px)',
            borderRadius: 13,
            background: `radial-gradient(50% 100% at 50% 50%, ${withAlpha(COLORS.teal, 0.4)} 0%, transparent 75%)`,
          }}
        />
        <div
          style={{
            position: 'absolute',
            left: '12%',
            right: '12%',
            top: `${20 + sweep * 46}%`,
            height: 4,
            borderRadius: 3,
            background: `linear-gradient(90deg, ${withAlpha(COLORS.teal, 0.2)} 0%, #9FF2FF 50%, ${withAlpha(COLORS.teal, 0.2)} 100%)`,
            boxShadow: `0 0 22px 7px ${withAlpha(COLORS.teal, 0.7)}`,
          }}
        />
        {/* pill loading: spinner nhỏ + chữ (gọn, nằm trọn trên mép bàn) */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '58%',
            transform: 'translateX(-50%)',
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: '8px 16px 8px 10px',
            borderRadius: 999,
            background: withAlpha('#06181C', 0.78),
            border: `2px solid ${withAlpha(COLORS.teal, 0.4)}`,
            boxShadow: `0 0 20px ${withAlpha(COLORS.teal, 0.3)}`,
          }}
        >
          <Spinner size={26} spin={frame * 10} />
          <span style={{ color: '#EAFBFE', fontWeight: 800, fontSize: 19, whiteSpace: 'nowrap' }}>
            {ANALYZING_LABEL}
          </span>
        </div>
      </div>

      {/* ===== THẺ KẾT QUẢ ===== */}
      {showResult > 0.01 && (
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '42%',
            width: '92%',
            transform: `translate(-50%, calc(-50% + ${(1 - showResult) * 26}px)) scale(${0.8 + showResult * 0.2})`,
            opacity: showResult,
            background: 'linear-gradient(172deg, #FFFFFF 0%, #FBFEFF 60%, #F2FAFB 100%)',
            borderRadius: 26,
            boxShadow: `0 22px 44px ${withAlpha('#02171C', 0.55)}, 0 0 40px ${withAlpha(COLORS.teal, 0.28)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.95)}`,
            padding: 18,
            boxSizing: 'border-box',
          }}
        >
          {/* header: icon + tên + chất liệu + độ khớp */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 52,
                height: 52,
                flexShrink: 0,
                borderRadius: '50%',
                background: `radial-gradient(circle at 34% 28%, #FFFFFF 0%, ${COLORS.paperWarm} 100%)`,
                boxShadow: `inset 0 -3px 6px ${withAlpha(COLORS.ink, 0.1)}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <IconCup size={36} />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minWidth: 0 }}>
              <span
                style={{
                  fontFamily: HEADING,
                  fontWeight: 800,
                  fontSize: 26,
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
                    padding: '3px 10px',
                    borderRadius: 999,
                    background: `linear-gradient(180deg, ${withAlpha(COLORS.teal, 0.2)} 0%, ${withAlpha(COLORS.teal, 0.12)} 100%)`,
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
                    color: COLORS.tree,
                    fontWeight: 800,
                    fontSize: 14,
                    whiteSpace: 'nowrap',
                  }}
                >
                  <svg width={15} height={15} viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="11" fill={COLORS.tree} />
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
          <div style={{ height: 1.5, background: withAlpha(COLORS.ink, 0.1), margin: '14px 0' }} />

          {/* "Bạn có biết?" + lịch sử ra đời */}
          <div style={{ display: 'flex', gap: 10 }}>
            <div style={{ flexShrink: 0, marginTop: 1 }}>
              <Bulb size={26} />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <span style={{ color: COLORS.tealDark, fontWeight: 800, fontSize: 14 }}>{OBJECT_FACT_EYEBROW}</span>
              <span style={{ color: COLORS.ink, fontWeight: 600, fontSize: 17, lineHeight: 1.3 }}>{OBJECT_FACT}</span>
            </div>
          </div>
        </div>
      )}

      {/* chớp shutter (khi vừa bấm chụp) */}
      <div style={{ position: 'absolute', inset: 0, background: '#FFFFFF', opacity: flash, pointerEvents: 'none' }} />
    </div>
  );
};
