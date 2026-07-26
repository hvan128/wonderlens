# Thiết kế vòng cải thiện lịch sử, cách làm ra và guardrails

**Ngày:** 2026-07-26
**Task:** TASK-024
**Trạng thái:** Approved theo yêu cầu tự động chọn phương án recommended

## Mục tiêu

Làm rõ ba câu hỏi chính của landing page:

1. Đồ vật xuất hiện vì nhu cầu nào và câu chuyện của nó thay đổi ra sao?
2. Nguyên liệu đi qua những bước nào để thành đồ vật đang cầm?
3. Gia đình cần biết giới hạn nào trước khi dùng AI cùng trẻ?

Vòng này giữ nguyên Next.js App Router, Server Components, token, component và
asset curated hiện có. Không thêm dependency, API, form, analytics, client-side
state hoặc claim release/safety mới.

## Phương án

### A. Timeline-first — chọn

Trang đi theo mạch `Nguồn gốc/lịch sử → Cách làm ra → Sau khi dùng`. Một dải
guardrails riêng nằm ngay sau hero để giới hạn sản phẩm không bị chôn cuối trang.
Hướng này khớp câu hỏi cốt lõi “món đồ này từ đâu ra?”, dùng được tốt trên mobile
và tận dụng đúng nội dung/ảnh cốc giấy đã curated.

### B. Hai lăng kính song song

Lịch sử và dây chuyền sản xuất nằm cạnh nhau như hai cột. Desktop dễ so sánh
nhưng mobile phải xếp lại thành hai khối dài, làm đứt mạch thời gian.

### C. Trust-first

Toàn bộ guardrails đứng trước câu chuyện sản phẩm. Minh bạch mạnh nhưng làm giảm
time-to-wow và khiến landing giống trang policy hơn trải nghiệm khoa học.

## Kiến trúc nội dung

```text
SiteHeader
  ├── Hero — lời hứa: vì sao xuất hiện, được làm ra thế nào
  ├── Guardrails — giới hạn thấy sớm
  ├── ObjectHistory — lịch sử curated của cốc giấy
  ├── JourneyGallery — bốn bước sản xuất
  │   └── After-use prompt — câu hỏi tiếp theo, không claim tái chế tuyệt đối
  ├── ProductStory — cách WonderLens đưa vật thật vào câu chuyện
  ├── AppGallery — nhật ký và bộ sưu tập local
  └── FinalCta
SiteFooter
```

Thứ tự này chủ ý đưa nội dung lịch sử/cách làm ra lên trước giải thích tính năng.
Header ưu tiên anchor `#lich-su`, `#cach-lam-ra`, `#rao-chan`; CTA hero đi tới
`#lich-su`. Anchor `#cach-hoat-dong` và `#ung-dung` vẫn tồn tại để không phá link
đã công bố.

## Nội dung lịch sử

`ObjectHistory` dùng duy nhất dữ liệu đã curated tại
`app/assets/content/paper_cup.json`:

- hơn một trăm năm trước, một số nơi công cộng từng dùng chung cốc uống nước;
- cốc giấy dùng một lần dần xuất hiện vì sạch sẽ và tiện hơn;
- ngày nay câu hỏi tiếp tục ở khâu thu gom và tái chế.

Không thêm năm cụ thể, tên nhà phát minh hoặc tuyên bố môi trường chưa có nguồn.
Visual là cutout cốc giấy, màn timeline thật và một đường thời gian bất đối xứng;
không dùng icon/emoji hoặc ba card bằng nhau.

## Nội dung cách làm ra

`JourneyGallery` giữ bốn ảnh thật và bốn bước khớp content source:

1. sợi gỗ từ rừng trồng;
2. gỗ và nước thành bột giấy;
3. ép, sấy thành cuộn giấy;
4. cắt, cuộn, tạo hình và thêm lớp màng mỏng.

Phần kết không gọi mọi cốc giấy là “tái chế được”. Copy mời gia đình xem lớp vật
liệu và làm theo hướng dẫn thu gom tại nơi sống. Đây là câu hỏi học tiếp, không
phải tính năng nhận diện rác địa phương.

## Guardrails

Section `#rao-chan` dùng heading rõ, không núp dưới chữ “trust”. Nội dung gồm:

- **Có người lớn đồng hành:** WonderLens được thiết kế cho phụ huynh/giáo viên
  dùng cùng trẻ 6–10, không phải công cụ để trẻ tự dùng không giám sát.
- **AI luôn có nhãn và có thể sai:** AI-live không thay thế giáo viên, sách giáo
  khoa hoặc nội dung đã kiểm chứng.
- **Luồng ảnh được nói thẳng:** ảnh chụp đi qua Vercel proxy tới AI để nhận diện;
  cutout và bộ sưu tập có thể lưu trên thiết bị. Không nói ảnh “không bao giờ rời
  máy”.
- **Safety chưa được tuyệt đối hoá:** prompt/moderation là một lớp bảo vệ; runtime
  kid-safety audit vẫn chưa hoàn tất, nên chưa tuyên bố family beta/public safety
  pass.
- **Không hồ sơ trẻ, quảng cáo hoặc tracking:** giữ đúng press kit; landing không
  thêm analytics/cookie/form.

Status safety được đặt thành câu riêng có nhãn `Chưa hoàn tất`, không dùng badge
“safe” hoặc icon chiếc khiên.

## Hướng thị giác

- Giữ product cinema sáng, ink xanh đậm, teal là accent và font local
  Baloo 2/Nunito theo `DESIGN.md`.
- Signature mới là “hộ chiếu đồ vật”: cutout cốc giấy nối với ba mốc lịch sử bằng
  một đường teal mảnh. Chỉ một composition táo bạo; phần còn lại dùng khoảng thở
  và divider.
- Guardrails dùng nền ink nhất quán, chữ sáng, nhãn trạng thái màu sunny; không
  tạo lưới card trắng generic.
- Chỉ animate `opacity` và `transform`; không thêm parallax, scroll listener hoặc
  client JavaScript. Tắt motion qua `prefers-reduced-motion`.
- Mobile 375px xếp timeline một cột, bỏ overlap/rotation; touch target giữ 44px.

## Component và token

- Tạo `ObjectHistory` với CSS Module riêng vì đây là boundary nội dung mới.
- Đổi `TrustSection` thành `Guardrails`, giữ data tĩnh trong component.
- Chỉnh `Hero`, `JourneyGallery`, `ProductStory`, `SiteHeader` và thứ tự route.
- Thêm semantic token chỉ khi có vai trò mới như status/caution surface; không
  hardcode màu trùng trong component.
- Tất cả component tiếp tục là Server Components, ảnh qua `next/image`.

## Accessibility và kiểm thử

- Mỗi section dùng `aria-labelledby`; một `h1`, heading không nhảy cấp.
- Timeline lịch sử là danh sách có thứ tự; guardrails là danh sách semantic.
- Alt text mô tả cốc/screenshot; decorative line/cutout phụ dùng `aria-hidden`.
- Test route thật phải bắt được các lỗi: mất section lịch sử, thiếu bốn bước sản
  xuất, chôn/mất guardrail safety, hoặc nav trỏ sai anchor.
- Chạy focused test RED trước production code, sau đó test, lint, build, browser
  375/768/1440, reduced motion, overflow, ảnh và console.

## Tự review spec

- Không có `TODO`, placeholder, fact lịch sử mới hoặc claim safety/release mới.
- Nội dung guardrail khớp PRD, domains, API contracts và press kit.
- Giữ contract route/anchor cũ cần thiết; không đụng Flutter/proxy/schema.
- Scope đủ nhỏ cho một phase TDD và một redeploy production.
- Người dùng đã yêu cầu tự động duyệt recommend, nên phương án A được xem là
  approved.
