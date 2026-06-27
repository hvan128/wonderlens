# Product Vision — WonderLens

## Problem

Trẻ 6–10 tuổi tò mò về thế giới nhưng đồ vật quanh chúng "vô hình" về mặt khoa học — không thấy được câu chuyện vật liệu/sản xuất đằng sau. Cần biến vật tầm thường thành câu chuyện khám phá hấp dẫn để nuôi hứng thú khoa học.

## Vision

> Biến mỗi đồ vật văn phòng thành một hành trình khoa học sống động cho trẻ.

## Target users

| User | Mô tả |
|------|-------|
| Trẻ 6–10 | Người dùng chính: chụp, khám phá, sưu tầm |
| Phụ huynh / giáo viên | Giám sát, khuyến khích |
| Giám khảo hackathon | Demo audience — ưu tiên wow-factor |

## Core experience (luồng chính)

```
Camera → Nhận diện → Research (wiki/official) → Info + Lịch sử (summary) → Timeline (text + audio) → Video script "cách làm" → Huy hiệu → Bộ sưu tập
```

1. Trẻ mở app, hướng camera vào đồ vật văn phòng
2. Chụp → nhận diện → hero load bundled timeline **offline < 2s**
3. Song song (có mạng): proxy lấy snippet Wikipedia/trang chính thống → OpenAI tóm tắt **thông tin + lịch sử** kid-safe
4. App hiển thị card "Vật này là gì?" + "Lịch sử" + nguồn tham khảo, kèm timeline stages + `flutter_tts`
5. System prompt sinh **kịch bản video "cách làm"** (4-6 scene, 30-60s) từ summary + stages
6. Trẻ bấm "Xem cách tạo ra" → xem script/scene hoặc video MP4 (phase sau)
7. Khám phá xong → confetti + huy hiệu → Bộ sưu tập (hero only)
8. Vật lạ → cùng pipeline research + AI journey; nhãn "Khám phá vui (AI)"

## Domains

| Domain | Mô tả |
|--------|-------|
| **Recognition** | Nhận diện vật qua camera + OpenAI Vision |
| **Content** | Nội dung origin timeline + research summary từ wiki/official |
| **Narration** | TTS audio tự động theo timeline |
| **Video Journey** | System prompt → kịch bản video "cách làm"; sau đó phát MP4 bundled/gen |
| **Collection** | Bộ sưu tập + huy hiệu local |
| **Proxy** | Vercel serverless giấu API key |

## Hero objects (~8 vật văn phòng)

| ID | Tên | Emoji |
|----|-----|-------|
| `a4_paper` | Tờ giấy A4 | 📄 |
| `ball_pen` | Bút bi | 🖊️ |
| `coffee_cup` | Cốc giấy cà phê | ☕ |
| `plastic_bottle` | Chai nước nhựa | 💧 |
| `paper_clip` | Kẹp giấy | 📎 |
| `pencil` | Bút chì | ✏️ |
| `sticky_note` | Giấy note | 🗒️ |
| `aa_battery` | Pin AA | 🔋 |

## Success metrics

- Time-to-wow < 5s cho vật hero (offline)
- ≥ 8 vật hero hoạt động **không cần wifi**
- ≥ 8 video hero dài 30–60s xem được offline hoặc fallback sang poster + text nếu chưa có asset
- Demo 90s chạy trọn vẹn offline
- ≥ 1 vật live AI thành công khi có mạng
- Onboarding < 10s để trẻ hiểu cách dùng
