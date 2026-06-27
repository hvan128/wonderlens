---
phase: 6
title: Polish & Demo
status: completed
priority: P2
dependencies:
  - 3
  - 4
  - 5
effort: D6-D7
---

# Phase 6: Polish & Demo

## Overview
Đánh bóng wow + đảm bảo demo không vỡ: animation chuyển chặng, haptics, onboarding mascot, đóng gói offline cho hero, tập demo + lưới an toàn + clip dự phòng.

## Requirements
- Functional: transition mượt giữa chặng (Rive/Lottie), confetti/sound polish, onboarding ngắn (<10s), nút "demo mode" dùng vật hero offline.
- Non-functional: demo 90s chạy trọn vẹn **không cần wifi** cho hero; có clip quay sẵn dự phòng.

## Architecture
- Lớp animation tách khỏi logic; "demo mode" ép dùng asset hero (bỏ qua network).
- Kiểm tra bundle: mọi asset hero (JSON + tranh + audio) nằm trong app, chạy offline.

## Related Code Files
- Modify: `app/lib/screens/timeline_screen.dart`, `app/lib/widgets/stage_card.dart` (animation/transition)
- Modify: `app/lib/screens/camera_screen.dart` (mascot hint, haptics), `app/lib/main.dart` (demo mode flag)
- Create: `app/assets/animations/*.riv|*.json`, `docs/demo-script.md`, clip dự phòng (quay màn hình)

## Implementation Steps
1. Thêm transition + micro-animation (Rive/Lottie) cho chặng + mở huy hiệu.
2. Haptics + sound design nhẹ; onboarding mascot ngắn gọn.
3. "Demo mode": toggle ép hero offline (an toàn khi mạng kém).
4. Kiểm thử offline toàn bộ 8 hero (tắt wifi).
5. Viết `docs/demo-script.md` (kịch bản 90s) + tập diễn; quay clip dự phòng.
6. Lưới an toàn: confidence thấp → chọn lại; lỗi mạng (live) → fallback gợi ý vật hero.

## Success Criteria
- [ ] Demo 90s chạy mượt offline cho hero (cốc giấy → bút bi do giám khảo cầm).
- [ ] Có clip dự phòng + demo mode hoạt động khi tắt mạng.
- [ ] Onboarding <10s, animation/haptics tạo cảm giác "sản phẩm thật".

## Risk Assessment
- Mạng sân khấu chập chờn → demo mode + clip dự phòng là bắt buộc.
- Animation làm tụt FPS máy yếu → giữ nhẹ, test trên thiết bị demo thật.
- Hết thời gian → ưu tiên offline reliability > số lượng animation.
