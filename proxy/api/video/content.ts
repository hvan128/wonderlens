import type { VercelRequest, VercelResponse } from '@vercel/node';

import { fetchVideoContent } from '../../lib/openai-video.js';

/**
 * Tải nội dung MP4 (hoặc thumbnail) của job đã 'completed', giấu OpenAI key.
 * Buffer toàn bộ rồi trả 200 (clip ngắn vài MB) — app tải hẳn về file để phát
 * cho chắc, tránh các trục trặc streaming/Range của AVPlayer.
 *
 * Request:  GET ?id=<video_id>&variant=video|thumbnail   header: x-app-token
 * Response: video/mp4 (hoặc image/webp)
 */

export const config = { maxDuration: 60 };

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
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

  const id = (req.query.id as string) ?? '';
  if (!id) {
    res.status(400).json({ error: 'missing_id' });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'missing_openai_key' });
    return;
  }

  try {
    const variant = req.query.variant === 'thumbnail' ? 'thumbnail' : 'video';
    const upstream = await fetchVideoContent(id, apiKey, variant);
    const buf = Buffer.from(await upstream.arrayBuffer());
    res.setHeader(
      'Content-Type',
      upstream.headers.get('content-type') ??
        (variant === 'thumbnail' ? 'image/webp' : 'video/mp4'),
    );
    res.setHeader('Content-Length', buf.length.toString());
    res.setHeader('Cache-Control', 'private, max-age=3600');
    res.status(200).send(buf);
  } catch (err) {
    console.error('video content error:', err);
    res.status(502).json({ error: 'video_content_failed' });
  }
}
