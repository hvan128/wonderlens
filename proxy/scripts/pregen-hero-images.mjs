#!/usr/bin/env node
/**
 * Tạo SẴN ảnh minh hoạ "từng chặng" cho các vật hero rồi đóng gói vào app
 * (offline, demo tức thì, $0 lúc demo). Chạy 1 lần khi nội dung hero ổn định.
 *
 *   cd proxy && node scripts/pregen-hero-images.mjs          # tất cả vật
 *   cd proxy && node scripts/pregen-hero-images.mjs ball_pen pencil   # chọn vật
 *
 * Yêu cầu: proxy/.env có OPENAI_API_KEY. Tốn tiền thật (gpt-image-1, ~4 ảnh/vật).
 *
 * Việc nó làm cho mỗi vật:
 *   1) đọc app/assets/content/<id>.json
 *   2) với mỗi chặng (tối đa 4): dựng prompt (world bible chung + beat riêng)
 *      → POST /v1/images/generations → ghi app/assets/images/<id>_stage<n>.png
 *   3) set stages[n].illustration = "assets/images/<id>_stage<n>.png" trong JSON
 *
 * LƯU Ý: buildStagePrompt() ở đây phải khớp lib/image-prompt.ts (giữ đồng bộ).
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { setTimeout as sleep } from 'node:timers/promises';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = join(__dirname, '..', '..');
const CONTENT_DIR = join(REPO, 'app', 'assets', 'content');
const IMAGES_DIR = join(REPO, 'app', 'assets', 'images');

const MODEL = process.env.IMAGE_MODEL ?? 'gpt-image-1';
const SIZE = process.env.IMAGE_SIZE ?? '1024x1024';
const QUALITY = process.env.IMAGE_QUALITY ?? 'low';
const API_URL = 'https://api.openai.com/v1/images/generations';
const MAX_STAGES = 4;

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

// --- Mirror của lib/image-prompt.ts — giữ đồng bộ khi sửa prompt. ---
function clean(s, max = 200) {
  return (s ?? '')
    .replace(/[\r\n]+/g, ' ')
    .replace(/\p{Extended_Pictographic}/gu, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}
const RAILS =
  'Absolutely no people, no faces, no hands, and no readable text, letters or numbers anywhere in the image. ' +
  'Nothing scary, dark, tense or dangerous: no monsters, no sharp threatening close-ups, no open flames as a hazard, no blood. ' +
  'Keep it bright, soft, rounded and delightful for young kids.';
function worldBible(journey) {
  const name = clean(journey.name, 80) || 'an everyday object';
  const material = clean(journey.material_badge, 40);
  return [
    `A children's storybook illustration of one stage in the journey of how "${name}"${
      material ? ` (made mainly of ${material})` : ''
    } is made, from raw material to the finished object.`,
    'Keep a consistent art direction across the whole series: soft 3D claymation and friendly cartoon look,',
    'the same warm pastel color palette, bright cozy lighting, the same tidy bright workshop tabletop as the recurring background,',
    'rounded chunky shapes, gentle and wholesome mood.',
    'One clear focal subject, centered, square composition, with soft empty space around it.',
  ].join(' ');
}
function buildStagePrompt(journey, i) {
  const stage = (journey.stages ?? []).slice(0, MAX_STAGES)[i];
  const title = clean(stage?.title, 100);
  const detail = clean(stage?.kid_text, 160);
  const beat = [
    title ? `This picture shows stage ${i + 1}: ${title}.` : '',
    detail ? `Show: ${detail}` : '',
  ]
    .filter(Boolean)
    .join(' ');
  return [worldBible(journey), beat, RAILS].filter(Boolean).join(' ');
}
// --- hết phần mirror ---

// Gọi API có retry cho lỗi tạm thời (429/5xx/network).
async function apiImage(prompt) {
  const body = { model: MODEL, prompt, size: SIZE, n: 1 };
  if (MODEL.startsWith('gpt-image')) body.quality = QUALITY;
  else body.response_format = 'b64_json';

  let last;
  for (let i = 0; i < 5; i++) {
    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${API_KEY}`,
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

async function genOne(id) {
  const jsonPath = join(CONTENT_DIR, `${id}.json`);
  if (!existsSync(jsonPath)) {
    console.log(`  ✗ ${id}: không thấy ${jsonPath}`);
    return false;
  }
  const journey = JSON.parse(readFileSync(jsonPath, 'utf8'));
  const stages = (journey.stages ?? []).slice(0, MAX_STAGES);
  if (stages.length === 0) {
    console.log(`  ✗ ${id}: không có chặng`);
    return false;
  }

  mkdirSync(IMAGES_DIR, { recursive: true });
  let ok = 0;
  for (let i = 0; i < stages.length; i++) {
    process.stdout.write(`\r  → ${id}: chặng ${i + 1}/${stages.length}…   `);
    try {
      const png = await apiImage(buildStagePrompt(journey, i));
      writeFileSync(join(IMAGES_DIR, `${id}_stage${i}.png`), png);
      journey.stages[i].illustration = `assets/images/${id}_stage${i}.png`;
      ok++;
    } catch (e) {
      console.log(`\n  ! ${id} chặng ${i + 1}: ${e.message}`);
    }
  }

  // Ghi lại JSON với các illustration đã điền (chỉ những chặng thành công).
  writeFileSync(jsonPath, `${JSON.stringify(journey, null, 2)}\n`);
  console.log(`\n  ✓ ${id}: ${ok}/${stages.length} ảnh → assets/images/${id}_stage*.png`);
  return ok > 0;
}

const API_KEY = loadEnv();
if (!API_KEY) {
  console.error('Thiếu OPENAI_API_KEY (đặt trong proxy/.env hoặc biến môi trường).');
  process.exit(1);
}

const ids =
  process.argv.slice(2).length > 0
    ? process.argv.slice(2)
    : readdirSync(CONTENT_DIR)
        .filter((f) => f.endsWith('.json'))
        .map((f) => f.replace(/\.json$/, ''));

console.log(`Pre-gen ảnh chặng cho ${ids.length} vật (${MODEL} ${SIZE} ${QUALITY}):`);
let done = 0;
for (const id of ids) {
  try {
    if (await genOne(id)) done++;
  } catch (e) {
    console.log(`\n  ✗ ${id}: ${e.message}`);
  }
}
console.log(`\nXong: ${done}/${ids.length} vật. Nhớ \`flutter pub get\` rồi build lại app.`);
