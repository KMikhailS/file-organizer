#!/usr/bin/env bash
# The full cycle of the real app (docs/stage2_android.md, section 10 and
# 5.25) on one device or emulator, on the TEST ROOT only:
#   integration_test/full_cycle/run_android.sh <adb-serial>
#
# The app takes /storage/emulated/0/FileOrganizerTest for the storage, so
# this is safe on a real phone: nothing outside that folder is touched. The
# script fills it with "a phone with duplicate photos" (camera photos with
# copies in Telegram and WhatsApp) and "a typical Download folder" (plus
# NOTES small notes, so that the execution takes a while), records every
# file (path, modification time, md5), installs the app clean,
# grants the permissions on the system screens when the test asks, presses
# Home while the cleanup executes and opens the app again, and at the end
# compares the tree after the undo with the one before. Checks that the
# service holds its wake lock while it runs and none is left at the end.
# Removes the test
# root and the app at the end; hides error dialogs while it runs.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/full_cycle_test.log
UI=/data/local/tmp/fo-ui.xml
NOTES=${NOTES:-1500}
# With LOW_SPACE_MB, the storage is filled up to leave about that much free
# space while the app works ("little free space" of the checklist); the
# filler lives in /data/local/tmp (the same partition) and is removed.
LOW_SPACE_MB=${LOW_SPACE_MB:-}
FILLER=/data/local/tmp/fo_filler.bin
# Android refuses to install below its low-storage threshold (up to 500 MB),
# so this much stays free until the test APK is in.
INSTALL_MB=1000

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[full_cycle] $*" >&2; }
FAILED=0
wake_locks() {
  # Only the locks held now: the "Wake Locks: size=N" section.
  "${ADB[@]}" shell dumpsys power | tr -d '\r' |
    awk '/^Wake Locks: size=/ { on = 1; next } on && /^$/ { on = 0 } on' |
    grep -c "FileOrganizer:cleanup" || true
}
free_kb() {
  "${ADB[@]}" shell "df -k /storage/emulated/0 | tail -1" | tr -s ' ' | cut -d' ' -f4 | tr -d '\r'
}
fail() { say "FAIL: $*"; FAILED=1; }

# shellcheck source=integration_test/support/system_ui.sh
source integration_test/support/system_ui.sh
# shellcheck source=integration_test/support/test_root.sh
source integration_test/support/test_root.sh

SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $SDK_INT"

HIDE=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  "${ADB[@]}" shell "rm -rf $ROOT $UI $FILLER $FILLER.2" || true
  "${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null 2>&1 || true
  "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
  if [ "${HIDE:-null}" = null ]; then
    "${ADB[@]}" shell settings delete global hide_error_dialogs >/dev/null || true
  else
    "${ADB[@]}" shell settings put global hide_error_dialogs "$HIDE" || true
  fi
}
trap cleanup EXIT
"${ADB[@]}" shell settings put global hide_error_dialogs 1

for _ in $(seq 1 60); do
  "${ADB[@]}" shell "ls /storage/emulated/0/" >/dev/null 2>&1 && break
  sleep 1
done
if "${ADB[@]}" shell "ls -d $ROOT" >/dev/null 2>&1; then
  say "refusing: $ROOT exists already (left from another run?)"
  trap - EXIT
  exit 2
fi

make_test_root

BEFORE=$(snapshot)

if [ -n "$LOW_SPACE_MB" ]; then
  FILL_MB=$(( $(free_kb) / 1024 - LOW_SPACE_MB - INSTALL_MB ))
  if [ "$FILL_MB" -gt 0 ]; then
    say "filling ${FILL_MB} MB (the APK still needs room to install)"
    "${ADB[@]}" shell "dd if=/dev/zero of=$FILLER bs=1048576 count=$FILL_MB" >/dev/null 2>&1 || true
  fi
fi
say "recorded $(echo "$BEFORE" | grep -cE '^[0-9a-f]{32} ') files"

"$FLUTTER" build apk --debug >/dev/null
"${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE default
if [ "$SDK_INT" -ge 33 ]; then
  "${ADB[@]}" shell pm revoke "$APP" android.permission.POST_NOTIFICATIONS || true
  "${ADB[@]}" shell pm clear-permission-flags "$APP" \
    android.permission.POST_NOTIFICATIONS user-set user-fixed || true
fi
"${ADB[@]}" logcat -b crash -c

"$FLUTTER" test integration_test/full_cycle/full_cycle_test.dart -d "$SERIAL" \
  --dart-define=SDK_INT="$SDK_INT" >"$LOG" 2>&1 &
TEST_PID=$!
if [ -n "$LOW_SPACE_MB" ]; then
  # Once installed, take the room the APK needed as well.
  for _ in $(seq 1 600); do
    grep -q 'CYCLE|' "$LOG" && break
    sleep 0.5
  done
  FILL_MB=$(( $(free_kb) / 1024 - LOW_SPACE_MB ))
  [ "$FILL_MB" -gt 0 ] && "${ADB[@]}" shell "dd if=/dev/zero of=$FILLER.2 bs=1048576 count=$FILL_MB" >/dev/null 2>&1 || true
  say "free now: $(( $(free_kb) / 1024 )) MB"
fi
handled=0
while kill -0 "$TEST_PID" 2>/dev/null; do
  mapfile -t actions < <(grep -o 'CYCLE|[A-Z_]*' "$LOG" | cut -d'|' -f2 || true)
  while [ "$handled" -lt "${#actions[@]}" ]; do
    action=${actions[$handled]}
    case $action in
      ALL_FILES_* | NOTIFICATIONS_*) act "$action" || true ;;
      LEAVE)
        "${ADB[@]}" shell input keyevent KEYCODE_HOME
        sleep 2
        RUNNING=$("${ADB[@]}" shell dumpsys activity services "$APP" | tr -d '\r' | grep -c 'isForeground=true' || true)
        [ "$RUNNING" -ge 1 ] && say "in the background: the service runs" || say "in the background: no service (the work may have ended)"
        # The service keeps the CPU awake while it runs (5.26).
        WAKE=$(wake_locks)
        if [ "$RUNNING" -ge 1 ]; then
          [ "$WAKE" -ge 1 ] && say "the cleanup holds its wake lock" || fail "no wake lock while the service runs"
        fi
        "${ADB[@]}" shell am start -n "$APP/.MainActivity" >/dev/null ;;
      APPLIED)
        # The test waits 5 s here: the work is over, the app still runs.
        for _ in $(seq 1 10); do [ "$(wake_locks)" -eq 0 ] && break; sleep 0.3; done
        [ "$(wake_locks)" -eq 0 ] && say "the work is over: no wake lock left" || fail "the wake lock is still held after the work"
        WAKE_CHECKED=1 ;;
      *) say "test: $action" ;;
    esac
    handled=$((handled + 1))
  done
  sleep 0.3
done
STATUS=0
wait "$TEST_PID" || STATUS=$?
TEST_PID=
grep -o 'CYCLE|[A-Z]*' "$LOG" | tail -3 | sed 's/^/[full_cycle] test: /' >&2 || true
[ "$STATUS" -eq 0 ] || { fail "the test failed (log: $LOG)"; grep -vE '^\s*$' "$LOG" | tail -40 >&2; }
grep -q 'CYCLE|UNDONE' "$LOG" || fail "the test did not undo"
[ "${WAKE_CHECKED:-0}" -eq 1 ] || fail "the wake lock was not checked after the work"

AFTER=$(snapshot)
if [ "$BEFORE" = "$AFTER" ]; then
  say "the tree is back as it was: every file (date and md5), every folder"
else
  fail "the tree differs after the undo"
  diff <(echo "$BEFORE") <(echo "$AFTER") | head -20 >&2 || true
fi
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
[ -z "$CRASHES" ] || { fail "the app crashed"; echo "$CRASHES" >&2; }

if [ "$FAILED" -eq 0 ]; then say "PASSED"; else say "FAILED"; fi
exit "$FAILED"
