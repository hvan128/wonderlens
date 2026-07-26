# WonderLens Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Status:** In Progress
**Goal:** Build and deploy a static, Apple-like WonderLens product landing page
inside `landing-page/`.

**Architecture:** Next.js App Router uses Server Components, local product assets,
local fonts, CSS custom-property tokens and CSS Modules. No backend, analytics,
PII collection or runtime API calls.

**Tech Stack:** Next.js 16.2.12, React 19.2.8, TypeScript, CSS Modules, Vitest,
Testing Library, Vercel.

## Global Constraints

- Vietnamese copy for parents using WonderLens with children ages 6–10.
- Reuse real product screenshots, cutouts and stage illustrations; no emoji or
  stock images as object visuals.
- No new API route, OpenAI call, secret, waitlist form or unverified claim.
- Mobile-first, WCAG AA, 44px touch targets and reduced-motion support.
- TDD for product behavior; generated scaffold/config is setup only.
- Branch `feature/TASK-024-landing-page`; never push directly to `main`.

## Phases

- [Phase 01 — Build, verify and deploy](phase-01-build-verify-deploy.md)

## Dependencies

- TASK-024 Goal/AC.
- ADR-016 architecture.
- `DESIGN.md` brand tokens and asset rules.
- Existing app/store/promo assets.
- Authenticated Vercel scope for production deployment.

## Acceptance Criteria

- TASK-024 AC all checked with fresh evidence.
- `npm test`, `npm run lint`, `npm run build` exit 0.
- Browser checks pass at mobile/tablet/desktop and reduced motion.
- Vercel deployment READY; production `/` returns HTTP 200.
