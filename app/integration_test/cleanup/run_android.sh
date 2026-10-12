#!/usr/bin/env bash
# Applies a plan through the real UI and undoes it (docs/stage2_android.md,
# 5.19), on an EMULATOR only:
#   integration_test/cleanup/run_android.sh <emulator-serial>
#
# It moves files in shared storage, so it refuses a real device: there the
# plan would include the owner's own files. It also refuses an emulator
# whose Download/ or messenger folders are not empty (the quarantine folder
# .FileOrganizer/ that every start of the app makes does not count).
#
# Puts five test files into Download/ (a document and its copy, a song, a
# photo with a capture date, an archive), installs the app clean with "All
# files access" (and notifications on Android 13+), runs the test, then
# checks that every file is back with its content and removes the test
# files, the template folders the cleanup made and the quarantine.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
STORAGE=/storage/emulated/0
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/cleanup_test.log
FILES=(fo13_report.pdf "fo13_report (1).pdf" fo13_song.mp3 fo13_photo.jpg fo13_archive.zip)

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[cleanup] $*" >&2; }
FAILED=0
fail() { say "FAIL: $*"; FAILED=1; }

QEMU=$("${ADB[@]}" shell 'getprop ro.kernel.qemu; getprop ro.boot.qemu' | tr -d '\r' | tr -d '\n')
if [[ $SERIAL != emulator-* || $QEMU != *1* ]]; then
  say "refusing $SERIAL: not an emulator (this test moves files in shared storage)"
  exit 2
fi
SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $SDK_INT"

# Shared storage comes up a little after boot_completed.
for _ in $(seq 1 60); do
  "${ADB[@]}" shell "ls $STORAGE/Download" >/dev/null 2>&1 && break
  sleep 1
done
BUSY=$("${ADB[@]}" shell "ls -A $STORAGE/Download; ls -d $STORAGE/Telegram $STORAGE/WhatsApp $STORAGE/Photos $STORAGE/Archives 2>/dev/null" | tr -d '\r' || true)
if [ -n "$BUSY" ]; then
  say "refusing: the emulator storage is not clean:"
  echo "$BUSY" >&2
  exit 2
fi

HIDE=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  for f in "${FILES[@]}"; do
    "${ADB[@]}" shell "rm -f '$STORAGE/Download/$f' '$STORAGE/Documents/$f' '$STORAGE/Music/$f' '$STORAGE/Photos/2021/$f' '$STORAGE/Archives/$f'" || true
  done
  "${ADB[@]}" shell "rmdir $STORAGE/Photos/2021 $STORAGE/Photos $STORAGE/Archives 2>/dev/null; rm -rf $STORAGE/.FileOrganizer" || true
  if [ "$HIDE" = null ]; then
    "${ADB[@]}" shell settings delete global hide_error_dialogs >/dev/null || true
  else
    "${ADB[@]}" shell settings put global hide_error_dialogs "$HIDE" || true
  fi
}
trap cleanup EXIT
"${ADB[@]}" shell settings put global hide_error_dialogs 1

say "test files in Download/"
"${ADB[@]}" shell "echo 'report 2024' > '$STORAGE/Download/fo13_report.pdf'"
"${ADB[@]}" shell "touch -d '2024-01-15 10:00:00' '$STORAGE/Download/fo13_report.pdf'"
# The copy came later (as a second download does): the original stays.
"${ADB[@]}" shell "cp '$STORAGE/Download/fo13_report.pdf' '$STORAGE/Download/fo13_report (1).pdf'"
"${ADB[@]}" shell "head -c 4000 /dev/urandom > '$STORAGE/Download/fo13_song.mp3'"
"${ADB[@]}" push integration_test/native/fixtures/photo.jpg "$STORAGE/Download/fo13_photo.jpg" >/dev/null
"${ADB[@]}" shell "head -c 3000 /dev/urandom > '$STORAGE/Download/fo13_archive.zip'"
"${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null
BEFORE=$("${ADB[@]}" shell "cd $STORAGE/Download && md5sum fo13_*" | tr -d '\r' | sort)

"$FLUTTER" build apk --debug >/dev/null
"${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
if [ "$SDK_INT" -ge 33 ]; then
  "${ADB[@]}" shell pm grant "$APP" android.permission.POST_NOTIFICATIONS
fi
"${ADB[@]}" logcat -b crash -c

STATUS=0
"$FLUTTER" test integration_test/cleanup/cleanup_test.dart -d "$SERIAL" >"$LOG" 2>&1 || STATUS=$?
grep -o 'CLEANUP|[A-Z]*' "$LOG" | sed 's/^/[cleanup] test: /' >&2 || true
[ "$STATUS" -eq 0 ] || { fail "the test failed (log: $LOG)"; grep -vE '^\s*$' "$LOG" | tail -40 >&2; }
grep -q 'CLEANUP|UNDONE' "$LOG" || fail "the test did not undo"

AFTER=$("${ADB[@]}" shell "cd $STORAGE/Download && md5sum fo13_*" | tr -d '\r' | sort)
if [ "$BEFORE" = "$AFTER" ]; then
  say "Download/ is back as it was (5 files, same content)"
else
  fail "Download/ differs after undo"
  diff <(echo "$BEFORE") <(echo "$AFTER") >&2 || true
fi
LEFT=$("${ADB[@]}" shell "ls -d $STORAGE/Photos $STORAGE/Archives $STORAGE/Documents/fo13_* $STORAGE/Music/fo13_* 2>/dev/null" | tr -d '\r' || true)
[ -z "$LEFT" ] || fail "left after undo: $LEFT"
CRASHES=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
[ -z "$CRASHES" ] || { fail "the app crashed"; echo "$CRASHES" >&2; }

if [ "$FAILED" -eq 0 ]; then say "PASSED"; else say "FAILED"; fi
exit "$FAILED"
