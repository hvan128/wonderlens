import { useCurrentFrame } from 'remotion';
import { COLORS, CINE, seeded, withAlpha } from '../theme';
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

// mốc scene-frame khi thẻ kết quả bắt đầu hiện (khớp BoyWorld: showResult 224->246)
const RESULT_BURST_FRAME = 224;

/** Bóng đèn nhỏ (gợi "mẹo / điều thú vị") — vẽ bằng SVG. */
const Bulb = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={{ filter: `drop-shadow(0 0 6px ${withAlpha(COLORS.badgeGold, 0.8)})` }}>
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

/** Vòng xoay loading (arc quay liên tục) — phát sáng neon. */
const Spinner = ({ size, spin }: { size: number; spin: number }) => {
  const r = size * 0.4;
  const c = 2 * Math.PI * r;
  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      style={{ transform: `rotate(${spin}deg)`, filter: `drop-shadow(0 0 5px ${withAlpha(CINE.neon, 0.9)})` }}
    >
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={withAlpha(CINE.neon, 0.2)} strokeWidth={size * 0.1} />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke={CINE.neonSoft}
        strokeWidth={size * 0.1}
        strokeLinecap="round"
        strokeDasharray={`${c * 0.3} ${c}`}
      />
    </svg>
  );
};

/**
 * Màn hình "lens" kiểu HUD phát sáng:
 *   captured  -> ẢNH VỪA CHỤP (khung crop neon + "Đã chụp")
 *   analyzing -> lớp loading "Đang phân tích…" (vạch quét AI)
 *   showResult-> THẺ KẾT QUẢ kính tối viền neon + burst hạt sáng
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
  const burstT = frame - RESULT_BURST_FRAME; // thời gian burst hạt sáng
  const cardIn = Math.min(1, showResult * 1.7); // thẻ rõ chữ sớm, transform vẫn theo showResult

  return (
    <div style={{ position: 'absolute', inset: 0, fontFamily: BODY, overflow: 'hidden' }}>
      {/* nền camera đêm */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(90% 70% at 50% 44%, #0D3844 0%, #07222B 68%, #03141A 100%)`,
        }}
      />
      {/* lưới HUD mờ */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage: `repeating-linear-gradient(0deg, ${withAlpha(CINE.neon, 0.07)} 0 1px, transparent 1px 34px),
            repeating-linear-gradient(90deg, ${withAlpha(CINE.neon, 0.07)} 0 1px, transparent 1px 34px)`,
          opacity: 0.8,
        }}
      />
      {/* viền màn hình phát sáng nhẹ — cảm giác HUD */}
      <div
        style={{
          position: 'absolute',
          inset: 6,
          borderRadius: 24,
          boxShadow: `inset 0 0 26px ${withAlpha(CINE.neon, 0.18)}`,
        }}
      />

      {/* ===== ẢNH VỪA CHỤP ===== */}
      <div style={{ position: 'absolute', inset: 0, opacity: photoFade }}>
        {/* vũng sáng ấm quanh cốc trong ảnh (đúng ánh sáng cảnh thật) */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '47%',
            width: 190,
            height: 190,
            transform: 'translate(-50%, -50%)',
            borderRadius: '50%',
            background: `radial-gradient(circle, ${withAlpha(CINE.warm, 0.3)} 0%, transparent 70%)`,
            filter: 'blur(6px)',
          }}
        />
        {/* cốc trong ảnh */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '47%',
            transform: `translate(-50%, -50%) scale(${photoScale})`,
            filter: `drop-shadow(0 18px 16px ${withAlpha('#000000', 0.55)})`,
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
            background: withAlpha(CINE.neonSoft, 0.22),
          }}
        />
        {/* khung crop 4 góc — neon */}
        {(['tl', 'tr', 'bl', 'br'] as const).map((corner) => {
          const top = corner[0] === 't';
          const left = corner[1] === 'l';
          const L = 30;
          const thick = 5;
          const base: React.CSSProperties = {
            position: 'absolute',
            [top ? 'top' : 'bottom']: '7%',
            [left ? 'left' : 'right']: '8%',
            background: CINE.neonSoft,
            borderRadius: 3,
            boxShadow: `0 0 10px ${withAlpha(CINE.neon, 0.9)}`,
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
            background: withAlpha('#04181E', 0.78),
            border: `2px solid ${withAlpha(CINE.neon, 0.65)}`,
            boxShadow: `0 0 16px ${withAlpha(CINE.neon, 0.35)}`,
            color: CINE.textLight,
            fontWeight: 800,
            fontSize: 17,
            whiteSpace: 'nowrap',
          }}
        >
          <svg width={16} height={16} viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="11" fill="#3DBE7B" />
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
        <div style={{ position: 'absolute', inset: 0, background: withAlpha('#020809', 0.32) }} />
        {/* vạch quét AI chạy trên ảnh — glow mạnh */}
        <div
          style={{
            position: 'absolute',
            left: '10%',
            right: '10%',
            top: `${20 + sweep * 46}%`,
            height: 4,
            borderRadius: 3,
            background: `linear-gradient(90deg, transparent, ${CINE.neonSoft} 30%, #FFFFFF 50%, ${CINE.neonSoft} 70%, transparent)`,
            boxShadow: `0 0 26px 9px ${withAlpha(CINE.neon, 0.75)}`,
          }}
        />
        {/* pill loading: spinner nhỏ + chữ */}
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
            background: withAlpha('#04181E', 0.82),
            border: `2px solid ${withAlpha(CINE.neon, 0.5)}`,
            boxShadow: `0 0 18px ${withAlpha(CINE.neon, 0.35)}`,
          }}
        >
          <Spinner size={26} spin={frame * 10} />
          <span style={{ color: CINE.textLight, fontWeight: 800, fontSize: 19, whiteSpace: 'nowrap' }}>
            {ANALYZING_LABEL}
          </span>
        </div>
      </div>

      {/* ===== BURST HẠT SÁNG khi ra kết quả ===== */}
      {burstT >= 0 && burstT < 40 && (
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          {Array.from({ length: 26 }).map((_, i) => {
            const a = seeded(i * 3 + 1) * Math.PI * 2;
            const sp = 3 + seeded(i * 5 + 2) * 6;
            const d = sp * burstT * (1 - burstT / 90);
            const x = 50 + (Math.cos(a) * d * 100) / 262; // % theo bề ngang màn
            const y = 42 + (Math.sin(a) * d * 100) / 480;
            const op = Math.max(0, 1 - burstT / 34);
            const r = 2 + seeded(i * 7 + 3) * 3.5;
            const warm = seeded(i * 11 + 5) > 0.6;
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: `${x}%`,
                  top: `${y}%`,
                  width: r * 2,
                  height: r * 2,
                  borderRadius: '50%',
                  background: warm ? CINE.warmSoft : CINE.neonSoft,
                  boxShadow: `0 0 ${8 + r * 2}px ${warm ? withAlpha(CINE.warm, 0.9) : withAlpha(CINE.neon, 0.9)}`,
                  opacity: op,
                }}
              />
            );
          })}
        </div>
      )}

      {/* ===== THẺ KẾT QUẢ — kính tối viền neon ===== */}
      {showResult > 0.01 && (
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '42%',
            width: '92%',
            transform: `translate(-50%, calc(-50% + ${(1 - showResult) * 26}px)) scale(${0.8 + showResult * 0.2})`,
            opacity: cardIn,
            background: `linear-gradient(165deg, ${withAlpha('#0E3540', 0.94)} 0%, ${withAlpha('#06202A', 0.96)} 100%)`,
            borderRadius: 26,
            border: `2px solid ${withAlpha(CINE.neon, 0.6)}`,
            boxShadow: `0 0 34px ${withAlpha(CINE.neon, 0.35)}, 0 22px 44px ${withAlpha('#010A0E', 0.6)}`,
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
                background: `radial-gradient(circle at 40% 32%, ${withAlpha(CINE.neon, 0.28)}, ${withAlpha('#08222B', 0.9)})`,
                border: `1.5px solid ${withAlpha(CINE.neon, 0.45)}`,
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
                  color: CINE.textLight,
                  lineHeight: 1,
                  whiteSpace: 'nowrap',
                  textShadow: `0 0 14px ${withAlpha(CINE.neon, 0.55)}`,
                }}
              >
                {OBJECT_NAME}
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span
                  style={{
                    padding: '3px 10px',
                    borderRadius: 999,
                    background: withAlpha(CINE.neon, 0.16),
                    border: `1.5px solid ${withAlpha(CINE.neon, 0.5)}`,
                    color: CINE.neonSoft,
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
                    color: '#7BEFA8',
                    fontWeight: 800,
                    fontSize: 14,
                    whiteSpace: 'nowrap',
                  }}
                >
                  <svg width={15} height={15} viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="11" fill="#2FA36B" />
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

          {/* ngăn cách — vạch sáng mờ */}
          <div
            style={{
              height: 1.5,
              background: `linear-gradient(90deg, transparent, ${withAlpha(CINE.neon, 0.45)}, transparent)`,
              margin: '14px 0',
            }}
          />

          {/* "Bạn có biết?" + lịch sử ra đời */}
          <div style={{ display: 'flex', gap: 10 }}>
            <div style={{ flexShrink: 0, marginTop: 1 }}>
              <Bulb size={26} />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <span style={{ color: CINE.neonSoft, fontWeight: 800, fontSize: 14 }}>{OBJECT_FACT_EYEBROW}</span>
              <span style={{ color: CINE.textDim, fontWeight: 600, fontSize: 17, lineHeight: 1.3 }}>{OBJECT_FACT}</span>
            </div>
          </div>
        </div>
      )}

      {/* chớp shutter (khi vừa bấm chụp) */}
      <div style={{ position: 'absolute', inset: 0, background: '#FFFFFF', opacity: flash, pointerEvents: 'none' }} />
    </div>
  );
};
