#!/usr/bin/env bash
# Runs the AndroidFileSource tests (docs/stage2_android.md, section 5.11) on
# one device or emulator:
#   integration_test/android/run_android.sh <adb-serial>
#
# Touches only /storage/emulated/0/FileOrganizerTest/ and removes it at the
# end. Installs the app (com.brobrocode.file_organizer) and grants it "All
# files access" through appops. Fails if the app crashed.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/android_test.log

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[run_android] $*" >&2; }

say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')"

# Installed first so access can be granted; `flutter test` reinstalls it and
# keeps the grant.
if ! "${ADB[@]}" shell pm path "$APP" >/dev/null 2>&1; then
  "$FLUTTER" build apk --debug
  "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
fi
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow

# An indexed photo for the capture dates.
"${ADB[@]}" shell rm -rf "$ROOT"
"${ADB[@]}" shell mkdir -p "$ROOT/media"
"${ADB[@]}" push integration_test/native/fixtures/photo.jpg "$ROOT/media/photo.jpg" >/dev/null
"${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null

cleanup() {
  "${ADB[@]}" shell rm -rf "$ROOT" || true
  "${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null || true
}
trap cleanup EXIT

"${ADB[@]}" logcat -b crash -c
STATUS=0
"$FLUTTER" test integration_test/android/android_file_source_test.dart -d "$SERIAL" >"$LOG" 2>&1 || STATUS=$?

grep -o 'ANDROID|[a-zA-Z=]*' "$LOG" | sort -u | sed 's/^ANDROID|/[run_android] /' >&2 || true
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
if [ -n "$CRASHES" ]; then
  say "the app crashed:"
  echo "$CRASHES" >&2
  STATUS=1
fi
grep -E '^[0-9]+:[0-9]+ \+' "$LOG" | tail -1 || true
if [ "$STATUS" -ne 0 ]; then
  grep -E '\[E\]' "$LOG" | head -20 || true
  say "full log: $LOG"
fi
exit "$STATUS"
