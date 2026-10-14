#!/usr/bin/env bash
# The manual checklist on a phone (docs/stage2_android.md, section 10 and
# 5.25), on the TEST ROOT only: a debug build of the app takes
# /storage/emulated/0/FileOrganizerTest for the storage, so the owner's
# files are never touched. The owner acts on the phone; this script
# prepares and checks:
#   integration_test/checklist/phone.sh <adb-serial> prepare
#       fills the test root (as the full cycle does, with NOTES notes so
#       that a cleanup takes a while), installs the test build clean and
#       records the tree in build/checklist_before.txt
#   integration_test/checklist/phone.sh <adb-serial> status
#       how many files each top folder of the test root holds (the template
#       folders have the names of the app's language), the quarantine,
#       whether the app and its service run
#   integration_test/checklist/phone.sh <adb-serial> compare
#       the tree now against the recorded one, file by file
#   integration_test/checklist/phone.sh <adb-serial> finish
#       removes the test root and the app
set -euo pipefail

SERIAL=$1
COMMAND=${2:-status}
APP=com.brobrocode.file_organizer
ROOT=/storage/emulated/0/FileOrganizerTest
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
NOTES=${NOTES:-6000}
BEFORE=build/checklist_before.txt

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[checklist] $*" >&2; }

# shellcheck source=integration_test/support/test_root.sh
source integration_test/support/test_root.sh

case $COMMAND in
  prepare)
    if "${ADB[@]}" shell "ls -d $ROOT" >/dev/null 2>&1; then
      say "refusing: $ROOT exists already; run finish first"
      exit 2
    fi
    make_test_root
    "${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null
    snapshot >"$BEFORE"
    say "recorded $(grep -cE '^[0-9a-f]{32} ' "$BEFORE") files in $BEFORE"
    "$FLUTTER" build apk --debug --dart-define=FO_TEST_ROOT="$ROOT" >/dev/null
    "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
    "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
    say "the test build is installed: it sees only $ROOT"
    ;;
  status)
    "${ADB[@]}" shell "cd '$ROOT' 2>/dev/null || exit 0; \
      for d in */; do \
        echo \"\${d%/}: \$(find \"\$d\" -type f | wc -l) files\"; done; \
      echo \"quarantine: \$(find .FileOrganizer -type f 2>/dev/null | grep -vc nomedia) files\"" | tr -d '\r'
    PID=$("${ADB[@]}" shell pidof "$APP" | tr -d '\r' || true)
    SERVICE=$("${ADB[@]}" shell dumpsys activity services "$APP" | tr -d '\r' | grep -c 'isForeground=true' || true)
    echo "app process: ${PID:-none}; foreground service: $SERVICE"
    ;;
  compare)
    if [ "$(snapshot)" = "$(cat "$BEFORE")" ]; then
      say "the tree is as recorded: every file (date and md5), every folder"
    else
      say "the tree differs from the recorded one:"
      diff "$BEFORE" <(snapshot) | head -30 >&2 || true
      exit 1
    fi
    ;;
  finish)
    "${ADB[@]}" shell "rm -rf $ROOT"
    "${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null 2>&1 || true
    "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
    say "the test root and the app are gone"
    ;;
  *)
    say "unknown command $COMMAND (prepare, status, compare, finish)"
    exit 2
    ;;
esac
