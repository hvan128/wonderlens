# Thiết kế landing page WonderLens

**Ngày:** 2026-07-26
**Task:** TASK-024
**Trạng thái:** Approved theo yêu cầu tự động chọn phương án recommended

## Bối cảnh và mục tiêu

WonderLens cần một trang giới thiệu cho phụ huynh, giáo viên và người xem beta.
Một trang phải trả lời nhanh ba câu hỏi: sản phẩm làm gì, trải nghiệm trông ra
sao, và gia đình nên tin điều gì. Trang không thu email hoặc hứa lịch phát hành
vì repo chưa có CRM, consent flow hay release approval.

## Phương án

### 1. Product cinema — chọn

Trang cuộn một cột, hero bất đối xứng, ảnh sản phẩm lớn, screenshot điện thoại
được dàn như vật thể và một chương ảnh kể hành trình cốc giấy. Ưu điểm: premium,
ít chữ, chứng minh sản phẩm bằng asset thật, tải tốt khi giữ Server Components.

### 2. App Store gallery

Hero thiết bị ở giữa, carousel screenshot và CTA tải app lặp lại. Dễ hiểu nhưng
phụ thuộc store link/rating chưa được release owner xác nhận và dễ thành template.

### 3. Science lab tương tác

Nhiều motion, parallax và vật thể kéo/thả. Đúng chất khám phá nhưng tăng JavaScript,
rủi ro hiệu năng/mobile và vượt yêu cầu landing đơn giản.

## Hướng thị giác

- **Chủ thể:** ứng dụng camera STEM Việt cho phụ huynh dùng cùng trẻ 6–10.
- **Tone:** refined, sáng, tò mò; tối giản kiểu Apple nhưng ấm và vui hơn.
- **Màu:** canvas `#F4FBFC`, paper `#FFFDF7`, ink `#0B1830`, teal `#0E97AC`,
  cyan `#22D3EE`, sky `#38BDF8`, sunny `#FFC857`, grape `#B794F4`.
- **Type:** Baloo 2 ExtraBold cho wordmark/display; Nunito 400–900 cho nội dung.
- **Layout:** split hero; chapter cuộn xen kẽ copy và thiết bị; gallery lệch nhịp
  thay vì ba card bằng nhau.
- **Signature:** logo aperture mở ra một quỹ đạo cutout vật thật quanh cặp màn
  result/timeline. Đây là điểm táo bạo duy nhất; phần còn lại giữ kỷ luật.
- **Motion:** reveal bằng opacity/transform và hover/press 180–360ms; không
  continuous animation; giảm hoặc tắt khi `prefers-reduced-motion`.
- **Copy voice:** ngắn, cụ thể, tiếng Việt; nói với phụ huynh bằng giọng bình tĩnh.

## Kiến trúc trang

```text
src/app/layout.tsx
  ├── SiteHeader
  ├── route /
  │   ├── Hero
  │   ├── ProductStory
  │   ├── JourneyGallery
  │   ├── AppGallery
  │   ├── TrustSection
  │   └── FinalCta
  └── SiteFooter
```

Trang dùng Server Components. Anchor navigation tới `#cach-hoat-dong`,
`#hanh-trinh`, `#ung-dung`; CTA chính cuộn tới phần demo sản phẩm. Privacy và
Terms mở các trang pháp lý hiện có.

## Design tokens và component

`tokens.css` sở hữu primitive và semantic token:

- color/surface/text/accent;
- type family/size/line-height;
- space 4–128;
- radius 12–40/pill;
- shadow/elevation;
- motion duration/easing;
- z-index base/sticky/overlay.

Component dùng chung:

- `Brand`: logo + wordmark;
- `SiteHeader`: nav, CTA, sticky glass;
- `ButtonLink`: primary/secondary và external-safe props;
- `SectionHeading`: eyebrow, heading, description;
- `PhoneFrame`: khung screenshot có `next/image`;
- `SiteFooter`: brand, trạng thái beta, legal links.

Component chỉ nhận semantic props; màu/spacing lấy từ token, không hardcode.

## Nội dung và asset

Asset curated:

- `brand_logo.png`;
- cutout cốc giấy, bút bi, thước, chai nhựa và kẹp giấy;
- `onboarding_scene.jpg`;
- bốn ảnh `paper_cup_stage0..3`;
- sáu screenshot store production;
- Play feature graphic làm social preview khi phù hợp.

Không dùng ảnh trẻ thật, stock photo, emoji làm vật, testimonial hoặc rating giả.
Ảnh dưới fold lazy load; hero screenshot/cutout quan trọng có kích thước cố định
để tránh CLS.

## Responsive và accessibility

- 375px: một cột, bỏ overlap/rotation mạnh, nav phụ ẩn nhưng CTA còn 44px.
- 768px: gallery hai cột, hero vẫn ưu tiên copy trước.
- 1024px+: split hero và composition bất đối xứng.
- Semantic `header/nav/main/section/footer`, một `h1`, heading không nhảy cấp.
- Skip link, focus ring rõ, contrast WCAG AA, alt mô tả nội dung.
- Không khóa zoom, không horizontal overflow, hỗ trợ reduced motion.

## Error và fallback

Trang không fetch runtime. Ảnh có kích thước/aspect ratio ổn định; source asset
được kiểm tra trong test/build. Font local có fallback `ui-rounded, sans-serif`.
External legal link dùng HTTPS. Nếu JavaScript tắt, toàn bộ nội dung và anchor
navigation vẫn hoạt động.

## Kiểm thử

- Vitest/Testing Library: landmarks, heading, CTA anchors, trust copy, alt text và
  shared components.
- `next lint` qua ESLint script, TypeScript trong `next build`.
- Browser: 375×812, 768×1024, 1440×1000; keyboard, reduced motion, console,
  overflow và ảnh hỏng.
- Production: Vercel READY, `/` trả 200, metadata/OG hiện đúng.

## Tự review spec

- Không có placeholder, form/analytics/backend ngầm hoặc claim chưa có bằng chứng.
- Kiến trúc khớp TASK-024 và ADR-016.
- Scope một app tĩnh, một route public; đủ nhỏ để triển khai trong một plan.
- Người dùng đã yêu cầu tự động duyệt phương án recommended, nên phương án 1 được
  coi là approved và chuyển thẳng sang plan.
