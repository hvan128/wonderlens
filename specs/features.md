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
- [ ] Chỉ hero objects được lưu (không lưu AI live)
- [ ] Dedup: cùng object khám phá nhiều lần → chỉ 1 entry

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
- [ ] AI output không vào bộ sưu tập

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
- [ ] Onboarding < 10s (mascot guide lần đầu mở app)
- [ ] "Chụp lại" / "Chọn lại" UI khi confidence thấp
- [ ] Demo 90s script chạy không lỗi offline

---

## F-07: Tranh minh hoạ thật (Backlog)

**Priority:** P2 | **Status:** Backlog

**Description:**  
Thay emoji placeholder bằng illustration thật cho mỗi stage. Trường `Stage.illustration` đã sẵn trong schema.

**Why deferred:** Không ảnh hưởng demo. Cần design resource riêng (vẽ tay hoặc sinh sẵn).

---

## F-08: Kid-safe runtime audit (Critical backlog)

**Priority:** P0 (trước deploy thật) | **Status:** Backlog

**Description:**  
Red-team AI live output với nhiều object types để đảm bảo không có nội dung không phù hợp trẻ em thoát ra.

**Why deferred:** Cần OpenAI key + deployed proxy. Hackathon scope không cover.

**Blocker:** F-05 (AI live) không được dùng cho trẻ thật trước khi F-08 done.

---

# Trục C/D — Tích hợp game (Học sâu & Chơi)

> Gộp từ nhánh `integration/truc-c-d` vào main-lineage.
> Nền: [ADR-012](../adrs/ADR-012-material-graph-model.md) · [ADR-013](../adrs/ADR-013-learn-play-domain.md) · [ADR-014](../adrs/ADR-014-missions-and-teacher-parent.md) · [specs/materials.md](./materials.md).
> Nền dữ liệu/model tích hợp ở **TASK-017**; UI game ở các task sau (TASK-018..021).

## F-09: Thẻ Vật Liệu & Mạng lưới

**Priority:** P1 | **Status:** Planned | **Domain:** Collection, Cards & Missions | **Task:** TASK-017 (nền) + TASK-019 (UI) | **ADR:** ADR-012

**Description:**
Mỗi vật liệu (Dầu mỏ, Thép, Gỗ, Cát→Thuỷ tinh…) là một **thẻ sưu tầm**. Khám phá đồ vật → mở thẻ. Chạm thẻ → thấy **mạng lưới**: các vật khác cùng vật liệu đó.

**User story:** *Bé khám phá bút bi và chai nước → mở thẻ "Dầu mỏ" → thấy cả hai đều bắt đầu từ dầu mỏ.*

**Acceptance criteria:** Cốt lõi (ADR-012): graph object↔material, thẻ mờ khi chưa mở, thẻ chi tiết có blurb + fun_facts + danh sách vật cùng vật liệu, suy ra từ `discoveredIds` (không Hive field mới), AI-live không vào mạng lưới.

---

## F-10: Đố vui sau timeline

**Priority:** P1 | **Status:** Planned | **Domain:** Learn & Play | **Task:** TASK-018 | **ADR:** ADR-013

**Description:** Sau timeline hero → 1–3 câu đố ("Bút bi bắt đầu từ đâu nào?") → củng cố + huy hiệu nhỏ.

**Acceptance criteria:** Cốt lõi: `quiz[]` trong content (optional), offline cho hero, bỏ qua được (không chặn Collection), AI-live không sinh quiz.

---

## F-12: Nhiệm vụ khám phá

**Priority:** P2 | **Status:** Planned | **Domain:** Collection, Cards & Missions | **Task:** TASK-019 | **Depends:** F-09 | **ADR:** ADR-014

**Description:** "Tìm 3 vật làm từ kim loại trong nhà!" → khám phá đủ → hoàn thành + huy hiệu.

**Acceptance criteria:** `missions.json`, Hive box `wonderlens_progress` persist, tự cập nhật theo khám phá (đếm qua material graph ADR-012), offline.

---

## F-13: Game ghép ngược

**Priority:** P2 | **Status:** Planned | **Domain:** Learn & Play | **Task:** TASK-018 | **Depends:** F-09 | **ADR:** ADR-013

**Description:** Kéo nguyên liệu để lắp ra đồ vật theo chuỗi biến đổi (dầu mỏ → hạt nhựa → vỏ bút → bút bi).

**Acceptance criteria:** `assembly` trong content (optional), `Draggable`/`DragTarget` core (không package mới), offline ≥ 4 hero.

---

## F-17: Sân chơi (điểm vào game & bottom-nav tab)

**Priority:** P1 | **Status:** In Progress (mới) | **Domain:** Cross-cutting (UI shell) | **Task:** TASK-021 | **ADR:** ADR-016

**Description:** Bottom-nav 2 tab **Sân chơi** + **Bộ sưu tập**, nút giữa 📷 mở camera toàn màn hình (hành động quét). Sân chơi gom điểm vào game (đố vui, ghép ngược, nhiệm vụ, thẻ vật liệu). Camera + timeline + game là route toàn màn hình push **trên** shell (giữ nguyên vòng đời camera). Lớp điều hướng, không chứa business logic.

**Acceptance criteria:** Tab điều hướng tới Learn & Play + Missions; nút giữa mở camera; Đố vui/Ghép ngược chọn vật đã khám phá phù hợp (gợi ý nếu chưa có); vòng đời camera (RouteObserver) không hồi quy.

---

## F-18: Chuỗi ngày khám phá (daily streak)

**Priority:** P2 | **Status:** In Progress (mới) | **Domain:** Collection, Cards & Missions | **Task:** TASK-020 | **ADR:** ADR-015

**Description:** Đếm số ngày liên tiếp bé khám phá ≥1 vật → khích lệ quay lại. Lưu ở Hive box `wonderlens_streak` (key-value đơn giản), offline. Ghi nhận khi mở hành trình một vật (Timeline); chuỗi sang ngày mới (≥2) → màn "Chuỗi N ngày! 🔥". Bộ sưu tập hiện chip 🔥. **Không** cấp huy hiệu, **không** phạt khi đứt (khởi động lại về 1).

**Acceptance criteria:** Tăng streak khi khám phá trong ngày mới liên tiếp; reset về 1 khi bỏ ngày; persist qua restart; không PII, không account.

---

## Ngoài phạm vi đợt tích hợp này (backlog Trục C/D)

Các feature sau đã có trong backlog nhánh `integration/truc-c-d` nhưng **chưa** thuộc đợt tích hợp hiện tại — giữ số hiệu để không đụng:

- **F-11: So sánh 2 vật** — Learn & Play, dùng `sharedMaterials(a,b)` (ADR-012). *Planned, chưa lên lịch.*
- **F-14: Cây "Tại sao?"** — Learn & Play + Proxy; nhánh AI-live qua `/api/explain-deeper` **bị chặn bởi F-08**. *Planned, chưa lên lịch.*
- **F-15: Chế độ Giáo viên/Phụ huynh (B2B)** — **DEFERRED** (Domain 6, ADR-014 §Phạm vi tích hợp).
- **F-16: Album chung gia đình/lớp** — **DEFERRED**, cần backend + **ADR riêng** đảo non-goal (PRD §6).
