// Sinh cặp ảnh cho màn onboarding "chụp thử" (mô phỏng viewfinder):
//   1. onboarding_scene.jpg  — ảnh kiểu chụp điện thoại: cốc giấy trên bàn gỗ
//      (gpt-image-1 sinh PNG → nén JPEG cho nhẹ bundle, nền không cần alpha)
//   2. onboarding_cutout.png — CÙNG khung hình, tách nền bằng Apple Vision
//      on-device (scripts/CutoutForeground.swift) → khớp pixel tuyệt đối với
//      cảnh. KHÔNG dùng /v1/images/edits: model vẽ lại vật, lệch vị trí/scale.
//
// Chạy: cd proxy && node scripts/pregen-onboarding-images.mjs [--force]
// Ảnh tốn tiền thật — mặc định bỏ qua khi file đã tồn tại; --force để gen lại.
// Bước nén + tách nền cần macOS (sips + swift/Vision).

import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const IMAGES_DIR = path.resolve(__dirname, '../../app/assets/images');
// PNG thô nằm NGOÀI assets/ — pubspec bundle nguyên thư mục assets/images/,
// file trung gian sót lại sẽ ship theo app (~2MB) nếu lỡ commit.
const SCENE_PNG = path.join(tmpdir(), 'wonderlens_onboarding_scene_raw.png');
const SCENE_JPG = path.join(IMAGES_DIR, 'onboarding_scene.jpg');
const CUTOUT_PATH = path.join(IMAGES_DIR, 'onboarding_cutout.png');
const CUTOUT_SWIFT = path.join(__dirname, 'CutoutForeground.swift');

const MODEL = process.env.IMAGE_MODEL || 'gpt-image-1';
// Khổ dọc — phủ kín màn điện thoại như viewfinder thật.
const SIZE = process.env.IMAGE_SIZE || '1024x1536';
const QUALITY = process.env.IMAGE_QUALITY || 'medium';

// Ảnh "thật" kiểu CapWords (không claymation): một vật quen thuộc giữa khung,
// đủ khoảng trống quanh vật cho 4 góc ngắm. Guard rails: không người/tay/chữ.
const SCENE_PROMPT = [
  'Vertical smartphone photo of a single cheerful paper cup with soft pastel',
  'colored stripes, standing upright on a warm wooden table.',
  'The cup is centered with generous empty space around it, fully visible.',
  'Soft natural window daylight, gently blurred cozy neutral wall background.',
  'Photorealistic, bright, warm, kid-friendly mood.',
  'No people, no faces, no hands, no text, no logos, no scary elements.',
].join(' ');

function loadApiKey() {
  if (process.env.OPENAI_API_KEY) return process.env.OPENAI_API_KEY;
  const envPath = path.resolve(__dirname, '../.env');
  if (existsSync(envPath)) {
    const m = readFileSync(envPath, 'utf8').match(/^OPENAI_API_KEY=(.+)$/m);
    if (m) return m[1].trim();
  }
  throw new Error('Thiếu OPENAI_API_KEY (env hoặc proxy/.env)');
}

// Retry backoff cho 429/5xx — giống pregen-hero-images.mjs.
async function withRetry(label, fn) {
  let lastErr;
  for (let i = 0; i < 5; i++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      const retriable = /(^| )(429|500|502|503|504)( |$)/.test(String(err.message));
      if (!retriable) throw err;
      const wait = Math.min(2000 * 2 ** i, 20000);
      console.log(`  ${label}: ${err.message} → thử lại sau ${wait}ms`);
      await new Promise((r) => setTimeout(r, wait));
    }
  }
  throw lastErr;
}

async function generateScene() {
  const body = { model: MODEL, prompt: SCENE_PROMPT, size: SIZE, n: 1 };
  if (MODEL.startsWith('gpt-image')) body.quality = QUALITY;
  else body.response_format = 'b64_json';
  const res = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${loadApiKey()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`generations ${res.status} ${text.slice(0, 300)}`);
  }
  const json = await res.json();
  const b64 = json.data?.[0]?.b64_json;
  if (!b64) throw new Error('generations: response không có b64_json');
  return Buffer.from(b64, 'base64');
}

const force = process.argv.includes('--force');

if (!force && existsSync(SCENE_JPG) && existsSync(CUTOUT_PATH)) {
  console.log(
    'Đã có onboarding_scene.jpg + onboarding_cutout.png — bỏ qua (--force để gen lại).',
  );
  process.exit(0);
}

// Check platform TRƯỚC khi gọi API — non-darwin không hoàn thành được pipeline
// (thiếu sips + Vision), gọi generations chỉ tốn tiền dở chừng.
if (process.platform !== 'darwin') {
  console.error('Cần macOS: sips (nén JPEG) + swift/Vision (tách nền). Dừng, chưa gọi API.');
  process.exit(1);
}

console.log(`Gen cảnh onboarding (${MODEL}, ${SIZE}, ${QUALITY})…`);
const scene = await withRetry('scene', generateScene);
writeFileSync(SCENE_PNG, scene);

// Xoá cutout cũ TRƯỚC khi ghi scene mới: nếu bước cutout bên dưới fail, trạng
// thái là "thiếu file" rõ ràng (lần chạy sau không skip) — không bao giờ để
// cặp scene mới + cutout cũ lệch pixel được chấp nhận im lặng.
rmSync(CUTOUT_PATH, { force: true });

console.log('Nén JPEG (sips q82)…');
execFileSync('sips', [
  '-s', 'format', 'jpeg',
  '-s', 'formatOptions', '82',
  SCENE_PNG,
  '--out', SCENE_JPG,
]);
rmSync(SCENE_PNG);

console.log('Tách cutout bằng Apple Vision (cùng khung hình → khớp pixel)…');
execFileSync('swift', [CUTOUT_SWIFT, SCENE_JPG, CUTOUT_PATH], {
  stdio: 'inherit',
});

console.log(`Xong: ${SCENE_JPG} + ${CUTOUT_PATH}`);
