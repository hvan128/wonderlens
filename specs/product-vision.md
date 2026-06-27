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
Camera → Nhận diện vật → Origin Timeline (text + audio) → Video "cách tạo ra" → Huy hiệu → Bộ sưu tập
```

1. Trẻ mở app, hướng camera vào đồ vật văn phòng
2. Chụp → nhận diện → khớp hero object → hiện Origin Timeline **offline < 2s**
3. Timeline hiển thị lịch sử/hành trình bằng text, kèm giọng kể tự động qua từng chặng (Narration)
4. Trẻ bấm "Xem cách tạo ra" để xem video ngắn minh hoạ quy trình sản xuất theo ngôn ngữ trẻ em
5. Khám phá xong → confetti + mở huy hiệu
6. Vật vào Bộ sưu tập (local)
7. Vật lạ (không phải hero) → AI live fallback qua proxy (cần mạng), chỉ sinh text + audio; video live là nâng cấp sau

## Domains

| Domain | Mô tả |
|--------|-------|
| **Recognition** | Nhận diện vật qua camera + OpenAI Vision |
| **Content** | Nội dung origin timeline (curated + AI-generated) |
| **Narration** | TTS audio tự động theo timeline |
| **Video Journey** | Video ngắn minh hoạ cách tạo ra đồ vật, ưu tiên bundled assets cho hero |
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
