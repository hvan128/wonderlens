#!/usr/bin/env node
import { existsSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DEFAULTS = {
  fps: 30,
  seconds: 14,
  width: 540,
  height: 960,
  output: path.resolve(__dirname, '../out/wonderlens-gsap-landing.mp4'),
  framesDir: path.resolve(__dirname, '../out/gsap-landing-frames'),
  htmlPath: path.resolve(__dirname, '../gsap-landing.html'),
};

const parseArgs = () => {
  const opts = { ...DEFAULTS, dryRun: false };
  for (const arg of process.argv.slice(2)) {
    if (arg === '--dry-run') {
      opts.dryRun = true;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      opts.help = true;
      continue;
    }
    if (arg.startsWith('--fps=')) opts.fps = Number(arg.slice(6));
    else if (arg.startsWith('--seconds=')) opts.seconds = Number(arg.slice(10));
    else if (arg.startsWith('--width=')) opts.width = Number(arg.slice(8));
    else if (arg.startsWith('--height=')) opts.height = Number(arg.slice(9));
    else if (arg.startsWith('--output=')) opts.output = path.resolve(arg.slice(9));
    else if (arg.startsWith('--frames-dir=')) opts.framesDir = path.resolve(arg.slice(13));
    else if (arg.startsWith('--html=')) opts.htmlPath = path.resolve(arg.slice(7));
    else {
      throw new Error(`Unknown arg: ${arg}`);
    }
  }

  if (opts.fps <= 0 || Number.isNaN(opts.fps)) throw new Error('fps must be > 0');
  if (opts.seconds <= 0 || Number.isNaN(opts.seconds)) throw new Error('seconds must be > 0');
  if (opts.width <= 0 || opts.height <= 0) throw new Error('width/height must be > 0');
  return opts;
};

const printHelp = () => {
  console.log(`
npm run render:gsap-landing [options]

Options:
  --fps=30
  --seconds=14
  --width=540
  --height=960
  --output=out/wonderlens-gsap-landing.mp4
  --frames-dir=out/gsap-landing-frames
  --html=gsap-landing.html
  --dry-run
`);
};

const checkBinary = (cmd) => {
  const result = spawnSync('which', [cmd], { stdio: 'pipe', encoding: 'utf8' });
  return result.status === 0;
};

const run = async () => {
  const opts = parseArgs();
  if (opts.help) {
    printHelp();
    return;
  }

  const frameCount = Math.round(opts.fps * opts.seconds);
  const fileUrl = `file://${opts.htmlPath}`;

  if (!existsSync(opts.htmlPath)) {
    throw new Error(`Không tìm thấy file landing: ${opts.htmlPath}`);
  }

  if (opts.dryRun) {
    console.log('--- DRY RUN ---');
    console.log('Mã hóa video thử nghiệm từ:', fileUrl);
    console.log('Frames:', frameCount, '| FPS:', opts.fps, '| Kích thước:', `${opts.width}x${opts.height}`);
    console.log('FFmpeg output:', opts.output);
    console.log('Cần cài:', 'npm i -D playwright, ffmpeg');
    return;
  }

  let chromium;
  try {
    ({ chromium } = await import('playwright'));
  } catch (_error) {
    throw new Error(
      'Chưa có module `playwright`. Chạy: npm i -D playwright (hoặc thêm --help để đọc hướng dẫn).',
    );
  }

  if (!checkBinary('ffmpeg')) {
    throw new Error('Không tìm thấy `ffmpeg` trong PATH. Vui lòng cài ffmpeg trước.');
  }

  await mkdir(opts.framesDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: opts.width, height: opts.height } });
  await page.goto(fileUrl, { waitUntil: 'networkidle' });
  await page.waitForFunction(() => typeof window.__seekGsapFrame === 'function');

  for (let i = 0; i < frameCount; i += 1) {
    const seek = `${i},${frameCount}`;
    const framePath = path.join(opts.framesDir, `frame-${String(i).padStart(4, '0')}.png`);
    await page.evaluate((payload) => {
      const [frame, total] = payload.split(',').map(Number);
      window.__seekGsapFrame?.(frame, total);
    }, seek);
    await page.screenshot({ path: framePath });
    process.stdout.write(`\rRendered frame ${i + 1}/${frameCount}`);
  }
  process.stdout.write('\n');

  await browser.close();

  const ffArgs = [
    '-y',
    '-framerate',
    String(opts.fps),
    '-i',
    path.join(opts.framesDir, 'frame-%04d.png'),
    '-c:v',
    'libx264',
    '-pix_fmt',
    'yuv420p',
    '-movflags',
    '+faststart',
    '-r',
    String(opts.fps),
    opts.output,
  ];
  const ffmpeg = spawnSync('ffmpeg', ffArgs, { stdio: 'inherit' });
  if (ffmpeg.status !== 0) {
    throw new Error('FFmpeg render thất bại.');
  }

  console.log('✓ Hoàn tất:', opts.output);
};

run().catch((error) => {
  console.error(error?.message ?? error);
  process.exitCode = 1;
});
