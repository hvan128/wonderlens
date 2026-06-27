/** Dựng prompt text-to-video kid-safe cho Sora từ "hành trình tạo ra vật". */

export interface JourneyStageInput {
  title: string;
  kid_text?: string;
}

export interface JourneyInput {
  name: string;
  material_badge?: string;
  stages: JourneyStageInput[];
}

const MAX_STAGES = 4;
const MAX_FIELD = 160;

/**
 * Gọn về 1 dòng, bỏ emoji + xuống dòng/khoảng trắng thừa, cắt độ dài.
 * BỎ EMOJI quan trọng cho an toàn: title vật lạ có thể chứa 🔥🔪💉 → nếu lọt vào
 * prompt sẽ lái Sora ra hình lửa/dao/máu. Emoji chỉ dùng ở UI, không vào prompt.
 */
function clean(s: string | undefined, max = MAX_FIELD): string {
  return (s ?? '')
    .replace(/[\r\n]+/g, ' ')
    .replace(/\p{Extended_Pictographic}/gu, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}

/**
 * Tạo prompt mô tả một đoạn phim hoạt hình ngắn, vui, an toàn cho trẻ 6-10,
 * kể "hành trình tạo ra vật". Hướng dẫn style + rào chắn an toàn viết bằng tiếng
 * Anh (Sora bám tốt nhất), từng "beat" cảnh lấy từ tiêu đề các chặng của journey.
 *
 * Chủ đích KHÔNG dùng ảnh chụp (text-to-video) để tránh Sora từ chối ảnh có mặt
 * người và để kiểm soát nội dung dễ đoán, an toàn hơn.
 */
export function buildVideoPrompt(journey: JourneyInput): string {
  const name = clean(journey.name, 80) || 'an everyday object';
  const material = clean(journey.material_badge, 40);
  const beats = (journey.stages ?? [])
    .slice(0, MAX_STAGES)
    .map((s, i) => {
      const title = clean(s.title, 100);
      return title ? `Scene ${i + 1}: ${title}.` : '';
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
