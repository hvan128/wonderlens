import type { VercelRequest, VercelResponse } from '@vercel/node';

import { generateJourney } from '../lib/openai-generate';

/**
 * Sinh "hành trình tạo ra vật" kid-safe cho vật ngoài bộ hero.
 *
 * Request:  POST { image_base64: string }   header: x-app-token
 * Response: { id, name, emoji, material_badge, stages[], source: 'live' }
 *           name === 'unknown' + stages [] nếu không nhận ra/không phù hợp.
 */

const MAX_BASE64_LEN = 4_000_000;

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

  const body = (req.body ?? {}) as { image_base64?: string };
  const image = body.image_base64;
  if (!image) {
    res.status(400).json({ error: 'missing_image_base64' });
    return;
  }
  if (image.length > MAX_BASE64_LEN) {
    res.status(413).json({ error: 'image_too_large' });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'missing_openai_key' });
    return;
  }

  try {
    const journey = await generateJourney(image, apiKey);
    res.status(200).json({ ...journey, source: 'live' });
  } catch (err) {
    console.error('generate error:', err);
    res.status(502).json({ error: 'generation_failed' });
  }
}
