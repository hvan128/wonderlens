# User Roles — WonderLens

## Personas

### P0 — Bé Khám Phá (core user)

| Field | Value |
|-------|-------|
| Tuổi | 6–10 |
| Thiết bị | Điện thoại phụ huynh hoặc tablet |
| Literacy | Đọc được tiếng Việt cơ bản; ưu tiên hình ảnh + giọng đọc |
| Motivation | Tò mò, thích thu thập, thích được "bật mí" |
| Pain | Sách khoa học khô, video dài, không tương tác thật |

**Kịch bản:** Bé nhìn thấy bút bi trên bàn → chụp → nghe kể hành trình từ dầu mỏ thành bút → thu thập huy hiệu → hỏi bố "tại sao có bi thép nhỏ vậy?"

**Yêu cầu từ persona này:**
- Onboard ≤ 10s không cần đọc hướng dẫn
- Ngôn ngữ ≤ 50 từ/stage, không thuật ngữ khó
- Giọng đọc tự động (không cần nhấn play)
- Phản hồi tức thì (< 5s), không màn hình loading trống

---

### P1 — Phụ Huynh (decision maker)

| Field | Value |
|-------|-------|
| Tuổi | 28–45 |
| Mục tiêu | Tìm app giáo dục an toàn, không quảng cáo, không in-app purchase ẩn |
| Lo ngại | Nội dung không phù hợp, màn hình quá nhiều, app "nghiện" |

**Kịch bản:** Tải app từ App Store → thử vài vật → thấy nội dung kiểm chứng + không ads → cho phép con dùng.

**Yêu cầu từ persona này:**
- Nội dung kid-safe, có thể kiểm tra
- Không cần tạo tài khoản
- AI-generated content có nhãn rõ ràng ("Khám phá vui (AI)")
- Không push notification spam

---

### P2 — Giáo Viên Tiểu Học

| Field | Value |
|-------|-------|
| Bối cảnh | Lớp 1–5, STEM tích hợp |
| Mục tiêu | Công cụ khởi động bài học về vật liệu / quy trình sản xuất |

**Kịch bản (v2):** Giáo viên mở app trên bảng chiếu → cho học sinh thay nhau lên chụp vật → thảo luận hành trình.

**Yêu cầu (v2, không chặn v1):**
- Mode "classroom" hiện timeline to trên màn hình lớn
- Teacher dashboard xem vật học sinh đã khám phá

---

### P0 (v1 only) — Giám Khảo Hackathon

| Field | Value |
|-------|-------|
| Thời gian đánh giá | 90–180 giây |
| Tiêu chí | Wow-factor, feasibility, originality |

**Kịch bản:** Cầm điện thoại chụp bút bi trên bàn → timeline hiện < 3s → giọng kể tự chạy → badge confetti → "Ồ ngầu đấy."

**Yêu cầu từ persona này:**
- Demo không cần wifi (hero offline)
- Không màn hình lỗi, không spinner vô tận
- Confetti + haptics = moment ấn tượng

---

## Permissions model

| Action | Bé | Phụ huynh | Giáo viên (v2) |
|--------|-----|-----------|----------------|
| Chụp + khám phá | ✅ | ✅ | ✅ |
| Xem bộ sưu tập | ✅ | ✅ | ✅ |
| Xem nội dung AI live | ✅ | ✅ | ✅ |
| Xoá bộ sưu tập | ✅ | ✅ | — |
| Xem dashboard lớp | — | — | ✅ |

> v1 không có auth — tất cả quyền local trên thiết bị.
