# Features — WonderLens

## F-01: Camera & Recognition

**Priority:** P0 | **Status:** Done | **Domain:** Camera & Recognition

**Description:**  
Mở camera → hiện khung ngắm với mascot dẫn dắt → chụp → gửi lên proxy → nhận diện → route đến đúng flow.

**User story:**  
*Bé mở app, thấy khung camera vui nhộn, chĩa vào bút bi, nhấn chụp → app biết đây là "bút bi" và hiện hành trình.*

**Acceptance criteria:**
- [ ] Camera mở được trên iOS + Android (permission handled)
- [ ] Mascot/guide hiện trong viewfinder
- [ ] Chụp → upload → nhận `object_id + confidence` trong ≤ 10s (có mạng)
- [ ] Confidence < 0.7 → UI "Có phải [X]? / Chụp lại"
- [ ] Timeout 10s → toast lỗi, không crash
- [ ] Không gọi OpenAI trực tiếp từ app

**Edge cases:**
- Camera bị revoke permission → hướng dẫn vào Settings
- Background/resume → reinit camera đúng (không rò controller)
- App lock khi chụp → graceful cancel

---

## F-02: Origin Timeline (hero, offline)

**Priority:** P0 | **Status:** Done | **Domain:** Timeline & Narration

**Description:**  
Hero object → load nội dung bundled → hiện timeline cuộn dọc qua từng chặng sản xuất.

**User story:**  
*Bé chụp tờ giấy A4, trong 2 giây timeline hiện ra: "Từ cây gỗ → thành bột giấy → thành tờ giấy trắng" với hình + text ngắn gọn.*

**Acceptance criteria:**
- [ ] 8 hero objects có đầy đủ content (≥ 3 stages/vật)
- [ ] Load offline < 2s
- [ ] Mỗi stage: title + kid_text (≤ 50 từ) + fun_fact + illustration
- [ ] Cuộn dọc mượt giữa stages
- [ ] Content kiểm chứng khoa học, ngôn ngữ trẻ 6–10

**Hero objects:**
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

---

## F-03: Narration tự động

**Priority:** P0 | **Status:** Done | **Domain:** Timeline & Narration

**Description:**  
Giọng đọc on-device (`flutter_tts`) tự phát khi vào mỗi stage — không cần nhấn play.

**User story:**  
*Bé cuộn sang stage mới, giọng đọc tự kể câu chuyện — bé không cần đọc chữ.*

**Acceptance criteria:**
- [ ] Giọng đọc tự chạy khi stage active
- [ ] Dừng giọng khi cuộn sang stage khác
- [ ] Hoạt động offline (on-device TTS)
- [ ] Tiếng Việt, giọng phù hợp trẻ em

**Note:** Dùng `flutter_tts` thay vì OpenAI TTS pre-gen để đảm bảo offline-first. Trường `Stage.audio` giữ lại cho upgrade sau.

---

## F-04: Bộ sưu tập + Huy hiệu

**Priority:** P1 | **Status:** Done | **Domain:** Collection & Badges

**Description:**  
Sau khám phá hero object → confetti + badge unlock → lưu vào bộ sưu tập local.

**User story:**  
*Bé khám phá bút bi → confetti + "Huy hiệu Nhựa + Mực!" → vào tab Bộ sưu tập thấy bút bi đã được đánh dấu khám phá.*

**Acceptance criteria:**
- [ ] Confetti animation khi hoàn thành timeline
- [ ] Badge hiện với tên material (ví dụ: "Nhựa + Mực")
- [ ] Haptic feedback khi badge mở
- [ ] Collection screen hiện tất cả vật đã khám phá
- [ ] Data persist qua restart
- [ ] Hero objects vào lưới chính + huy hiệu/level; vật AI-live lưu vào khu
      "Khám phá thêm (AI)" riêng (ảnh cutout thật + nhãn AI), KHÔNG tính level/huy hiệu
- [ ] Dedup: cùng object khám phá nhiều lần → chỉ 1 entry
- [ ] Nhấn giữ vật phẩm → mở hành động lưu ảnh thẻ sticker vào thư viện ảnh
      của máy (nền giấy cũ, vật + tên có viền trắng) hoặc xoá khỏi Rương; xoá
      đồng thời gỡ ảnh sticker local đã lưu

---

## F-05: AI Live Fallback

**Priority:** P1 | **Status:** Done (chưa test runtime) | **Domain:** Timeline & Narration

**Description:**  
Vật không phải hero → gọi `/api/generate-journey` → sinh hành trình kid-safe + TTS on-device.

**User story:**  
*Bé chụp con chuột máy tính (không phải hero) → app hiện "Đang khám phá..." → sau vài giây timeline xuất hiện với nhãn "Khám phá vui (AI)".*

**Acceptance criteria:**
- [ ] Unknown object + online → gọi generate-journey
- [ ] Loading state rõ ràng (spinner + text "Đang khám phá...")
- [ ] Timeline hiện với nhãn "Khám phá vui (AI)" để phân biệt với curated
- [ ] TTS on-device đọc nội dung sinh ra
- [ ] Unknown object + offline → "Khám phá sau nhé!" (không crash)
- [ ] AI output lưu vào "Khám phá thêm (AI)" của bộ sưu tập (nhãn AI, mở lại
      offline từ nội dung đã lưu) — không tính level/huy hiệu vì chưa red-team

**⚠️ Blocker trước khi deploy thật:**  
Guardrail hiện là prompt-only. Phải red-team output thật trước khi cho trẻ thật dùng.

---

## F-06: Polish & Demo UX

**Priority:** P1 | **Status:** Done | **Domain:** Cross-cutting

**Acceptance criteria:**
- [ ] Mascot pulse animation trong camera viewfinder
- [ ] Transition animation mượt: camera → timeline
- [ ] Stage appearance animation (fade/slide in)
- [ ] Haptics: chụp ảnh, badge unlock
- [x] Onboarding < 10s (splash + màn "chụp thử" mô phỏng viewfinder lần đầu mở app, có Bỏ qua)
- [ ] "Chụp lại" / "Chọn lại" UI khi confidence thấp
- [ ] Demo 90s script chạy không lỗi offline

---

## F-07: Tranh minh hoạ thật (Backlog)

**Priority:** P2 | **Status:** Backlog

**Description:**  
Thay emoji placeholder bằng illustration thật cho mỗi stage. Trường `Stage.illustration` đã sẵn trong schema.

**Why deferred:** Không ảnh hưởng demo. Cần design resource riêng (vẽ tay hoặc sinh sẵn).

---

## F-09: Timeline xem đơn giản (Supersedes effort gates)

**Priority:** P1 | **Status:** Done | **Domain:** Timeline & Narration | **Ref:** [ADR-008](../adrs/ADR-008-effort-gated-discovery.md), [TASK-011](../../tasks/TASK-011-effort-gated-discovery.md)

**Description:**
Giữ timeline như một câu chuyện khoa học ngắn, trực quan: toàn bộ chặng hiện
ngay theo thứ tự với ảnh, tiêu đề, chữ ngắn, fun fact và nút nghe lại từng
chặng. Các dữ liệu `predict`, `action`, `experiment` vẫn parse để tương thích
content cũ nhưng không render thành cổng chặn.

**User story:**
*Bé chụp bút bi. App hiện ngay các chặng "dầu mỏ → hạt nhựa → vỏ bút → cây bút",
mỗi chặng có hình và câu ngắn để bé tự xem hoặc bấm nghe lại.*

**Acceptance criteria:**
- [ ] Toàn bộ chặng hiện ngay, không có chặng khoá.
- [ ] Không render quiz/thí nghiệm/gesture gate trong timeline chính.
- [ ] Nút nghe câu chuyện đọc toàn bộ hành trình.
- [ ] Bé vẫn có thể nghe lại từng chặng.
- [ ] Ghi bộ sưu tập khi trẻ xem tới cuối hoặc khi nội dung quá ngắn không cần cuộn.

**Note:** Effort-gated flow cũ bị bỏ theo ADR-008 amendment 2026-07-05 vì tạo
ma sát cao hơn giá trị học tập trong demo trẻ 6-10.

---

## F-08: Kid-safe runtime audit (Critical backlog)

**Priority:** P0 (trước deploy thật) | **Status:** Backlog

**Description:**  
Red-team AI live output với nhiều object types để đảm bảo không có nội dung không phù hợp trẻ em thoát ra.

**Why deferred:** Cần OpenAI key + deployed proxy. Hackathon scope không cover.

**Blocker:** F-05 (AI live) không được dùng cho trẻ thật trước khi F-08 done.
