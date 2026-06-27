import type { VercelRequest, VercelResponse } from '@vercel/node';

import { recognizeWithOpenAI } from '../lib/openai-vision.js';

/**
 * Nhận diện vật từ ảnh bằng OpenAI Vision, ép phân loại vào bộ "vật hero".
 *
 * Request:  POST { image_base64: string }   header: x-app-token
 * Response: { object_id, confidence, display_name, source }
 */

// Giới hạn ~4MB base64 để tránh vượt body limit của Vercel serverless (~4.5MB).
const MAX_BASE64_LEN = 4_000_000;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  // Auth đơn giản: shared secret để tránh lạm dụng đốt quota OpenAI.
  const expected = process.env.APP_SHARED_SECRET;
  if (!expected) {
    console.warn(
      'APP_SHARED_SECRET chưa set — endpoint đang MỞ. Hãy set biến này + đặt spend limit ở OpenAI trước khi deploy công khai.',
    );
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
    const result = await recognizeWithOpenAI(image, apiKey);
    res.status(200).json({ ...result, source: 'openai' });
  } catch (err) {
    console.error('recognize error:', err);
    res.status(502).json({ error: 'recognition_failed' });
  }
}
