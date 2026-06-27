import type { VercelRequest, VercelResponse } from '@vercel/node';

import { getVideoStatus } from '../../lib/openai-video.js';

/**
 * Trả trạng thái + tiến độ của một job video.
 *
 * Request:  GET ?id=<video_id>   header: x-app-token
 * Response: { status, progress, error }
 *           status: queued | in_progress | completed | failed | expired
 */

export const config = { maxDuration: 30 };

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
    const job = await getVideoStatus(id, apiKey);
    res.status(200).json({
      status: job.status,
      progress: job.progress,
      error: job.error,
    });
  } catch (err) {
    console.error('video status error:', err);
    res.status(502).json({ error: 'video_status_failed' });
  }
}
