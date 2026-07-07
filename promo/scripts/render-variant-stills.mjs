// Render still cho một entry point bất kỳ (so sánh biến thể đồ hoạ).
// Usage: node scripts/render-variant-stills.mjs <entry.ts> <outdir> [frames]
import path from 'node:path';
import { mkdirSync } from 'node:fs';
import { bundle } from '@remotion/bundler';
import { selectComposition, renderStill } from '@remotion/renderer';

const [entryArg, outdirArg, framesArg] = process.argv.slice(2);
if (!entryArg || !outdirArg) {
  console.error('Usage: node scripts/render-variant-stills.mjs <entry.ts> <outdir> [frames]');
  process.exit(1);
}
const frames = (framesArg ?? '100,230,340,450')
  .split(',')
  .map((n) => parseInt(n.trim(), 10));

const entryPoint = path.resolve(entryArg);
mkdirSync(path.resolve(outdirArg), { recursive: true });

console.log('Bundling…', entryPoint);
const serveUrl = await bundle({ entryPoint, publicDir: path.resolve('public') });
const composition = await selectComposition({ serveUrl, id: 'WonderLensPromo' });

for (const frame of frames) {
  const output = path.resolve(outdirArg, `still-${String(frame).padStart(3, '0')}.png`);
  await renderStill({ serveUrl, composition, output, frame, overwrite: true });
  console.log('✓ frame', frame, '→', output);
}
console.log('DONE');
