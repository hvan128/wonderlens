import { HERO_IDS, displayNameOf } from './hero-objects';

export interface VisionResult {
  object_id: string;
  confidence: number;
  display_name: string;
}

const SYSTEM_PROMPT = [
  'Bạn là trợ lý nhận diện đồ vật văn phòng cho một app khám phá khoa học cho trẻ em.',
  'Nhìn ảnh và phân loại ĐỒ VẬT CHÍNH vào đúng một id trong danh sách cho sẵn.',
  'Nếu không chắc, hoặc đồ vật không thuộc danh sách, trả object_id = "unknown".',
  'confidence là mức độ chắc chắn từ 0 đến 1.',
  'display_name là tên tiếng Việt ngắn gọn của vật.',
].join(' ');

/**
 * Gọi OpenAI Vision (gpt-4o) với structured output ép phân loại vào HERO_IDS.
 * Dùng fetch (Node 18+/Vercel có sẵn) để khỏi thêm SDK.
 */
export async function recognizeWithOpenAI(
  imageBase64: string,
  apiKey: string,
): Promise<VisionResult> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);
  let res: Response;
  try {
    res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
      model: 'gpt-4o',
      max_tokens: 200,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Đồ vật chính trong ảnh này là gì?' },
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
                detail: 'low',
              },
            },
          ],
        },
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'object_recognition',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            properties: {
              object_id: { type: 'string', enum: [...HERO_IDS, 'unknown'] },
              confidence: { type: 'number' },
              display_name: { type: 'string' },
            },
            required: ['object_id', 'confidence', 'display_name'],
          },
        },
      },
    }),
    });
  } finally {
    clearTimeout(timeout);
  }

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenAI ${res.status}: ${text.slice(0, 200)}`);
  }

  const data = (await res.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('OpenAI: empty content');

  const parsed = JSON.parse(content) as VisionResult;
  // Clamp confidence về [0,1] phòng khi model trả giá trị ngoài khoảng.
  parsed.confidence = Math.max(0, Math.min(1, parsed.confidence ?? 0));
  // Chuẩn hoá display_name theo danh sách hero khi nhận ra vật hero.
  if (parsed.object_id !== 'unknown') {
    parsed.display_name = displayNameOf(parsed.object_id);
  }
  return parsed;
}
