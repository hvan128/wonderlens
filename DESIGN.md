---
version: alpha
name: WonderLens-design-system
description: WonderLens is a Vietnamese STEM discovery app for children ages 6-10. The interface should feel like a bright, safe science lens: camera-first, tactile, liquid-glass surfaces over soft colorful backgrounds, large readable Vietnamese text, and playful spring motion. This file is the visual contract for AI agents. It complements AGENTS.md; it does not override product, safety, API, or architecture rules.
---

# WonderLens DESIGN.md

Use this file when creating or changing WonderLens UI. Keep app behavior aligned
with `AGENTS.md`, `specs/`, and `adrs/`; use this file for visual decisions.

## 1. Visual Theme And Atmosphere

WonderLens should feel like a kid-safe science tool, not a generic SaaS app and
not a marketing landing page.

- Mood: bright, curious, tactile, warm, trustworthy.
- Core metaphor: a magic science lens that turns real objects into a story.
- Surface language: liquid glass, soft canvas gradients, real captured object
  cutouts, stage images, and gentle spring motion.
- Reading experience: short Vietnamese copy, high contrast, large touch targets,
  and clear hierarchy for children ages 6-10.
- Product priority: the camera, object, timeline, prediction/action gates,
  experiment, collection, and badge moments are the main visual moments.

Do not make WonderLens look like enterprise dashboards, fintech apps, dark IDEs,
or generic AI landing pages. Do not copy another brand's identity from
`awesome-design-md`; adapt only the idea of a structured design contract.

## 2. Color Palette And Roles

Source of truth in Flutter: `app/lib/theme/wonder_tokens.dart`.

| Token | Hex | Role |
|---|---:|---|
| `WonderColors.teal` | `#26C6DA` | Primary brand color, scan energy, active states |
| `WonderColors.tealDeep` | `#0E97AC` | Strong teal for icons, text accents, depth |
| `WonderColors.cyan` | `#22D3EE` | CTA gradient start, bright science glow |
| `WonderColors.sky` | `#38BDF8` | CTA gradient end, ring highlight |
| `WonderColors.indigo` | `#7C8CF8` | Secondary cool accent |
| `WonderColors.grape` | `#B794F4` | Wonder, reward, secondary accent |
| `WonderColors.mint` | `#5EEAD4` | Success, safe discovery, ring accent |
| `WonderColors.sunny` | `#FFC857` | Reward, badge, flashlight active state |
| `WonderColors.coral` | `#FF8A65` | Warm attention, warning-lite emphasis |
| `WonderColors.ink` | `#0B1220` | Dark glass base over camera/video |
| `WonderColors.inkSoft` | `#14203A` | Softer dark glass and supporting surfaces |
| `WonderColors.textStrong` | `#15233B` | Main text on light surfaces |
| `WonderColors.textSoft` | `#54657F` | Secondary text on light surfaces |
| `WonderColors.canvasTop` | `#EAF8FB` | Top of content-screen background |
| `WonderColors.canvasBottom` | `#F4EFFF` | Bottom of content-screen background |
| `WonderColors.paper` | `#FFFDF7` | Warm fallback scaffold background |

Use `WonderGradients.cta` for primary action buttons:
`#22D3EE -> #26C6DA -> #38BDF8`.

Use `WonderGradients.ring` for scan or reward loops:
teal, sky, grape, sunny, mint, teal.

Use `WonderGradients.canvas` for content screens:
`#EAF8FB -> #F4EFFF`.

## 3. Typography Rules

Source of truth: `WonderType` in `app/lib/theme/wonder_tokens.dart` (ADR-010).

Fonts are BUNDLED assets (offline-first, Latin + Vietnamese subsets, no
network loading): **Baloo 2** for display/title/wordmark only, **Nunito** for
everything else. `ThemeData(fontFamily: 'Nunito')` makes raw TextStyles
inherit the body family automatically.

| Token | Family | Size | Weight | Line Height | Use |
|---|---|---:|---:|---:|---|
| `WonderType.display` | Baloo 2 | 28 | 800 | 1.15 | Onboarding and high-emphasis numbers |
| `WonderType.title` | Baloo 2 | 21 | 800 | 1.10 | Screen headers, brand wordmark |
| `WonderType.heading` | Nunito | 17 | 900 | 1.20 | Cards, stage titles, sheet titles |
| `WonderType.body` | Nunito | 16 | 700 | 1.45 | Main child-facing Vietnamese text |
| `WonderType.button` | Nunito | 17 | 900 | normal | Primary buttons |
| `WonderType.textButton` | Nunito | 15 | 800 | normal | Secondary text actions |
| `WonderType.label` | Nunito | 13 | 800 | normal | Chips, tags, status labels |
| `WonderType.caption` | Nunito | 12.5 | 700 | normal | Short hints and supporting copy |

Rules:

- Do NOT use Baloo 2 at 17px or below, or for long text — stacked Vietnamese
  diacritics merge at heavy weights in small sizes.
- Avoid ALL-CAPS Vietnamese with wide letterSpacing in child-facing copy —
  sentence case with tracking ≤0.5 reads better for ages 6-10.
- Prefer short Vietnamese labels. Avoid long paragraphs in UI chrome.
- Stage `kid_text` should stay under 50 words; `fun_fact` under 20 words.
- Do not scale font size with viewport width.
- Do not use negative letter spacing.
- Body copy must be readable over both light canvas and dark camera surfaces.
- New font weights must go through the gwfh Vietnamese subset pipeline, not
  full Google Fonts TTFs (see ADR-010).

## 4. Spacing, Radius, And Layout

Source of truth: `WonderTokens`.

Spacing scale:

| Token | Value |
|---|---:|
| `space4` | 4 |
| `space8` | 8 |
| `space12` | 12 |
| `space16` | 16 |
| `space20` | 20 |
| `space24` | 24 |
| `space32` | 32 |
| `space40` | 40 |

Radius scale:

| Token | Value | Use |
|---|---:|---|
| `radiusSm` | 14 | Chips, small grouped controls |
| `radiusMd` | 20 | Primary buttons and compact surfaces |
| `radiusLg` | 28 | Glass cards and major controls |
| `radiusXl` | 34 | Sheets and large floating panels |
| `pill` | 999 | Full pills and circular controls |

Layout rules:

- Mobile-first. Assume one-handed use by children.
- Touch targets should be at least 44px; key controls should be larger.
- Use stable dimensions for scan buttons, avatar areas, icon buttons, stage
  media, and collection tiles so motion and dynamic content do not shift layout.
- Do not nest cards inside cards. Use one glass surface per visual group.
- Keep main workflows visible quickly: camera action, next stage, prediction
  choices, experiment confirmation, collection entry.

## 5. Component Styling

Prefer existing Flutter components before inventing new ones:

- `WonderBackground`: light content background with `WonderGradients.canvas` and
  subtle radial color fields.
- `GlassSurface`: liquid-glass surface with one optional `BackdropFilter`, tint,
  hairline, top sheen, and specular rim.
- `GlassIconButton`: round glass icon action. Use Phosphor icons through
  `phosphor_compat.dart`.
- `WonderButton`: primary gradient action with sheen and glow.
- `WonderTextButton`: secondary text action.
- `WonderChip`: material/status tag with optional Phosphor icon.
- `ScanRingButton`: central camera action with rotating rainbow ring.
- `GlassSheet`: bottom sheet with spring entrance, grabber, and drag dismissal.
- `GlassPanel`: dev/creative floating panel only; not for normal child flows.

### Camera Screen

- Use darker `GlassTone.dark` surfaces over camera preview.
- Keep camera preview visually dominant.
- The scan action should be the largest control.
- Use `ScanRingButton` for primary scanning or discovery start.
- Use icon-only buttons for tools such as flash, close, switch, and gallery.

### Timeline Screen

- Show the real captured object cutout when available. Fall back to emoji only
  when no cutout exists.
- Stage cards should feel like a guided story: stage image, title, short
  Vietnamese text, fun fact, audio action.
- Prediction gates should ask one clear question with 2-3 options.
- Action gates should use tactile verbs: nhan giu, vuot, cham, keo.
- The reward should happen after completion, not when the screen opens.

### Collection Screen

- Collection tiles should feel earned, persistent, and personal.
- Hero objects belong in the main grid and can unlock level/badges.
- AI-live discoveries belong in the "Kham pha them (AI)" journal style area and
  must not visually imply verified curriculum content.

### Onboarding

- Start with the actual usable experience, not a marketing hero.
- Use short text, visible camera/object affordance, and a clear first action.
- Avoid explaining every feature in prose.

## 6. Motion And Interaction

Source of truth: `app/lib/ui/motion.dart`.

Use `WonderSpring` instead of arbitrary duration/curve choices:

| Spring | Response | Damping | Use |
|---|---:|---:|---|
| `smooth` | 0.42 | 1.00 | Normal layout transitions |
| `snappy` | 0.32 | 0.85 | Buttons, toggles, quick UI feedback |
| `bouncy` | 0.42 | 0.65 | Rewards, badge reveals, playful child moments |
| `interactive` | 0.24 | 0.86 | Panels, sheets, drag gestures |

Interaction rules:

- Hand off real gesture velocity into spring simulations.
- Use haptics intentionally on scan, snap, reward, and completion.
- Avoid infinite animations except lightweight transform-only ambient motion.
- Camera/video overlays should minimize blur; use `GlassSurface(blur: 0)` when
  performance matters.
- Keep no more than three blurred glass surfaces visible at the same time.

## 7. Assets And Imagery

- Primary visuals should be real object cutouts, stage illustrations, bundled
  videos, or generated stage images from the proxy flow.
- Do not use generic stock photos for hero objects.
- Do not use emoji as UI icons. Use icons through `phosphor_compat.dart`
  (mapped to **Iconsax** via `iconsax_plus` — a friendly rounded set that
  compiles on current Flutter; Phosphor/Lucide do not).
- Icon hierarchy is two-tier (ADR-010): `PhosphorIconsBold.*` → Iconsax Linear
  (OUTLINE, navigation/tools); `PhosphorIconsFill/Duotone.*` → Iconsax Bold
  (FILLED, status/active/emphasis). Pick the tier by meaning, not by looks.
- Add a new glyph by mapping it in `phosphor_compat.dart` only; verify with
  `flutter test` (compiles the icon font), not just `flutter analyze`.
- Emoji is acceptable only as content fallback for object identity.
- Hero object images and videos must remain offline-first.
- AI-live generated imagery is optional and must fail gracefully.

## 8. Content And Safety Guardrails

WonderLens is for Vietnamese children ages 6-10.

- Use Vietnamese by default.
- Keep tone curious, calm, and encouraging.
- Explain STEM ideas with concrete everyday examples.
- Do not include dangerous experiments, violence, medical claims, conspiracy
  content, or anti-science claims.
- Do not imply AI-live content is fully verified. Label it as AI exploration.
- Do not call OpenAI directly from Flutter UI. All AI calls go through proxy.

## 9. Do's And Don'ts

Do:

- Reuse `WonderColors`, `WonderTokens`, `WonderType`, and `WonderSpring`.
- Prefer existing `app/lib/ui/` components.
- Make the camera, object, stage, and reward visually obvious.
- Use large tap areas and concise Vietnamese labels.
- Check text overflow on small phones before finishing UI work.
- Preserve offline-first hero flows.

Don't:

- Add a new UI dependency without an ADR.
- Add custom fonts or remote font loading.
- Create a landing page when the app needs a working screen.
- Use dark enterprise palettes, crypto/fintech density, or dashboard-heavy UI.
- Put glass cards inside other glass cards.
- Use decorative gradient orbs as standalone design filler.
- Hide important child-facing actions in dense menus.

## 10. Responsive Behavior

- Primary target: mobile portrait.
- Support small phones by reducing columns, not by shrinking text.
- Keep bottom controls above system safe areas.
- Stage media should use stable aspect ratios.
- Collection grids should keep tiles tappable and readable.
- Sheets should max out at about 86% screen height and remain dismissible.
- Landscape/tablet layouts can widen content, but should not become desktop
  dashboards.

## 11. Agent Prompt Guide

When asking an AI agent to build WonderLens UI, use prompts like:

```text
Use AGENTS.md for engineering rules and DESIGN.md for visual rules.
Build this as Flutter UI using existing app/lib/ui components and
app/lib/theme/wonder_tokens.dart. Keep the UI Vietnamese, kid-safe,
offline-first for hero objects, and do not add dependencies.
```

For a new timeline interaction:

```text
Create a WonderLens timeline interaction that uses WonderBackground,
GlassSurface, WonderType, WonderButton, WonderChip, and WonderSpring.
The copy is Vietnamese for ages 6-10. Stage text stays under 50 words.
No OpenAI call is made from Flutter.
```

For a visual review:

```text
Review this screen against DESIGN.md. Flag text overflow, low contrast,
too many blurred glass surfaces, card nesting, missing Phosphor icons,
and any UI that feels like SaaS instead of a kid-safe STEM discovery app.
```

## 12. Flutter Mapping Quick Reference

| Design need | Use |
|---|---|
| Light content screen | `WonderBackground` |
| Glass card/surface | `GlassSurface` |
| Round tool button | `GlassIconButton` |
| Primary action | `WonderButton` |
| Secondary action | `WonderTextButton` |
| Material/status label | `WonderChip` |
| Camera scan action | `ScanRingButton` |
| Bottom modal | `showGlassSheet` / `GlassSheet` |
| Floating dev panel | `GlassPanelArea` / `GlassPanel` |
| Colors/spacing/type | `wonder_tokens.dart` |
| Motion | `motion.dart` / `WonderSpring` |

