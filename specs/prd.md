# PRD — WonderLens

**Version:** 1.0 (Hackathon MVP)  
**Date:** 2026-06-27  
**Status:** Shipped (demo)  
**Owner:** Dev team  

---

## 1. Business context

### Problem

Trẻ em 6–10 tuổi tiếp xúc hàng ngày với đồ vật (bút, giấy, chai nước...) nhưng không biết câu chuyện khoa học + vật liệu đằng sau. Nội dung giáo dục STEM hiện tại phần lớn là sách tĩnh hoặc video thụ động — không có trải nghiệm *khám phá bằng tay* gắn với đồ vật thật.

### Opportunity

Camera điện thoại + AI Vision tạo ra trải nghiệm mới: **chỉ cần chụp → ngay lập tức thấy hành trình khoa học** của đồ vật đó. Điểm khác biệt:
- Tức thì (< 5s), không cần nhập từ khoá
- Kể chuyện = ngôn ngữ trẻ + giọng đọc = dễ tiếp thu hơn text
- Game sưu tầm = động lực quay lại

### Business goal (hackathon)

Thuyết phục giám khảo rằng WonderLens là sản phẩm **giáo dục STEM khả thi, có wow-factor thật**, xứng đáng đầu tư/phát triển tiếp.

### Business goal (production path)

| Giai đoạn | Mục tiêu |
|-----------|----------|
| v1 (Hackathon) | Proof of concept, demo 90s không lỗi, giám khảo ấn tượng |
| v1.1 (Post-hackathon) | Deploy thật, kiểm chứng nội dung, safety audit kid-content |
| v2 | Mở rộng bộ hero, thêm chủ đề (không gian, động vật...), B2B trường học |

---

## 2. Users

Xem chi tiết: [`specs/user-roles.md`](./user-roles.md)

| Segment | Priority |
|---------|----------|
| Trẻ 6–10 (người dùng chính) | P0 |
| Phụ huynh (người quyết định install) | P1 |
| Giáo viên tiểu học | P2 |
| Giám khảo hackathon | P0 (v1 only) |

---

## 3. Product goals

| Goal | Metric | Target (v1) |
|------|--------|-------------|
| Tức thì | Time-to-wow (camera → timeline) | < 5s (hero, offline) |
| Phủ rộng | Hero objects hoạt động offline | ≥ 8 |
| Khám phá tự do | AI live object thành công | ≥ 1 khi có mạng |
| Demo tin cậy | Demo 90s chạy không cần wifi | 100% |
| Onboard nhanh | Trẻ hiểu cách dùng không cần hướng dẫn | < 10s |

---

## 4. Features

Xem chi tiết: [`specs/features.md`](./features.md)

| ID | Feature | Priority | Status |
|----|---------|----------|--------|
| F-01 | Camera & recognition | P0 | Done |
| F-02 | Origin Timeline (hero, offline) | P0 | Done |
| F-03 | Narration tự động (on-device TTS) | P0 | Done |
| F-04 | Bộ sưu tập + huy hiệu | P1 | Done |
| F-05 | AI live fallback (vật lạ) | P1 | Done |
| F-06 | Polish & demo UX | P1 | Done |
| F-07 | Tranh minh hoạ thật (thay emoji) | P2 | Backlog |
| F-08 | Kid-safe runtime audit (red-team) | P0* | Backlog* |

> *F-08: Bắt buộc trước khi deploy cho trẻ thật (hiện guardrail là prompt-only, chưa test runtime).

---

## 5. Architecture summary

```
[Flutter app]
     │
     ├─ Hero objects → bundled assets (offline, < 2s)
     │
     └─ Unknown objects → [Vercel proxy] → OpenAI gpt-4o (Vision + TTS)
```

- Vercel proxy giấu `OPENAI_API_KEY` (không bao giờ trong app)
- Giọng đọc: `flutter_tts` on-device (không cần key, offline)
- Local storage: Hive (bộ sưu tập + badges)
- AI live không vào bộ sưu tập (nội dung chưa kiểm chứng)

ADR chi tiết: [`adrs/`](../adrs/)

---

## 6. Non-goals (v1)

- Không có tài khoản user / backend database
- Không sinh ảnh minh hoạ live (chỉ text + TTS)
- Không localisation tiếng khác (chỉ tiếng Việt)
- Không AR overlay
- Không social features (chia sẻ bộ sưu tập)
- Không subscription / monetisation

---

## 7. Risks & mitigations

| Rủi ro | Mức | Mitigation |
|--------|-----|------------|
| AI live sinh nội dung sai/không safe cho trẻ | HIGH | Guardrail prompt + temperature thấp + nhãn "Khám phá vui (AI)". Chưa red-team runtime → **không deploy cho trẻ thật trước khi audit** |
| Lộ API key | HIGH | Key chỉ ở Vercel env. Đổi `APP_SHARED_SECRET` khỏi giá trị mẫu trước deploy công khai |
| Mạng yếu khi demo | MED | Hero offline-first + clip dự phòng |
| OpenAI cost leo thang | MED | Đặt spend limit trước khi deploy. Cache response proxy |
| Nhận diện sai vật | LOW | Confidence threshold + "Chụp lại" UI |

---

## 8. Definition of Done (product)

- [ ] 8 hero objects: nhận diện đúng + timeline đầy đủ + giọng đọc chạy
- [ ] Demo 90s: offline, không crash, wow-factor
- [ ] AI live: ≥ 1 vật lạ sinh hành trình + TTS thành công
- [ ] Bộ sưu tập persist qua restart
- [ ] Build release (không debug) chạy được trên iPhone thật

---

## 9. Roadmap (post-hackathon)

### v1.1 — Production-ready

- Red-team AI live output (kid-safe audit)
- Đổi `APP_SHARED_SECRET` + set OpenAI spend limit
- Tranh minh hoạ thật thay emoji (`Stage.illustration` đã sẵn)
- Thêm 4–8 hero objects (mở rộng bộ văn phòng)
- TestFlight / Play beta với phụ huynh thật

### v2 — Growth

- Mở rộng chủ đề: không gian, đại dương, cơ thể người
- B2B: package cho trường tiểu học
- Social: chia sẻ bộ sưu tập giữa bạn bè
- Tài khoản giáo viên: xem tiến độ học sinh
