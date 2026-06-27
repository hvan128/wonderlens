---
phase: 4
title: Collection & Badges
status: completed
priority: P2
dependencies:
  - 2
effort: D4
---

# Phase 4: Collection & Badges

## Overview
Lớp game giữ chân: sau mỗi khám phá → confetti + huy hiệu vật liệu; màn Bộ sưu tập (lưới vật đã quét) + cấp độ "Nhà Khoa Học Vật Liệu Nhí". Lưu local, không cần server.

## Requirements
- Functional: lưu vật đã khám phá + huy hiệu vật liệu (giấy, nhựa, kim loại…); confetti + âm thanh khi mở huy hiệu mới; màn Collection grid + thanh tiến độ cấp độ.
- Non-functional: bền qua restart (persist local); thao tác mượt, vui mắt.

## Architecture
- `CollectionRepository` trên Hive: lưu `discovered[]` (object_id, timestamp), `badges[]` (material).
- `BadgeService`: khi hoàn thành timeline → ghi nhận, tính huy hiệu mới → trigger confetti.
- `CollectionScreen`: grid card vật đã quét (mờ nếu chưa quét), huy hiệu, progress cấp độ.

## Related Code Files
- Create: `app/lib/data/collection_repository.dart`, `app/lib/services/badge_service.dart`
- Create: `app/lib/screens/collection_screen.dart`, `app/lib/widgets/{badge_chip,discovery_card,level_progress}.dart`
- Modify: `app/lib/main.dart` (init Hive), `app/lib/screens/timeline_screen.dart` (gọi BadgeService khi hoàn thành)

## Implementation Steps
1. Init Hive + box `collection`.
2. `CollectionRepository`: add discovery, list, query badge theo material.
3. `BadgeService`: map vật→material, phát hiện huy hiệu mới, tính cấp độ theo số vật/loại vật liệu.
4. Confetti (`confetti` pkg) + sound khi mở huy hiệu.
5. `CollectionScreen`: grid + huy hiệu + thanh tiến độ "X/10 → Nhà Khoa Học Vật Liệu Nhí".

## Success Criteria
- [ ] Hoàn thành timeline → confetti + huy hiệu vật liệu mới (nếu có).
- [ ] Bộ sưu tập hiển thị đúng vật đã quét + tiến độ cấp độ, bền qua restart.

## Risk Assessment
- Trùng huy hiệu/ghi nhận lặp → key theo object_id, idempotent.
- Hive init lỗi → fallback in-memory để demo không vỡ.
