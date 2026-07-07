# Kịch bản demo WonderLens (90 giây)

> Mục tiêu: tạo "khoảnh khắc wow" + demo **không vỡ**. Bộ vật hero chạy **offline**, không phụ thuộc wifi.

## Chuẩn bị trước khi lên sân khấu
- Cài **bản release** lên điện thoại (`flutter run --release -d <device>`), tắt bản debug.
- Để sẵn vài **vật văn phòng** trên bàn: cốc giấy, bút bi, kẹp giấy, chai nước.
- **Demo không cần mạng** cho vật hero (nhận diện mock/offline + nội dung + giọng đọc on-device). Nếu muốn khoe AI live cho vật lạ → bật wifi + đã cấu hình `PROXY_BASE_URL`.
- Bật âm lượng. Kiểm tra giọng đọc tiếng Việt (Settings → Accessibility → Spoken Content → Voices → Tiếng Việt).
- **Quay sẵn 1 clip dự phòng** chạy đủ luồng, phòng khi sự cố sân khấu.

## Lời thoại + thao tác (90s)
1. **(0–15s) Mồi tò mò.** "Đây là cái cốc giấy bình thường. Nhưng bé có biết nó từ đâu mà ra không?" → mở app → **Mở ống kính khám phá**.
2. **(15–35s) Khoảnh khắc wow.** Chĩa vào cốc → **chụp** → "Tèn ten! Bắt được manh mối: Cốc giấy 🥤" → **Mở hành trình**.
3. **(35–60s) Kể chuyện.** Bấm **Nghe câu chuyện 🔊** → để khán giả nghe giọng đọc cuộn qua: rừng trồng → bột giấy → cán giấy → màng chống nước. Confetti 🎉 + **huy hiệu Vật liệu Giấy**.
4. **(60–75s) Sản phẩm thật.** Mở **Rương khám phá** → khoe huy hiệu + thanh cấp độ "Mở đủ 8 đồ vật để lên hạng bậc thầy".
5. **(75–90s) Mời giám khảo.** "Mời thầy/cô cầm thử cái bút trên bàn" → giám khảo chụp → ra ngay (đã có sẵn) → chốt.
6. *(Tuỳ chọn, nếu có mạng)* chụp một vật lạ ngoài bộ hero → **AI live** sinh hành trình → khoe tính tổng quát ("AI kể chuyện vui").

## Lưới an toàn khi demo
- Nhận diện sai/độ tin cậy thấp → app hỏi "Có phải …?" + **Soi lại**.
- Mất mạng lúc khoe AI live → app báo thân thiện, KHÔNG crash; quay về vật hero offline.
- Sự cố thiết bị → phát **clip dự phòng**.

## Trạng thái hiện tại (cho người trình bày)
- Nhận diện: **mock offline xoay tua** — mỗi lần chụp ra lần lượt 1 trong 8 vật hero (lần chụp đầu sau khi mở app = Cốc giấy). Bật **API thật** (OpenAI Vision) bằng `--dart-define=PROXY_BASE_URL=...` lúc build, hoặc bật ngay trong app qua **Dev panel ẩn** (nhấn giữ logo "WonderLens" / nhãn "NHIỆM VỤ KHÁM PHÁ").
- 8 vật hero có nội dung + giọng đọc chạy offline.
- AI live + kid-safe guardrail là **prompt-based**, cần red-team output thật trước khi cho trẻ dùng công khai.
