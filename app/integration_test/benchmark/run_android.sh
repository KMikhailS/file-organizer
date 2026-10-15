#!/usr/bin/env bash
# Where the time of one cleanup operation goes (docs/stage2_android.md,
# 5.27), on one device or emulator, on the TEST ROOT only:
#   integration_test/benchmark/run_android.sh <adb-serial>
#
# The journal's transactions in each SQLite mode (in the app's own
# storage) and stat + move through the adapter in
# /storage/emulated/0/FileOrganizerTest, which the script removes with the
# app at the end. Writes the BENCH lines to build/benchmark_<serial>.txt.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/benchmark_test.log
OUT=build/benchmark_$SERIAL.txt

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[benchmark] $*" >&2; }

SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
MODEL=$("${ADB[@]}" shell getprop ro.product.model | tr -d '\r')
say "device $MODEL, API $SDK_INT"
if "${ADB[@]}" shell "ls -d $ROOT" >/dev/null 2>&1; then
  say "refusing: $ROOT exists already (left from another run?)"
  exit 2
fi

cleanup() {
  "${ADB[@]}" shell "rm -rf $ROOT" || true
  "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
}
trap cleanup EXIT

"$FLUTTER" build apk --debug >/dev/null
"${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
"${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow

STATUS=0
"$FLUTTER" test integration_test/benchmark/benchmark_test.dart -d "$SERIAL" >"$LOG" 2>&1 || STATUS=$?
{
  echo "device: $MODEL, API $SDK_INT ($SERIAL)"
  grep -o 'BENCH|[a-z_]*=[A-Za-z0-9]*' "$LOG" | cut -d'|' -f2
} | tee "$OUT" | sed 's/^/[benchmark] /' >&2
if [ "$STATUS" -ne 0 ]; then
  say "FAILED (log: $LOG)"
  grep -vE '^\s*$' "$LOG" | tail -30 >&2
  exit 1
fi
say "PASSED"
