# ADR-016: Next.js App Router cho marketing landing

**Status:** Accepted
**Date:** 2026-07-26
**Ref:** TASK-024

## Context

WonderLens có Flutter app, Vercel proxy, promo Remotion và đủ asset product thật,
nhưng chưa có website giới thiệu sản phẩm. Landing cần deploy độc lập trên
Vercel, tải nhanh, SEO tốt, responsive, dùng nhiều ảnh và có component/token tái
sử dụng. Landing không thuộc runtime Flutter và không được mở thêm đường gọi AI,
thu PII hoặc analytics khi chưa có product/privacy decision.

Các hướng được cân nhắc:

1. Next.js App Router, Server Components và CSS Modules.
2. HTML/CSS tĩnh trong `promo/`.
3. Next.js + UI/motion library.

## Decision

Chọn **Next.js App Router + TypeScript** trong `landing-page/`.

- Dùng Next.js `16.2.12` và React `19.2.8`, là bản stable hiện hành khi task bắt
  đầu; pin lockfile và không dùng canary.
- Route marketing mặc định là Server Component, prerender tĩnh. Chỉ thêm Client
  Component khi có tương tác không thể làm bằng HTML/CSS.
- Dùng CSS custom properties trong `src/styles/tokens.css` và CSS Modules. Không
  thêm Tailwind, component kit hoặc motion dependency.
- Dùng `next/image` cho ảnh và `next/font/local` cho font Baloo 2 + Nunito đã
  bundle trong repo. Không tải font remote.
- Copy bộ asset curated cần thiết vào `landing-page/public/`; không symlink ra
  ngoài project vì Vercel phải build thư mục độc lập.
- Test UI bằng Vitest + Testing Library + jsdom. Browser smoke/visual check chạy
  trên build thật trước và sau deploy.
- Deploy trực tiếp thư mục `landing-page/` thành Vercel project riêng.
- Không có API route, form email, cookie, analytics, OpenAI call hoặc secret.
  Privacy/Terms dùng link HTTPS hiện có của proxy.

## Visual decision

Landing dùng “product cinema” tối giản theo tinh thần Apple: typography lớn,
khoảng thở rộng, ảnh sản phẩm thật chiếm vai trò chính, điều hướng mờ cố định và
motion ít nhưng có mục đích. Không sao chép logo, copy hoặc component proprietary
của Apple.

`DESIGN.md` vẫn là nguồn brand:

- Baloo 2 cho wordmark/display; Nunito cho body.
- Canvas sáng, ink xanh đậm, teal/cyan là accent chính.
- Aperture/lens, cutout vật thật và ảnh hành trình là signature.
- Không emoji làm icon/visual vật, không gradient tím SaaS, không card lồng card.

## Consequences

- Repo có thêm Node application độc lập và lockfile riêng.
- Asset product bị duplicate có chủ đích; nguồn marketing được kiểm soát, build
  Vercel không phụ thuộc đường dẫn ngoài project.
- Không có backend nên landing an toàn để deploy nhưng chưa hỗ trợ waitlist.
- Thay asset/copy public phải giữ đúng privacy/safety/release claims trong
  `docs/launch/press-kit.md`.
