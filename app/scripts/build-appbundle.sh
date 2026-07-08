#!/usr/bin/env bash
# Build a release Android App Bundle (.aab) for Google Play with PRODUCTION
# config baked in, signed with the shared upload key (android/key.properties).
#
# Usage: ./scripts/build-appbundle.sh
# Output: build/app/outputs/bundle/release/app-release.aab
# Upload: cd android && set -a && source ../fastlane-secrets.env && set +a && fastlane internal

set -euo pipefail

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

echo "Building release AAB"
echo "  PROXY_BASE_URL = ${PROXY_BASE_URL}"

flutter build appbundle --release \
  --dart-define=PROXY_BASE_URL="${PROXY_BASE_URL}" \
  --dart-define=APP_TOKEN="${APP_TOKEN}"

echo ""
echo "Done. AAB at: build/app/outputs/bundle/release/app-release.aab"
