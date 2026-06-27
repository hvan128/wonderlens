// Nội dung "Hành trình tạo ra Cốc giấy" — port từ app/assets/content/paper_cup.json.
import { COLORS } from './theme';

export type StageIcon = 'tree' | 'pulp' | 'sheet' | 'cup';

export type Stage = {
  title: string;
  icon: StageIcon;
  accent: string;
  image?: string; // ảnh minh hoạ AI (staticFile path) — fallback về icon nếu thiếu
};

export const OBJECT_NAME = 'Cốc giấy';
export const MATERIAL_BADGE = 'Giấy';
export const CONFIDENCE = '98%';

// Trạng thái màn hình "lens": chụp xong -> AI phân tích -> ra kết quả.
export const CAPTURED_LABEL = 'Đã chụp';
export const ANALYZING_LABEL = 'Đang phân tích…';

// Thông tin cơ bản ngắn hiện trong popup khi nhận ra vật — ưu tiên nguồn gốc/giá trị, hợp trẻ nhỏ.
export const OBJECT_MADE_FROM = 'Làm từ gỗ cây';
export const OBJECT_FACT_EYEBROW = 'Bạn có biết?';
export const OBJECT_FACT = 'Năm 1907, cốc giấy ra đời để ai cũng có cốc sạch riêng!';

export const CUP_STAGES: Stage[] = [
  { title: 'Bắt đầu từ cái cây', icon: 'tree', accent: COLORS.tree, image: 'stages/paper_cup_stage0.png' },
  { title: 'Nấu gỗ thành bột giấy', icon: 'pulp', accent: COLORS.pulp, image: 'stages/paper_cup_stage1.png' },
  { title: 'Cán thành tấm giấy', icon: 'sheet', accent: COLORS.pulpDark, image: 'stages/paper_cup_stage2.png' },
  { title: 'Cuộn thành cốc, tráng chống nước', icon: 'cup', accent: COLORS.cupBand, image: 'stages/paper_cup_stage3.png' },
];
