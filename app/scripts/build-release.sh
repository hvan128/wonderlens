#!/usr/bin/env bash
# Build a release IPA for App Store Connect with PRODUCTION config baked in.
#
# The app reads config via --dart-define (lib/data/app_settings.dart). A release
# build MUST receive PROXY_BASE_URL + APP_TOKEN or the shipped app silently
# falls back to Mock (proxy 401) — AI live and journey images stop working.
#
# Usage:
#   ./scripts/build-release.sh
#
# Upload after build:
#   cd ios && set -a && source ../fastlane-secrets.env && set +a && fastlane beta

set -euo pipefail

# APP_TOKEN comes from .env.local (gitignored). PROXY_BASE_URL is forced to
# production below regardless of what .env.local holds (that file is for dev).
if [[ -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.local
  set +a
fi

PROXY_BASE_URL="https://wonderlens-proxy.vercel.app"

if [[ -z "${APP_TOKEN:-}" ]]; then
  echo "ERROR: APP_TOKEN missing in .env.local (= APP_SHARED_SECRET của proxy)" >&2
  exit 1
fi

echo "Building release IPA"
echo "  PROXY_BASE_URL = ${PROXY_BASE_URL}"
echo "  APP_TOKEN loaded from .env.local"

# flutter build ipa tạo archive + ghi dart-defines vào Generated.xcconfig; bước
# export của nó cần account Xcode nên có thể fail (exit vẫn 0). Nếu thiếu IPA,
# lane build_ipa (gym + ASC API key) export lại từ đúng archive/defines đó.
flutter build ipa --release \
  --dart-define=PROXY_BASE_URL="${PROXY_BASE_URL}" \
  --dart-define=APP_TOKEN="${APP_TOKEN}" || true

if ! ls build/ios/ipa/*.ipa >/dev/null 2>&1; then
  echo "flutter export không ra IPA — dùng fastlane build_ipa (ASC API key)…"
  (cd ios && set -a && source ../fastlane-secrets.env && set +a \
    && FASTLANE_SKIP_UPDATE_CHECK=1 fastlane build_ipa)
fi

echo ""
echo "Done. Archive + IPA at: build/ios/ipa/"
