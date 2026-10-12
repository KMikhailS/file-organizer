# Plays the user on system screens for the Android runners: the "All files
# access" settings screen and the notification permission dialog.
# Source it after setting ADB (array), APP and UI (a dump path on the
# device) and defining say(); the caller removes $UI at the end.
#   act ALL_FILES_BACK       settings screen opens -> back, nothing granted
#   act ALL_FILES_GRANT      settings screen opens -> access granted -> back
#   act NOTIFICATIONS_DENY   permission dialog -> "Don't allow"
#   act NOTIFICATIONS_ALLOW  permission dialog -> "Allow"
#   act NOTIFICATION_CANCEL  notification shade -> "Cancel" of the app's
#                            notification (title $NOTICE_TITLE, expanded
#                            if needed) -> shade closed

# The activity in front. Reads the whole output: an early exit of a reader
# would fail the pipeline under pipefail.
resumed() {
  "${ADB[@]}" shell dumpsys activity activities | tr -d '\r' |
    grep -E 'mResumedActivity|topResumedActivity|ResumedActivity:' |
    sed -n 1p || true
}

# Waits until an activity of a package matching $1 is in front and keeps
# which one it is (its record id) in SCREEN.
wait_front() {
  local front
  for _ in $(seq 1 100); do
    front=$(resumed)
    if [[ $front =~ $1 ]]; then
      SCREEN=$(grep -o 'ActivityRecord{[0-9a-f]*' <<<"$front" || true)
      return 0
    fi
    sleep 0.3
  done
  say "timeout waiting for $1 (front: $(resumed))"
  return 1
}

# The window with the input focus.
focus() {
  "${ADB[@]}" shell dumpsys window | tr -d '\r' | grep -E 'mCurrentFocus' |
    sed -n 1p || true
}

# A slow emulator may show "<app> isn't responding" over everything; wait
# for that app instead of letting the dialog eat the input.
dismiss_anr() {
  local f
  f=$(focus)
  if [[ $f =~ "Not Responding" ]]; then
    say "dismissing: $f"
    tap_id 'aerr_wait' || "${ADB[@]}" shell input keyevent KEYCODE_BACK
    sleep 1
  fi
}

# Leaves the screen found by wait_front with "back". Presses "back" only
# while that very screen (the same activity record) is in front: the test
# may already have opened the next one, and a "back" too many would close
# the app under test.
leave() {
  local front
  for _ in $(seq 1 20); do
    dismiss_anr
    front=$(resumed)
    if [[ -z $SCREEN || $front != *"$SCREEN"* ]]; then return 0; fi
    "${ADB[@]}" shell input keyevent KEYCODE_BACK
    sleep 1
  done
  say "the screen did not go (front: $(resumed))"
  return 1
}

# Taps the view whose resource id ends with $1.
tap_id() {
  for _ in $(seq 1 20); do
    "${ADB[@]}" shell uiautomator dump "$UI" >/dev/null 2>&1 || true
    local bounds
    bounds=$("${ADB[@]}" shell cat "$UI" | tr -d '\r' |
      grep -o "resource-id=\"[^\"]*$1\"[^>]*bounds=\"\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]\"" |
      grep -o 'bounds="[^"]*"' | sed -n 1p || true)
    if [ -n "$bounds" ]; then
      local x1 y1 x2 y2
      read -r x1 y1 x2 y2 < <(echo "$bounds" | grep -o '[0-9]*' | tr '\n' ' ')
      "${ADB[@]}" shell input tap $(((x1 + x2) / 2)) $(((y1 + y2) / 2))
      return 0
    fi
    sleep 0.5
  done
  "${ADB[@]}" pull "$UI" build/ui_dump.xml >/dev/null 2>&1 || true
  say "no view $1 on screen (dump: build/ui_dump.xml, focus: $(focus))"
  return 1
}

# The centre "x y" of the first view whose text is $1 (any case: some
# versions show notification actions in capitals), tried $2 times (20).
find_text() {
  for _ in $(seq 1 "${2:-20}"); do
    "${ADB[@]}" shell uiautomator dump "$UI" >/dev/null 2>&1 || true
    local bounds
    bounds=$("${ADB[@]}" shell cat "$UI" | tr -d '\r' |
      grep -io "text=\"$1\"[^>]*bounds=\"\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]\"" |
      grep -o 'bounds="[^"]*"' | sed -n 1p || true)
    if [ -n "$bounds" ]; then
      local x1 y1 x2 y2
      read -r x1 y1 x2 y2 < <(echo "$bounds" | grep -o '[0-9]*' | tr '\n' ' ')
      echo "$(((x1 + x2) / 2)) $(((y1 + y2) / 2))"
      return 0
    fi
    sleep 0.5
  done
  "${ADB[@]}" pull "$UI" build/ui_dump.xml >/dev/null 2>&1 || true
  return 1
}

# Taps the first view whose text is $1 (see find_text).
tap_text() {
  local at
  if at=$(find_text "$1" "${2:-20}"); then
    # shellcheck disable=SC2086 # "x y" are two arguments.
    "${ADB[@]}" shell input tap $at
    return 0
  fi
  say "no view with text $1 on screen (dump: build/ui_dump.xml)"
  return 1
}

# The title of the app's notification for NOTIFICATION_CANCEL.
NOTICE_TITLE=${NOTICE_TITLE:-Cleaning up}

# Waits for the "All files access" settings screen and keeps it in SCREEN.
# Newer versions open it through a short-lived trampoline activity of the
# same package, so it waits until the same settings activity stays in
# front for a second.
settings_front() {
  wait_front 'com\.android\.settings'
  local first
  for _ in $(seq 1 10); do
    first=$SCREEN
    sleep 1
    wait_front 'com\.android\.settings'
    [ "$SCREEN" = "$first" ] && return 0
  done
  return 0
}

# Taps the button $1 of the dialog found by wait_front until that dialog
# goes: a tap while it is still opening is lost.
answer() {
  local front
  for _ in $(seq 1 10); do
    dismiss_anr
    front=$(resumed)
    if [[ -z $SCREEN || $front != *"$SCREEN"* ]]; then return 0; fi
    tap_id "$1" || true
    sleep 1.5
  done
  say "the dialog did not go (front: $(resumed))"
  return 1
}

act() {
  dismiss_anr
  case $1 in
    ALL_FILES_BACK)
      settings_front
      leave ;;
    ALL_FILES_GRANT)
      settings_front
      "${ADB[@]}" shell appops set --uid "$APP" MANAGE_EXTERNAL_STORAGE allow
      sleep 1
      leave ;;
    NOTIFICATIONS_DENY)
      wait_front 'permissioncontroller'
      answer 'permission_deny_button' ;;
    NOTIFICATIONS_ALLOW)
      wait_front 'permissioncontroller'
      answer 'permission_allow_button' ;;
    NOTIFICATION_CANCEL)
      "${ADB[@]}" shell cmd statusbar expand-notifications
      sleep 1
      local tapped=0 at
      if ! tap_text 'Cancel' 4 2>/dev/null; then
        # Newer versions show it collapsed, without its actions: a swipe
        # down on its title expands it.
        if at=$(find_text "$NOTICE_TITLE"); then
          read -r x y <<<"$at"
          "${ADB[@]}" shell input swipe "$x" "$y" "$x" $((y + 500)) 300
          sleep 1
        fi
        tap_text 'Cancel' && tapped=1
      else
        tapped=1
      fi
      "${ADB[@]}" shell cmd statusbar collapse
      [ "$tapped" = 1 ] || return 1 ;;
    *) say "unknown action $1"; return 1 ;;
  esac
  say "done: $1"
}
