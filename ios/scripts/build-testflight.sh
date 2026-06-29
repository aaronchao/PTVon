#!/usr/bin/env bash
#
# Archive PTVon (Release, signed) and upload it to TestFlight.
#
# One-time prerequisites (see TESTFLIGHT.md for the walkthrough):
#   • A paid Apple Developer Program membership.
#   • An App record created in App Store Connect for bundle id com.ptvon.app.
#   • An App Store Connect API key (.p8) with "App Manager" access.
#
# Required environment variables:
#   TEAM_ID        Your 10-char Apple Developer Team ID (e.g. AB12CD34EF)
#   ASC_KEY_ID     App Store Connect API Key ID
#   ASC_ISSUER_ID  App Store Connect API Issuer ID (UUID)
#   ASC_KEY_PATH   Path to the downloaded AuthKey_XXXX.p8 file
#
# Usage:
#   TEAM_ID=AB12CD34EF ASC_KEY_ID=XXXX ASC_ISSUER_ID=uuid \
#   ASC_KEY_PATH=~/private_keys/AuthKey_XXXX.p8 ./scripts/build-testflight.sh
#
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export PATH="/opt/homebrew/bin:$PATH"
cd "$(dirname "$0")/.."

: "${TEAM_ID:?Set TEAM_ID to your Apple Developer Team ID}"
: "${ASC_KEY_ID:?Set ASC_KEY_ID to your App Store Connect API Key ID}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID to your App Store Connect Issuer ID}"
: "${ASC_KEY_PATH:?Set ASC_KEY_PATH to the AuthKey_XXXX.p8 file}"

# Regenerate the Xcode project from project.yml if xcodegen is available.
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
fi

ARCHIVE="build/PTVon.xcarchive"
rm -rf build && mkdir -p build

echo "▸ Archiving (Release, automatic signing)…"
xcodebuild -project PTVon.xcodeproj -scheme PTVon \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  archive

echo "▸ Exporting and uploading to TestFlight…"
sed "s/YOUR_TEAM_ID/$TEAM_ID/" ExportOptions.plist > build/ExportOptions.plist

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath build/export \
  -exportOptionsPlist build/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

echo "✓ Upload submitted. The build will appear in App Store Connect → TestFlight"
echo "  after Apple finishes processing (usually 5–15 minutes)."
