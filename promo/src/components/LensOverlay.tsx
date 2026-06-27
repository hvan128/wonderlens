import { COLORS, withAlpha } from '../theme';
import { HEADING, BODY } from '../fonts';
import { IconCup } from './Icons';
import { OBJECT_NAME, CONFIDENCE } from '../content';

type Corner = 'tl' | 'tr' | 'bl' | 'br';

const Bracket = ({ corner, inset, size }: { corner: Corner; inset: number; size: number }) => {
  const thick = 7;
  const v: React.CSSProperties = { position: 'absolute', background: COLORS.teal, borderRadius: 4 };
  const top = corner[0] === 't';
  const left = corner[1] === 'l';
  const base: React.CSSProperties = {
    [top ? 'top' : 'bottom']: `${inset}%`,
    [left ? 'left' : 'right']: `${inset}%`,
  };
  return (
    <>
      <div style={{ ...v, ...base, width: size, height: thick }} />
      <div style={{ ...v, ...base, width: thick, height: size }} />
    </>
  );
};

/** Viewfinder của "lens" — máy đang ngắm vào cốc giấy. */
export const LensOverlay = ({
  scanY,
  bracketInset,
  label,
  scanning,
  showResult,
  flash,
  showBrackets = true,
}: {
  scanY: number; // 0..1 vị trí vạch quét
  bracketInset: number; // % lề khung ngắm
  label: string;
  scanning: number; // 0..1 độ rõ của lớp quét
  showResult: number; // 0..1 độ hiện chip kết quả
  flash: number; // 0..1 chớp shutter
  showBrackets?: boolean;
}) => {
  return (
    <div style={{ position: 'absolute', inset: 0, fontFamily: BODY }}>
      {/* cảnh máy ảnh: cốc giấy trên mặt bàn */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(90% 70% at 50% 42%, #20424B 0%, #11272D 70%, #0A1A1F 100%)`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: '50%',
          top: '46%',
          transform: 'translate(-50%, -50%)',
          filter: `drop-shadow(0 18px 16px ${withAlpha('#000000', 0.45)})`,
        }}
      >
        <IconCup size={98} />
      </div>
      {/* mặt bàn */}
      <div
        style={{
          position: 'absolute',
          left: '12%',
          right: '12%',
          top: '60%',
          height: 4,
          borderRadius: 2,
          background: withAlpha('#FFFFFF', 0.16),
        }}
      />

      {/* lớp quét + vạch quét */}
      <div style={{ position: 'absolute', inset: 0, opacity: scanning }}>
        <div
          style={{
            position: 'absolute',
            left: '14%',
            right: '14%',
            top: `${scanY * 100}%`,
            height: 5,
            borderRadius: 3,
            background: COLORS.teal,
            boxShadow: `0 0 22px 6px ${withAlpha(COLORS.teal, 0.8)}`,
          }}
        />
      </div>

      {/* khung ngắm 4 góc (trong màn hình) */}
      {showBrackets && (
        <>
          <Bracket corner="tl" inset={bracketInset} size={70} />
          <Bracket corner="tr" inset={bracketInset} size={70} />
          <Bracket corner="bl" inset={bracketInset} size={70} />
          <Bracket corner="br" inset={bracketInset} size={70} />
        </>
      )}

      {/* nhãn trên */}
      {label !== '' && (
        <div
          style={{
            position: 'absolute',
            top: '7%',
            left: '50%',
            transform: 'translateX(-50%)',
            padding: '6px 13px',
            borderRadius: 999,
            background: withAlpha('#06181C', 0.66),
            color: '#EAFBFE',
            fontWeight: 800,
            fontSize: 18,
            letterSpacing: 0.3,
            whiteSpace: 'nowrap',
            border: `2px solid ${withAlpha(COLORS.teal, 0.55)}`,
          }}
        >
          {label}
        </div>
      )}

      {/* nút chụp */}
      <div
        style={{
          position: 'absolute',
          bottom: '6%',
          left: '50%',
          transform: 'translateX(-50%)',
          width: 50,
          height: 50,
          borderRadius: '50%',
          background: withAlpha('#FFFFFF', 0.2),
          border: `4px solid ${withAlpha('#FFFFFF', 0.9)}`,
          boxSizing: 'border-box',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <div style={{ width: 34, height: 34, borderRadius: '50%', background: '#FFFFFF' }} />
      </div>

      {/* chip kết quả */}
      {showResult > 0.01 && (
        <div
          style={{
            position: 'absolute',
            top: '13%',
            left: '50%',
            transform: `translate(-50%, ${(1 - showResult) * 30}px) scale(${0.7 + showResult * 0.3})`,
            opacity: showResult,
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '7px 15px 7px 7px',
            borderRadius: 999,
            background: '#FFFFFF',
            boxShadow: `0 16px 30px ${withAlpha('#0A2A30', 0.4)}`,
          }}
        >
          <div
            style={{
              width: 38,
              height: 38,
              borderRadius: '50%',
              background: COLORS.paper,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <IconCup size={28} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
            <span
              style={{
                fontFamily: HEADING,
                fontWeight: 800,
                fontSize: 21,
                color: COLORS.ink,
                whiteSpace: 'nowrap',
              }}
            >
              {OBJECT_NAME}
            </span>
            <span
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 5,
                fontFamily: BODY,
                fontWeight: 700,
                fontSize: 15,
                color: COLORS.tealDark,
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
              khớp {CONFIDENCE}
            </span>
          </div>
        </div>
      )}

      {/* chớp shutter */}
      <div
        style={{ position: 'absolute', inset: 0, background: '#FFFFFF', opacity: flash, pointerEvents: 'none' }}
      />
    </div>
  );
};
