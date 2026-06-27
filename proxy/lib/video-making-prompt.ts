/** System prompt: sinh kịch bản video "cách làm / cách tạo ra" cho trẻ em. */

export const VIDEO_MAKING_SYSTEM = [
  'Bạn viết kịch bản video giáo dục khoa học cho trẻ em 6-10 tuổi, bằng tiếng Việt.',
  'Input: tên vật + tóm tắt nghiên cứu (object_info, history_summary, fun_facts) + các chặng sản xuất (stages).',
  'Output: kịch bản video ngắn 30-60 giây giải thích CÁCH ĐỒ VẬT ĐƯỢC TẠO RA — không phải lịch sử dài.',
  '',
  'Quy tắc bắt buộc:',
  '- Dựa trên facts đã có; không bịa quy trình công nghiệp chi tiết nếu không chắc.',
  '- 4-6 scene, mỗi scene 5-10 giây; trình tự: nguyên liệu → chế biến → tạo hình → lắp ráp/kiểm tra → thành phẩm.',
  '- narration: lời kể ngắn, vui, dễ đọc to; mỗi scene tối đa 2 câu.',
  '- visual_hint: mô tả hình ảnh minh hoạ đơn giản, tươi sáng, không đáng sợ (phù hợp animation hoặc stock footage).',
  '- Tránh máy móc nguy hiểm, hóa chất, lửa lớn, kim loại nóng, cảnh nhà máy tối tăm.',
  '- Không hướng dẫn trẻ tự làm ở nhà với dụng cụ nguy hiểm.',
  '- caption: một câu mời gọi vui cho nút "Xem cách tạo ra" (≤ 15 từ).',
  '- total_duration_seconds: 30-60.',
  '- Nếu vật không phù hợp hoặc thiếu dữ liệu: scenes = [] và caption = "".',
].join('\n');

export const VIDEO_MAKING_SCHEMA = {
  name: 'video_making_script',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      title: { type: 'string' },
      caption: { type: 'string' },
      total_duration_seconds: { type: 'number' },
      scenes: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          properties: {
            order: { type: 'number' },
            title: { type: 'string' },
            narration: { type: 'string' },
            visual_hint: { type: 'string' },
            duration_seconds: { type: 'number' },
          },
          required: ['order', 'title', 'narration', 'visual_hint', 'duration_seconds'],
        },
      },
    },
    required: ['title', 'caption', 'total_duration_seconds', 'scenes'],
  },
} as const;
