# Android beta waitlist — product/spec handoff

**Jira:** [KAN-39](https://aichoem.atlassian.net/browse/KAN-39)  
**Owner:** Hoàng Hiệp  
**Trạng thái:** Spec/copy hoàn tất; live implementation bị gate  
**Cập nhật:** 2026-07-15

## Vì sao chưa dựng form live

Repo chưa có database/CRM cho email, data controller/owner, retention/deletion
process, consent approval hoặc ADR cho PII. Tự thêm endpoint lưu email vào proxy
sẽ mở rộng kiến trúc và privacy ngoài phạm vi hiện tại. Bản live chỉ bắt đầu khi
các mục trong [go-live gate](#go-live-gate) có owner và chữ ký.

## Audience

- Phụ huynh/người giám hộ từ 18 tuổi dùng Android và đồng hành cùng trẻ 6–10.
- Giáo viên/người làm giáo dục muốn pilot có người lớn giám sát.
- Không nhận form trực tiếp từ trẻ; copy phải nói rõ điều này trước field email.

## Landing copy

### Hero

**Eyebrow:** `WonderLens Android closed beta`  
**Headline:** `Cùng bé soi một đồ vật, mở ra cả hành trình`  
**Body:** `WonderLens biến ảnh chụp đồ vật quanh nhà thành câu chuyện ngắn về vật
liệu và cách món đồ được tạo ra — bằng tiếng Việt, để bố mẹ và bé cùng khám phá.`  
**Primary CTA:** `Đăng ký beta dành cho phụ huynh`  
**Secondary CTA:** `Xem demo 45 giây`

### Three value points

1. `Chụp là khám phá` — từ một đồ vật thật tới hành trình dễ hiểu.
2. `Bố mẹ đồng hành` — không tài khoản trẻ, không quảng cáo, không tracking.
3. `Học bằng câu chuyện` — hình, giọng kể và bộ sưu tập để cùng nhìn lại.

### Trust note

> Ảnh chụp được gửi qua máy chủ WonderLens tới OpenAI để tạo hành trình; máy chủ
> WonderLens không lưu ảnh. OpenAI có thể giữ dữ liệu API tối đa 30 ngày để
> giám sát lạm dụng. Hãy tránh chụp khuôn mặt hoặc thông tin cá nhân.

### Beta expectation

> Đây là bản thử nghiệm giới hạn. AI có thể nhận diện hoặc kể chưa đúng; phụ
> huynh hãy dùng cùng bé và gửi lỗi cho team. Đăng ký không đảm bảo được mời ngay.

## Demo/asset

- Video: `promo/wonderlens-promo/wonderlens-promo.mp4`
- Poster: `promo/wonderlens-promo/poster.png`
- Logo: `app/assets/images/brand_logo.png`
- Store screenshots: `app/store-assets/screenshots/` (chỉ dùng sau khi thêm
  camera/result/timeline theo [store metadata](../release/store-metadata.md)).

Không dùng ảnh trẻ thật. Nếu demo video hiện flow không còn đúng HEAD, quay lại
screen recording trước khi publish.

## Form schema

| Field | Type | Required | Rule |
|---|---|---:|---|
| Email người lớn | email | Yes | Normalize lower-case; không hiển thị lại public |
| Vai trò | enum | Yes | Phụ huynh / Giáo viên / Khác |
| Thiết bị Android | text/select | Yes | Model hoặc nhóm máy; không lấy device ID |
| Phiên bản Android | select/text | Yes | Dùng phân bổ test |
| Khu vực | enum | No | Chỉ quốc gia/tỉnh rộng; không địa chỉ chính xác |
| Đồng ý beta contact | checkbox | Yes | Consent riêng cho email beta |
| Đồng ý research contact | checkbox | No | Không gộp với beta consent |
| Privacy acknowledgement | checkbox | Yes | Link policy, xác nhận người điền ≥18 |
| Referral source | enum/campaign | No | Không fingerprint/tracking chéo site |

Không thu tên trẻ, tuổi/ngày sinh trẻ, trường/lớp, ảnh, số điện thoại, địa chỉ,
device ID hoặc advertising ID.

## Consent copy

**Bắt buộc:**

> Tôi từ 18 tuổi trở lên và đồng ý để WonderLens dùng email này nhằm liên hệ về
> Android closed beta. Tôi đã đọc Chính sách quyền riêng tư và hiểu rằng mình có
> thể rút đăng ký bất cứ lúc nào.

**Tuỳ chọn, tách riêng:**

> Tôi đồng ý để team liên hệ mời phỏng vấn ngắn về trải nghiệm gia đình/giáo dục.

Không pre-check checkbox. Submit phải lưu consent version/timestamp cùng record,
không lưu IP đầy đủ chỉ để chứng minh consent nếu legal không yêu cầu.

## Success state

**Title:** `Đã ghi nhận đăng ký của bạn`  
**Body:** `Nếu thiết bị và đợt test phù hợp, team sẽ gửi hướng dẫn tới email này.
Trong lúc chờ, bạn có thể xem các câu chuyện build-in-public của WonderLens.`  
**No dark pattern:** không yêu cầu share để “tăng hạng”.

## Data lifecycle

| Hoạt động | Recommendation |
|---|---|
| Controller | Pháp nhân/developer name khớp store; PM điền trước launch |
| Processor/storage | Managed form/CRM trong business workspace đã duyệt |
| Access | Hoàng Hiệp + PM beta owner; least privilege, 2FA |
| Retention | Xoá waitlist không được mời sau 90 ngày kể từ beta close; PM chốt |
| Unsubscribe | Link hoặc reply email; xử lý ≤7 ngày nội bộ |
| Deletion request | Privacy contact xác minh và xoá record + processor copies |
| Export | Không tải CSV xuống máy cá nhân nếu không cần; không commit repo |
| Incident | Thu hồi access, ghi impact, làm theo legal incident process |

Con số 90 ngày là recommendation vận hành, không có hiệu lực cho tới khi PM/legal
duyệt và policy được cập nhật.

## Tracking tối thiểu

Chỉ bật sau privacy approval:

- Aggregate page views.
- Demo play.
- CTA/form start.
- Submit success/error.
- Campaign code do team đặt, không user/device identifier.

Không session replay, heatmap, ad pixel, fingerprint, cross-site tracking hoặc
raw IP retention. Nếu không có công cụ aggregate phù hợp, đo số submit từ form
và platform link clicks là đủ cho beta.

## Phương án triển khai

### A. Managed form/CRM — recommend

Dùng provider đã có business account, DPA, access control, export/delete và spam
protection. Embed hoặc link từ static landing; không thêm database vào proxy.

### B. Custom proxy endpoint

Chỉ chọn khi có ADR cho storage, encryption, auth/admin, rate limiting, deletion,
backup, retention và incident response. Không hợp lý cho beta nhỏ hiện tại.

### C. Email link thuần

Không đủ: dữ liệu không có schema/consent version, khó chống spam và xoá. Chỉ
dùng làm support fallback, không phải waitlist chính.

## Acceptance tests cho bản live

- [ ] Headline, demo, value prop và parent-only statement hiển thị trên mobile.
- [ ] Email invalid/blank bị chặn; valid submit chỉ tạo một record idempotent.
- [ ] Role/device/Android/consent lưu đúng; optional research consent tách riêng.
- [ ] Không thể submit nếu chưa xác nhận ≥18/privacy/beta contact.
- [ ] Duplicate email update consent/source an toàn, không tạo spam rows.
- [ ] Success/error states không lộ email trong URL/log.
- [ ] Privacy và unsubscribe dùng được.
- [ ] Rate limit/honeypot/CAPTCHA privacy-safe chống bot.
- [ ] PM thử submit trên Android; data owner kiểm tra record và xoá thử end-to-end.
- [ ] Tracking chỉ aggregate events đã duyệt.

## Go-live gate

- [ ] PM ghi data controller/legal entity.
- [ ] Chọn storage/CRM và account owner có 2FA.
- [ ] Chốt retention, unsubscribe, deletion và incident owner.
- [ ] Privacy/legal duyệt landing + consent + processor.
- [ ] Có live URL/domain và release owner.
- [ ] Core beta path/build đã sẵn sàng nhận tester.
- [ ] Acceptance tests pass và có bằng chứng.

Cho tới khi các ô trên đủ, KAN-39 có thể ghi `spec ready`, không được ghi `live`
hoặc Done theo Jira DoD.

