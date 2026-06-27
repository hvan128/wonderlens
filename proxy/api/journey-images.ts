import type { VercelRequest, VercelResponse } from '@vercel/node';

import { generateImage } from '../lib/openai-image.js';
import {
  buildStageImagePrompt,
  imageStageCount,
} from '../lib/image-prompt.js';
import { isTextFlagged } from '../lib/openai-video.js';
import type { JourneyInput } from '../lib/video-prompt.js';

/**
 * Sinh ảnh minh hoạ kid-safe cho TỪNG CHẶNG của hành trình (vật AI-live).
 * Mọi chặng dùng chung "world bible" → ảnh đồng nhất bối cảnh. Sinh song song.
 *
 * Request:  POST { name, material_badge?, stages: [{title, kid_text?}] }
 *           header: x-app-token
 * Response: { images: [{ stage_index, image_base64 }] }
 *           Chặng nào lỗi thì vắng mặt trong mảng → app rớt về không-ảnh.
 *
 * Hero objects KHÔNG gọi đây: ảnh đã bundle sẵn (scripts/pregen-hero-images.mjs).
 */

export const config = { maxDuration: 60 };

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const expected = process.env.APP_SHARED_SECRET;
  if (!expected) {
    console.warn('APP_SHARED_SECRET chưa set — endpoint đang MỞ.');
  } else if (req.headers['x-app-token'] !== expected) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  const body = (req.body ?? {}) as Partial<JourneyInput>;
  if (!body.name || !Array.isArray(body.stages) || body.stages.length === 0) {
    res.status(400).json({ error: 'missing_journey' });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'missing_openai_key' });
    return;
  }

  try {
    // Lưới an toàn server-side trước khi tốn tiền gọi image API: kiểm duyệt text
    // journey (không tin tuyệt đối client — token là secret tĩnh).
    const moderationText = [
      body.name,
      body.material_badge ?? '',
      ...(body.stages ?? []).map((s) => `${s?.title ?? ''} ${s?.kid_text ?? ''}`),
    ].join('\n');
    if (await isTextFlagged(moderationText, apiKey)) {
      res.status(422).json({ error: 'content_not_kid_safe' });
      return;
    }

    const journey = body as JourneyInput;
    const count = imageStageCount(journey);
    // Song song: 1 chặng lỗi không kéo đổ cả batch (allSettled).
    const settled = await Promise.allSettled(
      Array.from({ length: count }, (_, i) =>
        generateImage(buildStageImagePrompt(journey, i), apiKey),
      ),
    );

    const images = settled
      .map((r, i) =>
        r.status === 'fulfilled'
          ? { stage_index: i, image_base64: r.value }
          : null,
      )
      .filter((x): x is { stage_index: number; image_base64: string } => x !== null);

    if (images.length === 0) {
      res.status(502).json({ error: 'image_generation_failed' });
      return;
    }
    res.status(200).json({ images });
  } catch (err) {
    console.error('journey-images error:', err);
    res.status(502).json({ error: 'image_generation_failed' });
  }
}
