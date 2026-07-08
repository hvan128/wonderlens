#!/usr/bin/env node
/**
 * Sinh SẴN bộ ảnh cutout (nền trong suốt) đóng vai "ảnh bé chụp đã tách nền"
 * để render screenshot store — seed vào CaptureStore.debugSetStore trong
 * app/tool/pregen_store_screenshots.dart. Không bundle vào app.
 *
 *   cd proxy && node scripts/pregen-demo-captures.mjs
 *
 * Ra: app/store-assets/demo-captures/{id}.png
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, '..', '..', 'app', 'store-assets', 'demo-captures');

const MODEL = process.env.IMAGE_MODEL ?? 'gpt-image-1';
const API_URL = 'https://api.openai.com/v1/images/generations';

// Chụp "kiểu ảnh thật đã tách nền" cho khớp look cutout trong app.
const STYLE =
  'single object only, photorealistic product photo, softly lit, natural colors, ' +
  'slight three-quarter angle, isolated cutout on fully transparent background, ' +
  'no shadow, no text, no watermark, no other objects';

const OBJECTS = {
  wooden_spoon: 'a simple wooden cooking spoon with visible wood grain',
  clay_pot: 'a small rustic terracotta clay pot',
  rubber_duck: 'a classic yellow rubber duck bath toy',
  glass_cup: 'a clear drinking glass cup',
  wool_hat: 'a knitted wool beanie hat, warm mustard color',
  paper_cup: 'a plain white disposable paper cup',
  pencil: 'a classic yellow wooden pencil with pink eraser',
  plastic_bottle: 'a clear plastic water bottle with blue cap',
};

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

async function gen(id, desc, apiKey) {
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      prompt: `${desc}, ${STYLE}`,
      size: '1024x1024',
      quality: 'medium',
      background: 'transparent',
      n: 1,
    }),
  });
  if (!res.ok) throw new Error(`${id}: ${res.status} ${await res.text()}`);
  const json = await res.json();
  const b64 = json.data?.[0]?.b64_json;
  if (!b64) throw new Error(`${id}: no image payload`);
  writeFileSync(join(OUT_DIR, `${id}.png`), Buffer.from(b64, 'base64'));
  console.log(`✓ ${id}.png`);
}

const apiKey = loadEnv();
if (!apiKey) {
  console.error('Thiếu OPENAI_API_KEY (env hoặc proxy/.env)');
  process.exit(1);
}
mkdirSync(OUT_DIR, { recursive: true });

// Chạy 3 luồng song song cho nhanh, vật nào lỗi báo riêng vật đó.
const entries = Object.entries(OBJECTS).filter(
  ([id]) => !existsSync(join(OUT_DIR, `${id}.png`)),
);
console.log(`Sinh ${entries.length} ảnh cutout demo…`);
let failed = 0;
for (let i = 0; i < entries.length; i += 3) {
  const batch = entries.slice(i, i + 3);
  const results = await Promise.allSettled(
    batch.map(([id, desc]) => gen(id, desc, apiKey)),
  );
  for (const r of results) {
    if (r.status === 'rejected') {
      failed++;
      console.error(`✗ ${r.reason}`);
    }
  }
}
process.exit(failed ? 1 : 0);
