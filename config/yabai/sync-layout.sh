#!/usr/bin/env sh
# Dynamically labels spaces by display geometry and switches between:
# - Single-monitor mode (laptop only): all spaces use `stack` layout
# - Multi-monitor mode: center/main display spaces use `bsp`, side displays use `stack`
#
# Note: Never call global `yabai -m config layout ...` here because `yabai`
# applies global layout changes to ALL existing spaces across all monitors.
# Instead, set layout per-space via `yabai -m space <idx> --layout <bsp|stack>`
# only when a space is visible (`is-visible == true`).

STATE_FILE="/tmp/yabai_layout_state_${USER:-rkj}"
OVERRIDE_FILE="/tmp/yabai_manual_override_${USER:-rkj}"
RESTART_FILE="/tmp/yabai_last_restart_${USER:-rkj}"
EVENT_TYPE="${1:-init}"

# When displays are added/removed, give macOS WindowServer a moment to finish
# migrating spaces across displays before querying geometry.
if [ "$EVENT_TYPE" = "display" ]; then
  sleep 1
fi

DISPLAYS_JSON="$(yabai -m query --displays 2>/dev/null)" || exit 0
SPACES_JSON="$(yabai -m query --spaces 2>/dev/null)" || exit 0

# If any window on a currently visible space lost its macOS Accessibility reference
# (e.g. Chrome or Chrome PWAs showing as `app_mode_loader` after sleep/reconnect),
# restart yabai once (with a 15s cooldown) so yabai re-resolves all AX references.
if [ "$EVENT_TYPE" != "init" ]; then
  BROKEN_AX="$(yabai -m query --windows 2>/dev/null | jq '[.[] | select(."is-visible" == true and ."has-ax-reference" == false and .role != "AXHelpTag")] | length')"
  if [ "${BROKEN_AX:-0}" -gt 0 ]; then
    NOW="$(date +%s)"
    LAST_RESTART="$(cat "$RESTART_FILE" 2>/dev/null || echo 0)"
    if [ $((NOW - LAST_RESTART)) -gt 15 ]; then
      printf '%s\n' "$NOW" > "$RESTART_FILE"
      yabai --restart-service >/dev/null 2>&1 &
      exit 0
    fi
  fi
fi

NUM_DISPLAYS="$(printf '%s' "$DISPLAYS_JSON" | jq 'length')"
if [ "$NUM_DISPLAYS" -le 1 ]; then
  CURRENT_MODE="single"
else
  CURRENT_MODE="multi_${NUM_DISPLAYS}"
fi

PREV_MODE="$(cat "$STATE_FILE" 2>/dev/null || echo "")"

# Clear manual Hyper+Space overrides when startup or monitor count changes
if [ "$EVENT_TYPE" = "init" ] || [ "$EVENT_TYPE" = "display" ] || [ "$CURRENT_MODE" != "$PREV_MODE" ]; then
  rm -f "$OVERRIDE_FILE"
fi
printf '%s\n' "$CURRENT_MODE" > "$STATE_FILE"

MANUAL_OVERRIDES=" $(cat "$OVERRIDE_FILE" 2>/dev/null | tr '\n' ' ') "

# Ensure a visible space has `target_layout` unless manually overridden via Hyper+Space
sync_visible_space() {
  space_idx="$1"
  target_layout="$2"

  case "$MANUAL_OVERRIDES" in
    *" $space_idx "*) return 0 ;;
  esac

  current_type="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.index == $space_idx) | .type")"
  if [ "$current_type" != "$target_layout" ]; then
    yabai -m space "$space_idx" --layout "$target_layout" 2>/dev/null || true
  fi
}

if [ "$NUM_DISPLAYS" -le 1 ]; then
  # Single monitor (undocked): label main1..N and set visible space to `stack`
  pos=1
  for idx in $(printf '%s' "$SPACES_JSON" | jq -r '.[].index'); do
    yabai -m space "$idx" --label "main${pos}" 2>/dev/null || true
    is_vis="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.index == $idx) | .\"is-visible\"")"
    if [ "$is_vis" = "true" ]; then
      sync_visible_space "$idx" "stack"
    fi
    pos=$((pos + 1))
  done
else
  # Multi-monitor (docked):
  MAIN_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r 'sort_by((.frame.w * .frame.h) * -1) | .[0].index')"
  MAIN_X="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index == $MAIN_DISPLAY) | .frame.x")"

  LEFT_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index != $MAIN_DISPLAY and .frame.x < $MAIN_X) | .index" | head -n 1)"
  RIGHT_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index != $MAIN_DISPLAY and .frame.x > $MAIN_X) | .index" | head -n 1)"

  # Label main display spaces (main1..N) and sync visible ones to `bsp`
  pos=1
  for idx in $(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $MAIN_DISPLAY) | .index"); do
    yabai -m space "$idx" --label "main${pos}" 2>/dev/null || true
    is_vis="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.index == $idx) | .\"is-visible\"")"
    if [ "$is_vis" = "true" ]; then
      sync_visible_space "$idx" "bsp"
    fi
    pos=$((pos + 1))
  done

  # Label and sync left monitor space (`left` -> `stack`)
  if [ -n "$LEFT_DISPLAY" ]; then
    left_space="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $LEFT_DISPLAY) | .index" | head -n 1)"
    if [ -n "$left_space" ]; then
      yabai -m space "$left_space" --label "left" 2>/dev/null || true
      sync_visible_space "$left_space" "stack"
    fi
  fi

  # Label and sync right monitor space (`right` -> `stack`)
  if [ -n "$RIGHT_DISPLAY" ]; then
    right_space="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $RIGHT_DISPLAY) | .index" | head -n 1)"
    if [ -n "$right_space" ]; then
      yabai -m space "$right_space" --label "right" 2>/dev/null || true
      sync_visible_space "$right_space" "stack"
    fi
  fi

  # On display/space count change, refresh window placement rules
  if [ "$EVENT_TYPE" != "space_changed" ] || [ "$CURRENT_MODE" != "$PREV_MODE" ]; then
    if [ -f "$HOME/.config/yabai/local.sh" ]; then
      . "$HOME/.config/yabai/local.sh"
    fi
    yabai -m rule --apply 2>/dev/null || true
  fi
fi
