/**
 * Gọi OpenAI Images API sinh 1 ảnh minh hoạ từ prompt. Dùng fetch (Node 18+/
 * Vercel có sẵn) để khỏi thêm SDK. Trả base64 PNG (KHÔNG kèm tiền tố data:).
 *
 * Mặc định gpt-image-1 (luôn trả b64_json). Đổi sang dall-e-3 qua env nếu org
 * chưa verify gpt-image-1 — khi đó cần response_format để nhận b64.
 */

const API_URL = 'https://api.openai.com/v1/images/generations';

// Cấu hình mặc định (đổi qua env mà không sửa code).
export const IMAGE_MODEL = process.env.IMAGE_MODEL ?? 'gpt-image-1';
export const IMAGE_SIZE = process.env.IMAGE_SIZE ?? '1024x1024';
// gpt-image-1: low | medium | high | auto. dall-e-3 bỏ qua trường này.
export const IMAGE_QUALITY = process.env.IMAGE_QUALITY ?? 'low';

/** Sinh 1 ảnh từ prompt. Trả base64 PNG. Ném lỗi nếu API fail/timeout. */
export async function generateImage(
  prompt: string,
  apiKey: string,
): Promise<string> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 60_000);

  const body: Record<string, unknown> = {
    model: IMAGE_MODEL,
    prompt,
    size: IMAGE_SIZE,
    n: 1,
  };
  if (IMAGE_MODEL.startsWith('gpt-image')) {
    body.quality = IMAGE_QUALITY;
  } else {
    // dall-e-* mặc định trả url → ép b64 để proxy không lộ key qua redirect.
    body.response_format = 'b64_json';
  }

  let res: Response;
  try {
    res = await fetch(API_URL, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
    });
  } finally {
    clearTimeout(timeout);
  }

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenAI images ${res.status}: ${text.slice(0, 200)}`);
  }

  const data = (await res.json()) as {
    data?: { b64_json?: string }[];
  };
  const b64 = data.data?.[0]?.b64_json;
  if (!b64) throw new Error('OpenAI images: empty b64_json');
  return b64;
}
