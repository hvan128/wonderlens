# ADR-008: Khám phá phải "kiếm được" — cổng phần thưởng bằng công sức của bé

**Status:** Accepted
**Date:** 2026-07-01 (accepted 2026-07-02)

## Context

Luồng timeline hiện tại cho phần thưởng **miễn phí**: `TimelineScreen.initState()`
tự `record()` vào bộ sưu tập + confetti + mở badge ngay khi mở trang, đồng thời tự
đọc cả câu chuyện và dựng phim ngầm. Bé chỉ cần chụp là "xong" — trải nghiệm thụ
động, học nông, badge mất giá trị vì không gắn với nỗ lực nào.

Mục tiêu giáo dục cần bé **chủ động tham gia** vào chính quá trình khám phá: dự
đoán, tự "vận hành" từng chặng, và làm một việc ở thế giới thật. Nhưng vẫn phải
giữ nguyên tắc **time-to-wow < 5s** cho demo (PRD §3).

## Decision

**Phần thưởng (ghi bộ sưu tập + confetti + badge + thẻ) chỉ kích hoạt SAU khi bé
hoàn thành hành trình có công sức**, không còn tự chạy trong `initState()`.

Ba lớp công sức, tất cả **offline**, dữ liệu là **optional** (thiếu → rớt về hành
vi cũ, không crash):

1. **Đoán trước mỗi chặng** — trước khi lộ chặng `i` (i ≥ 1), hỏi bé chọn 1 trong
   2–3 phương án. Chọn đúng → lộ chặng; chọn sai → gợi ý, cho chọn lại (không phạt).
2. **Chạm để vận hành** — mỗi chặng có một hành động chủ đề (nhấn giữ/vuốt/kéo) để
   "thực hiện" phép biến đổi của chặng đó rồi mới sang bước kế. Thiếu `action` →
   dùng nút "Tiếp tục" mặc định.
3. **Thí nghiệm mini thật** — cuối hành trình, đố bé làm một việc an toàn với vật
   thật → bé xác nhận đã làm → badge phụ "Nhà khoa học nhí".

**Hai chế độ** để không phá demo:
- `guided` (mặc định): đầy đủ công sức, chặng hé lộ dần, phần thưởng kiếm được.
- `quick` (nút "Khám phá nhanh"): hiện toàn bộ như hiện tại — dùng cho demo 90s /
  giám khảo. `quick` vẫn ghi bộ sưu tập khi bé cuộn hết.

Ghi bộ sưu tập vẫn **chỉ áp dụng hero** (vật `source: live` không lưu — giữ ADR cũ).

## Reasons

- Badge/thẻ có giá trị khi gắn với nỗ lực → động lực quay lại mạnh hơn.
- Dự đoán trước khi lộ đáp án là kỹ thuật sư phạm hiệu quả (tăng ghi nhớ), rẻ để
  cài (chỉ thêm dữ liệu lựa chọn cho mỗi chặng).
- Thí nghiệm thật kéo bé rời màn hình, chạm vật thật → khác biệt không app "video
  giáo dục thụ động" nào sao chép bằng ảnh stock.
- Chế độ `quick` bảo toàn nguyên tắc demo < 5s của PRD.

## Consequences

- **Đổi contract:** không còn `record-on-open`. Việc ghi bộ sưu tập chuyển sang sự
  kiện "hoàn thành hành trình" → cập nhật `specs/api-contracts.md` (CollectedObject
  flow) và test liên quan.
- `Stage` thêm field optional `predict`, `action`; `ObjectContent` thêm `experiment`.
  Tất cả optional, backward-compatible — 8 hero JSON điền dần, thiếu thì fallback.
- Cần soạn + kiểm chứng nội dung `predict`/`experiment` cho 8 hero (nội dung trẻ em,
  khoa học đúng — cùng chuẩn F-02).
- Narration đổi: chế độ `guided` đọc **theo từng chặng khi lộ** thay vì đọc cả
  chuyện lúc mở; nút "Nghe kể chuyện" giữ nguyên.
- AI-live: chưa có `predict`/`experiment` sinh runtime ở v1 → vật lạ chạy thẳng
  chế độ `quick` (giữ đơn giản, tránh phụ thuộc thêm proxy).

## Amendment (2026-07-04): một cổng mỗi chặng

Chạy thử thực tế cho thấy lớp "chạm để vận hành" **phản tác dụng** khi đi kèm
cổng dự đoán: mỗi chặng cần 2 tương tác (gesture + đố) × 4 chặng + thí nghiệm
= 8 bước trước phần thưởng đầu tiên. Gesture thuần cơ học không dạy gì nhưng
chặn nội dung; hành trình thành chuỗi việc vặt, còn "Chơi nhanh" cho mọi thứ
chỉ bằng cuộn → lối thoát hấp dẫn hơn lối chính. Trang cũng nhìn "trống" vì
chặng khoá vô hình và chặng mới lộ dưới mép màn hình không tự cuộn tới.

Điều chỉnh (giữ nguyên mục tiêu "phần thưởng kiếm được"):

- **Một cổng mỗi chặng:** câu đố dự đoán là cổng duy nhất giữa các chặng
  (đóng khung "Giải đố để mở chặng tiếp"); thiếu `predict` → nút "Mở chặng
  tiếp". Lớp "vận hành" (mục 2 ở Decision) bị bỏ khỏi UI; field `action` giữ
  trong schema + content (optional, không render) để khỏi sửa 8 hero JSON.
- Hết chặng: có `experiment` → thẻ thí nghiệm hiện ngay; không có → nút
  "Hoàn thành nhiệm vụ".
- Chặng chưa mở hiện **teaser khoá** (số thứ tự + ổ khoá, giấu tựa đề vì tựa
  có thể là đáp án câu đố) — bé thấy hành trình còn bao xa.
- Lộ chặng mới **tự cuộn tới** chặng đó.
- Nút "Nghe câu chuyện" ở guided chỉ đọc **phần đã lộ** — đọc cả chuyện sẽ
  spoil đáp án các câu đố phía sau.

## Amendment (2026-07-05): timeline xem đơn giản

Phản hồi mới: bỏ hết các bước phức tạp để các chặng đơn giản, dễ xem và trực
quan hơn. Cổng quiz, teaser khoá, thẻ thí nghiệm bắt buộc, thanh tiến trình mở
chặng và nút "Chơi nhanh" đều làm timeline giống nhiệm vụ nhiều bước thay vì
một câu chuyện khoa học ngắn.

Điều chỉnh:

- Timeline mặc định hiển thị **toàn bộ chặng ngay** theo thứ tự, với ảnh, tiêu
  đề, `kid_text`, `fun_fact` và nút nghe lại từng chặng.
- `predict`, `action`, `experiment` vẫn nằm trong schema/model để tương thích
  content đã soạn, nhưng UI không render chúng thành cổng chặn.
- Nút "Nghe câu chuyện" đọc toàn bộ hành trình vì không còn nội dung bị spoil.
- Phần thưởng vẫn không chạy trước khi trẻ thấy nội dung; app ghi nhận khi trẻ
  cuộn tới cuối, hoặc tự ghi nhận nếu nội dung quá ngắn không cần cuộn.
