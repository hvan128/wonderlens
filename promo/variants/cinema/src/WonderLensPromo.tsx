import { AbsoluteFill, Sequence } from 'remotion';
import { BackgroundPaper } from './components/BackgroundPaper';
import { CinematicGrade } from './components/CinematicGrade';
import { BoyWorld } from './scenes/BoyWorld';
import { TimelineScene } from './scenes/TimelineScene';
import { LogoScene } from './scenes/LogoScene';

/**
 * Clip 16s (480f @30fps) — biến thể CINEMA (đêm magic sci-fi -> bình minh ấm):
 *  A  bé tò mò → ngắm & chụp cốc giấy (cam sau)                 (0–135)
 *  B  lật máy → ảnh vừa chụp → AI phân tích (loading) → kết quả (135–250)
 *  C  lao vào màn hình                                          (244–282)
 *  D  hành trình tạo ra cốc giấy + huy hiệu                     (256–432)
 *  E  chốt logo WonderLens                                      (426–480)
 * Trên cùng: vignette + grain phim (CinematicGrade), toàn cảnh tăng nhẹ contrast.
 */
export const WonderLensPromo = () => (
  <AbsoluteFill>
    <AbsoluteFill style={{ filter: 'contrast(1.06) saturate(1.08)' }}>
      <BackgroundPaper />
      <Sequence from={0} durationInFrames={282} premountFor={20}>
        <BoyWorld />
      </Sequence>
      <Sequence from={256} durationInFrames={176} premountFor={30}>
        <TimelineScene />
      </Sequence>
      <Sequence from={426} durationInFrames={54} premountFor={20}>
        <LogoScene />
      </Sequence>
    </AbsoluteFill>
    <CinematicGrade />
  </AbsoluteFill>
);
