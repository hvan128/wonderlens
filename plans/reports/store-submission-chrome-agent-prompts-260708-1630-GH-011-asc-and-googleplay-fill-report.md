# WonderLens — Prompt Claude for Chrome: điền nốt console 2 store

Đã tự động hoá xong (KHÔNG điền lại): App Store Connect — build 1.0.0(1) VALID,
mô tả/keywords/subtitle/copyright/category/support URL, 4 screenshot, App Review
contact (Ngô Hải Văn, +84383274914, van.nh120802@gmail.com) + notes. Google Play
— app đã tạo, AAB đã upload Internal testing.

Hai prompt dưới đây dán cho Claude for Chrome. Cả hai ĐỀU dừng trước nút
Submit/Publish cuối để người xác nhận.

Dữ liệu dùng chung:
- Email liên hệ: van.nh120802@gmail.com
- Privacy: https://wonderlens-proxy.vercel.app/privacy
- Support: https://wonderlens-proxy.vercel.app/support
- Bản chất app: KHÔNG tài khoản, KHÔNG quảng cáo, KHÔNG analytics, KHÔNG mua
  hàng trong app, KHÔNG tiền. Chỉ xử lý ẢNH tức thời qua server trung gian →
  OpenAI (không lưu trên server). Nhật ký/bộ sưu tập lưu trên máy. App gia đình
  (bố mẹ dùng cùng bé), KHÔNG thuộc Kids Category/Families.

---

## PROMPT 1 — App Store Connect

```
Bạn giúp tôi điền các mục còn lại cho app WonderLens trên App Store Connect. Tôi đã đăng nhập. Chỉ điền đúng những gì tôi ghi; KHÔNG bấm "Submit for Review" cho tới bước cuối và phải hỏi tôi trước.

Mở https://appstoreconnect.apple.com → My Apps → WonderLens.

A. App Privacy (menu trái, mục "App Privacy"):
1. Nếu chưa có Privacy Policy URL, bấm Edit và điền: https://wonderlens-proxy.vercel.app/privacy
2. Data Collection: chọn "Yes, we collect data from this app".
3. Thêm DUY NHẤT một loại dữ liệu: "Photos or Videos" (nhóm User Content).
   - Purpose: chỉ tick "App Functionality".
   - "Is this data linked to the user's identity?": No.
   - "Is this data used for tracking?": No.
4. KHÔNG thêm bất kỳ loại dữ liệu nào khác (không Contact Info, không Identifiers, không Usage Data, không Diagnostics). Lưu (Publish nếu nó hỏi — đây chỉ là nhãn quyền riêng tư, không phải nộp app).

B. Age Rating (trong tab "General" hoặc mục "Age Rating" của version):
- Mở bảng câu hỏi. Trả lời TẤT CẢ là mức thấp nhất/None/No:
  Violence (cartoon, realistic): None; Sexual Content or Nudity: None; Profanity/Crude Humor: None; Alcohol/Tobacco/Drugs: None; Mature/Suggestive Themes: None; Horror/Fear: None; Gambling: No; Contests: No; Unrestricted Web Access: No; Medical/Treatment Info: No.
- "Made for Kids": để TẮT/No.
- Kết quả kỳ vọng: 4+. Lưu.

C. Pricing and Availability (menu trái):
- Price: chọn 0 (Free / miễn phí).
- Availability: chọn tất cả quốc gia (mặc định), hoặc nếu buộc chọn thì tick Việt Nam. Lưu.

D. Version 1.0 (mục "1.0 Prepare for Submission"):
- Kiểm tra đã có sẵn (do tôi đẩy qua API): mô tả, từ khoá, ảnh chụp màn hình 6.7", subtitle, support URL, bản quyền. KHÔNG sửa các mục này.
- Kéo xuống "Build": nếu chưa gắn build, bấm "+" và chọn build 1.0.0 (1). 
- Nếu hỏi "Export Compliance" / mã hoá: chọn "None of the algorithms..." hoặc trả lời rằng app chỉ dùng mã hoá tiêu chuẩn/HTTPS và được miễn trừ (tương đương đã khai không dùng mã hoá phi tiêu chuẩn).
- App Review Information: KIỂM TRA đã có tên Ngô Hải Văn, điện thoại +84383274914, email van.nh120802@gmail.com và ghi chú review. Nếu trống thì điền:
    First name: Hải Văn | Last name: Ngô | Phone: +84383274914 | Email: van.nh120802@gmail.com
    Notes: "Không cần đăng nhập. Ứng dụng cần camera thật — vui lòng review trên thiết bị vật lý. Ảnh chụp chỉ dùng nhận diện tức thời qua server trung gian (không lưu trữ). Hình minh hoạ do AI tạo, có bộ lọc an toàn nội dung. App dành cho phụ huynh dùng cùng con."
  KHÔNG cần demo account (app không có đăng nhập).

DỪNG LẠI ở đây. Liệt kê cho tôi mọi mục còn thiếu dấu xanh (chưa hoàn tất) và chờ tôi xác nhận. CHỈ khi tôi gõ "submit" thì mới bấm "Add for Review" / "Submit for Review".
```

---

## PROMPT 2 — Google Play Console

```
Bạn giúp tôi điền các khai báo còn lại cho app WonderLens trên Google Play Console. Tôi đã đăng nhập và đã tạo app + upload AAB vào Internal testing. Chỉ điền đúng những gì tôi ghi; KHÔNG bấm nút publish/rollout/gửi duyệt cuối cho tới khi tôi xác nhận.

Mở https://play.google.com/console → chọn app WonderLens.

PHẦN A — App content (menu trái: "Policy and programmes" → "App content"). Làm từng thẻ:

1. Privacy policy: dán https://wonderlens-proxy.vercel.app/privacy → Save.

2. App access: chọn "All functionality is available without special access" → Save.

3. Ads: chọn "No, my app does not contain ads" → Save.

4. Content ratings: Start questionnaire.
   - Email: van.nh120802@gmail.com
   - Category: chọn "All other app types" (KHÔNG phải Game).
   - Trả lời TẤT CẢ câu hỏi là No/None: bạo lực No, nội dung tình dục No, ngôn từ thô tục No, ma tuý/rượu/thuốc lá No, cờ bạc No, nội dung đáng sợ No.
   - Phần tương tác: "Người dùng có tương tác/giao tiếp với nhau không?" No; "Chia sẻ vị trí?" No; "Chia sẻ nội dung do người dùng tạo?" No.
   - "Mua hàng kỹ thuật số?" No.
   - Submit. Kết quả kỳ vọng: Everyone / PEGI 3.

5. Target audience and content:
   - Target age: chọn nhóm "18 trở lên" (18+). (App định vị cho bố mẹ.)
   - "Store listing của bạn có thể vô tình thu hút trẻ em không?" → chọn "Có" (hình ảnh dễ thương). Khi Google hỏi tuân thủ, xác nhận app không thu thập dữ liệu trẻ, không quảng cáo. Save.

6. News app: No.

7. Health apps / COVID-19 contact tracing: No / không áp dụng.

8. Data safety (QUAN TRỌNG):
   - "Does your app collect or share any of the required user data types?": Yes.
   - "Is all of the user data encrypted in transit?": Yes.
   - "Do you provide a way for users to request that their data is deleted?": chọn "No" và giải thích app không lưu dữ liệu người dùng trên máy chủ (ảnh chỉ xử lý tức thời, không lưu). Nếu form bắt buộc URL, dùng https://wonderlens-proxy.vercel.app/privacy.
   - Data types: chỉ chọn nhóm "Photos and videos" → "Photos":
       * Collected: Yes. Shared: No.
       * "Processed ephemerally": Yes.
       * "Required or optional": Optional.
       * Purpose: chỉ tick "App functionality".
   - KHÔNG chọn bất kỳ nhóm dữ liệu nào khác (không Personal info, không Location, không App activity, không Device ID). Save và Submit thẻ này.

9. Government apps: No.

10. Financial features: chọn "My app doesn't provide any financial features".

11. Advertising ID: chọn "No" (app không dùng advertising ID).

PHẦN B — Store listing (menu trái: "Grow" → "Store presence" → "Main store listing"):
- App name: WonderLens
- Short description (tối đa 80 ký tự): 
  Bố mẹ cùng bé soi đồ vật quanh nhà, khám phá hành trình tạo ra chúng.
- Full description: dán đoạn sau —
  Mỗi đồ vật quanh nhà đều giấu một hành trình kỳ diệu. Chiếc cốc giấy từng là cái cây. Chiếc thìa inox từng là quặng sắt nằm sâu trong lòng đất.

  WonderLens biến câu hỏi "cái này làm từ gì hả mẹ?" thành một chuyến phiêu lưu: bố mẹ cùng bé đưa ống kính lên, chụp một đồ vật, và xem hành trình tạo ra nó hiện lên như một cuốn truyện tranh — từ nguyên liệu thô, qua bàn tay người thợ, đến món đồ trên tay bé.

  TÍNH NĂNG
  • Soi mọi đồ vật: chụp là nhận diện, kể chuyện hành trình bằng hình minh hoạ sinh động
  • Giọng kể tiếng Việt ấm áp, bé nghe như nghe kể chuyện
  • Nhật ký khám phá theo ngày
  • Bộ sưu tập thẻ khám phá để dán, khoe và chia sẻ
  • Không quảng cáo, không tài khoản, không thu thập dữ liệu

  Ảnh chụp chỉ dùng tức thời để nhận diện đồ vật, không lưu trên máy chủ.
  Quyền riêng tư: https://wonderlens-proxy.vercel.app/privacy

- App icon: khi cần upload file, DỪNG và nhờ tôi chọn file app/store-assets/play-icon-512.png (512x512).
- Feature graphic: nhờ tôi chọn file app/store-assets/play-feature-graphic-1024x500.png (1024x500).
- Phone screenshots: nhờ tôi chọn 4 file trong app/store-assets/screenshots/ (65_01..65_04). Cần tối thiểu 2 ảnh.
- Save.

PHẦN C — Store settings (menu trái: "Store presence" → "Store settings"):
- App category: Application → Education (danh mục chính). 
- Email liên hệ: van.nh120802@gmail.com. Save.

DỪNG LẠI. Liệt kê cho tôi mọi thẻ trong "App content" và "Dashboard" còn báo chưa hoàn tất (dấu chưa xanh), và chờ tôi xác nhận. KHÔNG tự bấm "Send X for review" / "Publish" / rollout Production. Khi tôi gõ "submit" thì mới promote Internal → Production và gửi duyệt.
```

---

## Sau khi cả hai qua duyệt
- iOS bản sau: `./scripts/build-release.sh` rồi `cd ios && fastlane release` (bump `version:` trong pubspec trước).
- Android bản sau: `./scripts/build-appbundle.sh` rồi `cd android && fastlane internal` (hoặc `production`).

## Câu hỏi chưa chốt
1. Play target audience để 18+ (định vị bố mẹ) — nếu sau muốn huy hiệu "Teacher Approved"/Families sẽ cần vòng khai báo khác.
2. Danh mục ASC hiện Education/Entertainment; Play để Education — giữ nhất quán vậy nhé?
```
