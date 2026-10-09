#!/usr/bin/env bash
# Runs the native layer tests (docs/stage2_android.md, section 5.9) on one
# device or emulator:
#   integration_test/native/run_android.sh <adb-serial>
#
# Touches only /storage/emulated/0/FileOrganizerTest/ and removes it at the
# end. Installs the app (com.brobrocode.file_organizer), resets its "All
# files access" and notification permission, and plays the user when the
# test prints NATIVE|<action>:
#   ALL_FILES_BACK       settings screen opens → back, nothing granted
#   ALL_FILES_GRANT      settings screen opens → access granted → back
#   NOTIFICATIONS_DENY   permission dialog → "Don't allow"
#   NOTIFICATIONS_ALLOW  permission dialog → "Allow"
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=$(mktemp)
UI=/data/local/tmp/fo-ui.xml

cd "$(dirname "$0")/../.."

say() { echo "[run_android] $*" >&2; }

# shellcheck source=integration_test/support/system_ui.sh
source integration_test/support/system_ui.sh

SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $SDK_INT"

# The app must be installed to reset its permissions before the test starts;
# `flutter test` then reinstalls it and keeps them.
if ! "${ADB[@]}" shell pm path "$APP" >/dev/null 2>&1; then
  "$FLUTTER" build apk --debug
  "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
fi
"${ADB[@]}" shell am force-stop "$APP"
# Error dialogs of other apps (a launcher that is slow to answer) would
# cover the screens the script works with; restored at the end.
HIDE_ERRORS=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
"${ADB[@]}" shell settings put global hide_error_dialogs 1
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE default
if [ "$SDK_INT" -ge 33 ]; then
  "${ADB[@]}" shell pm revoke "$APP" android.permission.POST_NOTIFICATIONS || true
  "${ADB[@]}" shell pm clear-permission-flags "$APP" \
    android.permission.POST_NOTIFICATIONS user-set user-fixed || true
fi

# MediaStore files for the capture dates.
"${ADB[@]}" shell rm -rf "$ROOT"
"${ADB[@]}" shell mkdir -p "$ROOT/dates"
"${ADB[@]}" push integration_test/native/fixtures/photo.jpg "$ROOT/dates/photo.jpg" >/dev/null
"${ADB[@]}" shell "echo plain > $ROOT/dates/plain.txt"
"${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null

cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  cp "$LOG" build/native_test.log 2>/dev/null || true
  "${ADB[@]}" shell rm -rf "$ROOT" "$UI" || true
  if [ "${HIDE_ERRORS:-null}" = null ]; then
    "${ADB[@]}" shell settings delete global hide_error_dialogs >/dev/null || true
  else
    "${ADB[@]}" shell settings put global hide_error_dialogs "$HIDE_ERRORS" || true
  fi
  rm -f "$LOG"
}
trap cleanup EXIT

"${ADB[@]}" logcat -b crash -c
"$FLUTTER" test integration_test/native/native_test.dart -d "$SERIAL" \
  --dart-define=SDK_INT="$SDK_INT" >"$LOG" 2>&1 &
TEST_PID=$!

handled=0
while kill -0 "$TEST_PID" 2>/dev/null; do
  mapfile -t actions < <(grep -o 'NATIVE|[A-Z_]*' "$LOG" | cut -d'|' -f2 || true)
  while [ "$handled" -lt "${#actions[@]}" ]; do
    act "${actions[$handled]}" || true
    handled=$((handled + 1))
  done
  sleep 0.3
done

STATUS=0
wait "$TEST_PID" || STATUS=$?
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
if [ -n "$CRASHES" ]; then
  say "the app crashed:"
  echo "$CRASHES" >&2
  STATUS=1
fi
grep -E '^[0-9]+:[0-9]+ \+[0-9]+' "$LOG" | tail -1 || true
if [ "$STATUS" -ne 0 ]; then
  grep -vE '^\s*$' "$LOG" | tail -60
fi
exit "$STATUS"
