import { KID_SAFE_SYSTEM, JOURNEY_SCHEMA } from './kid-safe-prompt';

export interface JourneyStage {
  title: string;
  kid_text: string;
  fun_fact: string;
}

export interface Journey {
  id: string;
  name: string;
  emoji: string;
  material_badge: string;
  stages: JourneyStage[];
}

/**
 * Sinh "hành trình tạo ra vật" kid-safe từ ảnh bằng OpenAI Vision (gpt-4o).
 * Trả name = 'unknown' + stages rỗng nếu không phù hợp/không nhận ra.
 */
export async function generateJourney(
  imageBase64: string,
  apiKey: string,
): Promise<Journey> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);
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
        max_tokens: 800,
        temperature: 0.4,
        messages: [
          { role: 'system', content: KID_SAFE_SYSTEM },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'Hãy kể hành trình tạo ra đồ vật chính trong ảnh.',
              },
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
        response_format: { type: 'json_schema', json_schema: JOURNEY_SCHEMA },
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

  return JSON.parse(content) as Journey;
}
