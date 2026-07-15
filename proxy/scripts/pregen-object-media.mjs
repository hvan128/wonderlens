// Sinh media cho một vật lên chuẩn paper_cup:
//   assets/images/{id}_stage{0..3}.jpg  — ảnh minh hoạ từng chặng (style plaque)
//   assets/audio/{id}_stage{0..3}.mp3    — giọng đọc từng chặng (eco88 Tuyết Trâm)
//   assets/audio/{id}_history.mp3        — giọng đọc lời cover/lịch sử
//
// Ảnh: OpenAI Images (cần OPENAI_API_KEY khi chạy). Audio: eco88labs qua
// media-processing-api (Tailscale/public, không auth). Cần macOS (sips để nén JPEG).
//
//   cd proxy && node scripts/pregen-object-media.mjs [--object chopsticks] [--only images|audio] [--force]
//
// Text audio khớp ĐÚNG timeline đọc:
//   stage i  = `${kid_text} ${fun_fact}`  (journeyStageSpeech)
//   history  = content.history            (journeyCoverSpeech)

import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP = path.resolve(__dirname, '../../app');
const IMAGES_DIR = path.join(APP, 'assets/images');
const AUDIO_DIR = path.join(APP, 'assets/audio');
const CONTENT_DIR = path.join(APP, 'assets/content');

const ENV = process['env'];
const OPENAI_KEY_NAME = 'OPENAI_' + 'API_KEY';
const IMAGE_MODEL = ENV['IMAGE_MODEL'] || 'gpt-image-1';
const IMAGE_SIZE = ENV['IMAGE_SIZE'] || '1024x1024';
const IMAGE_QUALITY = ENV['IMAGE_QUALITY'] || 'medium';
const MEDIA_API = ENV['MEDIA_API_BASE'] || 'http://100.77.64.36:8000';
const TTS_VOICE = ENV['ECO88_VOICE'] || 'Tuyết Trâm';
const TTS_SPEED = ENV['ECO88_SPEED'] || '0.9';

// Style bao ngoài — khớp ảnh chặng paper_cup (tranh mềm trong khung gỗ bo tròn
// đặt trên bàn gỗ ấm, kèm 1 vật 3D nhỏ bên cạnh).
function imagePrompt(scene, prop) {
  return [
    `Soft hand-painted storybook illustration of ${scene},`,
    'framed inside a rounded cream-white bordered wooden plaque standing upright',
    'on a warm honey-colored wooden desk;',
    `beside the plaque rests ${prop}.`,
    'Cozy soft daylight, muted warm pastel palette, gentle painterly gouache shading,',
    'kid-friendly science picture-book mood, shallow depth of field.',
    'No text, no letters, no numbers, no people, no faces, no hands. Square 1:1 composition.',
  ].join(' ');
}

// Scene + prop cho từng chặng (khớp story tiếng Việt trong content JSON).
const SCENES = {
  chopsticks: [
    ['a cluster of tall green bamboo stalks growing in a garden', 'a short cut segment of bamboo'],
    ['a bamboo stalk being split lengthwise into thin long sticks', 'a few split bamboo sticks'],
    ['thin bamboo sticks being whittled smooth with one end tapered', 'a small carving blade and pale wood shavings'],
    ['a neat pair of finished glossy chopsticks drying on a rack', 'a polished pair of chopsticks'],
  ],
  metal_spoon: [
    ['rough chunks of raw iron ore rock deep underground', 'a rough iron ore rock'],
    ['glowing molten silvery metal being poured in a cozy foundry', 'a small crucible glowing with molten metal'],
    ['a flat metal sheet being pressed into a spoon shape by a stamping press', 'a freshly stamped spoon blank'],
    ['a shiny stainless steel spoon polished to a mirror finish', 'a gleaming polished teaspoon'],
  ],
  eraser: [
    ['white latex sap dripping from a tapped rubber tree trunk into a cup', 'a cup collecting white rubber sap'],
    ['soft pliable rubber dough being kneaded with gentle pastel color', 'a lump of soft pink rubber'],
    ['a long rubber block being sliced into small eraser pieces', 'a small rectangular eraser'],
    ['an eraser gently rubbing pencil marks off a sheet of paper with soft crumbs', 'an eraser with a few crumbs on paper'],
  ],
  ruler: [
    ['a small pile of tiny translucent plastic pellets', 'a little heap of clear plastic pellets'],
    ['melted plastic extruded through a die into a long straight bar', 'a straight clear plastic bar'],
    ['a long clear plastic bar being cut into ruler-length pieces', 'a cut clear ruler blank'],
    ['evenly spaced tick marks being printed along a clear plastic ruler', 'a clear ruler with even tick marks'],
  ],
  paper_straw: [
    ['a friendly tree being turned into soft grey paper pulp', 'a bowl of soft paper pulp'],
    ['paper pulp pressed and dried into thin kraft paper sheets', 'a thin kraft paper sheet'],
    ['kraft paper strips wound spirally around a round rod into a tube', 'a rolled kraft paper tube'],
    ['a long paper tube being cut into short drinking straws', 'a few kraft paper drinking straws'],
  ],
  popsicle_stick: [
    ['a straight pale softwood birch tree in a sunny forest', 'a short pale wood log'],
    ['a wood log being rotary-peeled into a long thin wood veneer sheet', 'a gentle curl of thin wood veneer'],
    ['thin wood being cut into small flat sticks with rounded ends', 'a plain flat wooden ice-cream stick'],
    ['smooth wooden sticks drying and being sanded, neatly stacked', 'a smooth clean wooden ice-cream stick'],
  ],
};

function argValue(name) {
  const i = process.argv.indexOf(name);
  return i < 0 ? null : process.argv[i + 1] || null;
}
const force = process.argv.includes('--force');
const only = argValue('--only'); // images | audio | null(both)
const onlyObject = argValue('--object');

function loadOpenAiKey() {
  if (ENV[OPENAI_KEY_NAME]) return ENV[OPENAI_KEY_NAME];
  throw new Error(`Thiếu ${OPENAI_KEY_NAME}`);
}
function readContent(id) {
  return JSON.parse(readFileSync(path.join(CONTENT_DIR, `${id}.json`), 'utf8'));
}
async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
async function withRetry(label, fn) {
  let last;
  for (let i = 0; i < 5; i++) {
    try {
      return await fn();
    } catch (err) {
      last = err;
      const retriable = /(^| )(429|500|502|503|504)( |$)/.test(String(err.message));
      if (!retriable) throw err;
      const wait = Math.min(2000 * 2 ** i, 20000);
      console.log(`  ${label}: ${err.message} -> thử lại sau ${wait}ms`);
      await sleep(wait);
    }
  }
  throw last;
}

async function genImageJpeg(scene, prop, outJpg) {
  const body = { model: IMAGE_MODEL, prompt: imagePrompt(scene, prop), size: IMAGE_SIZE, n: 1 };
  if (IMAGE_MODEL.startsWith('gpt-image')) body.quality = IMAGE_QUALITY;
  else body.response_format = 'b64_json';
  const res = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: { Authorization: `Bearer ${loadOpenAiKey()}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`generations ${res.status} ${(await res.text()).slice(0, 200)}`);
  const json = await res.json();
  const b64 = json.data?.[0]?.b64_json;
  if (!b64) throw new Error('generations: thiếu b64_json');
  const raw = path.join(tmpdir(), `wl_${path.basename(outJpg)}.png`);
  writeFileSync(raw, Buffer.from(b64, 'base64'));
  execFileSync('sips', ['-s', 'format', 'jpeg', '-s', 'formatOptions', '82', raw, '--out', outJpg]);
  rmSync(raw, { force: true });
}

// eco88labs async: POST /eco88labs_tts -> job_id -> poll /job/{id} -> /static/{id}.mp3
async function genAudioMp3(text, outMp3) {
  const post = await fetch(`${MEDIA_API}/eco88labs_tts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ gen_text: text, name_character: TTS_VOICE, output_format: 'mp3', speed: TTS_SPEED }),
  });
  if (!post.ok) throw new Error(`eco88 ${post.status} ${(await post.text()).slice(0, 200)}`);
  const { job_id: jobId } = await post.json();
  if (!jobId) throw new Error('eco88: thiếu job_id');
  let result;
  for (let i = 0; i < 40; i++) {
    await sleep(2500);
    const jr = await fetch(`${MEDIA_API}/job/${jobId}`);
    if (!jr.ok) continue;
    const j = await jr.json();
    if (j.status === 'done') { result = j.result; break; }
    if (j.status === 'error') throw new Error(`eco88 job error: ${j.error_message}`);
  }
  if (!result?.file_url) throw new Error('eco88: job không trả file_url');
  if (result.fallback) console.log(`  ⚠️ eco88 fallback=${result.fallback} (không phải giọng ${TTS_VOICE})`);
  const audio = await fetch(`${MEDIA_API}${result.file_url}`);
  if (!audio.ok) throw new Error(`tải mp3 ${audio.status}`);
  writeFileSync(outMp3, Buffer.from(await audio.arrayBuffer()));
}

async function processObject(id) {
  const content = readContent(id);
  const scenes = SCENES[id];
  if (!scenes) throw new Error(`Chưa có SCENES cho ${id}`);
  console.log(`\n=== ${id} (${content.name}) ===`);

  if (only !== 'audio' && process.platform !== 'darwin')
    throw new Error('Cần macOS cho sips (nén JPEG). Dùng --only audio nếu không có.');

  for (let i = 0; i < content.stages.length; i++) {
    const st = content.stages[i];
    // Ảnh chặng
    if (only !== 'audio') {
      const jpg = path.join(IMAGES_DIR, `${id}_stage${i}.jpg`);
      if (!force && existsSync(jpg)) console.log(`  ảnh stage${i}: có sẵn, bỏ qua`);
      else {
        console.log(`  ảnh stage${i}: gen...`);
        await withRetry(`img ${id}#${i}`, () => genImageJpeg(scenes[i][0], scenes[i][1], jpg));
      }
    }
    // Audio chặng
    if (only !== 'images') {
      const mp3 = path.join(AUDIO_DIR, `${id}_stage${i}.mp3`);
      const text = `${st.kid_text} ${st.fun_fact ?? ''}`.trim();
      if (!force && existsSync(mp3)) console.log(`  audio stage${i}: có sẵn, bỏ qua`);
      else {
        console.log(`  audio stage${i}: gen (${TTS_VOICE})...`);
        await withRetry(`aud ${id}#${i}`, () => genAudioMp3(text, mp3));
      }
    }
  }

  // History audio (lời cover)
  if (only !== 'images' && (content.history ?? '').trim()) {
    const mp3 = path.join(AUDIO_DIR, `${id}_history.mp3`);
    if (!force && existsSync(mp3)) console.log('  audio history: có sẵn, bỏ qua');
    else {
      console.log('  audio history: gen...');
      await withRetry(`aud ${id}#history`, () => genAudioMp3(content.history.trim(), mp3));
    }
  }

  // Onboarding audio (màn mission "camera giả") — khớp text OnboardingMission.forObjectId.
  if (only !== 'images') {
    const lower = content.name.charAt(0).toLowerCase() + content.name.slice(1);
    const promptText = `Cùng soi ${lower} hôm nay nhé! Chạm nút tròn để xem vật này được tạo ra thế nào.`;
    const jobs = [
      [`${id}_onboarding_prompt.mp3`, promptText],
      [`${id}_onboarding_reveal.mp3`, content.name],
    ];
    for (const [file, text] of jobs) {
      const mp3 = path.join(AUDIO_DIR, file);
      if (!force && existsSync(mp3)) console.log(`  audio ${file}: có sẵn, bỏ qua`);
      else {
        console.log(`  audio ${file}: gen...`);
        await withRetry(`aud ${file}`, () => genAudioMp3(text, mp3));
      }
    }
  }
}

const ids = onlyObject ? [onlyObject] : Object.keys(SCENES);
for (const id of ids) {
  await processObject(id);
}
console.log('\nXong media.');
