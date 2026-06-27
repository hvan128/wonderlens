# Brainstorm Report — WonderLens (tên tạm)

> App khơi gợi hứng thú khám phá khoa học cho trẻ: **chụp một đồ vật → hiện ra hành trình tạo ra nó**.

| Mục | Giá trị |
|---|---|
| Ngày | 2026-06-27 |
| Loại dự án | Hackathon, greenfield (`hackathon_codex/`) |
| Modes | (none) — brainstorm markdown |
| Trạng thái | Đã duyệt thiết kế, chuyển sang lập kế hoạch |

---

## 1. Problem statement & requirements

**Vấn đề gốc:** Trẻ 6–10 tuổi tò mò về thế giới nhưng đồ vật quanh chúng "vô hình" về mặt khoa học — không thấy được câu chuyện vật liệu/sản xuất đằng sau. Cần biến vật tầm thường thành câu chuyện khám phá hấp dẫn để nuôi hứng thú khoa học.

**Yêu cầu chốt (từ Discovery):**
- **Expected output:** App **Flutter** (iOS/Android) cho hackathon: chụp đồ vật văn phòng → hiện **Origin Timeline** có **lồng tiếng**, kèm **game sưu tầm + huy hiệu**. Có brainstorm report + plan.
- **Acceptance criteria:** chụp vật hero → nhận diện đúng → timeline hiện <5s (offline cho hero) → giọng đọc tự chạy → mở huy hiệu → vào bộ sưu tập. Vật lạ → fallback AI live.
- **Scope round này:** camera + nhận diện + timeline + narration + collection cho ~8 vật văn phòng; AI live fallback (đủ thời gian vì 1 tuần+).
- **Constraints (non-negotiable):** Flutter; OpenAI Vision (gpt-4o) + OpenAI TTS; proxy **Vercel serverless** giấu key; tiếng Việt; trẻ 6–10; chủ đề **đồ vật văn phòng**; **demo offline-first** cho vật hero.
- **Touchpoints:** greenfield trong `hackathon_codex/`. Không dùng backend Java; có thể tham khảo pattern Azure/auth của `vocaberry_be` nhưng không bắt buộc.
- **Tối ưu để ghi điểm:** **Wow-factor demo**.

---

## 2. Các hướng đã cân nhắc

### 2.1 Trải nghiệm (hero feature)
| Hướng | Pros | Cons | Quyết định |
|---|---|---|---|
| A. Origin Timeline | Dễ làm, dễ hiểu, demo chắc | Tĩnh nếu thiếu animation | ✅ Chọn (xương sống) |
| B. AR overlay | Cực wow | Khó, dễ vỡ khi demo | ❌ Loại |
| C. Comic + lồng tiếng | Trẻ mê, tận dụng TTS | Sinh ảnh comic live chậm/hên xui | ✅ Gộp làm narration chạy theo timeline |
| Lớp game sưu tầm | Giữ chân, ấn tượng "sản phẩm thật" | Thêm state | ✅ Chọn (local, không cần server) |

→ **Gộp cả 3 thành MỘT luồng** "khoảnh khắc khám phá": camera → nhận diện → timeline có giọng đọc → confetti huy hiệu → bộ sưu tập.

### 2.2 Engine nội dung
| Hướng | Pros | Cons | Quyết định |
|---|---|---|---|
| Live AI thuần | Tổng quát nhất | Chậm, dễ bịa sai, demo hên xui | ❌ |
| **Hybrid curated-first** | Demo chắc + vẫn "chụp gì cũng ra" | Tốn công soạn nội dung hero | ✅ Chọn |
| Curated thuần | An toàn nhất | Mất tính khám phá tự do | ❌ |

### 2.3 Nền tảng & nhận diện
- **Framework:** Flutter (✅) — camera + animation (Rive/Lottie) + 1 codebase.
- **Nhận diện + AI:** **OpenAI Vision (gpt-4o)** (✅) cho nhận diện + sinh hành trình; **OpenAI TTS** cho giọng đọc.
- **Proxy:** **Vercel serverless** (✅) giấu API key + cache; loại "gọi thẳng từ app" (lộ key) và Spring Boot (nặng cho demo).

---

## 3. Giải pháp khuyến nghị (đã duyệt)

### Kiến trúc
```
Flutter app (iOS/Android)
 ├─ Camera screen (khung ngắm ngộ nghĩnh + mascot dẫn dắt)
 ├─ Nhận diện: ảnh ─► Vercel proxy ─► OpenAI Vision (gpt-4o) ─► {object_id, confidence}
 │     ├─ khớp vật hero → nội dung ĐÓNG GÓI SẴN (offline, <2s)   ★ điểm ăn thua demo
 │     └─ không khớp    → OpenAI sinh "hành trình" JSON kid-safe + OpenAI TTS (live)
 ├─ Timeline screen: cuộn dọc, Rive/Lottie chuyển chặng, giọng đọc tự chạy
 ├─ Bộ sưu tập + huy hiệu (local: Hive/SQLite)
 └─ Vercel serverless proxy: giấu OpenAI key + cache kết quả
```

### Schema nội dung mỗi vật (curated, đã kiểm chứng)
```json
{
  "id": "ball_pen", "name": "Bút bi", "emoji": "🖊️", "material_badge": "Nhựa + Mực",
  "stages": [
    {"title": "Bắt đầu từ dầu mỏ", "illustration": "oil.png", "kid_text": "...", "fun_fact": "...", "audio": "st1.mp3"},
    {"title": "Biến thành hạt nhựa", "illustration": "...", "kid_text": "...", "fun_fact": "...", "audio": "..."},
    {"title": "Viên bi thép tí hon đầu bút", "illustration": "...", "kid_text": "...", "fun_fact": "...", "audio": "..."}
  ]
}
```

### Bộ "vật văn phòng anh hùng" (~8)
📄 Tờ giấy A4 · 🖊️ Bút bi · ☕ Cốc giấy cà phê · 💧 Chai nước nhựa · 📎 Kẹp giấy (quặng→thép) · ✏️ Bút chì (gỗ+than chì) · 🗒️ Giấy note (+keo siêu yếu) · 🔋 Pin AA. *(Dự phòng: ⌨️ phím bàn phím)*

### Lý do
- Vật văn phòng = giám khảo cầm đúng vật trên bàn họ chụp → wow thật, đáng tin.
- Curated-first + bundled offline = demo không phụ thuộc wifi sân khấu.
- Một nhà cung cấp (OpenAI: vision + TTS) = pipeline đơn giản, ít mảnh ghép.

---

## 4. Implementation considerations & risks

### Kế hoạch 1 tuần (định hướng)
- **D1–2:** skeleton Flutter, camera, gọi OpenAI Vision qua proxy, schema, 2 vật end-to-end (xương sống).
- **D3:** Timeline UI + narration + soạn nội dung kid-safe + pre-gen audio đủ 8 vật.
- **D4:** animation (Rive/Lottie), confetti, sound; bộ sưu tập + huy hiệu (local).
- **D5:** fallback AI live cho vật lạ + guardrail kid-safe.
- **D6:** đánh bóng wow (haptics, transition, onboarding mascot), đóng gói offline.
- **D7:** tập demo, lưới an toàn (confidence/"chọn lại"), quay clip dự phòng.

### Rủi ro & cách chặn
| Rủi ro | Cách chặn |
|---|---|
| AI bịa sai khoa học cho trẻ | Hero kiểm chứng tay; live: temperature thấp + prompt "chỉ nói sự thật đơn giản, không chắc thì nói tổng quát" + nhãn "khám phá vui" |
| Mạng yếu khi demo | Hero offline-first (bundled) + clip dự phòng |
| Lộ API key | Vercel proxy, không gọi thẳng từ app |
| Nhận diện sai | Ngưỡng confidence + "Có phải [X]? / Chọn lại" |
| Sinh ảnh live chậm/đắt | Hero dùng tranh tĩnh làm sẵn; live chỉ text + TTS (bỏ sinh ảnh live) |

---

## 5. Success metrics & validation
- Time-to-wow < 5s cho vật hero.
- ≥ 8 vật hero hoạt động **offline**.
- Demo chạy trọn vẹn **không cần wifi**.
- ≥ 1 vật **live ngẫu nhiên** thành công khi có mạng.
- Onboarding < 10s để trẻ hiểu "chĩa vào đồ vật rồi chụp".

---

## 6. Next steps & dependencies
- **Next:** `/ck:plan` chia phase triển khai theo kế hoạch 1 tuần ở trên.
- **Dependencies:** OpenAI API key (vision + TTS), tài khoản Vercel, Flutter SDK, bộ tranh minh hoạ cho 8 vật (vẽ tay/sinh sẵn), nội dung khoa học kiểm chứng cho 8 vật.
- **Quyết định mở (ghi nhận, không chặn):** chọn giọng TTS tiếng Việt phù hợp trẻ em; thư viện animation (Rive vs Lottie); engine lưu local (Hive vs SQLite/Drift).
