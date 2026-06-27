import type { VercelRequest, VercelResponse } from '@vercel/node';

import { createVideo, isTextFlagged } from '../../lib/openai-video.js';
import { buildVideoPrompt, type JourneyInput } from '../../lib/video-prompt.js';

/**
 * Khởi động job tạo "video hành trình" (text-to-video, Sora) từ nội dung journey.
 *
 * Request:  POST { name, material_badge?, stages: [{title, kid_text?}] }
 *           header: x-app-token
 * Response: { video_id, status }   (status thường 'queued')
 *
 * App tự poll /api/video/status rồi tải /api/video/content.
 */

export const config = { maxDuration: 30 };

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
  if (
    !body.name ||
    !Array.isArray(body.stages) ||
    body.stages.length === 0
  ) {
    res.status(400).json({ error: 'missing_journey' });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'missing_openai_key' });
    return;
  }

  try {
    // Lưới an toàn server-side trước khi tốn tiền gọi Sora: kiểm duyệt text
    // journey (không tin tưởng tuyệt đối client — token là secret tĩnh).
    const moderationText = [
      body.name,
      body.material_badge ?? '',
      ...(body.stages ?? []).map((s) => s?.title ?? ''),
    ].join('\n');
    if (await isTextFlagged(moderationText, apiKey)) {
      res.status(422).json({ error: 'content_not_kid_safe' });
      return;
    }
    const prompt = buildVideoPrompt(body as JourneyInput);
    const job = await createVideo(prompt, apiKey);
    res.status(200).json({ video_id: job.id, status: job.status });
  } catch (err) {
    console.error('video create error:', err);
    res.status(502).json({ error: 'video_create_failed' });
  }
}
