import { AbsoluteFill, Sequence } from 'remotion';
import { BackgroundPaper } from './components/BackgroundPaper';
import { BoyWorld } from './scenes/BoyWorld';
import { TimelineScene } from './scenes/TimelineScene';
import { LogoScene } from './scenes/LogoScene';

/**
 * Clip 15s (450f @30fps):
 *  A+B+C  bé tò mò → quét & chụp cốc giấy → lao vào màn hình   (0–240)
 *  D      hành trình tạo ra cốc giấy + huy hiệu                 (210–396)
 *  E      chốt logo WonderLens                                  (390–450)
 */
export const WonderLensPromo = () => (
  <AbsoluteFill>
    <BackgroundPaper />
    <Sequence from={0} durationInFrames={240} premountFor={20}>
      <BoyWorld />
    </Sequence>
    <Sequence from={210} durationInFrames={186} premountFor={30}>
      <TimelineScene />
    </Sequence>
    <Sequence from={390} durationInFrames={60} premountFor={20}>
      <LogoScene />
    </Sequence>
  </AbsoluteFill>
);
