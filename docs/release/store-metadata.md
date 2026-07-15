# Store metadata và screenshot handoff

**Jira:** [KAN-32](https://aichoem.atlassian.net/browse/KAN-32)  
**Owner:** Hoàng Hiệp  
**Trạng thái:** Copy + result/timeline assets ready; camera screenshot còn thiếu  
**Cập nhật:** 2026-07-15

## Positioning

- Audience: phụ huynh dùng cùng trẻ 6–10 tuổi.
- Category đề xuất: Education; secondary Entertainment nếu store cho phép.
- Không dùng “For Kids/For Children” trên App Store khi chưa chọn Kids Category.
- Không hứa “offline” cho camera production hiện tại.
- Không hứa “không thu thập dữ liệu”; nói chính xác no account/ads/tracking và
  ảnh được xử lý qua OpenAI.

## Metadata tiếng Việt

| Field | Copy |
|---|---|
| App name | `WonderLens` |
| App Store subtitle | `Soi đồ vật, mở ra hành trình` |
| Google Play short description | `Bố mẹ cùng bé soi đồ vật, khám phá hành trình tạo ra chúng.` |
| App Store keywords | `trẻ em,khám phá,đồ vật,giáo dục,hành trình,tò mò,gia đình,học,camera,bé` |
| Primary category | Education |
| Support URL | `https://wonderlens-proxy.vercel.app/support` |
| Privacy URL | `https://wonderlens-proxy.vercel.app/privacy` |

### Full description

Mỗi đồ vật quanh nhà đều giấu một hành trình. Chiếc cốc giấy bắt đầu từ sợi gỗ;
chiếc thìa kim loại từng là khoáng vật trong lòng đất.

WonderLens giúp bố mẹ cùng bé đưa ống kính lên, chụp một món đồ và xem câu
chuyện nó được tạo ra như thế nào — từ nguyên liệu, qua các bước chế tạo, đến
món đồ trong tay.

TÍNH NĂNG

• Chụp đồ vật và xem hành trình bằng tiếng Việt dễ hiểu  
• Hình minh hoạ, giọng kể và video ngắn có fallback khi mạng yếu  
• Nhật ký khám phá theo ngày, lưu ngay trên thiết bị  
• Bộ sưu tập thẻ vật liệu để bố mẹ và bé cùng nhìn lại  
• Chủ động tạo thẻ chia sẻ qua bảng chia sẻ của điện thoại

DÀNH CHO GIA ĐÌNH

WonderLens được thiết kế để phụ huynh dùng cùng trẻ 6–10 tuổi. Ứng dụng không có
tài khoản, quảng cáo hay tracking. Khi bạn chụp, ảnh được gửi qua máy chủ
WonderLens tới OpenAI để nhận diện và tạo hành trình; máy chủ WonderLens không
lưu ảnh. Hãy tránh chụp khuôn mặt hoặc thông tin cá nhân.

Nội dung sinh bởi AI được gắn nhãn và có thể cần phụ huynh kiểm tra. WonderLens
không thay thế sách giáo khoa hoặc lời khuyên chuyên môn.

Quyền riêng tư: https://wonderlens-proxy.vercel.app/privacy

## App Review notes

> WonderLens không cần đăng nhập. Core flow cần camera thật và kết nối mạng:
> mở app → cho phép camera → chụp một đồ vật → đợi kết quả → mở hành trình.
> Ảnh được gửi qua Vercel proxy tới OpenAI; proxy không lưu ảnh. Nội dung AI có
> nhãn và guardrails. Nhật ký/collection lưu local. Purchase và restore nằm
> trong khu phụ huynh, có parental gate. Vui lòng review trên thiết bị vật lý.

Không ghi “mọi câu hỏi age rating = No” như một script cứng. Release owner phải
trả lời theo capability đúng của build, gồm external links, IAP và AI content.

## Screenshot audit hiện tại

Sáu file hiện có đều `1290 × 2796`, là một kích thước portrait được Apple chấp
nhận cho nhóm iPhone 6.9-inch hiện hành. Tên `65_*` là legacy và không phản ánh
slot thực tế. Tool mirror cùng bộ sang `app/ios/fastlane/screenshots/vi/`.

| File | Nội dung đã kiểm tra | Kết quả so với KAN-32 |
|---|---|---|
| `app/store-assets/screenshots/65_01-home.png` | Home/journal | Dùng được, nhưng không mở core story |
| `app/store-assets/screenshots/65_02-day-detail.png` | Đồ vật theo ngày | Dùng bổ sung |
| `app/store-assets/screenshots/65_03-collection.png` | Rương khám phá | Đạt collection/learning |
| `app/store-assets/screenshots/65_04-profile.png` | Hồ sơ/huy hiệu | Dùng bổ sung |
| `app/store-assets/screenshots/65_05-result.png` | Result + cutout + nhãn AI | Đạt result/AI label |
| `app/store-assets/screenshots/65_06-timeline.png` | Timeline/story từ widget thật | Đạt learning journey |

Thiếu ảnh camera hardware/permission từ build thật. Vì vậy asset repo đã phủ
result, AI label, timeline và collection nhưng **chưa đạt trọn KAN-32**.

## Storyboard screenshot đề xuất

| Thứ tự | Headline | Màn app thật | Yêu cầu QA |
|---:|---|---|---|
| 1 | `Soi một đồ vật quanh bé` | Camera với đồ vật, không có mặt/người | Permission/camera chrome thật |
| 2 | `AI nhận ra — hành trình mở ra` | `65_05-result.png` | Đã có nhãn AI |
| 3 | `Từ nguyên liệu đến món đồ` | `65_06-timeline.png` | Đã có; PM chọn frame/copy |
| 4 | `Nghe câu chuyện theo từng chặng` | Timeline audio/media fallback | Không dùng waveform giả |
| 5 | `Cất mỗi khám phá vào rương` | Collection screenshot hiện có | Cutout, không emoji hero |
| 6 | `Bố mẹ đồng hành, dữ liệu tối giản` | Privacy/profile/parent controls | Copy khớp policy |

Screenshot phải là UI thật của build gửi review. Marketing text/frame được phép
thêm nếu không che UI hoặc mô tả chức năng chưa có. Không dùng ảnh trẻ thật nếu
chưa có consent rõ.

## Asset manifest

| Asset | Path | Trạng thái |
|---|---|---|
| Brand logo | `app/assets/images/brand_logo.png` | Có |
| iOS 1024 icon | `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | Có |
| Play icon 512 | `app/store-assets/play-icon-512.png` | Có, 512×512 |
| Play feature graphic | `app/store-assets/play-feature-graphic-1024x500.png` | Có, 1024×500 |
| Store screenshots | `app/store-assets/screenshots/` | 6 ảnh đúng size; thiếu camera hardware |
| Fastlane copy screenshots | `app/ios/fastlane/screenshots/vi/` | Mirror đủ 6 ảnh |
| Promo video | `promo/wonderlens-promo/wonderlens-promo.mp4` | Có |
| Promo poster | `promo/wonderlens-promo/poster.png` | Có |

## AI/privacy labels dùng trong marketing

- Ngắn: `Hành trình do AI hỗ trợ — bố mẹ cùng kiểm tra nhé.`
- Camera note: `Tránh chụp khuôn mặt hoặc thông tin cá nhân.`
- Privacy badge: `Không tài khoản · Không quảng cáo · Không tracking`.
- Không dùng: `100% chính xác`, `an toàn tuyệt đối`, `không thu thập dữ liệu`,
  `AI đã kiểm chứng mọi nội dung`.

## Metadata QA

- [ ] Name ≤ 30 ký tự.
- [ ] Subtitle ≤ 30 ký tự.
- [ ] Keywords ≤ 100 bytes/characters theo console locale.
- [ ] Play short description ≤ 80 ký tự.
- [ ] Copy không chứa “For Kids/For Children” nếu không Kids Category.
- [ ] Privacy wording khớp [privacy decision](privacy-age-rating.md).
- [ ] Screenshot 1–3 kể được camera → result → timeline.
- [ ] Có nhãn AI ở ít nhất một màn live.
- [ ] Tất cả screenshot lấy từ build đang submit, không lộ dev panel/token.
- [ ] PM review asset/copy; legal review privacy/child claims.
- [ ] Release owner kiểm tra kích thước lại trên tài liệu Apple tại ngày upload.

## Nguồn chính thức

- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple upload previews/screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots)
- [Apple app information/metadata limits](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Google Play metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842?hl=en)
- [Google store listing best practices](https://support.google.com/googleplay/android-developer/answer/13393723?hl=en)

## Sign-off

| Hạng mục | Owner | Trạng thái |
|---|---|---|
| Copy | PM | Pending |
| Privacy/age wording | PM + legal | Pending |
| Screenshot core flow | Design/release | Result/timeline ready; camera missing |
| Icon final | PM | Pending visual approval |
| Console upload | Release owner | External action |
