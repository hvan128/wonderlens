// Sinh ảnh cho mission onboarding từ notification:
//   assets/images/mission_{object_id}_scene.jpg
//   assets/images/mission_{object_id}_cutout.png
//
// Chạy trong proxy/ với biến OPENAI_API_KEY đã export sẵn:
//   node scripts/pregen-mission-images.mjs [--object ball_pen] [--force]
//
// Script chỉ đọc biến môi trường lúc chạy, không đọc/ghi file secret.
// Cần macOS vì dùng sips + Apple Vision để tách cutout cùng khung hình.

import { execFileSync } from 'node:child_process';
import { existsSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const IMAGES_DIR = path.resolve(__dirname, '../../app/assets/images');
const CUTOUT_SWIFT = path.join(__dirname, 'CutoutForeground.swift');

const ENV = process['env'];
const MODEL = ENV['IMAGE_MODEL'] || 'gpt-image-1';
const SIZE = ENV['IMAGE_SIZE'] || '1024x1536';
const QUALITY = ENV['IMAGE_QUALITY'] || 'medium';
const KEY_NAME = 'OPENAI_' + 'API_KEY';

const MISSIONS = {
  ball_pen: {
    name: 'ballpoint pen',
    prompt:
      'a single friendly blue ballpoint pen lying diagonally on a warm wooden desk, fully visible, centered with generous empty space',
  },
  paper_a4: {
    name: 'A4 paper sheet',
    prompt:
      'a single clean blank A4 paper sheet on a warm wooden desk, one corner slightly lifted, fully visible, centered with generous empty space',
  },
  plastic_bottle: {
    name: 'clear plastic water bottle',
    prompt:
      'a single clear plastic water bottle with no label and no text, upright on a warm wooden desk, fully visible, centered with generous empty space',
  },
  paper_clip: {
    name: 'paper clip',
    prompt:
      'a single shiny silver paper clip on a warm wooden desk, large enough to see clearly, fully visible, centered with generous empty space',
  },
  pencil: {
    name: 'wooden pencil',
    prompt:
      'a single yellow wooden pencil with no brand text, lying diagonally on a warm wooden desk, fully visible, centered with generous empty space',
  },
  sticky_note: {
    name: 'sticky note',
    prompt:
      'a single blank yellow sticky note with no writing, slightly curled corner, on a warm wooden desk, fully visible, centered with generous empty space',
  },
  battery_aa: {
    name: 'AA battery',
    prompt:
      'a single AA battery with simple plain colors and no brand text or warning text, lying on a warm wooden desk, fully visible, centered with generous empty space',
  },
  chopsticks: {
    name: 'wooden chopsticks',
    prompt:
      'a single pair of plain wooden chopsticks lying side by side diagonally on a warm wooden desk, fully visible, centered with generous empty space',
  },
  metal_spoon: {
    name: 'stainless steel spoon',
    prompt:
      'a single shiny stainless steel teaspoon lying on a warm wooden desk, bowl facing up, fully visible, centered with generous empty space',
  },
  eraser: {
    name: 'eraser',
    prompt:
      'a single plain white rubber eraser block with no brand text, on a warm wooden desk, fully visible, centered with generous empty space',
  },
  ruler: {
    name: 'plastic ruler',
    prompt:
      'a single clear plastic ruler lying diagonally on a warm wooden desk, no readable numbers or text, fully visible, centered with generous empty space',
  },
  paper_straw: {
    name: 'paper drinking straw',
    prompt:
      'a single plain kraft paper drinking straw lying diagonally on a warm wooden desk, no text, fully visible, centered with generous empty space',
  },
  popsicle_stick: {
    name: 'wooden ice cream stick',
    prompt:
      'a single plain flat wooden ice cream stick lying diagonally on a warm wooden desk, no text, fully visible, centered with generous empty space',
  },
};

function loadApiKey() {
  if (ENV[KEY_NAME]) return ENV[KEY_NAME];
  throw new Error(`Thiếu ${KEY_NAME} khi chạy script`);
}

function argValue(name) {
  const idx = process.argv.indexOf(name);
  if (idx < 0) return null;
  return process.argv[idx + 1] || null;
}

async function withRetry(label, fn) {
  let lastErr;
  for (let i = 0; i < 5; i++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      const retriable = /(^| )(429|500|502|503|504)( |$)/.test(
        String(err.message),
      );
      if (!retriable) throw err;
      const wait = Math.min(2000 * 2 ** i, 20000);
      console.log(`  ${label}: ${err.message} -> thử lại sau ${wait}ms`);
      await new Promise((r) => setTimeout(r, wait));
    }
  }
  throw lastErr;
}

function scenePrompt(mission) {
  return [
    `Vertical smartphone photo of ${mission.prompt}.`,
    'Soft natural window daylight, gently blurred cozy neutral wall background.',
    'Photorealistic, bright, warm, kid-friendly science discovery app mood.',
    'No people, no faces, no hands, no logos, no readable text, no scary elements.',
  ].join(' ');
}

async function generateScene(mission) {
  const body = {
    model: MODEL,
    prompt: scenePrompt(mission),
    size: SIZE,
    n: 1,
  };
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
const onlyObject = argValue('--object');

if (process.platform !== 'darwin') {
  console.error('Cần macOS: sips + swift/Vision. Dừng, chưa gọi API.');
  process.exit(1);
}

let entries = Object.entries(MISSIONS);
if (onlyObject) {
  if (!MISSIONS[onlyObject]) {
    console.error(`Không có mission object: ${onlyObject}`);
    process.exit(1);
  }
  entries = [[onlyObject, MISSIONS[onlyObject]]];
}

for (const [id, mission] of entries) {
  const scenePng = path.join(tmpdir(), `wonderlens_mission_${id}_raw.png`);
  const sceneJpg = path.join(IMAGES_DIR, `mission_${id}_scene.jpg`);
  const cutoutPath = path.join(IMAGES_DIR, `mission_${id}_cutout.png`);

  if (!force && existsSync(sceneJpg) && existsSync(cutoutPath)) {
    console.log(`Đã có ${id} - bỏ qua (--force để gen lại).`);
    continue;
  }

  console.log(`Gen mission ${id} (${mission.name})...`);
  const scene = await withRetry(id, () => generateScene(mission));
  writeFileSync(scenePng, scene);
  rmSync(cutoutPath, { force: true });

  console.log(`  Nén JPEG: ${path.basename(sceneJpg)}`);
  execFileSync('sips', [
    '-s',
    'format',
    'jpeg',
    '-s',
    'formatOptions',
    '82',
    scenePng,
    '--out',
    sceneJpg,
  ]);
  rmSync(scenePng, { force: true });

  console.log(`  Tách cutout: ${path.basename(cutoutPath)}`);
  execFileSync('swift', [CUTOUT_SWIFT, sceneJpg, cutoutPath], {
    stdio: 'inherit',
  });
}

console.log('Xong mission images.');
