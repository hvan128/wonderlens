import { useCurrentFrame } from 'remotion';
import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconCup } from './Icons';
import { glassFill, glassBorder, glassBlur, Specular } from './Glass';
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
    <g stroke={COLORS.badgeGold} strokeWidth={1.7} strokeLinecap="round">
      <line x1="12" y1="1.4" x2="12" y2="3.6" />
      <line x1="3.8" y1="4.8" x2="5.4" y2="6.4" />
      <line x1="20.2" y1="4.8" x2="18.6" y2="6.4" />
    </g>
    <circle cx="12" cy="10" r="5.6" fill={COLORS.badgeGold} />
    <circle cx="10" cy="8.3" r="1.7" fill={withAlpha('#FFFFFF', 0.6)} />
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
 * Nội dung màn hình "lens" sau khi đã chĩa cam sau vào cốc:
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
      {/* nền camera */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(90% 70% at 50% 44%, #20424B 0%, #11272D 70%, #0A1A1F 100%)`,
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
            background: withAlpha('#0A2A33', 0.55),
            border: `1.5px solid ${withAlpha('#FFFFFF', 0.4)}`,
            boxShadow: `inset 0 1px 0 ${withAlpha('#FFFFFF', 0.3)}, 0 0 16px ${withAlpha(COLORS.teal, 0.35)}`,
            ...glassBlur(10),
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
        {/* vạch quét AI chạy trên ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '12%',
            right: '12%',
            top: `${20 + sweep * 46}%`,
            height: 4,
            borderRadius: 3,
            background: COLORS.teal,
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
            background: withAlpha('#0A2A33', 0.6),
            border: `1.5px solid ${withAlpha('#FFFFFF', 0.4)}`,
            boxShadow: `inset 0 1px 0 ${withAlpha('#FFFFFF', 0.3)}, 0 0 18px ${withAlpha(COLORS.teal, 0.4)}`,
            ...glassBlur(10),
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
            background: glassFill(0.22),
            border: glassBorder(0.45, 1.5),
            borderRadius: 26,
            boxShadow: `0 22px 44px ${withAlpha('#02222B', 0.5)}, 0 0 30px ${withAlpha(COLORS.teal, 0.3)}, inset 0 1.5px 0 ${withAlpha('#FFFFFF', 0.45)}`,
            ...glassBlur(16),
            padding: 18,
            boxSizing: 'border-box',
          }}
        >
          <Specular radius={26} strength={0.26} />
          {/* header: icon + tên + chất liệu + độ khớp */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 52,
                height: 52,
                flexShrink: 0,
                borderRadius: '50%',
                background: withAlpha('#FFFFFF', 0.92),
                border: `1.5px solid ${withAlpha('#FFFFFF', 0.6)}`,
                boxShadow: `0 0 14px ${withAlpha(COLORS.teal, 0.4)}`,
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
                  color: '#FFFFFF',
                  textShadow: `0 1px 6px ${withAlpha('#02222B', 0.4)}`,
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
                    background: withAlpha(COLORS.teal, 0.32),
                    border: `1px solid ${withAlpha('#FFFFFF', 0.4)}`,
                    color: '#DFF9FD',
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
                    color: '#8CF0A6',
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
          <div style={{ height: 1.5, background: withAlpha('#FFFFFF', 0.22), margin: '14px 0' }} />

          {/* "Bạn có biết?" + lịch sử ra đời */}
          <div style={{ display: 'flex', gap: 10 }}>
            <div style={{ flexShrink: 0, marginTop: 1 }}>
              <Bulb size={26} />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <span style={{ color: '#7FE7F5', fontWeight: 800, fontSize: 14 }}>{OBJECT_FACT_EYEBROW}</span>
              <span style={{ color: '#F1FBFD', fontWeight: 600, fontSize: 17, lineHeight: 1.3 }}>{OBJECT_FACT}</span>
            </div>
          </div>
        </div>
      )}

      {/* chớp shutter (khi vừa bấm chụp) */}
      <div style={{ position: 'absolute', inset: 0, background: '#FFFFFF', opacity: flash, pointerEvents: 'none' }} />
    </div>
  );
};
