# Thiết kế copy an tâm cho phụ huynh

## Mục tiêu

Viết lại phần guardrails của landing bằng tiếng Việt ấm áp, ngắn và hữu ích cho
phụ huynh. Trang public nói rõ WonderLens đang bảo vệ trải nghiệm thế nào và
người lớn nên đồng hành ra sao, thay vì hiển thị thuật ngữ audit nội bộ.

## Quyết định

Chọn hướng “an tâm có căn cứ”:

- Nói lợi ích trước: nội dung phù hợp trẻ 6–10, có lớp kiểm tra an toàn, AI luôn
  có nhãn, người lớn đồng hành.
- Dùng từ quen thuộc: `nội dung do AI hỗ trợ`, `dịch vụ AI`, `theo dõi hành vi`.
- Giữ minh bạch cần thiết: AI có thể nhầm; ảnh được gửi tới dịch vụ AI để nhận
  diện; WonderLens không thay giáo viên hoặc sách đã kiểm chứng.
- Không hiển thị jargon nội bộ: `runtime`, `kid-safety audit`, `safety pass`,
  `prompt`, `moderation`, `proxy`, `tracking`, `cookie`, `analytics`, `AI-live`.
- Không tuyên bố WonderLens đã được chứng nhận, kiểm định hoặc bảo đảm an toàn
  tuyệt đối. Trạng thái F-08 vẫn được theo dõi trong PRD/release docs.

## Copy public

Điều hướng:

- `An tâm khám phá` → giữ anchor `#rao-chan`.

Section:

- Eyebrow: `Để bố mẹ an tâm`
- Tiêu đề: `Cùng con khám phá, với những lớp bảo vệ rõ ràng.`
- Mô tả: `WonderLens ưu tiên những câu chuyện ngắn, phù hợp lứa tuổi và giúp bố mẹ biết khi nào AI tham gia.`

Điểm nhấn:

- Nhãn: `Các lớp kiểm tra an toàn`
- Nội dung chính:
  `Có các lớp kiểm tra an toàn. Đồ vật quen thuộc dùng câu chuyện đã tuyển chọn; nội dung do AI hỗ trợ được giới hạn theo lứa tuổi và luôn có nhãn rõ ràng.`
- Nội dung phụ:
  `AI đôi khi có thể nhầm. Bố mẹ hoặc giáo viên hãy cùng trẻ xem, đặt câu hỏi và kiểm tra lại khi cần.`

Bốn cam kết:

1. `Bố mẹ cùng con khám phá` — hoạt động đồng sử dụng cho người lớn và trẻ
   6–10 tuổi.
2. `Nội dung phù hợp lứa tuổi` — câu chuyện ngắn, gần gũi; nội dung nguy hiểm,
   bạo lực hoặc không phù hợp nằm ngoài giới hạn trải nghiệm.
3. `Biết rõ khi AI tham gia` — nội dung AI có nhãn, có thể nhầm, không thay thế
   giáo viên hoặc sách đã kiểm chứng.
4. `Riêng tư được nói rõ` — không tài khoản trẻ, quảng cáo hay theo dõi hành vi;
   ảnh được gửi tới dịch vụ AI để nhận diện; ảnh tách nền và bộ sưu tập có thể
   lưu trên thiết bị.

Footer đổi từ trạng thái phát hành nội bộ sang một câu định vị dành cho phụ
huynh và giáo viên.

## Phạm vi kỹ thuật

- Chỉ sửa copy trong `Guardrails`, nhãn điều hướng, footer và test hành vi.
- Giữ `#rao-chan`, thứ tự section, semantic region/aside, CSS, Server Component,
  design token và toàn bộ asset.
- Không thêm dependency, Client Component, API, form, cookie, analytics hoặc
  runtime fetch.

## Kiểm thử

- Test phải thấy tiêu đề mới, bốn thông tin dành cho phụ huynh, việc ảnh được gửi
  tới dịch vụ AI và cảnh báo AI có thể nhầm.
- Test phải chứng minh section public không còn các thuật ngữ nội bộ bị cấm.
- Nav trên route `/` và 404 vẫn trỏ đúng `#rao-chan`.
- Chạy focused test theo RED → GREEN, full test, lint, build và browser
  375/768/1440 trước deploy.
