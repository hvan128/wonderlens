# WonderLens — Phiếu điền console App Store + Google Play

Trạng thái: hạ tầng build/ký/asset ĐÃ XONG (tự động). File này là toàn bộ phần
việc còn lại — mục A/B là các màn hình console chỉ con người bấm được, theo
đúng thứ tự. Mọi đáp án đã suy ra sẵn từ thực tế app: **không tài khoản, không
quảng cáo, không analytics, không IAP, không tiền; chỉ xử lý ảnh tức thời qua
proxy → OpenAI, không lưu server**.

## Đã xong tự động (recap)

| Hạng mục | Kết quả |
|---|---|
| Bundle ID Apple | `com.wonderlens.wonderlens` — ĐÃ đăng ký trên developer portal (qua API) |
| iOS build | iPhone-only (bỏ iPad → khỏi cần screenshot iPad); `ITSAppUsesNonExemptEncryption=false` (khỏi khai encryption mỗi build) |
| Android ký release | Keystore upload dùng chung (`android/app/upload-keystore.jks` + `android/key.properties`, ngoài git); AAB đã ký đúng SHA-1 `F1:55:...:70:43` |
| Artifact | `app/build/app/outputs/bundle/release/app-release.aab` (71.3MB) ✓; IPA đang build (fastlane `build_ipa`) |
| Privacy policy | https://wonderlens-proxy.vercel.app/privacy (VN+EN, khớp khai báo) — LIVE |
| Support URL | https://wonderlens-proxy.vercel.app/support — LIVE |
| Asset | Icon iOS 15 size + Android 5 mipmap; Play icon 512 `app/store-assets/play-icon-512.png`; feature graphic `app/store-assets/play-feature-graphic-1024x500.png` |
| AD_ID | Manifest AAB KHÔNG có quyền AD_ID → Play khai "No" là khớp |
| fastlane | iOS: `beta`/`release`/`metadata`/`screenshots`/`build_ipa`; Android: `internal`/`production` (SA key dùng chung) |

## A. App Store Connect — appstoreconnect.apple.com

**A1. Tạo app record** (bước chặn — làm trước, ~1 phút):
My Apps → nút `+` → New App:
- Platforms: **iOS**
- Name: **WonderLens**
- Primary Language: **Vietnamese**
- Bundle ID: chọn **com.wonderlens.wonderlens** (đã có sẵn trong dropdown)
- SKU: **com.wonderlens.wonderlens**
- User Access: Full Access
→ Xong bước này **báo tôi** — tôi chạy `fastlane beta` đẩy build lên TestFlight ngay.

**A2. App Information:**
- Category: Primary **Education**, Secondary **Entertainment**
- Content Rights: **không** chứa third-party content
- Age Rating (bảng hỏi): mọi mục **None/No** (không bạo lực, không sexual, không chửi thề, không chất cấm, không cờ bạc, không web không kiểm soát, không thi đấu tiền thật) → kết quả **4+**. KHÔNG bật "Made for Kids".

**A3. App Privacy** (tab App Privacy):
- Privacy Policy URL: `https://wonderlens-proxy.vercel.app/privacy`
- Data Collection: **Yes** → chỉ khai đúng MỘT loại:
  - **Photos or Videos** → purpose **App Functionality** → Linked to user: **No** → Tracking: **No**
- Không khai thêm bất kỳ loại nào (không Name/Email/Location/ID/Diagnostics).

**A4. Pricing and Availability:** Price **0 (Free)**; Availability: Việt Nam (+ nước khác tuỳ bạn).

**A5. Version 1.0 (tab iOS App):**
- Screenshots iPhone 6.7": tôi đang làm — sẽ đẩy bằng `fastlane screenshots`
- Promotional Text/Description/Keywords: dùng bản thảo ở mục C (đẩy được bằng `fastlane metadata` nếu bạn muốn tôi tự điền)
- Support URL: `https://wonderlens-proxy.vercel.app/support`
- Copyright: `© 2026 Ngô Hải Văn`
- App Review Information: điền ghi chú:
  > Không cần đăng nhập. Ứng dụng cần camera thật — vui lòng review trên thiết bị vật lý. Ảnh chụp chỉ dùng nhận diện tức thời qua server trung gian (không lưu trữ). Hình minh hoạ do AI tạo, có bộ lọc an toàn nội dung. App dành cho phụ huynh dùng cùng con.
- Export compliance: KHÔNG hỏi nữa (đã khai trong Info.plist).

**A6.** Add Build (chọn build TestFlight) → Submit for Review.

## B. Google Play Console — play.google.com/console

**B1. Tạo app** (~1 phút): All apps → **Create app**:
- App name: **WonderLens** · Default language: **Tiếng Việt – vi**
- App or game: **App** · Free or paid: **Free** · tick 2 ô cam kết → Create.

**B2. App content (Policy → App content)** — đi từng thẻ:
1. **Privacy policy**: `https://wonderlens-proxy.vercel.app/privacy`
2. **App access**: "All functionality is available without special access"
3. **Ads**: **No, my app does not contain ads**
4. **Content rating**: Start questionnaire → email liên hệ `vuongsky55.cv@gmail.com` → Category: **All Other App Types** → mọi câu trả lời **No** (bạo lực/sex/ngôn từ/ma tuý/cờ bạc: No; user tương tác với nhau: No; chia sẻ vị trí: No; mua hàng kỹ thuật số: No) → Save → rating **Everyone/3+**
5. **Target audience**: Age groups: chọn **18 trở lên** (app định vị cho bố mẹ, dùng cùng con). Câu "Store listing có thể vô tình hấp dẫn trẻ em?" → **Yes** (hình ảnh dễ thương) → Google nhắc tuân thủ guideline: app đạt sẵn (không ads, không thu thập dữ liệu trẻ).
6. **News app**: No
7. **COVID-19 app**: No
8. **Data safety**:
   - Collect or share data? **Yes**
   - Encrypted in transit? **Yes**
   - Cách yêu cầu xoá dữ liệu: chọn không áp dụng — app không lưu dữ liệu người dùng trên server (dữ liệu duy nhất là ảnh, xử lý tức thời)
   - Data types → **Photos and videos → Photos**:
     - Collected: **Yes** · Shared: **No** (OpenAI là service provider xử lý thay — đúng ngoại lệ của Google)
     - Processed ephemerally: **Yes**
     - Required or optional: **Optional** (người dùng chủ động chụp)
     - Purpose: **App functionality**
   - KHÔNG khai loại nào khác.
9. **Government app**: No
10. **Financial features**: **My app doesn't provide any financial features**
11. **Health**: My app does not have any health features
12. **Advertising ID**: **No** (đã xác minh manifest không chứa AD_ID)

**B3. Store listing (Grow → Main store listing):**
- App name: **WonderLens**
- Short description (≤80): `Bố mẹ cùng bé soi đồ vật quanh nhà, khám phá hành trình tạo ra chúng.`
- Full description: bản thảo mục C
- App icon 512: `app/store-assets/play-icon-512.png`
- Feature graphic: `app/store-assets/play-feature-graphic-1024x500.png`
- Phone screenshots: tôi đang làm (đợi bộ 1290×2796, dùng chung với iOS)

**B4. Countries**: Testing/Production → chọn Việt Nam (+ tuỳ).

**B5. Release đầu tiên** (Console bắt buộc làm tay lần đầu):
Test and release → **Internal testing** → Create release → kéo thả file
`app/build/app/outputs/bundle/release/app-release.aab` → Next → Save/Rollout.
Từ lần sau tôi đẩy bằng lệnh `fastlane internal` / `fastlane production`.
- Nếu Play account này chưa có service account fastlane: Users and permissions → mời `fastlane-deploy@hoantien-491209.iam.gserviceaccount.com` với quyền "Release to testing tracks" + "Release to production" (nếu là cùng account với hoantien thì đã có sẵn).
- KHÔNG cần đăng ký SHA-1 (app không dùng Google Sign-In).

**B6.** Khi Internal ổn → Promote lên Production → Submit review.

## C. Bản thảo store listing (dùng cho cả hai store)

**App Store — Subtitle (≤30):** `Soi đồ vật, mở ra hành trình`
**App Store — Keywords (≤100):** `trẻ em,khám phá,đồ vật,giáo dục,hành trình,tò mò,gia đình,học,camera,bé`

**Mô tả (App Store description / Play full description):**

> Mỗi đồ vật quanh nhà đều giấu một hành trình kỳ diệu. Chiếc cốc giấy từng là cái cây. Chiếc thìa inox từng là quặng sắt nằm sâu trong lòng đất.
>
> WonderLens biến câu hỏi "cái này làm từ gì hả mẹ?" thành một chuyến phiêu lưu: bố mẹ cùng bé đưa ống kính lên, chụp một đồ vật, và xem hành trình tạo ra nó hiện lên như một cuốn truyện tranh — từ nguyên liệu thô, qua bàn tay người thợ, đến món đồ trên tay bé.
>
> TÍNH NĂNG
> • Soi mọi đồ vật: chụp là nhận diện, kể chuyện hành trình bằng hình minh hoạ sinh động
> • Giọng kể tiếng Việt ấm áp, bé nghe như nghe kể chuyện
> • Nhật ký khám phá theo ngày — nhìn lại "hôm nay bé đã tò mò những gì"
> • Bộ sưu tập thẻ khám phá để dán, khoe và chia sẻ
> • Không quảng cáo, không tài khoản, không thu thập dữ liệu — dữ liệu của bé nằm ngay trên máy
>
> DÀNH CHO GIA ĐÌNH
> WonderLens sinh ra để bố mẹ và bé dùng CÙNG NHAU — mỗi lần soi là một dịp trò chuyện về thế giới. Ảnh chụp chỉ dùng tức thời để nhận diện đồ vật, không lưu trên máy chủ.
>
> Quyền riêng tư: https://wonderlens-proxy.vercel.app/privacy

**Play — Short description:** `Bố mẹ cùng bé soi đồ vật quanh nhà, khám phá hành trình tạo ra chúng.`

## D. Việc tôi làm tiếp sau khi bạn xong A1/B1

1. `fastlane beta` — đẩy IPA lên TestFlight (cần A1 xong).
2. Bộ screenshot iPhone 6.7" (1290×2796) — render từ app thật, dùng cho cả 2 store.
3. `fastlane metadata` + `fastlane screenshots` — điền text + ảnh vào App Store Connect tự động (nếu bạn muốn).
4. Play: sau khi bạn upload AAB lần đầu (B5), các bản sau tôi đẩy lệnh.

## Câu hỏi chưa chốt

1. Copyright/seller đứng tên: mặc định tôi ghi `© 2026 Ngô Hải Văn` — đổi không?
2. Phát hành thị trường nào ngoài Việt Nam?
3. Play target audience 18+ (định vị bố mẹ) đã chốt theo hướng "gia đình" — nếu sau này muốn vào Families program (badge thân thiện trẻ em) sẽ cần vòng khai báo khác, để bản 1.0 đơn giản trước.
