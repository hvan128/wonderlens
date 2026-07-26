# Phase 01 — Build, verify and deploy

### Task 1: Build and deploy WonderLens landing page

## Context

- [TASK-024](../../tasks/TASK-024-landing-page.md)
- [ADR-016](../../adrs/ADR-016-nextjs-marketing-landing.md)
- [Design spec](../../docs/superpowers/specs/2026-07-26-wonderlens-landing-design.md)
- [Visual source](../../DESIGN.md)

## Files

- Create: `landing-page/package.json`, Next.js/TypeScript/ESLint/Vitest config.
- Create: `landing-page/src/app/{layout,page,not-found}.tsx`.
- Create: `landing-page/src/styles/{tokens,globals}.css`.
- Create: `landing-page/src/components/*.tsx` and matching CSS Modules.
- Create: `landing-page/src/app/page.test.tsx`,
  `landing-page/src/components/button-link.test.tsx`.
- Create: curated files under `landing-page/public/images/` and
  `landing-page/src/assets/fonts/`.
- Modify: `AGENTS.md`, `specs/domains.md`, `README.md`, TASK-024.

## Interfaces

- `ButtonLink({ href, children, variant?: 'primary' | 'secondary',
  ariaLabel?: string })`
- `SectionHeading({ eyebrow, title, description?, align?: 'start' | 'center' })`
- `PhoneFrame({ src, alt, priority?, className? })`
- `Brand({ compact?: boolean })`

## Steps

- [ ] **1. Scaffold setup only**

  Run non-interactive `create-next-app` for `landing-page/` with TypeScript,
  App Router, ESLint, `src/`, npm and no Tailwind. Remove demo production page
  before starting TDD. Pin Next/React versions from ADR-016.

- [ ] **2. Copy curated assets**

  Copy exact source files named in design spec. Preserve original files. Put
  marketing copies under `public/images/{brand,objects,journey,screens}` and local
  fonts under `src/assets/fonts/`.

- [ ] **3. RED — page behavior**

  Add Vitest/Testing Library config and `page.test.tsx`. Test must render real
  page and fail because page implementation is absent. Assertions:

  ```tsx
  expect(screen.getByRole('heading', {
    level: 1,
    name: /mọi đồ vật đều có một câu chuyện khoa học/i,
  })).toBeInTheDocument()
  expect(screen.getByRole('link', {
    name: /xem cách wonderlens hoạt động/i,
  })).toHaveAttribute('href', '#cach-hoat-dong')
  expect(screen.getByRole('navigation', {
    name: /điều hướng chính/i,
  })).toBeInTheDocument()
  expect(screen.getByText(/không tài khoản trẻ/i)).toBeInTheDocument()
  ```

  Run `npm test -- page.test.tsx`; expected FAIL for missing page/component
  behavior, not config error.

- [ ] **4. GREEN — token system and shared components**

  Implement tokens, global styles, `Brand`, `SiteHeader`, `ButtonLink`,
  `SectionHeading`, `PhoneFrame`, `SiteFooter`. Add focused `ButtonLink` test
  before its production implementation and observe RED, then GREEN.

- [ ] **5. GREEN — landing route**

  Implement hero, product story, journey gallery, app gallery, trust section and
  final CTA using shared components and curated assets. Keep route as Server
  Component and use `next/image`. Run focused tests until GREEN.

- [ ] **6. Metadata and fallback**

  Add Vietnamese metadata, OG asset, skip link, semantic layout and branded 404.
  Add no API route or runtime fetch.

- [ ] **7. Verification**

  Run:

  ```bash
  npm test
  npm run lint
  npm run build
  git diff --check
  ```

  Start production server. Browser-check 375×812, 768×1024 and 1440×1000;
  verify keyboard focus, reduced motion, no horizontal overflow, no broken image
  and no serious console error.

- [ ] **8. Docs and review**

  Update `AGENTS.md`, `specs/domains.md`, root `README.md` and TASK-024 with
  verified commands. Review against design spec, anti-slop checklist and AC.

- [ ] **9. Production deploy**

  Link/deploy `landing-page/` as separate Vercel project. Inspect deployment
  until READY, smoke `/`, scan recent error logs and repeat browser check on
  production URL. Record URL and deployment evidence in TASK-024/README.

## Risks and rollback

- Large source PNGs increase upload/image transform work. Mitigation: only hero
  assets eager; below-fold images lazy through `next/image`.
- Marketing copy could overstate privacy/release. Mitigation: copy from press kit
  and TASK-024 trust rules.
- Production deploy can fail from Vercel auth/project naming. Rollback: keep last
  READY deployment; code/build remains local and no proxy/app state changes.
