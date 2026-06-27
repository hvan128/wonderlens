/**
 * Gọi OpenAI Videos API (Sora): tạo job, hỏi trạng thái, tải nội dung MP4.
 * Dùng fetch (Node 18+/Vercel có sẵn) để khỏi thêm SDK.
 *
 * Bất đồng bộ: createVideo() chỉ KHỞI ĐỘNG job (vài giây), việc render mất
 * 30s–vài phút → app poll getVideoStatus() rồi mới tải fetchVideoContent().
 */

const API_BASE = 'https://api.openai.com/v1/videos';

// Cấu hình mặc định (đổi qua env mà không sửa code). sora-2 720p 8 giây.
export const VIDEO_MODEL = process.env.VIDEO_MODEL ?? 'sora-2';
export const VIDEO_SIZE = process.env.VIDEO_SIZE ?? '1280x720';
export const VIDEO_SECONDS = process.env.VIDEO_SECONDS ?? '8';

export interface VideoJob {
  id: string;
  status: string; // queued | in_progress | completed | failed | expired
  progress: number; // 0..100
  error: string | null;
}

/** Khởi động một job tạo video từ prompt. Trả id + status ban đầu (thường queued). */
export async function createVideo(
  prompt: string,
  apiKey: string,
): Promise<VideoJob> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);
  let res: Response;
  try {
    res = await fetch(API_BASE, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: VIDEO_MODEL,
        prompt,
        size: VIDEO_SIZE,
        seconds: VIDEO_SECONDS,
      }),
    });
  } finally {
    clearTimeout(timeout);
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenAI videos ${res.status}: ${text.slice(0, 200)}`);
  }
  return normalizeJob(await res.json());
}

/** Hỏi trạng thái + tiến độ của một job. */
export async function getVideoStatus(
  id: string,
  apiKey: string,
): Promise<VideoJob> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);
  let res: Response;
  try {
    res = await fetch(`${API_BASE}/${encodeURIComponent(id)}`, {
      method: 'GET',
      signal: controller.signal,
      headers: { Authorization: `Bearer ${apiKey}` },
    });
  } finally {
    clearTimeout(timeout);
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenAI videos status ${res.status}: ${text.slice(0, 200)}`);
  }
  return normalizeJob(await res.json());
}

/**
 * Tải nội dung của job đã 'completed'. Trả thẳng Response để caller stream/buffer.
 * variant: 'video' (MP4) hoặc 'thumbnail' (WebP).
 */
export async function fetchVideoContent(
  id: string,
  apiKey: string,
  variant: 'video' | 'thumbnail' = 'video',
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 60_000);
  let res: Response;
  try {
    res = await fetch(
      `${API_BASE}/${encodeURIComponent(id)}/content?variant=${variant}`,
      {
        method: 'GET',
        signal: controller.signal,
        headers: { Authorization: `Bearer ${apiKey}` },
      },
    );
  } finally {
    clearTimeout(timeout);
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(
      `OpenAI videos content ${res.status}: ${text.slice(0, 200)}`,
    );
  }
  return res;
}

/**
 * Lưới an toàn rẻ (~miễn phí, ~tức thì) trước khi tốn tiền gọi Sora: kiểm duyệt
 * text journey bằng omni-moderation. Trả true nếu BỊ gắn cờ.
 * Lỗi gọi API → trả false (fail-open) để không làm vỡ demo — Sora vẫn có
 * moderation riêng làm lớp chặn cuối.
 */
export async function isTextFlagged(
  text: string,
  apiKey: string,
): Promise<boolean> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15_000);
  try {
    const res = await fetch('https://api.openai.com/v1/moderations', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ model: 'omni-moderation-latest', input: text }),
    });
    if (!res.ok) return false;
    const data = (await res.json()) as { results?: { flagged?: boolean }[] };
    return data.results?.[0]?.flagged === true;
  } catch {
    return false;
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeJob(data: unknown): VideoJob {
  const d = (data ?? {}) as {
    id?: string;
    status?: string;
    progress?: number;
    error?: { message?: string } | string | null;
  };
  const err =
    typeof d.error === 'string' ? d.error : d.error?.message ?? null;
  return {
    id: d.id ?? '',
    status: d.status ?? 'failed',
    progress: typeof d.progress === 'number' ? d.progress : 0,
    error: err,
  };
}
