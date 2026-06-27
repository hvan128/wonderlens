import type { VercelRequest, VercelResponse } from '@vercel/node';

import { synthesizeSpeech } from '../lib/openai-speech.js';

/**
 * Đọc to văn bản bằng OpenAI Text-to-Speech, trả audio MP3.
 *
 * Request:  POST { text: string }   header: x-app-token
 * Response: audio/mpeg (binary)
 */

// Chặn payload quá lớn (lib tự cắt còn 4000 ký tự cho OpenAI).
const MAX_TEXT_LEN = 6000;

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

  const body = (req.body ?? {}) as { text?: string };
  const text = (body.text ?? '').trim();
  if (!text) {
    res.status(400).json({ error: 'missing_text' });
    return;
  }
  if (text.length > MAX_TEXT_LEN) {
    res.status(413).json({ error: 'text_too_large' });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'missing_openai_key' });
    return;
  }

  try {
    const audio = await synthesizeSpeech(text, apiKey);
    res.setHeader('Content-Type', 'audio/mpeg');
    // Cùng văn bản → cùng audio: cho cache phía client/CDN để tiết kiệm chi phí.
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.status(200).send(audio);
  } catch (err) {
    console.error('speech error:', err);
    res.status(502).json({ error: 'speech_failed' });
  }
}
