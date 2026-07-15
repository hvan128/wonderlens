import { Composition } from "remotion";
import { WonderLensPromo } from "./WonderLensPromo";
import {
  CUP_JOURNEY_DURATION_IN_FRAMES,
  WonderLensCupJourneyPromo,
} from "./WonderLensCupJourneyPromo";
import {
  CUP_UI_DURATION_IN_FRAMES,
  WonderLensCupUiPromo,
} from "./WonderLensCupUiPromo";
import {
  CUP_WOW_DURATION_IN_FRAMES,
  WonderLensCupWowPromo,
} from "./WonderLensCupWowPromo";
import {
  ORBIT_DURATION_IN_FRAMES,
  WonderLensOrbitPromo,
} from "./WonderLensOrbitPromo";
import {
  STORY_PROMO_DURATION_IN_FRAMES,
  WonderLensStoryPromo,
} from "./WonderLensStoryPromo";
import { WIDTH, HEIGHT, FPS, DURATION_IN_FRAMES } from "./theme";

export const RemotionRoot = () => (
  <>
    <Composition
      id="WonderLensPromo"
      component={WonderLensPromo}
      durationInFrames={DURATION_IN_FRAMES}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
    <Composition
      id="WonderLensOrbitPromo"
      component={WonderLensOrbitPromo}
      durationInFrames={ORBIT_DURATION_IN_FRAMES}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
    <Composition
      id="WonderLensCupWowPromo"
      component={WonderLensCupWowPromo}
      durationInFrames={CUP_WOW_DURATION_IN_FRAMES}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
    <Composition
      id="WonderLensCupUiPromo"
      component={WonderLensCupUiPromo}
      durationInFrames={CUP_UI_DURATION_IN_FRAMES}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
    <Composition
      id="WonderLensCupJourneyPromo"
      component={WonderLensCupJourneyPromo}
      durationInFrames={CUP_JOURNEY_DURATION_IN_FRAMES}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
    <Composition
      id="WonderLensStoryPromo"
      component={WonderLensStoryPromo}
      durationInFrames={STORY_PROMO_DURATION_IN_FRAMES}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
  </>
);
