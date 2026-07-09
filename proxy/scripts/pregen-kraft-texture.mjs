#!/usr/bin/env node
/**
 * Tạo SẴN một texture "giấy thô" (kraft/recycled) xám-sáng, trung tính rồi bundle
 * vào app. Card thống kê tab Hồ sơ nhuộm màu ấm từng cái bằng BlendMode.multiply
 * lên texture NÀY → nhiều màu giấy thô từ 1 asset (offline, $0 lúc demo).
 *
 *   cd proxy && node scripts/pregen-kraft-texture.mjs
 *
 * Texture cố ý SÁNG & trung tính (gần trắng ngà) để multiply giữ được màu nền
 * tươi; hạt lốm đốm + sợi giấy mịn cho ra chất "giấy tái chế". Không vật, không chữ.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { setTimeout as sleep } from 'node:timers/promises';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = join(__dirname, '..', '..');
const IMAGES_DIR = join(REPO, 'app', 'assets', 'images');
const OUT = join(IMAGES_DIR, 'kraft_paper.png');

const MODEL = process.env.IMAGE_MODEL ?? 'gpt-image-1';
const SIZE = process.env.IMAGE_SIZE ?? '1024x1024';
const QUALITY = process.env.IMAGE_QUALITY ?? 'medium';
const API_URL = 'https://api.openai.com/v1/images/generations';

const PROMPT = [
  'A flat top-down macro photograph of a sheet of COARSE rough recycled kraft paper / speckled pulp cardstock, filling the entire frame edge to edge.',
  'Light warm off-white / pale oat base color, evenly and brightly lit with soft studio light, no shadows.',
  'Strong VISIBLE recycled-paper texture: many prominent dark brown and grey flecks, bits and specks scattered all over, plus coarse visible fibers and a rough matte grain — clearly textured and tactile, NOT smooth, like real recycled speckletone paper.',
  'Higher contrast grain so the speckles read clearly even when the image is scaled down small.',
  'Completely flat and even, no folds, no curl, no objects, no writing, no text, no letters, no logos, no borders — just the raw paper surface as a seamless background texture.',
].join(' ');

function loadEnv() {
  if (process.env.OPENAI_API_KEY) return process.env.OPENAI_API_KEY;
  const envPath = join(__dirname, '..', '.env');
  if (existsSync(envPath)) {
    for (const line of readFileSync(envPath, 'utf8').split('\n')) {
      const m = line.match(/^\s*OPENAI_API_KEY\s*=\s*(.+?)\s*$/);
      if (m) return m[1].replace(/^["']|["']$/g, '');
    }
  }
  return null;
}

async function apiImage(prompt, apiKey) {
  const body = { model: MODEL, prompt, size: SIZE, n: 1 };
  if (MODEL.startsWith('gpt-image')) body.quality = QUALITY;
  else body.response_format = 'b64_json';

  let last;
  for (let i = 0; i < 5; i++) {
    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });
      if (res.ok) {
        const data = await res.json();
        const b64 = data?.data?.[0]?.b64_json;
        if (b64) return Buffer.from(b64, 'base64');
        last = new Error('empty b64_json');
      } else {
        last = new Error(`${res.status}: ${(await res.text()).slice(0, 200)}`);
        if (![429, 500, 502, 503, 504].includes(res.status)) throw last;
      }
    } catch (e) {
      last = e;
    }
    await sleep(Math.min(2000 * 2 ** i, 20000));
  }
  throw last;
}

const API_KEY = loadEnv();
if (!API_KEY) {
  console.error('Thiếu OPENAI_API_KEY (đặt trong proxy/.env hoặc biến môi trường).');
  process.exit(1);
}

console.log(`Pre-gen texture giấy thô (${MODEL} ${SIZE} ${QUALITY})…`);
try {
  const png = await apiImage(PROMPT, API_KEY);
  mkdirSync(IMAGES_DIR, { recursive: true });
  writeFileSync(OUT, png);
  console.log(`✓ ${(png.length / 1024).toFixed(0)}KB → assets/images/kraft_paper.png`);
  console.log('Nhớ `flutter pub get` rồi build lại app.');
} catch (e) {
  console.error(`✗ ${e.message}`);
  process.exit(1);
}
