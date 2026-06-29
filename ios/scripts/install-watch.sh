#!/usr/bin/env bash
# Installs the built PTVon watch app to the paired Apple Watch.
# Wake + unlock the watch and keep it near the phone, then run this.
set -e
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
WATCH=5EB616EE-96F8-50A4-949F-652B7645647C
APP=$(find ~/Library/Developer/Xcode/DerivedData/PTVon-*/Build/Products/Debug-watchos -maxdepth 1 -name 'PTVonWatch.app' | head -1)
xcrun devicectl device info details --device "$WATCH" >/dev/null 2>&1 || true
for i in 1 2 3 4 5; do
  echo "attempt $i…"
  if xcrun devicectl device install app --device "$WATCH" "$APP" 2>&1 | grep -qi "App installed"; then
    echo "✓ installed to watch"; exit 0
  fi
  sleep 8
done
echo "Watch not reachable — wake/unlock it and retry."; exit 1
