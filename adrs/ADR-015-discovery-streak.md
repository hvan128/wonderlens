# ADR-015: Chuỗi ngày khám phá (daily streak) — lưu local, nhẹ nhàng

**Status:** Accepted
**Date:** 2026-07-01
**Liên quan:** `specs/features.md` (F-18), `specs/domains.md` (Domain 3), ADR-005 (Hive), ADR-011

## Context

Bộ sưu tập + huy hiệu tạo động lực khám phá, nhưng chưa có lý do **quay lại mỗi ngày**.
Brainstorm (`wonderlens-ui-brainstorm.html`, D2) đề xuất "chuỗi ngày khám phá" — streak
nhẹ: chỉ cần khám phá ≥1 vật/ngày để giữ ngọn lửa. Đây là feature **mới hoàn toàn**
(không có trên `integration/truc-c-d`), cần một mô hình lưu trạng thái theo ngày.

Yêu cầu: đơn giản, offline, **không áp lực** (không phạt khi đứt chuỗi), không cấp huy
hiệu (quyết định sản phẩm — giữ nguyên logic badge/level của ADR-011), không cần backend.

## Decision

Thêm **`StreakRepository`** lưu ở Hive box riêng **`wonderlens_streak`** (key-value đơn
giản, KHÔNG TypeAdapter/build_runner — nhất quán ADR-005 + DoD game):
- `last_day`: `yyyy-mm-dd` của lần khám phá gần nhất (lịch địa phương).
- `streak_count`: số ngày liên tiếp hiện tại.
- `best_streak`: chuỗi dài nhất từng đạt.

Luật (hàm **thuần** `computeUpdate`, không đọc Hive / không `DateTime.now()` → test tất định):
- Cùng ngày → giữ nguyên (đã tính hôm nay).
- Ngày liền kề hôm qua → +1.
- Đứt quãng / lần đầu → khởi động lại về **1** (không về 0, không phạt).

**Điểm ghi nhận:** gọi `recordVisit()` khi mở **hành trình một vật** (Timeline `initState`) —
đúng một hành động "khám phá". Khi chuỗi vừa sang ngày mới (`advancedToday` && `current ≥ 2`)
→ hiện màn chúc mừng "Chuỗi N ngày! 🔥" (dialog tắt được ngay, tối đa 1 lần/ngày). Bộ sưu
tập hiện chip "🔥 N ngày" ở thẻ cấp độ.

## Reasons

- **Tách biệt** khỏi collection/badge/level: streak không đụng `CollectionRepository`,
  không ảnh hưởng cấp độ hay huy hiệu (ADR-011 giữ nguyên) — rủi ro hồi quy tối thiểu.
- **Box riêng** `wonderlens_streak` → single-responsibility, không lẫn với
  `wonderlens_progress` (nhiệm vụ) hay `wonderlens_collection`.
- **Logic thuần** tách khỏi widget (AGENTS.md) và khỏi Hive → dễ test các ca ngày
  (liền kề, đứt quãng, qua tháng).

## Consequences

- Không cần dependency mới (Hive đã duyệt — ADR-005).
- `main.dart` thêm `StreakRepository.init()` (sau khi Hive init bởi `CollectionRepository`).
- Streak dựa lịch **thiết bị** → đổi giờ hệ thống có thể ảnh hưởng; chấp nhận được cho
  trải nghiệm trẻ em, không có cơ chế chống gian lận (không cần).
- Mở đường (không bắt buộc) cho nhắc nhở/thông báo sau này; hiện chỉ hiển thị + ăn mừng.
