// Font có subset 'vietnamese' để hiển thị đủ dấu khi render headless.
import { loadFont as loadBaloo } from '@remotion/google-fonts/Baloo2';
import { loadFont as loadNunito } from '@remotion/google-fonts/Nunito';

const baloo = loadBaloo('normal', {
  weights: ['600', '700', '800'],
  subsets: ['latin', 'vietnamese'],
});

const nunito = loadNunito('normal', {
  weights: ['600', '700', '800'],
  subsets: ['latin', 'vietnamese'],
});

/** Font tiêu đề — tròn, vui mắt (gợi theme trẻ em của app). */
export const HEADING = baloo.fontFamily;
/** Font nội dung — sạch, dễ đọc. */
export const BODY = nunito.fontFamily;
