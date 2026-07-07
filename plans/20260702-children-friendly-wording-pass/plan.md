# Children-Friendly Wording Pass

## Goal

Rewrite the app-facing Vietnamese copy so WonderLens feels warmer, more playful,
more scientific, and more motivating for children aged 6-10, with a gamified
learning tone inspired by modern lesson apps without copying any brand voice.

## Scope

- Flutter UI microcopy in onboarding, camera, timeline, collection, share, and
  guided discovery widgets.
- Hero object content JSON in `app/assets/content/`.
- AI-live prompt guardrails in `proxy/lib/kid-safe-prompt.ts`.
- No dependency, schema, API, or layout architecture changes.

## Acceptance Criteria

- Copy consistently speaks to children with `bé` / `mình` / `nhà khám phá nhí`.
- Science terms stay accurate and kid-safe.
- CTAs are active, short, and game-like.
- Hero `kid_text` remains under 50 words and `fun_fact` stays concise.
- Existing tests still compile or failures are clearly reported.

## Plan

1. Audit visible strings and hero content.
2. Patch core UI microcopy.
3. Patch share/guided widgets and AI prompt tone.
4. Rewrite 8 hero content files for consistency.
5. Run formatting and targeted tests.

## Status

- Step 1: Complete.
- Step 2: Complete.
- Step 3: Complete.
- Step 4: Complete.
- Step 5: Complete.
