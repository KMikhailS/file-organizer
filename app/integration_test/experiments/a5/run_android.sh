#!/usr/bin/env bash
# Runs the A.5 experiment (docs/stage2_android.md, section 4) on one device:
#   integration_test/experiments/a5/run_android.sh <adb-serial> <results.jsonl>
# Set SKIP_BUILD=1 to reuse the APK of a previous run.
#
# Touches only /storage/emulated/0/FileOrganizerTest/ and removes it at the
# end. Installs the app (com.brobrocode.file_organizer) with the experiment as
# its entry point and grants it "All files access" via appops.
set -euo pipefail

SERIAL=$1
OUT=$2
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=$(mktemp)

cd "$(dirname "$0")/../../.."

if [ "${SKIP_BUILD:-0}" != 1 ]; then
  "$FLUTTER" build apk --debug -t integration_test/experiments/a5/android_main.dart
fi

line() { echo "{\"id\":\"$1\",\"what\":\"$2\",\"result\":\"$3\"}"; }
rows() {
  # MediaStore rows of the experiment photos, one line.
  "${ADB[@]}" shell "content query --uri content://media/external/file --projection _data" |
    tr -d '\r' | grep -o "_data=$ROOT/[^ ]*\.jpg" | sed "s|_data=$ROOT/run-[0-9]*/||" | sort | tr '\n' ' '
}
wait_for() {
  for _ in $(seq 1 300); do
    if grep -q "A5|$1" "$LOG"; then return 0; fi
    sleep 1
  done
  echo "timeout waiting for $1" >&2
  return 1
}

"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
echo "appops: $("${ADB[@]}" shell appops get --uid "$APP" MANAGE_EXTERNAL_STORAGE | tr -d '\r')"
"${ADB[@]}" shell am force-stop "$APP"
"${ADB[@]}" shell rm -rf "$ROOT"
"${ADB[@]}" logcat -c
"${ADB[@]}" logcat -s flutter:I >"$LOG" &
LOGCAT=$!
trap 'kill $LOGCAT 2>/dev/null || true; rm -f "$LOG"' EXIT
"${ADB[@]}" shell am start -n "$APP/.MainActivity" >/dev/null

wait_for '{"id":"MS_READY"'
BASE=$(grep -o "A5|{\"id\":\"MS_READY\"[^}]*}" "$LOG" | sed 's/.*"result":"\([^"]*\)".*/\1/')
"${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null
BEFORE=$(rows)
"${ADB[@]}" shell touch "$BASE/ms/go"
wait_for '{"id":"MS_MOVED"'
sleep 3
AFTER=$(rows)
wait_for DONE

{
  line DEV device "$("${ADB[@]}" shell getprop ro.product.model | tr -d '\r') / API $("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')"
  sed -n 's/.*A5|//p' "$LOG" | grep -v -e '^DONE$' -e '"id":"MS_'
  line MSQ "MediaStore photo rows before / after the moves" "before: $BEFORE/ after: $AFTER"
} >"$OUT"

"${ADB[@]}" shell rm -rf "$ROOT"
"${ADB[@]}" shell am force-stop "$APP"
"${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null
line MSQ2 "MediaStore photo rows after removing the folder and a rescan" "$(rows)" >>"$OUT"
grep -q '"id":"BASE"' "$OUT" || { echo "experiment did not finish, see $OUT" >&2; exit 1; }
echo "results: $OUT"
