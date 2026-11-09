#!/usr/bin/env bash
# The local emulator stack for the app (backend/CLAUDE.md, "Test on your
# phone with the emulators"). Always the demo-plusprayer project: the
# emulators and SDKs never reach production for a demo- project.
#
#   emulators.sh start      empty emulators + the sweeper
#   emulators.sh seeded     the same, imported from emulator-data/seed (the snapshot)
#   emulators.sh snapshot   export the running emulators to emulator-data/seed
#
# Run through npm (backend/functions): `npm run emulators`, `npm run
# emulators:seeded`, `npm run emulators:snapshot`. The emulators listen on all
# interfaces (firebase.json), so a phone on the same Wi-Fi can reach them.
# Restoring = stopping (Ctrl-C) and starting `seeded` again: nothing is
# exported on exit, so the snapshot stays as it was taken.
set -euo pipefail

BACKEND="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$BACKEND"
PROJECT=demo-plusprayer
SNAPSHOT=emulator-data/seed
ONLY=auth,database,dataconnect,functions,eventarc
# The standalone `firebase` binary bundles Node 20, which can't load
# firebase-admin 14 in the Functions emulator (functions/README.md).
FIREBASE=(npx -y firebase-tools@15)

# The Database emulator needs Java 21+. Falls back to Android Studio's
# bundled runtime when the default java is older.
java_major() { "$1" -version 2>&1 | awk -F'"' '/version/ { split($2, v, "."); print (v[1] == "1" ? v[2] : v[1]); exit }'; }
if ! command -v java >/dev/null 2>&1 || [ "$(java_major java)" -lt 21 ]; then
  JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  if [ -x "$JBR/bin/java" ] && [ "$(java_major "$JBR/bin/java")" -ge 21 ]; then
    export JAVA_HOME="$JBR" PATH="$JBR/bin:$PATH"
  else
    echo "The Database emulator needs Java 21 or later (install a JDK 21, or set JAVA_HOME to one)." >&2
    exit 1
  fi
fi

case "${1:-start}" in
  snapshot)
    exec "${FIREBASE[@]}" emulators:export "$SNAPSHOT" --project "$PROJECT" --force
    ;;
  start | seeded)
    IMPORT=()
    if [ "${1:-start}" = seeded ]; then
      if [ ! -d "$SNAPSHOT" ]; then
        echo "No snapshot at backend/$SNAPSHOT yet: run \`npm run emulators\`, seed, then \`npm run emulators:snapshot\`." >&2
        exit 1
      fi
      IMPORT=(--import "$SNAPSHOT")
    fi
    npm --prefix functions run --silent build
    # The sweeper stands in for onPrayerLogged, which the Functions emulator
    # can't trigger (scripts/emulator-sweeper.ts). It starts once the hub is up.
    (
      until curl -sf http://127.0.0.1:4400/emulators >/dev/null 2>&1; do sleep 1; done
      exec npm --prefix functions run --silent emulators:sweeper
    ) &
    SWEEPER=$!
    trap 'kill "$SWEEPER" 2>/dev/null || true; pkill -f "scripts/emulator-sweeper.ts" 2>/dev/null || true' EXIT
    "${FIREBASE[@]}" emulators:start --project "$PROJECT" --only "$ONLY" ${IMPORT[@]+"${IMPORT[@]}"}
    ;;
  *)
    echo "usage: emulators.sh start|seeded|snapshot" >&2
    exit 64
    ;;
esac
