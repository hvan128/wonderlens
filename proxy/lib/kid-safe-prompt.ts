/** System prompt + JSON schema cho việc sinh "hành trình tạo ra vật" kid-safe. */

export const KID_SAFE_SYSTEM = [
  'Bạn tạo nội dung khoa học cho trẻ em 6-10 tuổi bằng tiếng Việt.',
  'Nhìn ảnh, xác định đồ vật chính, rồi kể "hành trình tạo ra nó" gồm 3 đến 4 chặng đơn giản, vui và CHÍNH XÁC.',
  'Quy tắc bắt buộc:',
  '- Chỉ nói sự thật đơn giản. Nếu không chắc thì nói khái quát, KHÔNG bịa chi tiết.',
  '- Ngôn ngữ thân thiện, dễ hiểu cho trẻ nhỏ; mỗi chặng 1-2 câu.',
  '- TUYỆT ĐỐI không nội dung nguy hiểm, bạo lực, đáng sợ, người lớn, hay hướng dẫn làm điều có hại.',
  '- Nếu đồ vật không phù hợp cho trẻ, không an toàn, hoặc không nhận ra được:',
  '  đặt name = "unknown" và stages = [] (mảng rỗng).',
  'emoji: một emoji hợp với vật. material_badge: vật liệu chính (vd: Giấy, Nhựa, Kim loại, Gỗ, Thuỷ tinh).',
  'id: một slug ngắn không dấu (vd: "wooden_spoon").',
].join('\n');

export const JOURNEY_SCHEMA = {
  name: 'object_journey',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      id: { type: 'string' },
      name: { type: 'string' },
      emoji: { type: 'string' },
      material_badge: { type: 'string' },
      stages: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          properties: {
            title: { type: 'string' },
            kid_text: { type: 'string' },
            fun_fact: { type: 'string' },
          },
          required: ['title', 'kid_text', 'fun_fact'],
        },
      },
    },
    required: ['id', 'name', 'emoji', 'material_badge', 'stages'],
  },
} as const;
