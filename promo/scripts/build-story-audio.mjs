import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const silentVideo = join(root, "out/wonderlens-story-promo-silent.mp4");
const finalVideo = join(root, "out/wonderlens-story-promo.mp4");
const workDir = join(root, "out/story-work");
const voiceDir = join(workDir, "voice");
const bedPath = join(workDir, "wonderlens-story-bed.wav");
const storySource = join(root, "src/WonderLensStoryPromo.tsx");
const durationSeconds = 61;
const runtimeEnv = process["env"];
const mediaApi =
  runtimeEnv["MEDIA_API_BASE"] ||
  "https://media-processing-api.hvan.it.com";
const eco88Voice = runtimeEnv["ECO88_VOICE"] || "Tuyết Trâm";
const eco88VoiceId = Number(runtimeEnv["ECO88_VOICE_ID"] || 151688);
const eco88Speed = runtimeEnv["ECO88_SPEED"] || "0.9";

const ffmpegVersion = spawnSync("ffmpeg", ["-version"], { stdio: "ignore" });
if (ffmpegVersion.error || ffmpegVersion.status !== 0) {
  throw new Error("`ffmpeg` is required and must be available in PATH.");
}

const run = (command, args) => {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} exited with status ${result.status}`);
  }
};

const probeMediaDuration = (path) => {
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-show_entries",
      "format=duration",
      "-of",
      "default=noprint_wrappers=1:nokey=1",
      path,
    ],
    { encoding: "utf8" },
  );
  if (result.error || result.status !== 0) return Number.NaN;
  return Number(result.stdout.trim());
};

if (!existsSync(silentVideo)) {
  throw new Error(
    `Missing silent render: ${silentVideo}\nRun npm run render:story first.`,
  );
}
if (statSync(silentVideo).mtimeMs < statSync(storySource).mtimeMs) {
  throw new Error("Silent render cũ hơn source. Chạy npm run render:story trước.");
}
const silentDuration = probeMediaDuration(silentVideo);
if (
  !Number.isFinite(silentDuration) ||
  Math.abs(silentDuration - durationSeconds) > 0.15
) {
  throw new Error(
    `Silent render phải dài ${durationSeconds}s, hiện là ${silentDuration}s.`,
  );
}

mkdirSync(voiceDir, { recursive: true });

const voiceLines = [
  { startMs: 450, text: "Một chiếc cốc... chỉ là một chiếc cốc?" },
  { startMs: 4200, text: "Đưa WonderLens lên, và nhìn gần hơn." },
  { startMs: 9000, text: "Tèn ten! Bắt được manh mối: cốc giấy." },
  {
    startMs: 12850,
    text: "Thân gỗ được đưa về nhà máy giấy. Vỏ cây được tách ra, phần gỗ sạch chuẩn bị cho chặng tiếp theo.",
  },
  {
    startMs: 20850,
    text: "Mảnh gỗ được làm mềm trong bồn kín bằng nhiệt và dung dịch chuyên dụng. Các sợi xen-lu-lô tách ra thành bột giấy.",
  },
  {
    startMs: 28850,
    text: "Bột giấy trải đều trên lưới. Nước được ép ra, rồi trục lăn nóng sấy và cán thành cuộn giấy mỏng, chắc.",
  },
  {
    startMs: 36850,
    text: "Giấy được phủ chống thấm, cắt thành thân và đáy. Máy cuộn rồi ép mép, và chiếc cốc đã ra đời!",
  },
  { startMs: 45000, text: "Khám phá xong, bé mở khóa huy hiệu vật liệu." },
  {
    startMs: 49800,
    text: "Bút bi, kẹp giấy, chai nước, thước kẻ... cả thế giới quanh bé đều chứa đầy khoa học.",
  },
  { startMs: 56100, text: "WonderLens. Soi đồ vật. Mở chuyện khoa học." },
];

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const fetchWithRetry = async (url, options) => {
  let lastError;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const response = await fetch(url, {
        ...options,
        signal: AbortSignal.timeout(30_000),
      });
      if (response.ok) return response;
      const error = new Error(
        `${response.status} ${(await response.text()).slice(0, 240)}`,
      );
      error.status = response.status;
      throw error;
    } catch (error) {
      lastError = error;
      const retriable =
        !error.status || error.status === 429 || error.status >= 500;
      if (!retriable || attempt === 2) throw error;
      await sleep(1000 * 2 ** attempt);
    }
  }
  throw lastError;
};

const fetchJson = async (url, options) => {
  const response = await fetchWithRetry(url, options);
  return response.json();
};

const verifyEco88Voice = async () => {
  const catalog = await fetchJson(`${mediaApi}/eco88labs/voices`);
  const voices = Array.isArray(catalog)
    ? catalog
    : catalog.voices || catalog.data || [];
  const nameMatches = voices.filter((voice) => voice.name === eco88Voice);
  if (
    nameMatches.length !== 1 ||
    Number(nameMatches[0]?.id) !== eco88VoiceId
  ) {
    throw new Error(
      `Eco88Labs voice ${eco88Voice} phải ánh xạ duy nhất tới id ${eco88VoiceId}.`,
    );
  }
};

const isValidAudioFile = (path) => {
  if (!existsSync(path)) return false;
  const duration = probeMediaDuration(path);
  return Number.isFinite(duration) && duration > 0.2;
};

const voicePathFor = (line, index) => {
  const fingerprint = createHash("sha256")
    .update(
      `${mediaApi}:${eco88Voice}:${eco88VoiceId}:${eco88Speed}:${line.text}`,
    )
    .digest("hex")
    .slice(0, 10);
  return join(
    voiceDir,
    `line-${String(index + 1).padStart(2, "0")}-${fingerprint}.mp3`,
  );
};

const generateEco88Line = async (line, path) => {
  if (isValidAudioFile(path)) return path;
  rmSync(path, { force: true });
  const job = await fetchJson(`${mediaApi}/eco88labs_tts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      gen_text: line.text,
      name_character: eco88Voice,
      output_format: "mp3",
      speed: eco88Speed,
    }),
  });
  if (!job.job_id) throw new Error("Eco88Labs không trả job_id.");

  let result;
  for (let attempt = 0; attempt < 60; attempt += 1) {
    await sleep(2500);
    const status = await fetchJson(`${mediaApi}/job/${job.job_id}`);
    if (status.status === "done") {
      result = status.result;
      break;
    }
    if (status.status === "error") {
      throw new Error(status.error_message || "Eco88Labs job bị lỗi.");
    }
  }
  if (!result?.file_url) throw new Error("Eco88Labs không trả file_url.");
  if (result.fallback) {
    throw new Error(
      `Eco88Labs đã fallback sang ${result.fallback}; dừng để giữ đúng giọng ${eco88Voice}.`,
    );
  }

  const audioUrl = new URL(result.file_url, mediaApi).toString();
  const response = await fetchWithRetry(audioUrl);
  const temporaryPath = `${path}.tmp`;
  writeFileSync(temporaryPath, Buffer.from(await response.arrayBuffer()));
  if (!isValidAudioFile(temporaryPath)) {
    rmSync(temporaryPath, { force: true });
    throw new Error("Eco88Labs trả về file audio không hợp lệ.");
  }
  renameSync(temporaryPath, path);
  return path;
};

const voicePaths = voiceLines.map(voicePathFor);
const missingVoiceCount = voicePaths.filter(
  (path) => !isValidAudioFile(path),
).length;
if (missingVoiceCount > 0) {
  await verifyEco88Voice();
  console.log(
    `Generating ${missingVoiceCount} lines with Eco88Labs ${eco88Voice} (${eco88VoiceId}), speed ${eco88Speed}`,
  );
  for (let index = 0; index < voiceLines.length; index += 1) {
    await generateEco88Line(voiceLines[index], voicePaths[index]);
  }
} else {
  console.log(`Using ${voicePaths.length} cached Eco88Labs voice lines.`);
}

const audioDurationSeconds = (path) => {
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-show_entries",
      "format=duration",
      "-of",
      "default=noprint_wrappers=1:nokey=1",
      path,
    ],
    { encoding: "utf8" },
  );
  if (result.error || result.status !== 0) {
    throw new Error(`Không đọc được thời lượng voice line: ${path}`);
  }
  return Number(result.stdout.trim());
};

voicePaths.forEach((path, index) => {
  const endMs = voiceLines[index].startMs + audioDurationSeconds(path) * 1000;
  const nextStartMs = voiceLines[index + 1]?.startMs ?? 61_000;
  if (endMs > nextStartMs + 50) {
    throw new Error(
      `Voice line ${index + 1} chồng mốc kế tiếp ${Math.ceil(endMs - nextStartMs)}ms.`,
    );
  }
});

const sampleRate = 48_000;
const sampleCount = durationSeconds * sampleRate;
const samples = new Float32Array(sampleCount);

const addTone = ({ start, duration, frequency, amplitude, decay = 0 }) => {
  const first = Math.max(0, Math.floor(start * sampleRate));
  const count = Math.min(
    sampleCount - first,
    Math.floor(duration * sampleRate),
  );
  for (let i = 0; i < count; i += 1) {
    const t = i / sampleRate;
    const edge = Math.min(
      1,
      i / (sampleRate * 0.025),
      (count - i) / (sampleRate * 0.08),
    );
    const envelope = Math.max(0, edge) * (decay > 0 ? Math.exp(-decay * t) : 1);
    samples[first + i] +=
      Math.sin(Math.PI * 2 * frequency * t) * amplitude * envelope;
  }
};

const chords = [
  [261.63, 329.63, 392.0],
  [220.0, 261.63, 329.63],
  [174.61, 220.0, 261.63],
  [196.0, 246.94, 293.66],
];

for (
  let start = 0, chordIndex = 0;
  start < durationSeconds;
  start += 2, chordIndex += 1
) {
  const chord = chords[chordIndex % chords.length];
  for (const frequency of chord) {
    addTone({ start, duration: 2.05, frequency, amplitude: 0.014 });
    addTone({
      start,
      duration: 2.05,
      frequency: frequency / 2,
      amplitude: 0.009,
    });
  }
}

const motif = [523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 880.0, 698.46];
for (
  let start = 0.2, note = 0;
  start < durationSeconds - 1;
  start += 0.5, note += 1
) {
  addTone({
    start,
    duration: 0.28,
    frequency: motif[note % motif.length],
    amplitude: 0.042,
    decay: 8,
  });
}

const addChime = (start, rootFrequency) => {
  addTone({
    start,
    duration: 0.8,
    frequency: rootFrequency,
    amplitude: 0.07,
    decay: 3.8,
  });
  addTone({
    start: start + 0.07,
    duration: 0.75,
    frequency: rootFrequency * 1.25,
    amplitude: 0.055,
    decay: 4.2,
  });
  addTone({
    start: start + 0.14,
    duration: 0.7,
    frequency: rootFrequency * 1.5,
    amplitude: 0.048,
    decay: 4.5,
  });
};

addChime(9.0, 659.25);
addChime(45.0, 783.99);
addChime(56.1, 523.25);

let randomState = 0x5eed1234;
const random = () => {
  randomState = (1664525 * randomState + 1013904223) >>> 0;
  return randomState / 0xffffffff;
};

const clickStart = Math.floor(8.72 * sampleRate);
const clickCount = Math.floor(0.11 * sampleRate);
for (let i = 0; i < clickCount; i += 1) {
  const t = i / sampleRate;
  const envelope = Math.exp(-34 * t);
  samples[clickStart + i] +=
    ((random() * 2 - 1) * 0.19 + Math.sin(Math.PI * 2 * 120 * t) * 0.12) *
    envelope;
}

const wav = Buffer.alloc(44 + sampleCount * 2);
wav.write("RIFF", 0);
wav.writeUInt32LE(36 + sampleCount * 2, 4);
wav.write("WAVE", 8);
wav.write("fmt ", 12);
wav.writeUInt32LE(16, 16);
wav.writeUInt16LE(1, 20);
wav.writeUInt16LE(1, 22);
wav.writeUInt32LE(sampleRate, 24);
wav.writeUInt32LE(sampleRate * 2, 28);
wav.writeUInt16LE(2, 32);
wav.writeUInt16LE(16, 34);
wav.write("data", 36);
wav.writeUInt32LE(sampleCount * 2, 40);

for (let i = 0; i < sampleCount; i += 1) {
  const value = Math.max(-0.92, Math.min(0.92, samples[i]));
  wav.writeInt16LE(Math.round(value * 32767), 44 + i * 2);
}

mkdirSync(dirname(bedPath), { recursive: true });
writeFileSync(bedPath, wav);

const ffmpegInputs = ["-i", silentVideo, "-i", bedPath];
for (const path of voicePaths) ffmpegInputs.push("-i", path);

const filters = [
  "[1:a]volume=0.5,afade=t=in:st=0:d=1,afade=t=out:st=59:d=2[bed]",
  ...voiceLines.map(
    (line, index) =>
      `[${index + 2}:a]aresample=48000,adelay=${line.startMs}|${line.startMs},volume=1.28[voice${index}]`,
  ),
  `[bed]${voiceLines.map((_, index) => `[voice${index}]`).join("")}amix=inputs=${voiceLines.length + 1}:duration=longest:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=7,alimiter=limit=0.95[aout]`,
];

run("ffmpeg", [
  "-y",
  ...ffmpegInputs,
  "-filter_complex",
  filters.join(";"),
  "-map",
  "0:v:0",
  "-map",
  "[aout]",
  "-c:v",
  "copy",
  "-c:a",
  "aac",
  "-b:a",
  "192k",
  "-ar",
  "48000",
  "-t",
  String(durationSeconds),
  "-movflags",
  "+faststart",
  finalVideo,
]);

console.log(`Created ${finalVideo}`);
