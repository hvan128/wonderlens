# WonderLens press / launch kit

**Jira:** [KAN-40](https://aichoem.atlassian.net/browse/KAN-40)  
**Owner:** Hoàng Hiệp  
**Trạng thái:** Copy + asset index review-ready; team/contact cần founder điền  
**Cập nhật:** 2026-07-15

## Fast facts

| Field | Value |
|---|---|
| Product | WonderLens |
| Category | Family STEM education / camera AI |
| Audience | Phụ huynh dùng cùng trẻ 6–10 tuổi; giáo viên pilot |
| Platform | Flutter, iOS/Android |
| Language | Tiếng Việt |
| Core flow | Chụp đồ vật → reveal → hành trình → journal/share |
| AI | OpenAI qua Vercel proxy; không gọi thẳng từ app |
| Local data | Hive + app sandbox |
| Privacy posture | Không account/ads/tracking; camera photo gửi tới OpenAI |
| Release | Android closed beta đang chuẩn bị; không ghi là public launch |

## One-liner

**VI:** WonderLens biến đồ vật quanh nhà thành những hành trình STEM để bố mẹ và
trẻ cùng khám phá bằng camera AI.

**EN:** WonderLens turns everyday objects into Vietnamese STEM journeys that
parents and children explore together with an AI-powered camera.

## Mô tả 50 từ

### VI — 50 từ

WonderLens là ứng dụng STEM Việt giúp bố mẹ cùng trẻ 6–10 tuổi chụp một đồ vật
và khám phá hành trình tạo ra nó. Ứng dụng kể chuyện bằng hình, giọng đọc và bộ
sưu tập, không tài khoản, quảng cáo hay tracking. Nội dung AI được gắn nhãn.

### EN — 50 words

WonderLens is a Vietnamese STEM discovery app that helps parents and children
ages six to ten photograph an object and explore how it was made. Visual
stories, narration, and a local collection turn curiosity into conversation,
with no child accounts, advertising, or tracking. AI-generated journeys are
clearly labeled for families.

## Mô tả 150 từ

### VI — 150 từ

WonderLens biến câu hỏi “Món đồ này từ đâu ra?” thành hoạt động STEM ngắn để bố
mẹ làm cùng trẻ 6–10 tuổi. Người dùng chụp một đồ vật thật; ứng dụng tách vật
khỏi nền, gửi ảnh qua proxy tới AI, mở hành trình bằng tiếng Việt về nguyên liệu
và cách món đồ được tạo ra. Hình minh hoạ, giọng kể và video dùng fallback để
câu chuyện chữ vẫn dùng được khi media lỗi. Mỗi khám phá lưu vào nhật ký và bộ
sưu tập trên thiết bị hoặc chia sẻ khi người lớn chọn. WonderLens không có tài
khoản trẻ, quảng cáo hay tracking. Nội dung AI-live được gắn nhãn và phải qua
safety review trước beta cho gia đình. Sản phẩm chuẩn bị Android closed beta và
tiếp tục kiểm chứng tốc độ, retry, độ ổn định, tính đúng tuổi cùng phụ huynh,
giáo viên.

### EN — 150 words

WonderLens turns “Where did this object come from?” into a STEM activity for
parents and children ages six to ten. A family photographs an object; the app
separates it from the background, sends the image through a relay to AI, and
presents a Vietnamese journey explaining the materials and steps behind how it
was made. Illustrations, narration, and video use graceful fallbacks, so the
story remains usable when media fails. Discoveries can be saved to an on-device
journal and collection, or shared only when an adult chooses. WonderLens has no
child accounts, advertising, or tracking. AI-generated journeys are labeled and
must pass safety review before family beta testing. The team is preparing an
Android closed beta and validating speed, retry behavior, stability,
age-appropriate language, and privacy with parents and teachers. WonderLens is
designed as a family learning moment, not a social network for children or a
replacement for verified curriculum.

## Logo, icon và media

| Use | File | Ghi chú |
|---|---|---|
| Brand logo | `app/assets/images/brand_logo.png` | Dùng nền phù hợp, không stretch |
| iOS icon master | `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 1024 master |
| Android/Play icon | `app/store-assets/play-icon-512.png` | 512×512 |
| Feature graphic | `app/store-assets/play-feature-graphic-1024x500.png` | Google Play |
| Promo video | `promo/wonderlens-promo/wonderlens-promo.mp4` | Kiểm tra flow còn đúng HEAD |
| Promo poster | `promo/wonderlens-promo/poster.png` | Thumbnail/press preview |
| Screenshot folder | `app/store-assets/screenshots/` | 6 ảnh, 1290×2796 |

### Screenshot được phép dùng ngay

1. `65_01-home.png` — journal/home.
2. `65_02-day-detail.png` — object day detail.
3. `65_03-collection.png` — discovery collection.
4. `65_04-profile.png` — profile/badges.
5. `65_05-result.png` — object result + AI-assisted label.
6. `65_06-timeline.png` — journey/story screen.

Press/Product Hunt gallery đã có result/timeline nhưng vẫn cần camera capture từ
build thật. Xem [store screenshot storyboard](../release/store-metadata.md).

## Team note — founder phải điền

Không tự suy ra chức danh từ Git hoặc store contact. Founder/PM điền trước khi
phát hành:

> WonderLens được xây bởi **[tên team/pháp nhân]**, một nhóm **[vai trò/ngắn gọn]**
> tại **[địa điểm nếu muốn công khai]**. Team bắt đầu từ câu hỏi **[nguồn gốc ý
> tưởng bằng lời founder]** và đang làm việc cùng **[phụ huynh/giáo viên — chỉ
> ghi khi có bằng chứng/consent]** để chuẩn bị closed beta.

**Press contact:** `[name]` · `[role]` · `[business email]`  
**Website/beta:** `[live URL sau waitlist gate]`

## FAQ

### WonderLens làm gì?

Phụ huynh cùng trẻ chụp một đồ vật; app tạo hành trình tiếng Việt về vật liệu và
cách món đồ được làm, rồi cho lưu vào journal/collection hoặc chia sẻ chủ động.

### AI nằm ở đâu?

Flutter gửi ảnh qua Vercel proxy tới OpenAI. API key chỉ ở server. AI hỗ trợ
nhận diện, journey và media; output live phải có nhãn.

### Ảnh có được lưu không?

Máy chủ WonderLens không lưu ảnh. Cutout/content có thể lưu local trên thiết bị.
OpenAI công bố API abuse-monitoring logs có thể được giữ tối đa 30 ngày ở cấu
hình mặc định. Không nói “ảnh không bao giờ được lưu ở đâu”.

### OpenAI có dùng ảnh để train không?

OpenAI nói dữ liệu API không dùng để train mặc định trừ khi tổ chức opt in.
Release owner vẫn phải xác nhận cấu hình project và cập nhật policy nếu thay đổi.

### App có an toàn cho trẻ không?

Thiết kế là parent co-use, không ads/account/tracking. Prompt/moderation là một
lớp, không phải bảo đảm tuyệt đối; closed beta chỉ mở sau runtime safety review.

### Có phải nội dung giáo khoa đã kiểm chứng không?

Không. Curated content có mức kiểm soát cao hơn; AI-live có thể sai và được gắn
nhãn. WonderLens không thay thế giáo viên, sách giáo khoa hay tư vấn chuyên môn.

### App có social network hoặc profile trẻ không?

Không. Chia sẻ chỉ qua system share sheet khi người lớn chủ động chọn.

### Khi nào có Android beta?

Chưa công bố ngày. Chỉ đưa ngày/link khi core QA, safety/privacy và waitlist
operations pass.

### Business model là gì?

Repo có WonderLens Plus subscription foundation. Giao dịch thật phụ thuộc store
configuration, parental gate và release approval; không mô tả revenue đang có.

## Usage rules

- Không dùng ảnh trẻ thật nếu chưa có consent cho đúng mục đích/channel.
- Không crop logo thành icon mới hoặc thêm badge store chưa đạt.
- Không tuyên bố số tester, conversion, approval hoặc safety pass chưa đo.
- Mọi quote/testimonial phải có nguồn và permission.
- AI/privacy copy phải khớp
  [privacy decision](../release/privacy-age-rating.md).

## Review checklist

- [ ] PM duyệt one-liner và mô tả VI/EN.
- [ ] Script xác nhận copy 50/150 đúng số từ.
- [ ] Founder điền team note, contact, website.
- [ ] Design duyệt logo/icon/gallery.
- [ ] Privacy/safety reviewer duyệt FAQ.
- [ ] Không có ảnh trẻ hoặc claim thiếu bằng chứng.
