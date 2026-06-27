// Bundle 1 lần, render nhiều still để kiểm tra nhanh từng cảnh.
import path from 'node:path';
import { bundle } from '@remotion/bundler';
import { selectComposition, renderStill } from '@remotion/renderer';

const frames = (process.argv[2] ?? '40,120,165,215,300,380,430')
  .split(',')
  .map((n) => parseInt(n.trim(), 10));

const entryPoint = path.resolve('src/index.ts');
console.log('Bundling…');
const serveUrl = await bundle({ entryPoint });
const composition = await selectComposition({ serveUrl, id: 'WonderLensPromo' });

for (const frame of frames) {
  const output = path.resolve(`out/still-${String(frame).padStart(3, '0')}.png`);
  await renderStill({ serveUrl, composition, output, frame, overwrite: true });
  console.log('✓ frame', frame, '→', output);
}
console.log('DONE');
