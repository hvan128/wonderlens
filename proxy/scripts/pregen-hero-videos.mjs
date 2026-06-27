#!/usr/bin/env node
/**
 * Tạo SẴN video "hành trình" cho 8 vật hero rồi đóng gói vào app (offline, demo
 * tức thì, $0 lúc demo). Chạy 1 lần khi nội dung hero ổn định.
 *
 *   cd proxy && node scripts/pregen-hero-videos.mjs          # tất cả vật hero
 *   cd proxy && node scripts/pregen-hero-videos.mjs paper_cup pencil   # chọn vật
 *
 * Yêu cầu: proxy/.env có OPENAI_API_KEY. Tốn tiền thật (~$0.80/clip với sora-2 8s).
 *
 * Việc nó làm cho mỗi vật:
 *   1) đọc app/assets/content/<id>.json  → dựng prompt
 *   2) POST /v1/videos  → poll tới completed  → tải MP4
 *   3) ghi app/assets/videos/<id>.mp4  + thêm "video":"assets/videos/<id>.mp4" vào JSON
 *
 * LƯU Ý: buildPrompt() ở đây phải khớp logic lib/video-prompt.ts (giữ đồng bộ).
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { setTimeout as sleep } from 'node:timers/promises';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = join(__dirname, '..', '..');
const CONTENT_DIR = join(REPO, 'app', 'assets', 'content');
const VIDEOS_DIR = join(REPO, 'app', 'assets', 'videos');

const MODEL = process.env.VIDEO_MODEL ?? 'sora-2';
const SIZE = process.env.VIDEO_SIZE ?? '1280x720';
const SECONDS = process.env.VIDEO_SECONDS ?? '8';
const API_BASE = 'https://api.openai.com/v1/videos';

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

// Mirror của lib/video-prompt.ts — giữ đồng bộ khi sửa prompt (gồm cả bỏ emoji + rào chắn).
function clean(s, max = 160) {
  return (s ?? '')
    .replace(/[\r\n]+/g, ' ')
    .replace(/\p{Extended_Pictographic}/gu, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}
function buildPrompt(journey) {
  const name = clean(journey.name, 80) || 'an everyday object';
  const material = clean(journey.material_badge, 40);
  const beats = (journey.stages ?? [])
    .slice(0, 4)
    .map((s, i) => {
      const t = clean(s.title, 100);
      return t ? `Scene ${i + 1}: ${t}.` : '';
    })
    .filter(Boolean)
    .join(' ');
  return [
    `A cheerful, colorful animated short for young children (ages 6-10) showing the journey of how "${name}"${
      material ? ` (made mainly of ${material})` : ''
    } is created, from raw material to the finished object.`,
    'Style: friendly 3D claymation and soft cartoon look, bright warm lighting, magical and wholesome mood, gentle smooth camera moves between scenes.',
    'Show a montage of the making stages in order.',
    beats,
    'Absolutely no people, no faces, no readable text or letters on screen. Nothing scary, dark, tense or dangerous: no monsters, no jump-scares, no sharp or threatening close-ups, no open flames as a hazard, no blood. Keep it bright, soft, slow-paced and delightful for young kids.',
  ]
    .filter(Boolean)
    .join(' ');
}

// Gọi API có retry cho lỗi tạm thời (429/502/503/504/network) — tránh mất video
// đã trả tiền chỉ vì 1 cú gateway timeout lúc poll/tải nội dung.
async function api(path, opts) {
  let last;
  for (let i = 0; i < 6; i++) {
    try {
      const res = await fetch(`${API_BASE}${path}`, {
        ...opts,
        headers: { Authorization: `Bearer ${API_KEY}`, ...(opts?.headers ?? {}) },
      });
      if (res.ok) return res;
      last = new Error(`${res.status}: ${(await res.text()).slice(0, 200)}`);
      if (![429, 502, 503, 504].includes(res.status)) throw last;
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
  const prompt = buildPrompt(journey);

  console.log(`  → ${id}: tạo job…`);
  const create = await (
    await api('', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: MODEL, prompt, size: SIZE, seconds: SECONDS }),
    })
  ).json();
  const videoId = create.id;
  console.log(`     job=${videoId} (lưu lại để recover nếu mất kết nối)`);

  // Poll tới completed (tối đa ~10 phút).
  for (let i = 0; i < 60; i++) {
    await sleep(10_000);
    const job = await (await api(`/${videoId}`, { method: 'GET' })).json();
    process.stdout.write(`\r  … ${id}: ${job.status} ${job.progress ?? 0}%   `);
    if (job.status === 'completed') break;
    if (job.status === 'failed' || job.status === 'expired') {
      console.log(`\n  ✗ ${id}: job ${job.status} — ${job.error?.message ?? ''}`);
      return false;
    }
    if (i === 59) {
      console.log(`\n  ✗ ${id}: hết giờ chờ`);
      return false;
    }
  }

  const mp4 = Buffer.from(
    await (await api(`/${videoId}/content?variant=video`, { method: 'GET' })).arrayBuffer(),
  );
  mkdirSync(VIDEOS_DIR, { recursive: true });
  writeFileSync(join(VIDEOS_DIR, `${id}.mp4`), mp4);

  journey.video = `assets/videos/${id}.mp4`;
  writeFileSync(jsonPath, `${JSON.stringify(journey, null, 2)}\n`);

  console.log(`\n  ✓ ${id}: ${(mp4.length / 1e6).toFixed(1)}MB → assets/videos/${id}.mp4`);
  return true;
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

console.log(`Pre-gen video cho ${ids.length} vật (${MODEL} ${SIZE} ${SECONDS}s):`);
let ok = 0;
for (const id of ids) {
  try {
    if (await genOne(id)) ok++;
  } catch (e) {
    console.log(`\n  ✗ ${id}: ${e.message}`);
  }
}
console.log(`\nXong: ${ok}/${ids.length} video. Nhớ \`flutter pub get\` rồi build lại app.`);
