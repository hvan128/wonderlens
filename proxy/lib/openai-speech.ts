// Giọng đọc OpenAI Text-to-Speech cho trang chi tiết (audio/speech → MP3).
// Dùng fetch (Vercel/Node 18+ có sẵn) để khỏi thêm SDK.

const TTS_MODEL = process.env.TTS_MODEL || 'gpt-4o-mini-tts';
const TTS_VOICE = process.env.TTS_VOICE || 'nova';
const TTS_INSTRUCTIONS =
  process.env.TTS_INSTRUCTIONS ||
  'Đọc bằng tiếng Việt, giọng ấm áp, thân thiện, chậm rãi và vui tươi như đang kể chuyện cho trẻ 6-10 tuổi.';

// OpenAI TTS giới hạn 4096 ký tự input — cắt bớt cho an toàn.
const MAX_INPUT = 4000;

/**
 * Tổng hợp giọng đọc từ [text], trả về buffer MP3.
 * Ném lỗi nếu OpenAI trả mã != 2xx (để handler trả 502).
 */
export async function synthesizeSpeech(
  text: string,
  apiKey: string,
): Promise<Buffer> {
  const input = text.length > MAX_INPUT ? text.slice(0, MAX_INPUT) : text;

  const body: Record<string, unknown> = {
    model: TTS_MODEL,
    voice: TTS_VOICE,
    input,
    response_format: 'mp3',
  };
  // instructions chỉ áp dụng cho dòng gpt-4o-mini-tts.
  if (TTS_MODEL.includes('gpt-4o') && TTS_INSTRUCTIONS) {
    body.instructions = TTS_INSTRUCTIONS;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);
  try {
    const res = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const detail = await res.text();
      throw new Error(`openai speech ${res.status}: ${detail}`);
    }
    const arrayBuf = await res.arrayBuffer();
    return Buffer.from(arrayBuf);
  } finally {
    clearTimeout(timeout);
  }
}
