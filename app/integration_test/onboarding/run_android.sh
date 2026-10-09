#!/usr/bin/env bash
# Runs the onboarding of the real app (docs/stage2_android.md, 5.17) on one
# device or emulator:
#   integration_test/onboarding/run_android.sh <adb-serial>
#
# Two passes, each on a clean install of com.brobrocode.file_organizer with
# the notification permission reset:
#  1. refuse:  no access; the script leaves the settings screen without
#              granting (the app must say so), then grants it; notifications
#              (Android 13+) are refused and the user goes on without them;
#  2. granted: the access is granted beforehand; notifications are allowed.
# Both end on the home screen with the folder names saved. Hides error
# dialogs while it runs and restores the setting.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/onboarding_test.log
UI=/data/local/tmp/fo-ui.xml

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[onboarding] $*" >&2; }
FAILED=0
fail() { say "FAIL: $*"; FAILED=1; }

# shellcheck source=integration_test/support/system_ui.sh
source integration_test/support/system_ui.sh

SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $SDK_INT"

HIDE_ERRORS=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  "${ADB[@]}" shell rm -f "$UI" || true
  if [ "${HIDE_ERRORS:-null}" = null ]; then
    "${ADB[@]}" shell settings delete global hide_error_dialogs >/dev/null || true
  else
    "${ADB[@]}" shell settings put global hide_error_dialogs "$HIDE_ERRORS" || true
  fi
}
trap cleanup EXIT
"${ADB[@]}" shell settings put global hide_error_dialogs 1

"$FLUTTER" build apk --debug >/dev/null

run_pass() {
  local name=$1
  say "pass: $name"
  "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
  "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
  if [ "$name" = granted ]; then
    "${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
  else
    "${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE default
  fi
  if [ "$SDK_INT" -ge 33 ]; then
    "${ADB[@]}" shell pm revoke "$APP" android.permission.POST_NOTIFICATIONS || true
    "${ADB[@]}" shell pm clear-permission-flags "$APP" \
      android.permission.POST_NOTIFICATIONS user-set user-fixed || true
  fi
  "${ADB[@]}" logcat -b crash -c

  "$FLUTTER" test integration_test/onboarding/onboarding_test.dart -d "$SERIAL" \
    --dart-define=PASS="$name" --dart-define=SDK_INT="$SDK_INT" >"$LOG.$name" 2>&1 &
  TEST_PID=$!
  local handled=0 actions
  while kill -0 "$TEST_PID" 2>/dev/null; do
    mapfile -t actions < <(grep -o 'ONBOARDING|[A-Z_]*' "$LOG.$name" | cut -d'|' -f2 || true)
    while [ "$handled" -lt "${#actions[@]}" ]; do
      case ${actions[$handled]} in
        ALL_FILES_* | NOTIFICATIONS_*) act "${actions[$handled]}" || true ;;
        *) say "test: ${actions[$handled]}" ;;
      esac
      handled=$((handled + 1))
    done
    sleep 0.3
  done
  local status=0
  wait "$TEST_PID" || status=$?
  TEST_PID=
  [ "$status" -eq 0 ] || { fail "$name: the test failed (log: $LOG.$name)"; grep -vE '^\s*$' "$LOG.$name" | tail -40 >&2; }
  grep -q 'ONBOARDING|HOME' "$LOG.$name" || fail "$name: never reached the home screen"
  local crashes
  crashes=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
  [ -z "$crashes" ] || { fail "$name: the app crashed"; echo "$crashes" >&2; }
}

run_pass refuse
run_pass granted

if [ "$FAILED" -eq 0 ]; then say "PASSED"; else say "FAILED"; fi
exit "$FAILED"
