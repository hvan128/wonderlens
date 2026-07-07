import { Composition } from 'remotion';
import { WonderLensPromo } from './WonderLensPromo';
import { WIDTH, HEIGHT, FPS, DURATION_IN_FRAMES } from './theme';

export const RemotionRoot = () => (
  <Composition
    id="WonderLensPromo"
    component={WonderLensPromo}
    durationInFrames={DURATION_IN_FRAMES}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);
