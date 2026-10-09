#!/usr/bin/env bash
# Checks that a cleanup survives leaving the app (docs/stage2_android.md,
# sections 5.3 and 5.13) on one device or emulator:
#   integration_test/lifecycle/run_android.sh <adb-serial>
#
# Uses /storage/emulated/0/FileOrganizerTest/ (about 2 GB of test files) and
# removes it at the end. Hides error dialogs while it runs, and restores
# the setting. Grants "All files access" to the app
# (com.brobrocode.file_organizer).
#
#  1. The test starts a plan; while it analyzes large duplicates it closes
#     its screen (the activity finishes). The script checks that the
#     activity is gone, runs `am kill` (a process with a foreground service
#     must survive it) and checks that the notification keeps changing;
#     then it opens the app again. The test
#     checks that the work went on in the background and that the app came
#     back to the same workflow; the script that only one Flutter engine was
#     created (the cached one was reused).
#  2. Control: the app idle in the background, without the service, is
#     killed by the same `am kill`.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/lifecycle_test.log
GROUPS_OF_DUPLICATES=${GROUPS_OF_DUPLICATES:-10}

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[lifecycle] $*" >&2; }
fail() { say "FAIL: $*"; FAILED=1; }
FAILED=0

pid() { "${ADB[@]}" shell pidof "$APP" | tr -d '\r' || true; }
progress() {
  "${ADB[@]}" shell dumpsys notification --noredact | tr -d '\r' |
    grep -A40 "pkg=$APP" | grep -E 'android\.(progress|text)=' | tr '\n' ' ' || true
}
foreground_service() {
  "${ADB[@]}" shell dumpsys activity services "$APP" | tr -d '\r' |
    grep -c 'isForeground=true' || true
}

say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')"

HIDE=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
restore() {
  local name=$1 value=$2
  if [ "$value" = null ]; then
    "${ADB[@]}" shell settings delete global "$name" >/dev/null || true
  else
    "${ADB[@]}" shell settings put global "$name" "$value" || true
  fi
}
cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  "${ADB[@]}" shell rm -rf "$ROOT" || true
  restore hide_error_dialogs "$HIDE"
}
trap cleanup EXIT
"${ADB[@]}" shell settings put global hide_error_dialogs 1

# Shared storage comes up a little after boot_completed.
for _ in $(seq 1 60); do
  "${ADB[@]}" shell "mkdir -p $ROOT && touch $ROOT/.ready" >/dev/null 2>&1 && break
  sleep 1
done

# Large duplicates: groups of two equal files, each group of its own size.
say "writing $GROUPS_OF_DUPLICATES groups of 2 x 100 MB"
"${ADB[@]}" shell rm -rf "$ROOT"
"${ADB[@]}" shell mkdir -p "$ROOT/big"
"${ADB[@]}" shell "dd if=/dev/urandom of=$ROOT/base bs=1M count=100" >/dev/null 2>&1
for i in $(seq 1 "$GROUPS_OF_DUPLICATES"); do
  "${ADB[@]}" shell "cp $ROOT/base $ROOT/big/g$i-a && head -c $i /dev/urandom >> $ROOT/big/g$i-a && cp $ROOT/big/g$i-a $ROOT/big/g$i-b"
done
"${ADB[@]}" shell rm "$ROOT/base"

if ! "${ADB[@]}" shell pm path "$APP" >/dev/null 2>&1; then
  "$FLUTTER" build apk --debug
  "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
fi
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
# Without it Android 13+ hides the notification of the service.
SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
if [ "$SDK_INT" -ge 33 ]; then
  "${ADB[@]}" shell pm grant "$APP" android.permission.POST_NOTIFICATIONS
fi
"${ADB[@]}" logcat -c
"${ADB[@]}" logcat -b crash -c

"$FLUTTER" test integration_test/lifecycle/lifecycle_test.dart -d "$SERIAL" >"$LOG" 2>&1 &
TEST_PID=$!

for _ in $(seq 1 600); do
  grep -q 'LIFECYCLE|LEFT' "$LOG" && break
  kill -0 "$TEST_PID" 2>/dev/null || break
  sleep 0.5
done
if grep -q 'LIFECYCLE|LEFT' "$LOG"; then
  BEFORE=$(pid)
  sleep 3
  ACTIVITIES=$("${ADB[@]}" shell dumpsys activity activities | tr -d '\r' |
    grep -c "Hist.*$APP/.MainActivity" || true)
  [ "$ACTIVITIES" -eq 0 ] || fail "the activity is still there"
  "${ADB[@]}" shell am kill "$APP"
  sleep 2
  AFTER=$(pid)
  [ -n "$BEFORE" ] && [ "$BEFORE" = "$AFTER" ] || fail "the process did not survive am kill ($BEFORE -> $AFTER)"
  [ "$(foreground_service)" -ge 1 ] || fail "no foreground service while working"
  P1=$(progress); sleep 6; P2=$(progress)
  say "notification: $P1"
  say "6 s later:    $P2"
  [ -n "$P1" ] && [ "$P1" != "$P2" ] || fail "the notification did not change in the background"
  "${ADB[@]}" shell am start -n "$APP/.MainActivity" >/dev/null
else
  fail "the test never left its screen"
fi

STATUS=0
wait "$TEST_PID" || STATUS=$?
TEST_PID=
grep -o 'LIFECYCLE|[A-Za-z=0-9 ]*' "$LOG" | sed 's/^/[lifecycle] /' >&2 || true
[ "$STATUS" -eq 0 ] || fail "the test failed (log: $LOG)"
ENGINES=$("${ADB[@]}" logcat -d -s FileOrganizer:I | grep -c 'new Flutter engine' || true)
[ "$ENGINES" -eq 1 ] || fail "$ENGINES Flutter engines were created: the cached one was not reused"
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
[ -z "$CRASHES" ] || { fail "the app crashed"; echo "$CRASHES" >&2; }

# Control: the real app, idle in the background without the service.
say "control: the app idle in the background"
"$FLUTTER" build apk --debug >/dev/null
"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
"${ADB[@]}" logcat -b crash -c
"${ADB[@]}" shell am start -n "$APP/.MainActivity" >/dev/null
sleep 8
[ -n "$(pid)" ] || fail "the app did not start"
[ "$(foreground_service)" -eq 0 ] || fail "a foreground service while idle"
"${ADB[@]}" shell input keyevent KEYCODE_HOME
sleep 3
"${ADB[@]}" shell am kill "$APP"
sleep 2
[ -z "$(pid)" ] || fail "an idle app was not killed: am kill proves nothing"
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
[ -z "$CRASHES" ] || { fail "the app crashed"; echo "$CRASHES" >&2; }

if [ "$FAILED" -eq 0 ]; then say "PASSED"; else say "FAILED"; fi
exit "$FAILED"
