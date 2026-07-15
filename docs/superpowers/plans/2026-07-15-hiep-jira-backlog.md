# Hiep Jira Backlog Implementation Plan

> **For WonderLens maintainers:** Execute in order. External publication and
> legal approval are gates, not implementation steps in this branch.

**Goal:** Deliver review-ready product, release, handoff, growth, and launch
documentation for every Jira issue assigned to Hoàng Hiệp, while implementing
only changes safe and feasible with the repository's current architecture.

**Architecture:** Documentation is split by decision domain and connected by a
single traceability index. Existing specs, ADRs, app assets, privacy pages, and
store reports remain sources of truth. No runtime dependency, PII collection,
external account, schema, or API is added. The only app behavior extension is
an additive AI-assisted disclosure for live results; curated behavior stays
unchanged.

**Tech:** Markdown, Mermaid, existing Flutter/Vercel repository, shell-based
path/link checks, Flutter test/analyze/build.

---

## Task 1: Establish traceability and executable doc checks

**Files:**

- Create: `docs/hiep-jira-delivery.md`
- Modify: `tasks/TASK-017-hiep-jira-handoff.md`

**Step 1: Define failing inventory checks**

Run an `rg` assertion for all 13 Jira keys and all planned doc paths. It must
fail because the delivery index does not exist yet.

**Step 2: Write the delivery index**

Include Jira summary, source URL, deliverable path, current repo status,
remaining external gate, and a strict meaning for `Done in repo`.

**Step 3: Re-run inventory checks**

Confirm exactly 13 unique `KAN-*` entries and no issue is silently marked done
when it still needs PM/legal/console action.

## Task 2: Product scope and beta success metrics

**Files:**

- Create: `docs/product/sprint-scope.md`
- Create: `docs/product/beta-success-metrics.md`

**Step 1: Add failing content assertions**

Assert required sections for core promise, in/out scope, secondary/backlog,
time-to-wow, activation, completion, retry, crash-free, safety, owner, and
manual TestFlight checklist.

**Step 2: Write sprint scope**

Ground the scope in `specs/prd.md` and current implementation. Separate the
camera-to-journey core from collection, subscription, reminders, AI-live media,
and future growth work. Record PM sign-off as pending.

**Step 3: Write beta metrics**

Define formula, event-free/manual collection method, target, denominator,
sample size, owner, review cadence, and privacy guardrail for each metric. Never
present a target as observed data.

**Step 4: Re-run assertions**

Verify every metric has an operational definition and manual QA path that does
not require adding analytics.

## Task 3: Product flows and technical handoff

**Files:**

- Create: `docs/handoff/product-flows.md`
- Create: `docs/handoff/product-technical-overview.md`

**Step 1: Add failing flow checks**

Assert at least three Mermaid diagrams and links to PRD, domains, API contracts,
ADRs, workflow, and relevant local tasks.

**Step 2: Write JTBD and user flows**

Cover onboarding → permission → capture → proxy/curated response → journey →
collection/share, including offline/error branches and App Store release flow.

**Step 3: Write one-file handoff**

Explain core promise, parent/child personas, success metrics, Flutter domains,
Vercel proxy, OpenAI boundary, Hive/local assets, safety constraints, and source
links. Explicitly state current release status versus desired state.

**Step 4: Re-run flow checks**

Check Mermaid fences are paired and each diagram uses supported basic syntax.

## Task 4: Privacy, age rating, and store metadata

**Files:**

- Create: `docs/release/privacy-age-rating.md`
- Create: `docs/release/store-metadata.md`

**Step 1: Capture official sources**

Use current Apple App Review/App Privacy/Screenshot references, Google Play
Families/target-audience/AI-content references, OpenAI API retention controls,
and FTC COPPA guidance. Links must be primary sources.

**Step 2: Write a decision record for release declarations**

Distinguish age rating, Apple Kids Category, Google target audience, and legal
coverage. Recommend truthful child/family targeting and require legal review
before submission. Document that OpenAI may retain API abuse-monitoring logs up
to 30 days, so privacy declarations cannot claim zero third-party retention.

**Step 3: Write metadata and asset manifest**

Provide final Vietnamese name/subtitle/keywords/short/full description, review
notes, screenshot storyboard, AI/privacy wording, and exact existing asset paths.
Flag screenshots that do not show the camera/result story clearly enough.

**Step 4: Validate limits and files**

Measure character limits, verify every asset path exists, and compare screenshot
dimensions with current Apple accepted sizes. Record discrepancies as actions.

## Task 5: Growth system and Android beta waitlist spec

**Files:**

- Create: `docs/growth/viral-loop-strategy.md`
- Create: `docs/growth/social-calendar-30-days.md`
- Create: `docs/growth/build-in-public.md`
- Create: `docs/growth/android-beta-waitlist.md`

**Step 1: Add failing completeness checks**

Assert three viral loops, 30 calendar rows, at least ten post drafts, three
30–45 second scripts, five build-in-public drafts, waitlist schema, consent,
retention/deletion owner, and go-live gates.

**Step 2: Write viral-loop strategy**

Choose parent discovery cards, object-story short videos, and a seven-day family
challenge. Map entry → value → safe share → CTA → return; define metrics without
child accounts or public child profiles.

**Step 3: Write 30-day calendar and scripts**

Use four pillars: demo, object science, parent trust/safety, build in public.
Every row gets hook, format/channel, CTA, asset, owner, and metric. Draft the
first ten posts and three video scripts using only consent-safe assets.

**Step 4: Write build-in-public kit**

Define narrative, daily update template, milestone policy, review gate, privacy
red lines, and five ready-to-review posts.

**Step 5: Write waitlist implementation spec**

Provide landing copy, field schema, consent text, privacy note, validation,
minimal aggregate tracking, data lifecycle, abuse controls, acceptance tests,
and selection criteria for form/CRM. Mark live implementation blocked until a
PM names the data controller/owner, storage destination, retention and deletion
process, and approves privacy text.

**Step 6: Re-run completeness checks**

Verify counts and that no content asks children to submit personal data or post
their face publicly.

## Task 6: Press kit and Product Hunt draft

**Files:**

- Create: `docs/launch/press-kit.md`
- Create: `docs/launch/product-hunt.md`

**Step 1: Add failing launch-kit checks**

Assert VI/EN one-liner, 50-word and 150-word descriptions, asset manifest,
team-note placeholder, AI/data/safety FAQ, Product Hunt tagline/description,
maker comment, launch-day roles, FAQ, and post-launch metrics.

**Step 2: Write press kit**

Reuse bundled logo/icon/screenshots/promo video. Do not invent team biography or
claim real beta results. Label placeholders requiring founder input.

**Step 3: Write Product Hunt draft**

Follow current Product Hunt limits/guidance, gate launch on stable closed beta,
and require a human maker to personalize/post the first comment.

**Step 4: Re-run launch-kit checks**

Validate copy lengths, paths, and that gallery items are available in Git.

## Task 6.5: Close feasible KAN-32 asset/disclosure gaps

**Files:**

- Modify: `app/lib/screens/camera_screen.dart`
- Modify: `app/lib/screens/discovery_reveal_screen.dart`
- Modify: `app/lib/ui/capture_dissolve.dart`
- Modify: `app/tool/pregen_store_screenshots.dart`
- Create: `app/test/capture_dissolve_ai_label_test.dart`
- Create: `app/test/discovery_reveal_ai_label_test.dart`
- Create/update: store and Fastlane screenshot PNGs

**Step 1: Add failing disclosure tests**

Prove AI-live results need an `AI hỗ trợ` label in capture dissolve and result
route, while curated content must not show it.

**Step 2: Add the minimal source-driven label**

Pass `content.source == 'live'` into the existing UI and render the existing
`WonderChip`; do not infer AI from object ID or label curated content.

**Step 3: Extend the existing screenshot generator**

Render real paper-cup result and timeline widgets, disable external narration,
write all six 1290×2796 images, and mirror the exact bytes into Fastlane.

**Step 4: Verify**

Run the focused disclosure tests and screenshot generator before the full app
suite. Inspect result/timeline images visually.

## Task 7: Repository verification and handoff status

**Files:**

- Modify: `docs/hiep-jira-delivery.md`
- Modify: `tasks/TASK-017-hiep-jira-handoff.md`

**Step 1: Validate Markdown**

Run internal link/path checks, count-based acceptance checks,
`git diff --check`, and a secret-pattern scan on new files.

**Step 2: Verify app state**

From `app/`, run:

```bash
flutter test
flutter analyze
flutter build apk --release
flutter build ios --release --no-codesign
```

These are required because the handoff documents describe the current product
as shippable; failures must be reported, not rewritten as success.

**Step 3: Finalize statuses**

Mark doc acceptance items complete only where evidence exists. Keep PM review,
legal sign-off, external publishing, live waitlist, and Product Hunt timing open.

**Step 4: Commit scoped changes**

Stage only TASK-017 docs plus the scoped AI-label tests/code and generated store
assets. Exclude the user's existing `docs/workflow.md` change. Use scoped
`TASK-017:` commits and do not push.
