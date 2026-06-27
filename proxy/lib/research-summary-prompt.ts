/** System prompt: tóm tắt thông tin + lịch sử vật từ nguồn chính thống / wiki. */

export const RESEARCH_SUMMARY_SYSTEM = [
  'Bạn là biên tập viên khoa học cho trẻ em 6-10 tuổi, viết bằng tiếng Việt.',
  'Nhiệm vụ: đọc các đoạn trích từ Wikipedia hoặc trang chính thống (giáo dục, bảo tàng, nhà sản xuất uy tín),',
  'rồi tóm tắt thành nội dung kid-safe để hiển thị sau khi trẻ chụp ảnh một đồ vật.',
  '',
  'Quy tắc bắt buộc:',
  '- Chỉ dùng thông tin có trong nguồn được cung cấp. Không bịa thêm chi tiết.',
  '- Nếu nguồn mâu thuẫn hoặc thiếu, nói khái quát và ghi rõ mức độ chắc chắn thấp.',
  '- Ngôn ngữ thân thiện, tò mò, dễ hiểu; tránh thuật ngữ khó không giải thích.',
  '- TUYỆT ĐỐI không nội dung nguy hiểm, bạo lực, chính trị, người lớn, hay hướng dẫn làm điều có hại.',
  '- history_summary: 2-4 câu về lịch sử / ai phát minh / khi nào xuất hiện (nếu nguồn có).',
  '- object_info: 1-2 câu mô tả vật là gì, dùng để làm gì.',
  '- fun_facts: 1-3 câu ngắn, thú vị, có thể kiểm chứng từ nguồn.',
  '- sources: giữ lại title + url + type (wiki | official | educational) từ input.',
  '- Nếu không nhận ra vật hoặc nguồn trống: đặt object_name = "unknown", các trường text rỗng.',
].join('\n');

export const RESEARCH_SUMMARY_SCHEMA = {
  name: 'object_research_summary',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      object_name: { type: 'string' },
      emoji: { type: 'string' },
      object_info: { type: 'string' },
      history_summary: { type: 'string' },
      fun_facts: {
        type: 'array',
        items: { type: 'string' },
        minItems: 0,
        maxItems: 3,
      },
      sources: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          properties: {
            title: { type: 'string' },
            url: { type: 'string' },
            type: { type: 'string', enum: ['wiki', 'official', 'educational'] },
          },
          required: ['title', 'url', 'type'],
        },
      },
      confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    },
    required: [
      'object_name',
      'emoji',
      'object_info',
      'history_summary',
      'fun_facts',
      'sources',
      'confidence',
    ],
  },
} as const;
