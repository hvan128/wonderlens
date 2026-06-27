// Nội dung "Hành trình tạo ra Cốc giấy" — port từ app/assets/content/paper_cup.json.
import { COLORS } from './theme';

export type StageIcon = 'tree' | 'pulp' | 'sheet' | 'cup';

export type Stage = {
  title: string;
  icon: StageIcon;
  accent: string;
};

export const OBJECT_NAME = 'Cốc giấy';
export const MATERIAL_BADGE = 'Giấy';
export const CONFIDENCE = '98%';

export const CUP_STAGES: Stage[] = [
  { title: 'Bắt đầu từ cái cây', icon: 'tree', accent: COLORS.tree },
  { title: 'Nấu gỗ thành bột giấy', icon: 'pulp', accent: COLORS.pulp },
  { title: 'Cán thành tấm giấy', icon: 'sheet', accent: COLORS.pulpDark },
  { title: 'Cuộn thành cốc, tráng chống nước', icon: 'cup', accent: COLORS.cupBand },
];
