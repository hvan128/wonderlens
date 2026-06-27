/**
 * Dựng prompt text-to-image kid-safe cho từng "chặng" của hành trình tạo ra vật.
 *
 * Mấu chốt "đồng nhất bối cảnh": mọi chặng của CÙNG một vật dùng chung một
 * "world bible" (phong cách minh hoạ + bảng màu + bối cảnh nền + bố cục). Chỉ
 * phần "scene beat" đổi theo từng chặng → 4 ảnh cùng tông, như một bộ truyện
 * tranh. Tái dùng style + rào chắn an toàn của video-prompt.ts để đồng bộ look.
 */

import type { JourneyInput } from './video-prompt.js';

export const MAX_IMAGE_STAGES = 4;
const MAX_FIELD = 200;

/**
 * Gọn về 1 dòng, BỎ EMOJI + khoảng trắng thừa, cắt độ dài. Bỏ emoji quan trọng
 * cho an toàn: title vật lạ có thể chứa 🔥🔪💉 → nếu lọt vào prompt sẽ lái model
 * ra hình lửa/dao/máu. Emoji chỉ dùng ở UI, không vào prompt.
 */
function clean(s: string | undefined, max = MAX_FIELD): string {
  return (s ?? '')
    .replace(/[\r\n]+/g, ' ')
    .replace(/\p{Extended_Pictographic}/gu, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}

/** Rào chắn an toàn cho ảnh — khớp tinh thần video-prompt nhưng cho ảnh tĩnh. */
const KID_SAFE_IMAGE_RAILS =
  'Absolutely no people, no faces, no hands, and no readable text, letters or numbers anywhere in the image. ' +
  'Nothing scary, dark, tense or dangerous: no monsters, no sharp threatening close-ups, no open flames as a hazard, no blood. ' +
  'Keep it bright, soft, rounded and delightful for young kids.';

/**
 * "World bible" dùng CHUNG cho mọi chặng của một vật → các ảnh đồng nhất bối
 * cảnh: cùng phong cách, cùng bảng màu, cùng nền, cùng bố cục. Không chứa nội
 * dung riêng của chặng nào.
 */
export function buildImageWorldBible(journey: JourneyInput): string {
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

/**
 * Prompt ảnh cho MỘT chặng = world bible chung + "beat" riêng của chặng đó.
 * stageIndex ngoài phạm vi → dùng beat rỗng (chỉ còn world bible + rào chắn).
 */
export function buildStageImagePrompt(
  journey: JourneyInput,
  stageIndex: number,
): string {
  const stage = (journey.stages ?? []).slice(0, MAX_IMAGE_STAGES)[stageIndex];
  const title = clean(stage?.title, 100);
  const detail = clean(stage?.kid_text, 160);
  const beat = [
    title ? `This picture shows stage ${stageIndex + 1}: ${title}.` : '',
    detail ? `Show: ${detail}` : '',
  ]
    .filter(Boolean)
    .join(' ');
  return [buildImageWorldBible(journey), beat, KID_SAFE_IMAGE_RAILS]
    .filter(Boolean)
    .join(' ');
}

/** Số chặng sẽ sinh ảnh (khớp UI timeline, tối đa MAX_IMAGE_STAGES). */
export function imageStageCount(journey: JourneyInput): number {
  return Math.min((journey.stages ?? []).length, MAX_IMAGE_STAGES);
}
