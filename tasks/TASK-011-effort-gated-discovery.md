# TASK-011: Timeline xem đơn giản (bỏ cổng phức tạp)

**Owner:** Dev
**Status:** Updated 2026-07-05 — simplified timeline implemented
**Branch:** feature/TASK-011-effort-gated-discovery
**Ref:** [ADR-008](../adrs/ADR-008-effort-gated-discovery.md)

> Update 2026-07-05: user feedback supersedes the effort-gated flow. Timeline
> must be the simplest possible stage viewer: all stages visible immediately,
> easy to scan, image-first, no quiz/lock/experiment gate in the main flow.

## Current Goal

Đưa timeline về trải nghiệm xem chặng đơn giản nhất: bé mở màn là thấy toàn bộ
hành trình theo thứ tự, có ảnh + chữ ngắn + fun fact + nút nghe lại.

## Current Acceptance Criteria

- [ ] Toàn bộ stages render ngay; không có teaser khoá/chặng bí ẩn.
- [ ] Không render `predict`, `action`, `experiment` thành cổng chặn trong UI.
- [ ] Không còn nút "Chơi nhanh" vì màn chính đã là flow nhanh.
- [ ] Nút "Nghe câu chuyện" đọc toàn bộ hành trình; từng chặng vẫn có nút nghe lại.
- [ ] Ghi bộ sưu tập khi bé xem tới cuối hoặc khi nội dung ngắn không cần cuộn.
- [ ] Schema/model giữ `predict`, `action`, `experiment` để tương thích content cũ.

---

## Historical scope (superseded)

> **Phối hợp với TASK-010 (nhật ký AI):** dùng chữ ký mới
> `CollectionRepository.record(ObjectContent)` của TASK-010. Contract hợp nhất:
> hoàn thành guided/quick → hero vào `discovered`, vật live vào `journal`
> (live chạy thẳng chế độ quick).

**Đã xong:**
- Model: `StagePredict` / `StageAction` / `HomeExperiment` (parse an toàn, optional)
- Widgets: `stage_predict.dart`, `stage_action.dart`, `home_experiment.dart`
- Content: đủ 8 hero JSON (3 predict + 4 action + 1 experiment mỗi vật)
- Timeline rework: hé lộ dần + cổng công sức + phần thưởng dời sang hoàn thành
  + nút "Khám phá nhanh" + thanh tiến trình + quick-complete khi cuộn hết
- Test: `effort_content_test.dart` (10 case) + `timeline_test.dart` (3 case guided/quick)
- Icon shim: bổ sung 7 icon vào `phosphor_compat.dart`; không dùng emoji làm icon UI

## Goal

Biến timeline từ **xem thụ động** thành **bé tự tay khám phá**. Phần thưởng (ghi
bộ sưu tập + confetti + badge + thẻ) chỉ mở SAU khi bé hoàn thành hành trình có
công sức. Ba lớp công sức, tất cả offline:

1. **Đoán trước mỗi chặng** — chọn đúng mới lộ chặng kế.
2. **Chạm để vận hành** — mỗi chặng có 1 hành động chủ đề để "thực hiện" phép biến đổi.
3. **Thí nghiệm mini thật** — cuối hành trình, làm 1 việc với vật thật → badge phụ.

Giữ nút **"Khám phá nhanh"** (chế độ `quick`) cho demo 90s / giám khảo.

## Scope

- Sửa: `app/lib/screens/timeline_screen.dart`, `app/lib/models/object_content.dart`,
  `app/lib/data/collection_repository.dart` (nếu cần tách điểm ghi nhận).
- Thêm widget: `app/lib/widgets/stage_predict.dart`, `app/lib/widgets/stage_action.dart`,
  `app/lib/widgets/home_experiment.dart` (tên gợi ý).
- Nội dung: 8 hero JSON trong `app/assets/content/` điền `predict`/`action`/`experiment`.
- Docs: `specs/api-contracts.md` (schema), `specs/features.md` (F-09).
- KHÔNG đụng proxy. KHÔNG thêm dependency mới.

## Data schema (optional, backward-compatible)

Thêm vào `Stage` (áp dụng cho chặng cần đoán/để vận hành):

```json
"predict": {
  "question": "Dầu mỏ sẽ biến thành gì tiếp theo?",
  "options": ["Hạt nhựa nhỏ xíu", "Nước ngọt", "Cục đá"],
  "answer_index": 0,
  "hint": "Nghĩ xem vỏ bút cứng làm bằng gì nhỉ?"
},
"action": {
  "type": "hold",
  "label": "Nhấn giữ để nung chảy hạt nhựa"
}
```

Thêm vào `ObjectContent` (cấp vật):

```json
"experiment": {
  "title": "Thử nghiệm nhỏ tại nhà",
  "prompt": "Viết vài chữ rồi lật ngửa bút viết tiếp — viên bi có còn ra mực không?",
  "reveal": "Viên bi lăn được mọi hướng nên viết ngược vẫn ra mực một chút đấy!",
  "badge": "Nhà khoa học nhí"
}
```

Quy ước:
- `predict` của chặng `i` là câu hỏi hiện **trước khi lộ chặng `i`**. Chặng 0 luôn
  hiện sẵn (không có `predict`).
- `action.type` ∈ `hold | swipe | tap | drag`. Thiếu `action` → nút "Tiếp tục" mặc định.
- `answer_index` phải hợp lệ trong `options`; parse lỗi/thiếu → chặng đó bỏ qua bước
  đoán, lộ thẳng (không crash).
- Thiếu `experiment` → bỏ qua bước thí nghiệm, không có badge phụ.

## Flow (chế độ guided — mặc định)

```
Mở trang → chặng 0 hiện + đọc chặng 0
  → [action chặng 0] "chạm để vận hành"
  → [predict chặng 1] đoán đúng → lộ chặng 1 + đọc
  → [action chặng 1] → [predict chặng 2] → ... hết chặng
  → [experiment] "làm xong chưa?" → xác nhận
  → GHI bộ sưu tập + confetti + badge + badge phụ + phim hành trình
```

Thanh tiến trình "Con đã mở n/N chặng" bé tự lấp.

## Acceptance Criteria

- [ ] `TimelineScreen` KHÔNG còn `record()` trong `initState()`; ghi nhận chuyển sang
      sự kiện hoàn thành hành trình (guided: xong experiment/hết chặng; quick: cuộn hết).
- [ ] Chặng hé lộ dần ở chế độ `guided`; mỗi chặng ≥ 1 (index ≥ 1) có bước đoán khi
      content có `predict`.
- [ ] Đoán sai → gợi ý (`hint`) + cho chọn lại, không phạt, không chặn cứng.
- [ ] Mỗi chặng có `action` → yêu cầu thao tác (nhấn giữ/vuốt/kéo) + micro-animation
      trước khi sang bước kế; thiếu `action` → nút "Tiếp tục".
- [ ] Cuối hành trình có `experiment` → hiện card + nút xác nhận → badge phụ hiện.
- [ ] Confetti + badge + ghi bộ sưu tập chỉ chạy MỘT lần khi hoàn thành (không double).
- [ ] Nút "Khám phá nhanh" chuyển sang `quick`: hiện toàn bộ như hành vi cũ, vẫn ghi
      bộ sưu tập khi cuộn hết.
- [ ] Chỉ hero (`source: asset`) được ghi bộ sưu tập; vật `live` chạy thẳng `quick`.
- [ ] Content thiếu field mới → fallback hành vi cũ, không crash (mọi field optional).
- [ ] Narration guided: đọc theo từng chặng khi lộ; nút "Nghe kể chuyện" vẫn đọc cả chuyện.
- [ ] 8 hero JSON có `predict` (chặng ≥ 1) + `experiment`; `action` ít nhất cho hero
      có bước biến đổi rõ.

## DoD

- [ ] `flutter analyze` sạch
- [ ] `flutter test` pass; thêm test: parse `predict`/`action`/`experiment`; logic
      "ghi bộ sưu tập chỉ khi hoàn thành"; đoán sai không mở chặng.
- [ ] Build release chạy trên máy thật, demo 90s (chế độ quick) không lỗi
- [ ] `specs/api-contracts.md` + `specs/features.md` + ADR-008 cập nhật
- [ ] PR reviewed & merged

## Risks & notes

- **Tension demo:** guided làm chậm time-to-wow → mitigation là nút "Khám phá nhanh".
  Trong demo dùng quick; bản thật mặc định guided.
- **Nội dung `predict` cho trẻ:** phương án sai phải "sai một cách hợp lý, vui" —
  không đánh đố, không gây hiểu nhầm khoa học. Cùng chuẩn kiểm chứng F-02.
- **Experiment an toàn:** chỉ đề xuất việc an toàn tuyệt đối cho trẻ 6–10 (không lửa,
  không vật sắc, không nuốt). Review nội dung trước khi ship.
- Pre-existing: `test/share_test.dart` đang fail sẵn trên HEAD (ngoài phạm vi task này).
