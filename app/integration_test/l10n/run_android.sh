#!/usr/bin/env bash
# Checks that the language of the device reaches the app
# (docs/stage2_android.md, 5.15) on one device or emulator:
#   integration_test/l10n/run_android.sh <adb-serial>
#
# Two passes, each on a clean install of com.brobrocode.file_organizer:
#  1. the device as it is (English expected on the emulators);
#  2. Russian: on Android 13+ the language of the app
#     (`cmd locale set-app-locales`), below it the language of the system
#     (needs `adb root`; the framework restarts, and again at the end to
#     restore the old language; an empty old value comes back as en-US,
#     the default of the emulator images; adbd leaves root again).
# In each pass the test checks the resolved language and the proposed
# folder names, confirms them and shows the progress notification; the
# script reads its title, text and channel from `dumpsys notification`.
# Hides error dialogs while it runs and restores the setting.
set -euo pipefail

SERIAL=$1
APP=com.brobrocode.file_organizer
SDK=${ANDROID_HOME:-$HOME/development/android-sdk}
ADB=("$SDK/platform-tools/adb" -s "$SERIAL")
FLUTTER=${FLUTTER:-$HOME/development/flutter/bin/flutter}
LOG=build/l10n_test.log

cd "$(dirname "$0")/../.."
mkdir -p build

say() { echo "[l10n] $*" >&2; }
fail() { say "FAIL: $*"; FAILED=1; }
FAILED=0

SDK_INT=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
say "device $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), API $SDK_INT"

HIDE=$("${ADB[@]}" shell settings get global hide_error_dialogs | tr -d '\r')
OLD_LOCALE=""
SYSTEM_LOCALE_CHANGED=0
ROOTED=0

wait_for_framework() {
  for _ in $(seq 1 120); do
    if [ "$("${ADB[@]}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] &&
      "${ADB[@]}" shell pm path android >/dev/null 2>&1; then
      sleep 5
      return 0
    fi
    sleep 1
  done
  say "the framework did not come back"
  return 1
}
set_system_locale() {
  # `stop` resets sys.boot_completed, so wait_for_framework waits for real.
  "${ADB[@]}" shell "setprop persist.sys.locale $1 && stop && setprop sys.boot_completed 0 && start"
  wait_for_framework
}
cleanup() {
  [ -n "${TEST_PID:-}" ] && kill "$TEST_PID" 2>/dev/null || true
  if [ "$SYSTEM_LOCALE_CHANGED" = 1 ]; then
    say "restoring the system language '${OLD_LOCALE:-en-US}'"
    set_system_locale "${OLD_LOCALE:-en-US}" || true
  fi
  if [ "$ROOTED" = 1 ]; then
    "$SDK/platform-tools/adb" -s "$SERIAL" unroot >/dev/null || true
  fi
  if [ "$HIDE" = null ]; then
    "${ADB[@]}" shell settings delete global hide_error_dialogs >/dev/null || true
  else
    "${ADB[@]}" shell settings put global hide_error_dialogs "$HIDE" || true
  fi
}
trap cleanup EXIT
"${ADB[@]}" shell settings put global hide_error_dialogs 1

"$FLUTTER" build apk --debug >/dev/null

notification() {
  "${ADB[@]}" shell dumpsys notification --noredact | tr -d '\r' |
    grep -A40 "pkg=$APP" | grep -E 'android\.(title|text)=' | tr '\n' ' ' || true
}
channel() {
  "${ADB[@]}" shell dumpsys notification --noredact | tr -d '\r' |
    grep -o "mName=$1" | head -1 || true
}

# pass <language> <title> <text> <channel>
pass() {
  local language=$1 title=$2 text=$3 channel_name=$4
  say "pass: $language"
  "${ADB[@]}" uninstall "$APP" >/dev/null 2>&1 || true
  "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
  "${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
  if [ "$SDK_INT" -ge 33 ]; then
    "${ADB[@]}" shell pm grant "$APP" android.permission.POST_NOTIFICATIONS
    if [ "$language" = ru ]; then
      "${ADB[@]}" shell cmd locale set-app-locales "$APP" --locales ru-RU
    fi
  fi
  "${ADB[@]}" logcat -b crash -c

  "$FLUTTER" test integration_test/l10n/l10n_test.dart -d "$SERIAL" \
    --dart-define=EXPECT_LANGUAGE="$language" >"$LOG.$language" 2>&1 &
  TEST_PID=$!
  for _ in $(seq 1 600); do
    grep -q 'L10N|SHOWN' "$LOG.$language" && break
    kill -0 "$TEST_PID" 2>/dev/null || break
    sleep 0.5
  done
  if grep -q 'L10N|SHOWN' "$LOG.$language"; then
    sleep 1
    local shown
    shown=$(notification)
    say "notification: $shown"
    case "$shown" in
      *"android.title=String ($title)"*"android.text=String ($text)"*) ;;
      *) fail "$language: expected title '$title' and text '$text'" ;;
    esac
    [ -n "$(channel "$channel_name")" ] || fail "$language: no channel '$channel_name'"
  else
    fail "$language: the test never showed the notification"
  fi
  local status=0
  wait "$TEST_PID" || status=$?
  TEST_PID=
  grep -o 'L10N|[^"]*' "$LOG.$language" | sed 's/^/[l10n] /' >&2 || true
  [ "$status" -eq 0 ] || fail "$language: the test failed (log: $LOG.$language)"
  local crashes
  crashes=$("${ADB[@]}" logcat -d -b crash | tr -d '\r' | grep -A3 "Process: $APP" || true)
  [ -z "$crashes" ] || { fail "$language: the app crashed"; echo "$crashes" >&2; }
}

pass en 'Looking at your files' '125 files' 'Cleanup progress'

if [ "$SDK_INT" -lt 33 ]; then
  if [ "$("${ADB[@]}" shell id -u | tr -d '\r')" != 0 ]; then
    ROOTED=1
  fi
  "$SDK/platform-tools/adb" -s "$SERIAL" root >/dev/null
  "$SDK/platform-tools/adb" -s "$SERIAL" wait-for-device
  OLD_LOCALE=$("${ADB[@]}" shell getprop persist.sys.locale | tr -d '\r')
  SYSTEM_LOCALE_CHANGED=1
  say "system language: '${OLD_LOCALE}' -> ru-RU (the framework restarts)"
  set_system_locale ru-RU
fi
pass ru 'Просматриваю файлы' '125 файлов' 'Ход уборки'

if [ "$FAILED" -eq 0 ]; then say "PASSED"; else say "FAILED"; fi
exit "$FAILED"
