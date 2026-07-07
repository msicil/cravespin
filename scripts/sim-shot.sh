#!/bin/bash
# Build, install, launch CraveRoll on booted simulator, save screenshot.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/sim-screenshot.png}"
DERIVED="$ROOT/build"

cd "$ROOT"
xcodebuild -project CraveRoll.xcodeproj -scheme CraveRoll \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath "$DERIVED" build -quiet

APP="$DERIVED/Build/Products/Debug-iphonesimulator/CraveRoll.app"
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.cravespin.app >/dev/null
sleep 4
xcrun simctl io booted screenshot "$OUT"
echo "Screenshot: $OUT"
