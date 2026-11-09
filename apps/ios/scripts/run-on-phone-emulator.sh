#!/usr/bin/env bash
# Build, install and launch +Prayer on an iPhone against the emulators on
# this Mac (apps/ios/CLAUDE.md, "Test on your phone with the emulators").
#
#   apps/ios/scripts/run-on-phone-emulator.sh                 # Eric's iPhone, the Mac's Wi-Fi address
#   DEVICE=<udid> HOST=192.168.1.20 apps/ios/scripts/run-on-phone-emulator.sh
#   apps/ios/scripts/run-on-phone-emulator.sh --no-build      # relaunch only
#   apps/ios/scripts/run-on-phone-emulator.sh --mock          # back to the mock
#
# The app remembers `-PPEnvironment` and `-PPEmulatorHost`, so opening it
# from the Home Screen afterwards stays on the emulators until launched once
# with --mock. The phone and the Mac must be on the same Wi-Fi.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
DEVICE="${DEVICE:-00008150-001A75D02639401C}" # Eric's iPhone 17 Pro
DD="${DD:-${TMPDIR:-/tmp}/pp-dd-device-emulator-2}"
BUILD=1
ENVIRONMENT=emulator
for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    --mock) ENVIRONMENT=mock ;;
    *) echo "usage: run-on-phone-emulator.sh [--no-build] [--mock]" >&2; exit 64 ;;
  esac
done

# The Mac's address on the Wi-Fi the phone shares (en0 is Wi-Fi on most Macs).
if [ -z "${HOST:-}" ]; then
  for iface in en0 en1 en2; do
    HOST="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
    [ -n "$HOST" ] && break
  done
fi
if [ "$ENVIRONMENT" = emulator ] && [ -z "${HOST:-}" ]; then
  echo "Couldn't find this Mac's LAN address; set HOST=<address>." >&2
  exit 1
fi

if [ "$BUILD" = 1 ]; then
  xcodebuild -project "$REPO/apps/ios/PlusPrayer.xcodeproj" -scheme PlusPrayer \
    -configuration Debug -destination 'generic/platform=iOS' \
    -derivedDataPath "$DD" -allowProvisioningUpdates build
  xcrun devicectl device install app --device "$DEVICE" \
    "$DD/Build/Products/Debug-iphoneos/PlusPrayer.app"
fi

# "--" ends devicectl's own options, so -PP… reach the app.
if [ "$ENVIRONMENT" = emulator ]; then
  echo "Launching against the emulators at $HOST (same Wi-Fi as the phone)."
  xcrun devicectl device process launch --terminate-existing --device "$DEVICE" \
    dev.hammock.plusprayer -- -PPEnvironment emulator -PPEmulatorHost "$HOST"
else
  xcrun devicectl device process launch --terminate-existing --device "$DEVICE" \
    dev.hammock.plusprayer -- -PPEnvironment mock
fi
