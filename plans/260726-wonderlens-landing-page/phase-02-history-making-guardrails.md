# History, Making and Guardrails Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refocus WonderLens landing on object history, how products are made and
explicit family/AI guardrails, then redeploy verified source to production.

**Architecture:** Keep route static and server-rendered. Add one focused
`ObjectHistory` Server Component, replace late generic trust copy with an early
`Guardrails` Server Component, and reorder existing content around a
history-to-making narrative. Reuse curated paper-cup content and current product
assets; CSS custom properties and CSS Modules remain styling boundary.

**Tech Stack:** Next.js 16.2.12 App Router, React 19.2.8, TypeScript, CSS Modules,
`next/image`, Vitest, Testing Library and Vercel.

## Global Constraints

- Vietnamese copy for parents/teachers using WonderLens with children ages 6–10.
- No new dependency, Client Component, API route, form, cookie, analytics,
  OpenAI call or secret.
- Historical copy comes only from `app/assets/content/paper_cup.json`; do not add
  exact dates, inventors or unsupported environmental claims.
- Say camera photos pass through Vercel proxy to AI; never claim photos always
  remain on device.
- Say AI-live can be wrong and runtime kid-safety audit is not complete; never
  claim public/family safety approval.
- Keep `#cach-hoat-dong` and `#ung-dung` anchors compatible.
- Maintain WCAG AA contrast, 44px touch targets, descriptive alt, semantic
  landmarks, 375/768/1440 responsiveness and reduced-motion behavior.
- Branch stays `feature/TASK-024-landing-page`; never push directly to `main`.

---

### Task 1: History-to-making narrative

**Files:**

- Modify: `landing-page/src/app/page.test.tsx`
- Modify: `landing-page/src/app/page.tsx`
- Modify: `landing-page/src/app/layout.tsx`
- Create: `landing-page/src/components/object-history.tsx`
- Create: `landing-page/src/components/object-history.module.css`
- Modify: `landing-page/src/components/hero.tsx`
- Modify: `landing-page/src/components/hero.module.css`
- Modify: `landing-page/src/components/site-header.tsx`
- Modify: `landing-page/src/components/journey-gallery.tsx`
- Modify: `landing-page/src/components/journey-gallery.module.css`
- Modify: `landing-page/src/components/product-story.tsx`
- Modify: `landing-page/src/components/final-cta.tsx`
- Modify: `landing-page/src/styles/tokens.css`

**Interfaces:**

- Produces: `ObjectHistory(): JSX.Element`, section `#lich-su` labelled by
  `history-title`.
- Preserves: `ProductStory()` at `#cach-hoat-dong`, `AppGallery()` at
  `#ung-dung`.
- Updates: `JourneyGallery()` section ID from `#hanh-trinh` to
  `#cach-lam-ra`.

- [ ] **Step 1: Write failing route tests**

Import `within` from Testing Library. Replace old hero/section names and add:

```tsx
it("prioritizes object history and the real manufacturing journey", () => {
  render(<Home />);

  expect(
    screen.getByRole("heading", {
      level: 1,
      name: /mỗi đồ vật đều có một lịch sử để kể/i,
    }),
  ).toBeInTheDocument();
  expect(
    screen.getByRole("link", { name: /xem lịch sử cốc giấy/i }),
  ).toHaveAttribute("href", "#lich-su");
  expect(
    screen.getByRole("link", { name: /cách làm ra/i }),
  ).toHaveAttribute("href", "#cach-lam-ra");

  const history = screen.getByRole("region", {
    name: /hơn một trăm năm trong một chiếc cốc giấy/i,
  });
  expect(
    within(history).getByText(/nhiều người từng dùng chung cốc uống nước/i),
  ).toBeInTheDocument();

  const making = screen.getByRole("region", {
    name: /cách chiếc cốc giấy được làm ra/i,
  });
  expect(within(making).getAllByRole("figure")).toHaveLength(4);
  expect(
    within(making).getByRole("heading", {
      level: 3,
      name: /sau khi dùng, câu chuyện chưa kết thúc/i,
    }),
  ).toBeInTheDocument();
});
```

Update accessible-section test to use new history, making and retained product
flow/gallery headings.

- [ ] **Step 2: Run focused test and prove RED**

Run:

```bash
cd landing-page
npm test -- src/app/page.test.tsx
```

Expected: FAIL because H1, `#lich-su`, `#cach-lam-ra` and history region do not
exist. A configuration/import failure does not count.

- [ ] **Step 3: Implement `ObjectHistory`**

Use `SectionHeading`, `PhoneFrame` and `next/image`. Render an ordered list with
these literal source-backed beats:

```ts
const historyBeats = [
  {
    time: "Hơn một trăm năm trước",
    title: "Một nhu cầu sạch sẽ hơn",
    description:
      "Ở một số nơi công cộng, nhiều người từng dùng chung cốc uống nước.",
  },
  {
    time: "Dần xuất hiện",
    title: "Chiếc cốc dùng một lần",
    description:
      "Để sạch sẽ và tiện hơn, cốc giấy dùng một lần dần xuất hiện.",
  },
  {
    time: "Ngày nay",
    title: "Một câu hỏi mới sau khi dùng",
    description:
      "Gia đình tiếp tục tìm hiểu cách thu gom và tái chế phù hợp tại nơi mình sống.",
  },
];
```

Section heading:

```tsx
<SectionHeading
  eyebrow="Hộ chiếu của một đồ vật"
  headingId="history-title"
  title="Hơn một trăm năm trong một chiếc cốc giấy."
  description="WonderLens kể vì sao một đồ vật xuất hiện trước khi đi vào nguyên liệu và dây chuyền tạo ra nó."
/>
```

Compose paper-cup cutout with `/images/screens/timeline.png`. On mobile, remove
overlap/rotation. Keep image dimensions and `sizes` explicit.

- [ ] **Step 4: Reorder and rewrite route narrative**

Task 1 keeps current `TrustSection` until Task 2. Use this interim order so
TypeScript stays green:

```tsx
<Hero />
<ObjectHistory />
<JourneyGallery />
<ProductStory />
<AppGallery />
<TrustSection />
<FinalCta />
```

Update:

- H1: `Mỗi đồ vật đều có một lịch sử để kể.`
- Hero primary CTA: `Xem lịch sử cốc giấy` → `#lich-su`.
- Hero secondary CTA: `Theo cách chiếc cốc được làm ra` →
  `#cach-lam-ra`.
- Header links: `Lịch sử`, `Cách làm ra`, `Rào chắn`; Task 2 supplies
  `#rao-chan`.
- Journey heading: `Cách chiếc cốc giấy được làm ra.`
- Add a semantic `aside` after four figures with heading
  `Sau khi dùng, câu chuyện chưa kết thúc.` and copy telling families to inspect
  material layers and follow local collection guidance; do not say every paper
  cup is recyclable.
- Move product mechanics after manufacturing while preserving
  `#cach-hoat-dong`.
- Final CTA returns to `#lich-su`.
- Metadata description mentions both history and how objects are made.

- [ ] **Step 5: Run focused test and reach GREEN**

Run:

```bash
cd landing-page
npm test -- src/app/page.test.tsx
```

Expected: new history/manufacturing test PASS. Existing trust behavior remains
green until Task 2.

- [ ] **Step 6: Commit narrative**

```bash
git add landing-page/src
git commit -m "TASK-024: làm rõ lịch sử và cách đồ vật được tạo ra"
```

### Task 2: Explicit early guardrails

**Files:**

- Modify: `landing-page/src/app/page.test.tsx`
- Modify: `landing-page/src/app/page.tsx`
- Create: `landing-page/src/components/guardrails.tsx`
- Create: `landing-page/src/components/guardrails.module.css`
- Delete: `landing-page/src/components/trust-section.tsx`
- Delete: `landing-page/src/components/trust-section.module.css`
- Modify: `landing-page/src/styles/tokens.css`

**Interfaces:**

- Produces: `Guardrails(): JSX.Element`, section `#rao-chan` labelled by
  `guardrails-title`.
- Consumes: static route composition and `SectionHeading`.

- [ ] **Step 1: Write failing guardrail test**

Add:

```tsx
it("puts explicit family and AI guardrails before the story", () => {
  const { container } = render(<Home />);

  const guardrails = screen.getByRole("region", {
    name: /giới hạn được nói rõ, không giấu ở cuối trang/i,
  });
  expect(
    within(guardrails).getByText(/không phải công cụ để trẻ tự dùng/i),
  ).toBeInTheDocument();
  expect(
    within(guardrails).getByText(/ảnh chụp đi qua proxy tới AI/i),
  ).toBeInTheDocument();
  expect(
    within(guardrails).getByText(/AI-live có thể sai/i),
  ).toBeInTheDocument();
  expect(
    within(guardrails).getByText(/runtime kid-safety audit chưa hoàn tất/i),
  ).toBeInTheDocument();

  const sectionIds = Array.from(
    container.querySelector("main")?.children ?? [],
    (section) => section.id,
  );
  expect(sectionIds.indexOf("rao-chan")).toBeLessThan(
    sectionIds.indexOf("lich-su"),
  );
});
```

This catches a missing, euphemistic or buried guardrail section.

- [ ] **Step 2: Run focused test and prove RED**

Run:

```bash
cd landing-page
npm test -- src/app/page.test.tsx
```

Expected: FAIL because region `#rao-chan` and explicit safety status do not
exist.

- [ ] **Step 3: Implement `Guardrails`**

Render a section immediately after hero. Use one ruled semantic list, not equal
card grid:

```ts
const guardrails = [
  {
    title: "Người lớn cùng tham gia",
    description:
      "WonderLens được thiết kế để phụ huynh hoặc giáo viên dùng cùng trẻ 6–10 tuổi, không phải công cụ để trẻ tự dùng không giám sát.",
  },
  {
    title: "AI-live luôn có nhãn",
    description:
      "AI-live có thể sai và không thay thế giáo viên, sách giáo khoa hay nội dung đã kiểm chứng.",
  },
  {
    title: "Luồng ảnh được nói thẳng",
    description:
      "Ảnh chụp đi qua proxy tới AI để nhận diện; cutout và bộ sưu tập có thể lưu trên thiết bị.",
  },
  {
    title: "Không hồ sơ trẻ, quảng cáo hay tracking",
    description:
      "Landing không có form, cookie hoặc analytics; trải nghiệm được giới thiệu không cần tài khoản trẻ.",
  },
];
```

Heading:

```tsx
<SectionHeading
  eyebrow="Rào chắn trước khi bắt đầu"
  headingId="guardrails-title"
  title="Giới hạn được nói rõ, không giấu ở cuối trang."
  description="WonderLens là khoảnh khắc cùng học, không phải mạng xã hội hay chương trình khoa học đã kiểm chứng."
/>
```

Add a labelled status note containing:
`Chưa hoàn tất — runtime kid-safety audit chưa hoàn tất; prompt và moderation
chỉ là một lớp bảo vệ, chưa phải safety pass.`

- [ ] **Step 4: Replace late trust section and style**

Import `Guardrails` in `page.tsx`, place it immediately after `Hero`, delete
`TrustSection` files/import. Use semantic tokens for status/surface if needed.
CSS must:

- keep normal text contrast ≥ 4.5:1;
- use dividers rather than four floating cards;
- keep status visible without color alone;
- collapse two-column desktop layout to one column below 64rem;
- animate only opacity/transform and honor reduced motion.

- [ ] **Step 5: Run focused and full tests**

Run:

```bash
cd landing-page
npm test -- src/app/page.test.tsx
npm test
```

Expected: focused test and all test files PASS.

- [ ] **Step 6: Commit guardrails**

```bash
git add landing-page/src
git commit -m "TASK-024: đưa guardrails lên đầu landing"
```

### Task 3: Review, verify and redeploy

**Files:**

- Modify: `tasks/TASK-024-landing-page.md`
- Modify: `plans/260726-wonderlens-landing-page/plan.md`
- Modify: `plans/260726-wonderlens-landing-page/phase-02-history-making-guardrails.md`
- Modify: `landing-page/README.md`
- Modify: `README.md`

**Interfaces:**

- Consumes: source commits from Tasks 1–2.
- Produces: verified production deployment and updated PR #9.

- [ ] **Step 1: Run local quality gates**

From `landing-page/`:

```bash
npm test
npm run lint
npm run build
```

From repo root:

```bash
git diff --check
git status --short
```

Expected: all exit 0; only intended iteration files are modified.

- [ ] **Step 2: Run local production browser review**

Start `npm start` from successful build. At 375×812, 768×1024 and 1440×1000
verify:

- no horizontal overflow;
- history precedes manufacturing, product flow and collection;
- guardrails precede history in DOM and remain readable;
- all images complete with non-zero natural dimensions;
- anchor `#lich-su`, `#cach-lam-ra`, `#rao-chan`, `#cach-hoat-dong`,
  `#ung-dung` resolve;
- no console/page error;
- reduced motion removes long animation/transition.

- [ ] **Step 3: Review against sources and design**

Compare every claim against `paper_cup.json`, PRD risk table, Domain 6 and press
kit FAQ. Review modified UI against `DESIGN.md`, design spec, anti-slop rules and
performance guardrails. Fix concrete findings, rerun focused gates, then request
final code review.

- [ ] **Step 4: Commit verified implementation and push**

Update iteration checkboxes/evidence, mark phase complete only after local gates.
Commit:

```bash
git add tasks/TASK-024-landing-page.md \
  plans/260726-wonderlens-landing-page \
  landing-page/README.md README.md
git commit -m "TASK-024: ghi nhận kiểm chứng landing cải tiến"
git push origin feature/TASK-024-landing-page
```

Confirm PR #9 still OPEN and points at pushed HEAD; do not create a duplicate PR.

- [ ] **Step 5: Deploy exact pushed source**

From `landing-page/`, deploy project `sireals-projects/wonderlens-landing` with
production metadata `gitCommitSha=<pushed HEAD>`. Wait for READY; do not alter
proxy/app deployments.

- [ ] **Step 6: Smoke production and record evidence**

Verify production alias and immutable URL:

- `/` returns 200;
- nonexistent path returns branded 404;
- core history/journey/screen images return 200;
- DOM headings and guardrail status match approved copy;
- 375/768/1440 browser checks repeat without overflow, broken images or console
  error;
- deployment metadata source SHA equals pushed HEAD.

Update deployment ID, immutable URL, source SHA and evidence in TASK/READMEs.
Commit and push evidence, then redeploy that final documentation-only source so
production metadata matches final branch HEAD. Repeat root/404/core image smoke
and one desktop browser check.

## Risks and rollback

- History copy may drift from curated content. Mitigation: literal source-backed
  beats and source review before deploy.
- Guardrails may read like a safety certification. Mitigation: explicit
  `Chưa hoàn tất` status and prohibited safety-pass claim.
- Added section increases page weight only by markup/CSS; no new asset or client
  JavaScript. Existing image optimization remains.
- If final deployment fails, production alias keeps last READY deployment while
  branch/PR remains reviewable; no app, proxy or user data changes.
