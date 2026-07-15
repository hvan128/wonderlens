# Android Proxy Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy a new Vercel proxy owned by Hiệp and ship an Android release artifact configured to use it securely.

**Architecture:** Keep OpenAI credentials server-only in Vercel. Generate a separate app-to-proxy token, inject it into Android through `--dart-define`, and keep iOS pinned to its existing proxy. Verify every boundary from Android configuration through Vercel authentication to a real OpenAI response.

**Tech Stack:** Flutter/Dart, Bash release scripts, Vercel Functions/TypeScript, OpenAI API, Vercel CLI.

## Global Constraints

- Flutter never calls OpenAI directly; every AI call goes through Vercel proxy.
- Never commit or print API keys/tokens.
- No new dependency without ADR.
- Vietnamese, kid-safe output for children aged 6–10.
- Existing HTTP contracts stay unchanged.
- Google Play upload is outside this task; signing/store credentials remain separate.

---

### Task 1: Lock Android proxy configuration with a test

**Files:**
- Create: `app/test/android_proxy_config_test.dart`
- Modify: `app/lib/data/app_settings.dart`
- Modify: `app/scripts/build-appbundle.sh`

**Interfaces:**
- Consumes: Vercel production URL from Task 2.
- Produces: `AppSettings.publicProxyUrl` and Android `PROXY_BASE_URL` pointing to the same production origin.

- [ ] **Step 1: Write the failing URL contract test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/app_settings.dart';

void main() {
  test('Android production proxy uses the Hiệp-owned Vercel project', () {
    expect(
      AppSettings.publicProxyUrl,
      'https://wonderlens-android-proxy.vercel.app',
    );
    expect(AppSettings.baseUrl, AppSettings.publicProxyUrl);
  });
}
```

- [ ] **Step 2: Run test and confirm old URL fails**

Run: `cd app && flutter test test/android_proxy_config_test.dart`  
Expected: FAIL because current value is `https://wonderlens-proxy.vercel.app`.

- [ ] **Step 3: Update Android production URL only**

Set `AppSettings.publicProxyUrl` and `app/scripts/build-appbundle.sh` to
`https://wonderlens-android-proxy.vercel.app`. Do not change
`app/scripts/build-release.sh`.

- [ ] **Step 4: Verify focused test and shell references**

Run: `cd app && flutter test test/android_proxy_config_test.dart`  
Expected: PASS.

Run: `rg -n 'PROXY_BASE_URL=' app/scripts/build-appbundle.sh app/scripts/build-release.sh`  
Expected: Android uses new URL; iOS keeps old URL.

- [ ] **Step 5: Commit**

```bash
git add app/lib/data/app_settings.dart app/scripts/build-appbundle.sh app/test/android_proxy_config_test.dart
git commit -m "TASK-023: cấu hình proxy production cho Android"
```

### Task 2: Create and secure the Vercel project

**Files:**
- Runtime-only: `proxy/.vercel/project.json` (gitignored)
- Runtime-only: `app/.env.local` (gitignored, mode 600)

**Interfaces:**
- Consumes: authenticated Vercel account `sireal`, scope `sireals-projects`, user-provided OpenAI project API key.
- Produces: project `wonderlens-android-proxy`, production URL, `APP_SHARED_SECRET`, `OPENAI_API_KEY`.

- [ ] **Step 1: Create and deterministically link project**

```bash
cd proxy
vercel project add wonderlens-android-proxy --scope sireals-projects
vercel link --yes --project wonderlens-android-proxy --scope sireals-projects
```

Expected: `.vercel/project.json` names `wonderlens-android-proxy`.

- [ ] **Step 2: Generate app token and store it without logging value**

Run from `proxy/` in one shell session:

```bash
APP_SHARED_SECRET="$(openssl rand -hex 32)"
printf '%s' "$APP_SHARED_SECRET" | vercel env add APP_SHARED_SECRET production
vercel env pull ../app/.env.local --environment=production --yes
chmod 600 ../app/.env.local
unset APP_SHARED_SECRET
```

`APP_SHARED_SECRET` stays readable to authorized Vercel developers because the
Android app must embed the same value. It is an abuse throttle, not a secret
that can remain hidden from a shipped client.

- [ ] **Step 3: Add OpenAI key at the credential gate**

Open
`https://vercel.com/sireals-projects/wonderlens-android-proxy/settings/environment-variables`.
Create `OPENAI_API_KEY`, scope it to Production, mark it Sensitive, and paste a
project API key created at `https://platform.openai.com/api-keys`. Never place
the value in Flutter, git, command output, or Android artifact.

- [ ] **Step 4: Verify names/scopes only**

Run: `vercel env ls production`  
Expected: `APP_SHARED_SECRET` and `OPENAI_API_KEY` exist for Production.

### Task 3: Deploy and verify proxy end-to-end

**Files:**
- No tracked files.

**Interfaces:**
- Consumes: linked Vercel project and production env from Task 2.
- Produces: healthy public HTTPS API used by Android.

- [ ] **Step 1: Build and deploy production**

```bash
cd proxy
npm ci
npx tsc --noEmit
vercel build --prod
vercel deploy --prebuilt --prod
```

Expected: production alias `https://wonderlens-android-proxy.vercel.app`.

- [ ] **Step 2: Verify static routes and method guard**

Expected: `/privacy` and `/support` return `200`; GET `/api/recognize` returns
`405`.

- [ ] **Step 3: Verify authentication boundary**

Expected: POST without token returns `401`; POST with correct token and missing
image returns `400`.

- [ ] **Step 4: Verify real OpenAI boundary**

POST one small bundled kid-safe image with correct token. Expected: `200` and
JSON fields `object_id`, `confidence`, `display_name`, `is_hero`.

- [ ] **Step 5: Inspect deployment and runtime logs**

Run: `vercel inspect https://wonderlens-android-proxy.vercel.app`  
Run: `vercel logs https://wonderlens-android-proxy.vercel.app --since 30m --level error`  
Expected: deployment READY; no unhandled runtime errors.

### Task 4: Build and inspect Android release artifact

**Files:**
- Runtime-only: `app/build/app/outputs/bundle/release/app-release.aab`

**Interfaces:**
- Consumes: Android URL and app token from Tasks 1–2.
- Produces: Android release bundle configured for new proxy.

- [ ] **Step 1: Build through repository release script**

Run: `cd app && ./scripts/build-appbundle.sh`  
Expected: AAB at `build/app/outputs/bundle/release/app-release.aab`.

- [ ] **Step 2: Inspect artifact configuration safely**

Verify artifact contains `wonderlens-android-proxy.vercel.app`, does not contain
`OPENAI_API_KEY`, and is signed with release upload key if available. If upload
key is absent, report artifact as test-only and do not upload it.

- [ ] **Step 3: Run full gates**

Run: `cd app && flutter test`  
Run: `cd app && flutter analyze`  
Run: `cd proxy && npx tsc --noEmit`  
Expected: all pass.

- [ ] **Step 4: Commit deployment evidence**

Update `tasks/TASK-023-android-proxy-deploy.md` checkboxes/status with verified
facts only, then commit using:

```bash
git add tasks/TASK-023-android-proxy-deploy.md docs/superpowers/plans/2026-07-15-android-proxy-deploy.md
git commit -m "TASK-023: ghi nhận triển khai proxy Android"
```

### Task 5: Integrate through review

**Files:**
- No additional tracked files.

**Interfaces:**
- Consumes: verified feature branch.
- Produces: reviewed `main` containing Android production URL.

- [ ] **Step 1: Push branch and create PR into `main`**

Expected: PR includes TASK-023 code, tests, task, and plan only; no secret files.

- [ ] **Step 2: Review diff and checks**

Expected: no secret patterns, no iOS URL change, all local gates green.

- [ ] **Step 3: Merge PR after review**

Expected: `origin/main` contains TASK-023 commits and production proxy remains
healthy after merge.
