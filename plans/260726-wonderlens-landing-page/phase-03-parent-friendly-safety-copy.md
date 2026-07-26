# Parent-Friendly Safety Copy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace internal safety/audit language on the landing page with warm,
accurate Vietnamese copy that tells parents what protections exist and how to
use WonderLens with children.

**Architecture:** Keep the static Server Component structure and `#rao-chan`
anchor. Change only public copy, navigation/footer labels and route tests; retain
the internal F-08 risk in PRD/release docs.

**Tech Stack:** Next.js 16.2.12 App Router, React 19.2.8, TypeScript, CSS Modules,
Vitest, Testing Library and Vercel.

## Global Constraints

- Public copy is Vietnamese for parents/teachers using WonderLens with children
  ages 6–10.
- Do not claim a completed audit, certification or absolute safety.
- Say AI can be wrong, AI-assisted content is labeled, and photos are sent to an
  AI service for recognition.
- Do not show `runtime`, `kid-safety audit`, `safety pass`, `prompt`,
  `moderation`, `proxy`, `tracking`, `cookie`, `analytics` or `AI-live`.
- Keep `#rao-chan`, semantic landmarks, Server Components, current CSS/tokens and
  all existing assets.
- Add no dependency, API route, form, cookie, analytics, Client Component or
  runtime fetch.
- Branch remains `feature/TASK-024-landing-page`; never push directly to `main`.

---

### Task 1: Parent-facing trust language

**Files:**

- Modify: `landing-page/src/app/page.test.tsx`
- Modify: `landing-page/src/app/not-found.test.tsx`
- Modify: `landing-page/src/components/guardrails.tsx`
- Modify: `landing-page/src/components/site-header.tsx`
- Modify: `landing-page/src/components/site-footer.tsx`

**Interfaces:**

- Preserves: `Guardrails(): JSX.Element`, region `#rao-chan` labelled by
  `guardrails-title`.
- Preserves: `SiteHeader({ sectionHrefPrefix })` and all existing section hrefs.
- Produces: public Vietnamese copy defined by
  `docs/superpowers/specs/2026-07-26-parent-friendly-safety-copy-design.md`.

- [x] **Step 1: Write the failing route tests**

Replace the old guardrail assertions with:

```tsx
const safety = screen.getByRole("region", {
  name: /cùng con khám phá, với những lớp bảo vệ rõ ràng/i,
});

expect(
  within(safety).getByText(/có các lớp kiểm tra an toàn/i),
).toBeInTheDocument();
expect(
  within(safety).getByText(/nội dung do AI hỗ trợ.*luôn có nhãn/i),
).toBeInTheDocument();
expect(
  within(safety).getByText(/AI đôi khi có thể nhầm/i),
).toBeInTheDocument();
expect(
  within(safety).getByText(/ảnh chụp được gửi tới dịch vụ AI/i),
).toBeInTheDocument();
expect(
  within(safety).getByText(/không cần tài khoản trẻ.*không quảng cáo/i),
).toBeInTheDocument();
expect(safety).not.toHaveTextContent(
  /runtime|kid-safety|safety pass|prompt|moderation|proxy|tracking|cookie|analytics|AI-live/i,
);
```

Assert the home and not-found header link:

```tsx
expect(
  screen.getByRole("link", { name: "An tâm khám phá" }),
).toHaveAttribute("href", "/#rao-chan");
```

Use `#rao-chan` without `/` on the home route.

- [x] **Step 2: Run tests and prove RED**

Run:

```bash
cd landing-page
npm test -- src/app/page.test.tsx src/app/not-found.test.tsx
```

Expected: FAIL because the current route still renders `Rào chắn`, audit jargon
and the old accessible section name.

- [x] **Step 3: Implement the approved copy**

Use these section values:

```tsx
<SectionHeading
  eyebrow="Để bố mẹ an tâm"
  headingId="guardrails-title"
  title="Cùng con khám phá, với những lớp bảo vệ rõ ràng."
  description="WonderLens ưu tiên những câu chuyện ngắn, phù hợp lứa tuổi và giúp bố mẹ biết khi nào AI tham gia."
/>
```

Use this status aside:

```tsx
<aside className={styles.status} aria-label="Các lớp kiểm tra an toàn">
  <p className={styles.statusLabel}>Các lớp kiểm tra an toàn</p>
  <p>
    <strong>Có các lớp kiểm tra an toàn.</strong> Đồ vật quen thuộc dùng câu
    chuyện đã tuyển chọn; nội dung do AI hỗ trợ được giới hạn theo lứa tuổi và
    luôn có nhãn rõ ràng.
  </p>
  <p className={styles.statusDetail}>
    AI đôi khi có thể nhầm. Bố mẹ hoặc giáo viên hãy cùng trẻ xem, đặt câu hỏi
    và kiểm tra lại khi cần.
  </p>
</aside>
```

Replace the four list items with:

```ts
const guardrails = [
  {
    title: "Bố mẹ cùng con khám phá",
    description:
      "WonderLens được thiết kế cho những phút cùng học: bố mẹ hoặc giáo viên cùng trẻ 6–10 tuổi quan sát, đặt câu hỏi và kiểm tra lại điều thú vị.",
  },
  {
    title: "Nội dung phù hợp lứa tuổi",
    description:
      "Câu chuyện ngắn, gần gũi; WonderLens đặt giới hạn để tránh nội dung nguy hiểm, bạo lực hoặc không phù hợp với trẻ.",
  },
  {
    title: "Biết rõ khi AI tham gia",
    description:
      "Nội dung do AI hỗ trợ luôn có nhãn. AI có thể nhầm và không thay thế giáo viên hay sách đã được kiểm chứng.",
  },
  {
    title: "Riêng tư được nói rõ",
    description:
      "Không cần tài khoản trẻ, không quảng cáo, không theo dõi hành vi. Ảnh chụp được gửi tới dịch vụ AI để nhận diện; ảnh tách nền và bộ sưu tập có thể lưu trên thiết bị.",
  },
];
```

Change the header label to `An tâm khám phá` while retaining `#rao-chan`.
Replace the footer release-status sentence with:

```tsx
<p>
  Đồng hành cùng phụ huynh và giáo viên trong những phút khám phá khoa học với
  trẻ.
</p>
```

- [x] **Step 4: Run focused and full tests**

Run:

```bash
cd landing-page
npm test -- src/app/page.test.tsx src/app/not-found.test.tsx
npm test
```

Expected: focused tests and all landing tests PASS.

- [x] **Step 5: Commit the copy**

```bash
git add landing-page/src/app/page.test.tsx \
  landing-page/src/app/not-found.test.tsx \
  landing-page/src/components/guardrails.tsx \
  landing-page/src/components/site-header.tsx \
  landing-page/src/components/site-footer.tsx
git commit -m "TASK-024: viết lại copy an tâm cho phụ huynh"
```

### Task 2: Review, verify and redeploy

**Files:**

- Modify: `tasks/TASK-024-landing-page.md`
- Modify: `plans/260726-wonderlens-landing-page/plan.md`
- Modify: `plans/260726-wonderlens-landing-page/phase-03-parent-friendly-safety-copy.md`
- Modify: `landing-page/README.md`

**Interfaces:**

- Consumes: reviewed Task 1 source.
- Produces: updated PR #9 and a READY production deployment whose
  `gitCommitSha` matches the pushed source.

- [x] **Step 1: Run local quality gates**

```bash
cd landing-page
npm test
npm run lint
npm run build
cd ../app
flutter test
cd ..
git diff --check
```

Expected: 0 failures and no formatting errors.

- [x] **Step 2: Review local production UI**

Start the production build:

```bash
cd landing-page
npm start -- --hostname 127.0.0.1 --port 3100
```

At 375×812, 768×1024 and 1440×1000 verify:

- no horizontal overflow or broken image;
- `An tâm khám phá` remains readable and links to `#rao-chan`;
- parent-facing copy contains concrete safeguards and no forbidden jargon;
- AI fallibility and photo-to-AI disclosure remain visible;
- all five retained anchors resolve;
- no console/page error.

- [x] **Step 3: Run final review**

Compare public claims with `specs/prd.md`, `specs/domains.md`,
`docs/launch/press-kit.md` and `docs/release/privacy-age-rating.md`. Review for
friendly Vietnamese, factual accuracy, accessibility and responsive layout.
Fix Critical/Important findings; rerun affected gates.

- [x] **Step 4: Record evidence and push reviewed implementation**

Đã check toàn bộ iteration 3 AC, đặt task là `In Review — iteration 3 complete`,
đánh dấu phase 03 hoàn thành và ghi evidence test/browser vào TASK/README. Đã
push implementation đã review `ac0a70c`; PR #9 vẫn OPEN, base `main`, head
`feature/TASK-024-landing-page`, headRefOid khớp `ac0a70c`.

Evidence commit dùng:

```bash
git commit -m "TASK-024: ghi nhận kiểm chứng copy phụ huynh"
```

- [x] **Step 5: Deploy pushed implementation for validation**

Đã deploy implementation đã push `ac0a70c` để validation vào production project
`sireals-projects/wonderlens-landing`; deployment đạt `READY`.

- [x] **Step 6: Smoke validation deployment**

Đã smoke validation deployment `dpl_FVWbzWH4jhKfvTJkBEgs5STT4K5u` với metadata
SHA khớp `ac0a70c`:

- production `/` trả 200 và branded missing route trả 404;
- asset core object, journey và timeline trả 200;
- browser 375/768/1440 không overflow, ảnh hỏng hoặc console error;
- public HTML có approved parent copy và không có forbidden jargon;
- Vercel build error, runtime error/fatal và 5xx scan đều sạch.

### Operational handoff

Sau mỗi evidence commit làm thay đổi source, handoff gồm push final source,
deploy production, smoke lại và đăng deployment ID, immutable URL, source SHA
cùng gate summary cuối vào PR #9. Cách làm này tránh tài liệu tự tham chiếu SHA
của chính evidence commit.

## Evidence — 2026-07-26

- Task 1 review đạt Spec Compliance PASS và Task Quality PASS; không có finding
  Critical, Important hoặc Minor. Final branch review từ merge base đến
  `ac0a70c` cũng không có finding ở các mức này.
- Local: `npm test` (3 file, 6/6 test), `npm run lint`, `npm run build` và
  Flutter regression (92/92 test) đều pass. Build tạo static `/`,
  `/_not-found`, icon và Open Graph image.
- Browser production local và production tại 375×812, 768×1024, 1440×1000:
  không horizontal overflow; 26/26 ảnh tải sau lazy-load sweep; copy yêu cầu
  hiển thị; jargon cấm không xuất hiện trong `#rao-chan`; năm anchor còn lại
  resolve; `An tâm khám phá` liên kết `#rao-chan`; không có warning/error.
- Production validation: `dpl_FVWbzWH4jhKfvTJkBEgs5STT4K5u`, trạng thái
  `READY`, target production, source metadata
  `ac0a70c7b6a578d85a4cb1f1f0d9d291a493b2d4`; remote build hoàn tất trong 11
  giây. `/` trả 200, branded missing route trả 404, asset core trả 200; không
  có runtime error cluster, error/fatal log hoặc 5xx log.
- PR #9 vẫn OPEN với base `main`, head `feature/TASK-024-landing-page`; handoff
  final-source deployment ghi ID/SHA và gate summary cuối vào PR #9 theo quy
  trình ở trên.

## Risks and rollback

- Positive safety copy may sound like certification. Mitigation: explicit AI
  fallibility, adult co-use and no absolute/certification claim.
- Removing technical terms may hide data flow. Mitigation: keep direct
  photo-to-AI disclosure in parent language.
- If deploy fails, Vercel keeps the previous READY alias; branch and PR remain
  available for correction.
