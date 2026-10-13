#!/usr/bin/env bash
# Kills a cleanup in the middle and undoes it after the restart
# (docs/stage2_android.md, 5.21), on an EMULATOR only:
#   integration_test/interrupted/run_android.sh <emulator-serial>
#
# It moves files in shared storage, so it refuses a real device, and an
# emulator whose Download/ or messenger folders are not empty (the
# quarantine folder .FileOrganizer/ does not count).
#
# Puts FILES (default 2000) small text files into Download/, installs the
# app clean with "All files access" (and notifications on Android 13+),
# runs the test in phase "apply" (kept installed), kills the app with
# `am force-stop` while it moves the files, checks that some files moved
# and some did not, runs phase "recover" ("Undo it"), then checks that
# Download/ is back file by file (md5) and that no test file is left
# anywhere else. Removes the test files, the quarantine and the app at the
# end.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
STORAGE=/storage/emulated/0
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/interrupted_test.log
FILES=${FILES:-2000}

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[interrupted] $*" >&2; }
FAILED=0
fail() { say "FAIL: $*"; FAILED=1; }

QEMU=$("${ADB[@]}" shell 'getprop ro.kernel.qemu; getprop ro.boot.qemu' | tr -d '\r' | tr -d '\n')
if [[ $SERIAL != emulator-* || $QEMU != *1* ]]; then
  say "refusing $SERIAL: not an emulator (this test moves files in shared storage)"
  exit 2
fi
SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $SDK_INT"

for _ in $(seq 1 60); do
  "${ADB[@]}" shell "ls $STORAGE/Download" >/dev/null 2>&1 && break
  sleep 1
done
BUSY=$("${ADB[@]}" shell "ls -A $STORAGE/Download; ls -d $STORAGE/Telegram $STORAGE/WhatsApp 2>/dev/null; ls $STORAGE/Documents | grep fo14_ | head -1" | tr -d '\r' || true)
if [ -n "$BUSY" ]; then
  say "refusing: the emulator storage is not clean:"
  echo "$BUSY" | head -5 >&2
  exit 2
fi

HIDE=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  "${ADB[@]}" shell "rm -f $STORAGE/Download/fo14_* $STORAGE/Documents/fo14_*; rm -rf $STORAGE/.FileOrganizer" || true
  "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
  if [ "$HIDE" = null ]; then
    "${ADB[@]}" shell settings delete global hide_error_dialogs >/dev/null || true
  else
    "${ADB[@]}" shell settings put global hide_error_dialogs "$HIDE" || true
  fi
}
trap cleanup EXIT
"${ADB[@]}" shell settings put global hide_error_dialogs 1

say "$FILES test files in Download/"
"${ADB[@]}" shell "cd $STORAGE/Download && for i in \$(seq -w 1 $FILES); do echo \"fo14 file \$i\" > fo14_\$i.txt; done"
BEFORE=$("${ADB[@]}" shell "cd $STORAGE/Download && md5sum fo14_*" | tr -d '\r' | sort)
[ "$(echo "$BEFORE" | wc -l)" -eq "$FILES" ] || { say "could not write the test files"; exit 1; }

"$FLUTTER" build apk --debug >/dev/null
"${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
if [ "$SDK_INT" -ge 33 ]; then
  "${ADB[@]}" shell pm grant "$APP" android.permission.POST_NOTIFICATIONS
fi
"${ADB[@]}" logcat -b crash -c

say "phase apply"
"$FLUTTER" test integration_test/interrupted/interrupted_test.dart -d "$SERIAL" \
  --no-uninstall --dart-define=PHASE=apply >"$LOG.apply" 2>&1 &
TEST_PID=$!
for _ in $(seq 1 1200); do
  grep -q 'INTERRUPTED|EXECUTING' "$LOG.apply" && break
  kill -0 "$TEST_PID" 2>/dev/null || break
  sleep 0.25
done
if ! grep -q 'INTERRUPTED|EXECUTING' "$LOG.apply"; then
  fail "the cleanup never got under way (log: $LOG.apply)"
  grep -vE '^\s*$' "$LOG.apply" | tail -30 >&2
  exit 1
fi
"${ADB[@]}" shell am force-stop "$APP"
say "killed the app while it moved the files"
wait "$TEST_PID" 2>/dev/null || true
TEST_PID=

MOVED=$("${ADB[@]}" shell "ls $STORAGE/Documents | grep -c '^fo14_'" | tr -d '\r' || true)
LEFT=$("${ADB[@]}" shell "ls $STORAGE/Download | grep -c '^fo14_'" | tr -d '\r' || true)
say "after the kill: $MOVED in Documents/, $LEFT still in Download/"
[ "${MOVED:-0}" -gt 0 ] && [ "${LEFT:-0}" -gt 0 ] || fail "the kill did not land in the middle of the moves"

say "phase recover"
STATUS=0
"$FLUTTER" test integration_test/interrupted/interrupted_test.dart -d "$SERIAL" \
  --no-uninstall --dart-define=PHASE=recover >"$LOG.recover" 2>&1 || STATUS=$?
grep -o 'INTERRUPTED|[A-Z]*' "$LOG.recover" | sed 's/^/[interrupted] test: /' >&2 || true
[ "$STATUS" -eq 0 ] || { fail "the recover phase failed (log: $LOG.recover)"; grep -vE '^\s*$' "$LOG.recover" | tail -40 >&2; }

AFTER=$("${ADB[@]}" shell "cd $STORAGE/Download && md5sum fo14_*" | tr -d '\r' | sort)
if [ "$BEFORE" = "$AFTER" ]; then
  say "Download/ is back as it was ($FILES files, same content)"
else
  fail "Download/ differs after the undo"
  diff <(echo "$BEFORE") <(echo "$AFTER") | head -10 >&2 || true
fi
STRAY=$("${ADB[@]}" shell "ls $STORAGE/Documents | grep -c '^fo14_'" | tr -d '\r' || true)
[ "${STRAY:-0}" -eq 0 ] || fail "$STRAY test files left in Documents/"
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
[ -z "$CRASHES" ] || { fail "the app crashed"; echo "$CRASHES" >&2; }

if [ "$FAILED" -eq 0 ]; then say "PASSED"; else say "FAILED"; fi
exit "$FAILED"
