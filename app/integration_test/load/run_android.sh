#!/usr/bin/env bash
# The load test (docs/stage2_android.md, section 10 and 5.25) on one device
# or emulator, on the TEST ROOT only:
#   integration_test/load/run_android.sh <adb-serial>
#
# Writes FILES (default 50000) small files into
# /storage/emulated/0/FileOrganizerTest: 40% in Download/, 20% in Telegram
# and 20% in WhatsApp (cleaned), 20% in DCIM/Camera (the user's own);
# every 25th file repeats the one before (a duplicate). The app takes that
# folder for the storage, so nothing else is touched. The test plans,
# executes and undoes, and reports the times and the memory; the script
# writes them to build/load_<serial>.txt and removes the test root and the
# app.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
FILES=${FILES:-50000}
LOG=build/load_test.log
OUT=build/load_$SERIAL.txt

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[load] $*" >&2; }

SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
MODEL=$("${ADB[@]}" shell getprop ro.product.model | tr -d '\r')
say "device $MODEL, API $SDK_INT"
if "${ADB[@]}" shell "ls -d $ROOT" >/dev/null 2>&1; then
  say "refusing: $ROOT exists already (left from another run?)"
  exit 2
fi

cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  say "removing the test root"
  "${ADB[@]}" shell "rm -rf $ROOT" || true
  "${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null 2>&1 || true
  "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# One shell loop with builtins only: no process per file.
write() { # folder count extension-list
  "${ADB[@]}" shell "mkdir -p '$ROOT/$1' && cd '$ROOT/$1' && \
    pad=0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz && \
    set -- $3 && n=\$#; prev=; \
    i=1; while [ \$i -le $2 ]; do \
      k=\$(( i % n + 1 )); eval ext=\\\${\$k}; \
      if [ \$(( i % 25 )) -eq 0 ]; then body=\$prev; else body=\"$1 \$i \$pad\"; \
        r=\$(( i % 7 )); while [ \$r -gt 0 ]; do body=\"\$body\$pad\"; r=\$(( r - 1 )); done; fi; \
      echo \"\$body\" > f_\$i.\$ext; prev=\$body; i=\$(( i + 1 )); done"
}
START=$(date +%s)
say "writing $FILES files"
write Download $((FILES * 4 / 10)) "pdf txt docx jpg png mp3 mp4 zip apk xyz"
write "Telegram/Telegram Documents" $((FILES * 2 / 10)) "pdf docx txt zip"
write "WhatsApp/Media/WhatsApp Images" $((FILES * 2 / 10)) "jpg"
write DCIM/Camera $((FILES * 2 / 10)) "jpg"
COUNT=$("${ADB[@]}" shell "find $ROOT -type f | wc -l" | tr -d '\r ')
say "wrote $COUNT files in $(( $(date +%s) - START )) s"

"$FLUTTER" build apk --debug >/dev/null
"${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow

"$FLUTTER" test integration_test/load/load_test.dart -d "$SERIAL" >"$LOG" 2>&1 &
TEST_PID=$!
STATUS=0
wait "$TEST_PID" || STATUS=$?
TEST_PID=
{
  echo "device: $MODEL, API $SDK_INT ($SERIAL)"
  echo "files: $COUNT"
  grep -o 'LOAD|[a-z_]*=[A-Za-z0-9]*' "$LOG" | cut -d'|' -f2
} | tee "$OUT" | sed 's/^/[load] /' >&2
if [ "$STATUS" -ne 0 ]; then
  say "FAILED (log: $LOG)"
  grep -vE '^\s*$' "$LOG" | tail -30 >&2
  exit 1
fi
say "PASSED"
