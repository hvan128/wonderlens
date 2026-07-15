#!/usr/bin/env bash
# Build a release-mode Android App Bundle (.aab) with stable Vercel dev config.
# Upload to Google Play only when android/key.properties exists.
#
# Usage with Infisical (from repository root):
#   infisical run --env=prod --path=/wonderlens/android-proxy \
#     --project-config-dir=. -- bash -ceu 'cd app && ./scripts/build-appbundle.sh'
# Output: build/app/outputs/bundle/release/app-release.aab
# Upload: cd android && set -a && source ../fastlane-secrets.env && set +a && fastlane internal

set -euo pipefail

if [[ -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.local
  set +a
fi

PROXY_BASE_URL="https://wonderlens-android-proxy.vercel.app"
APP_TOKEN="${APP_TOKEN:-${APP_SHARED_SECRET:-}}"

if [[ -z "${APP_TOKEN:-}" ]]; then
  echo "ERROR: APP_TOKEN/APP_SHARED_SECRET missing (use Infisical prod path /wonderlens/android-proxy)" >&2
  exit 1
fi

echo "Building release AAB"
echo "  PROXY_BASE_URL = ${PROXY_BASE_URL}"

flutter build appbundle --release \
  --dart-define=PROXY_BASE_URL="${PROXY_BASE_URL}" \
  --dart-define=APP_TOKEN="${APP_TOKEN}"

echo ""
echo "Done. AAB at: build/app/outputs/bundle/release/app-release.aab"
