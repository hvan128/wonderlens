# Plan: Nhật ký khám phá — lưu vật AI-live vào bộ sưu tập

**Status:** Implemented & Verified (23/23 test pass; analyze sạch trong scope)
**Task:** [TASK-010](../../tasks/TASK-010-discovery-journal.md)

## Bối cảnh

- `CollectionRepository.record()` chặn mọi id ngoài 8 hero (`collection_repository.dart:43-45`)
  — đúng spec cũ (`features.md:95`, `domains.md:101`, lý do kid-safety: AI content chưa red-team).
- User quyết định thiết kế lại: 8 vật quá ít, vật bé chụp phải được lưu.
- Phương án chốt: **hai tầng** — hero giữ nguyên gamification (level/huy hiệu);
  vật AI-live vào khu "Khám phá thêm (AI)" riêng, gắn nhãn, không tính level/huy hiệu.

## Thiết kế

Storage (Hive box `wonderlens_collection` hiện có, không dependency mới):

- Key `discovered` (List<String> hero ids) — GIỮ NGUYÊN, tương thích data cũ.
- Key mới `journal`: List<String>, mỗi phần tử là JSON string
  `{id, name, emoji, discovered_at, content}` — `content` là `ObjectContent.toJson()`
  đầy đủ để mở lại timeline offline. Mới nhất đứng đầu. Dedup theo `id`.
- Chỉ vật NON-hero vào journal (hero đã có lưới 8 ô — tránh hiển thị trùng).

Luồng ghi: `TimelineScreen.initState` → `record(content)` (đổi chữ ký từ `record(String id)`;
1 call site duy nhất). Hero → nhánh cũ. Non-hero → upsert journal, `isNewObject` điều khiển
confetti, `newBadge` luôn null.

Luồng đọc: `CollectionScreen` thêm section "Khám phá thêm (AI)" (ẩn khi rỗng);
mỗi ô = `ObjectAvatar` (ảnh cutout thật từ `CaptureStore`, fallback emoji) + tên + chip AI.
Tap → `ObjectContent.fromJson(entry.content, source: 'live')` → push `/timeline`.
Ảnh chặng AI đã cache theo `content.id` (`journey_image_service.dart:48`) → mở lại không tốn proxy.

## Phases

1. **Model:** `Stage.toJson()` + `ObjectContent.toJson()` (`app/lib/models/object_content.dart`)
2. **Data:** `JournalEntry` + journal read/write trong `CollectionRepository`;
   `record(ObjectContent)` (`app/lib/data/collection_repository.dart`)
3. **UI:** `timeline_screen.dart:46` đổi call; `collection_screen.dart` thêm section + subtitle
4. **Specs:** `features.md` (F-04/F-05), `domains.md` (D2/D3 rules), `api-contracts.md` (local schema)
5. **Verify:** test journal (round-trip + dedup + hero không vào journal), `flutter analyze`, `flutter test`

## Rủi ro / Rollback

- Data cũ không cần migration (key `journal` mới, `discovered` không đổi schema).
- Kid-safety: nội dung AI thành bền — chấp nhận có nhãn AI + không vào gamification chính;
  blocker red-team trước deploy thật (features.md:118-119) VẪN GIỮ NGUYÊN.
- Rollback: bỏ section UI + bỏ nhánh non-hero trong `record` — key `journal` thừa vô hại.
