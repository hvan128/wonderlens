#!/usr/bin/env node
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const promoDir = path.resolve(__dirname, '..');
const apiBase = 'https://api.openai.com/v1';

const stages = [
  {
    id: 'stage1_wood_fibers',
    label: 'Gỗ',
    beat:
      'A responsibly sourced tree trunk in a tiny studio splits open into many soft golden paper fibers. The fibers float in a graceful stream toward the camera, magical but scientifically plausible.',
  },
  {
    id: 'stage2_pulp',
    label: 'Bột',
    beat:
      'The fibers swirl inside a clear shallow water basin and gradually become smooth creamy paper pulp. The motion is gentle, readable, and satisfying, like a clean educational transformation.',
  },
  {
    id: 'stage3_coating',
    label: 'Phủ',
    beat:
      'A warm paper sheet glides under two rounded teal rollers. A thin transparent waterproof coating sweeps across the paper as a glossy wave, with tiny highlights showing the new protective layer.',
  },
  {
    id: 'stage4_cut_blank',
    label: 'Cắt',
    beat:
      'A flat coated paper sheet is shaped into a curved fan-like blank for a cup body. Use a soft glowing guide line and a clean peel-away reveal, no sharp dangerous blade.',
  },
  {
    id: 'stage5_form_cup',
    label: 'Ép',
    beat:
      'The fan-shaped blank curls around into a paper cup body while a circular base disk rises into place. The seam and base press together with a soft warm pulse, no scary machinery.',
  },
  {
    id: 'stage6_water_test',
    label: 'Thử',
    beat:
      'The top rim of the paper cup curls neatly into a smooth rounded lip. A single teal water droplet falls into the cup, creates a small ripple, and the cup stays dry on the outside.',
  },
];

const styleBible = `WonderLens premium kid-safe educational animation.
Target audience: children age 6-10, but visual quality should feel polished enough for an app promo.
Visual style: consistent bright miniature papercraft diorama, tactile folded paper, rounded 3D shapes, soft studio shadows, clean teal-and-warm-cream palette with one stage accent color.
Camera: vertical 9:16, centered subject, slow elegant macro push-in, readable from a phone screen, no shaky camera.
Lighting: warm morning light, soft reflections, crisp edges, gentle depth of field.
Motion language: smooth app-like transitions, one clear transformation per clip, delightful "wow" moment near the middle.
Safety and clarity: simplified manufacturing for children, no people, no faces, no text, no labels, no logos, no watermark, no photoreal hazardous factory, no sparks, no fire, no scary machines.
Continuity: every clip must feel like the same WonderLens world, same tabletop, same background gradient, same rounded paper materials, same teal highlight line on the paper cup.`;

const styleReferenceSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="720" height="1280" viewBox="0 0 720 1280">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFDF7"/>
      <stop offset="0.56" stop-color="#F8EDD2"/>
      <stop offset="1" stop-color="#EFD9AD"/>
    </linearGradient>
    <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="22" stdDeviation="18" flood-color="#725018" flood-opacity="0.16"/>
    </filter>
  </defs>
  <rect width="720" height="1280" fill="url(#bg)"/>
  <path d="M40 204 C185 154 278 236 420 184 C552 136 628 164 748 118" fill="none" stroke="#26C6DA" stroke-width="24" stroke-linecap="round" opacity="0.24"/>
  <path d="M-20 1070 C122 1012 252 1110 392 1048 C518 992 618 1048 744 998" fill="none" stroke="#F2B643" stroke-width="24" stroke-linecap="round" opacity="0.2"/>
  <g filter="url(#shadow)">
    <rect x="88" y="110" width="544" height="900" rx="52" fill="#FFFFFF" opacity="0.82"/>
    <rect x="126" y="150" width="468" height="304" rx="46" fill="#16323A"/>
    <circle cx="505" cy="248" r="124" fill="#26C6DA" opacity="0.22"/>
    <path d="M238 240 C258 214 462 214 482 240 L448 560 C436 600 284 600 272 560 Z" fill="#F8EDD2" stroke="#14313A" stroke-width="8"/>
    <ellipse cx="360" cy="240" rx="124" ry="38" fill="#FFFFFF" stroke="#14313A" stroke-width="8"/>
    <ellipse cx="360" cy="240" rx="82" ry="20" fill="#DDF8FB" stroke="#14313A" stroke-width="3" opacity="0.5"/>
    <path d="M282 332 C326 360 404 360 446 334" stroke="#26C6DA" stroke-width="18" stroke-linecap="round" fill="none"/>
    <path d="M288 510 C330 536 392 536 432 510" stroke="#14313A" stroke-width="5" stroke-linecap="round" fill="none" opacity="0.22"/>
    <g transform="translate(146 654)">
      <circle cx="48" cy="48" r="34" fill="#38B979"/>
      <path d="M46 80 C20 70 18 36 44 16 C70 34 72 66 46 80Z" fill="#78CE7F"/>
      <circle cx="156" cy="48" r="34" fill="#F2B643"/>
      <path d="M130 50 C158 24 188 72 156 76" fill="none" stroke="#38B979" stroke-width="8" stroke-linecap="round"/>
      <rect x="240" y="20" width="76" height="58" rx="18" fill="#DDF8FB" stroke="#26C6DA" stroke-width="7"/>
      <path d="M356 28 C404 8 454 8 488 28 L474 88 C420 76 390 76 354 88Z" fill="#F8EDD2" stroke="#3D8BFF" stroke-width="7"/>
      <path d="M92 162 C130 144 192 144 230 162 L214 250 C174 264 136 264 104 250Z" fill="#F8EDD2" stroke="#FF7868" stroke-width="7"/>
      <ellipse cx="160" cy="252" rx="62" ry="18" fill="#EAD6AA" stroke="#14313A" stroke-width="6"/>
      <path d="M330 166 C352 144 458 144 480 166 L454 286 C444 314 366 314 356 286Z" fill="#F8EDD2" stroke="#7862F2" stroke-width="7"/>
      <path d="M368 204 C396 220 438 220 462 204" stroke="#26C6DA" stroke-width="14" stroke-linecap="round"/>
    </g>
  </g>
</svg>`;

const parseArgs = () => {
  const options = {
    output: path.join(promoDir, 'out', 'sora-cup-stages'),
    model: 'sora-2-pro',
    seconds: '4',
    size: '720x1280',
    pollMs: 10000,
    timeoutMs: 20 * 60 * 1000,
    dryRun: false,
    force: false,
    useReference: true,
    stageIds: null,
    resume: new Map(),
  };

  for (const arg of process.argv.slice(2)) {
    if (arg === '--dry-run') options.dryRun = true;
    else if (arg === '--force') options.force = true;
    else if (arg === '--no-reference') options.useReference = false;
    else if (arg.startsWith('--output=')) options.output = path.resolve(arg.slice('--output='.length));
    else if (arg.startsWith('--model=')) options.model = arg.slice('--model='.length);
    else if (arg.startsWith('--seconds=')) options.seconds = arg.slice('--seconds='.length);
    else if (arg.startsWith('--size=')) options.size = arg.slice('--size='.length);
    else if (arg.startsWith('--poll-ms=')) options.pollMs = Number(arg.slice('--poll-ms='.length));
    else if (arg.startsWith('--timeout-ms=')) options.timeoutMs = Number(arg.slice('--timeout-ms='.length));
    else if (arg.startsWith('--stage=')) {
      const value = arg.slice('--stage='.length);
      options.stageIds = value.split(',').map((item) => item.trim()).filter(Boolean);
    } else if (arg.startsWith('--resume=')) {
      const value = arg.slice('--resume='.length);
      for (const pair of value.split(',')) {
        const [stageId, videoId] = pair.split(':');
        if (!stageId || !videoId) throw new Error(`Invalid --resume pair: ${pair}`);
        options.resume.set(stageId.trim(), videoId.trim());
      }
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return options;
};

const readApiKey = () => process.env['OPENAI_API_KEY'] || null;

const styleReferenceDataUrl = () =>
  `data:image/svg+xml;base64,${Buffer.from(styleReferenceSvg).toString('base64')}`;

const stagePrompt = (stage, index) => `${styleBible}

Clip ${index + 1} of 6 for a paper cup origin journey.
Stage title in Vietnamese for internal planning only: ${stage.label}. Do not render any text.
Scene beat: ${stage.beat}

End frame should clearly communicate this stage and be usable as a loopable app asset.`;

const shouldRetryStatus = (status) => status === 429 || status === 500 || status === 502 || status === 503 || status === 504;

const apiFetch = async (pathName, apiKey, options = {}) => {
  const maxAttempts = options.maxAttempts ?? 5;
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const response = await fetch(`${apiBase}${pathName}`, {
      ...options,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        ...(options.body instanceof FormData ? {} : { 'Content-Type': 'application/json' }),
        ...options.headers,
      },
    });

    if (response.ok) return response;

    const text = await response.text();
    lastError = new Error(`OpenAI API ${response.status} ${response.statusText}: ${text}`);
    if (!shouldRetryStatus(response.status) || attempt === maxAttempts) throw lastError;

    const delayMs = Math.min(30000, 1200 * 2 ** (attempt - 1));
    console.warn(`  transient API ${response.status}; retrying in ${Math.round(delayMs / 1000)}s`);
    await sleep(delayMs);
  }

  throw lastError;
};

const createVideoJob = async ({ apiKey, stage, index, options }) => {
  const body = {
    model: options.model,
    prompt: stagePrompt(stage, index),
    seconds: options.seconds,
    size: options.size,
  };

  if (options.useReference) {
    body.input_reference = { image_url: styleReferenceDataUrl() };
  }

  const response = await apiFetch('/videos', apiKey, {
    method: 'POST',
    body: JSON.stringify(body),
  });

  return response.json();
};

const createVideoJobWithReferenceFallback = async ({ apiKey, stage, index, options }) => {
  try {
    return await createVideoJob({ apiKey, stage, index, options });
  } catch (error) {
    if (!options.useReference) throw error;
    console.warn(`  reference image was rejected or unavailable; retrying ${stage.id} without reference`);
    return createVideoJob({
      apiKey,
      stage,
      index,
      options: { ...options, useReference: false },
    });
  }
};

const retrieveVideo = async (apiKey, id) => {
  const response = await apiFetch(`/videos/${id}`, apiKey);
  return response.json();
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const waitForVideo = async ({ apiKey, id, pollMs, timeoutMs }) => {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    const video = await retrieveVideo(apiKey, id);
    const progress = video.progress ?? 0;
    console.log(`  ${id}: ${video.status} ${progress}%`);
    if (video.status === 'completed') return video;
    if (video.status === 'failed') {
      throw new Error(`Video ${id} failed: ${JSON.stringify(video.error ?? {})}`);
    }
    await sleep(pollMs);
  }
  throw new Error(`Timed out waiting for video ${id}`);
};

const downloadVariant = async ({ apiKey, id, variant, outputPath }) => {
  const response = await apiFetch(`/videos/${id}/content?variant=${variant}`, apiKey, {
    headers: { Accept: variant === 'thumbnail' ? 'image/webp,image/*' : 'video/mp4' },
  });
  await pipeline(Readable.fromWeb(response.body), createWriteStream(outputPath));
};

const writeJson = async (filePath, data) => {
  await writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`);
};

const upsertManifestRecord = async ({ manifest, manifestPath, options, stage, record }) => {
  manifest.stages = manifest.stages.filter((item) => item.id !== stage.id).concat(record);
  manifest.generated_at = new Date().toISOString();
  manifest.model = options.model;
  manifest.seconds = options.seconds;
  manifest.size = options.size;
  manifest.style_reference = options.useReference ? 'reference/style-board.svg' : null;
  await writeJson(manifestPath, manifest);
};

const safeReadJson = async (filePath, fallback) => {
  try {
    return JSON.parse(await readFile(filePath, 'utf8'));
  } catch (error) {
    if (error?.code === 'ENOENT') return fallback;
    throw error;
  }
};

const normalizeStageSelection = (stageIds) => {
  if (!stageIds) return stages;
  return stages.filter((stage, index) => {
    const oneBased = String(index + 1);
    return stageIds.includes(oneBased) || stageIds.includes(stage.id) || stageIds.includes(stage.label);
  });
};

const main = async () => {
  const options = parseArgs();
  const selectedStages = normalizeStageSelection(options.stageIds);
  if (!selectedStages.length) throw new Error('No stages matched --stage selection');

  await mkdir(options.output, { recursive: true });
  await mkdir(path.join(options.output, 'reference'), { recursive: true });
  await writeFile(path.join(options.output, 'reference', 'style-board.svg'), styleReferenceSvg);

  const manifestPath = path.join(options.output, 'manifest.json');
  const manifest = await safeReadJson(manifestPath, {
    object_id: 'paper_cup',
    generated_at: null,
    model: options.model,
    seconds: options.seconds,
    size: options.size,
    style_reference: options.useReference ? 'reference/style-board.svg' : null,
    stages: [],
  });

  const prompts = selectedStages.map((stage) => ({
    id: stage.id,
    label: stage.label,
    prompt: stagePrompt(stage, stages.indexOf(stage)),
  }));
  await writeJson(path.join(options.output, 'prompts.json'), {
    model: options.model,
    seconds: options.seconds,
    size: options.size,
    use_reference: options.useReference,
    prompts,
  });

  if (options.dryRun) {
    console.log(`Dry run. Wrote prompts and style reference to ${path.relative(promoDir, options.output)}`);
    return;
  }

  const apiKey = readApiKey();
  if (!apiKey) {
    throw new Error('Missing OPENAI_API_KEY in the current shell environment.');
  }

  for (const stage of selectedStages) {
    const index = stages.indexOf(stage);
    const videoPath = path.join(options.output, `${stage.id}.mp4`);
    const thumbnailPath = path.join(options.output, `${stage.id}.webp`);
    const existing = manifest.stages.find((item) => item.id === stage.id);
    if (existing?.status === 'completed' && !options.force) {
      console.log(`Skip ${stage.id}: already completed. Use --force to regenerate.`);
      continue;
    }

    let created = existing?.video_id && existing.status !== 'completed' && !options.force ? existing : null;
    const resumeVideoId = options.resume.get(stage.id);
    if (resumeVideoId && !options.force) {
      created = {
        ...existing,
        id: resumeVideoId,
        video_id: resumeVideoId,
        status: existing?.status ?? 'in_progress',
      };
      console.log(`Resume Sora job for ${stage.id} (${stage.label}): ${resumeVideoId}`);
    }

    if (!created) {
      console.log(`Create Sora job for ${stage.id} (${stage.label})`);
      created = await createVideoJobWithReferenceFallback({ apiKey, stage, index, options });
      console.log(`  job ${created.id}: ${created.status}`);
      await upsertManifestRecord({
        manifest,
        manifestPath,
        options,
        stage,
        record: {
          id: stage.id,
          label: stage.label,
          status: created.status,
          video_id: created.id,
          model: created.model,
          seconds: created.seconds,
          size: created.size,
          completed_at: null,
          video: null,
          thumbnail: null,
          prompt: stagePrompt(stage, index),
        },
      });
    }

    const completed = await waitForVideo({
      apiKey,
      id: created.video_id ?? created.id,
      pollMs: options.pollMs,
      timeoutMs: options.timeoutMs,
    });

    console.log(`  download ${path.basename(videoPath)}`);
    await downloadVariant({ apiKey, id: completed.id, variant: 'video', outputPath: videoPath });
    console.log(`  download ${path.basename(thumbnailPath)}`);
    await downloadVariant({ apiKey, id: completed.id, variant: 'thumbnail', outputPath: thumbnailPath });

    const record = {
      id: stage.id,
      label: stage.label,
      status: completed.status,
      video_id: completed.id,
      model: completed.model,
      seconds: completed.seconds,
      size: completed.size,
      completed_at: completed.completed_at,
      video: path.relative(options.output, videoPath),
      thumbnail: path.relative(options.output, thumbnailPath),
      prompt: stagePrompt(stage, index),
    };
    await upsertManifestRecord({ manifest, manifestPath, options, stage, record });
  }

  console.log(`Done. Manifest: ${path.relative(promoDir, manifestPath)}`);
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
