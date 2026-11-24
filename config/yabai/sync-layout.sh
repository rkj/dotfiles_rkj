#!/usr/bin/env sh
# Dynamically labels spaces by display geometry and switches between:
# - Single-monitor mode (laptop only): all spaces use `stack` layout
# - Multi-monitor mode: center/main display spaces use `bsp`, side displays use `stack`
#
# Optional `~/.config/yabai/local.sh` can set `SPACE_LAYOUT_OVERRIDES` (space-separated
# `label=layout` pairs, e.g. `main1=stack`) and define `apply_local_rules()`.
#
# Note: Never call global `yabai -m config layout ...` here because `yabai`
# applies global layout changes to ALL existing spaces across all monitors.
# Instead, set layout per-space via `yabai -m space <idx> --layout <bsp|stack>`
# only when a space is visible (`is-visible == true`).

STATE_FILE="/tmp/yabai_layout_state_${USER:-rkj}"
SYNCED_SPACES_FILE="/tmp/yabai_synced_spaces_${USER:-rkj}"
OVERRIDE_FILE="/tmp/yabai_manual_override_${USER:-rkj}"
RESTART_FILE="/tmp/yabai_last_restart_${USER:-rkj}"
DISPLAY_PID_FILE="/tmp/yabai_display_sync_pid_${USER:-rkj}"
SIGNALS_STAMP_FILE="/tmp/yabai_signals_v3_${USER:-rkj}"
EVENT_TYPE="${1:-init}"

sync_once() {
  force_pass="${1:-0}"

  if [ "$EVENT_TYPE" = "init" ] || [ ! -f "$SIGNALS_STAMP_FILE" ]; then
    SYNC_SCRIPT="$HOME/.config/yabai/sync-layout.sh"
    yabai -m signal --add event=display_added        label="sync_display_add"     action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_removed      label="sync_display_remove"  action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_moved        label="sync_display_moved"   action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_resized      label="sync_display_resized" action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_changed      label="sync_display_changed" action="$SYNC_SCRIPT space_changed" 2>/dev/null || true
    yabai -m signal --add event=system_woke          label="sync_system_woke"     action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m rule   --add label="rule_deskrest"      app="^[Dd]esk ?[Rr]est$"     manage=off                          2>/dev/null || true
    yabai -m rule   --apply                                                                                           2>/dev/null || true
    printf '1\n' > "$SIGNALS_STAMP_FILE"
  fi

  DISPLAYS_JSON="$(yabai -m query --displays 2>/dev/null)" || return 0
  SPACES_JSON="$(yabai -m query --spaces 2>/dev/null)" || return 0
  WINDOWS_JSON="$(yabai -m query --windows 2>/dev/null)" || return 0
  [ -n "$DISPLAYS_JSON" ] && [ -n "$SPACES_JSON" ] && [ -n "$WINDOWS_JSON" ] || return 0

  # If any Chrome PWA window shows up as unresolved `app_mode_loader` (which happens
  # after Chrome crashes/restarts or wakes from sleep with `has-ax-reference: false`),
  # restart yabai once (with a 15s cooldown) so yabai re-resolves all AX references.
  # Skip if macOS reports the lock screen / shield window is active, because AppKit
  # refuses to vend AXWindow references system-wide in that state and restarting
  # yabai cannot resolve them.
  if [ "$EVENT_TYPE" != "init" ]; then
    SHIELD_SHOWING="$(notifyutil -g com.apple.sessionagent.shieldWindowIsShowing 2>/dev/null | awk '{print $NF}')"
    LOCK_SHOWING="$(notifyutil -g com.apple.sessionagent.screenLockUIIsShowing 2>/dev/null | awk '{print $NF}')"
    if [ "${SHIELD_SHOWING:-0}" = "0" ] && [ "${LOCK_SHOWING:-0}" = "0" ]; then
      BROKEN_PWA="$(printf '%s' "$WINDOWS_JSON" | jq '[.[] | select(.app == "app_mode_loader" or (."has-ax-reference" == false and .app == "Google Chrome"))] | length')"
      if [ "${BROKEN_PWA:-0}" -gt 0 ]; then
        NOW="$(date +%s)"
        LAST_RESTART="$(cat "$RESTART_FILE" 2>/dev/null || echo 0)"
        if [ $((NOW - LAST_RESTART)) -gt 15 ]; then
          printf '%s\n' "$NOW" > "$RESTART_FILE"
          yabai --restart-service >/dev/null 2>&1 &
          exit 0
        fi
      fi
    fi
  fi

  NUM_DISPLAYS="$(printf '%s' "$DISPLAYS_JSON" | jq 'length' 2>/dev/null)"
  case "$NUM_DISPLAYS" in
    ''|*[!0-9]*) return 0 ;;
  esac
  # Track full display geometry + space assignment topology so delayed space migrations
  # across newly connected monitors are always detected as a topology change.
  CURRENT_MODE="$(printf '%s' "$DISPLAYS_JSON" | jq -r 'sort_by(.index) | map("\(.index):\(.frame.x | floor),\(.frame.y | floor),\(.frame.w | floor)x\(.frame.h | floor):\(.spaces | map(tostring) | join(","))") | join("|")')"
  PREV_MODE="$(cat "$STATE_FILE" 2>/dev/null || echo "")"

  # Clear manual Hyper+Space overrides and per-space sync cache when startup or topology changes
  if [ "$EVENT_TYPE" = "init" ] || [ "$CURRENT_MODE" != "$PREV_MODE" ]; then
    rm -f "$OVERRIDE_FILE" "$SYNCED_SPACES_FILE"
  elif [ "$force_pass" = "1" ]; then
    rm -f "$SYNCED_SPACES_FILE"
  fi
  printf '%s\n' "$CURRENT_MODE" > "$STATE_FILE"

  MANUAL_OVERRIDES=" $(cat "$OVERRIDE_FILE" 2>/dev/null | tr '\n' ' ') "
  SYNCED_SPACES=" $(cat "$SYNCED_SPACES_FILE" 2>/dev/null | tr '\n' ' ') "

  # Resolve effective layout for a space index, honoring any label-based override
  # from `SPACE_LAYOUT_OVERRIDES` (e.g. `main1=stack`).
  resolve_target_layout() {
    rtl_idx="$1"
    rtl_layout="$2"
    rtl_label=""
    for rtl_pair in $SPACE_LABELS; do
      case "$rtl_pair" in
        "${rtl_idx}="*) rtl_label="${rtl_pair#*=}" ;;
      esac
    done
    if [ -n "$rtl_label" ]; then
      for rtl_override in $SPACE_LAYOUT_OVERRIDES; do
        case "$rtl_override" in
          "${rtl_label}="*)
            rtl_val="${rtl_override#*=}"
            case "$rtl_val" in
              bsp|stack|float) rtl_layout="$rtl_val" ;;
            esac
            ;;
        esac
      done
    fi
    printf '%s' "$rtl_layout"
  }

  # Ensure a visible space has `target_layout` (and fresh display bounds on first sync
  # after a topology change) unless manually overridden via Hyper+Space.
  sync_visible_space() {
    space_idx="$1"
    target_layout="$(resolve_target_layout "$space_idx" "$2")"

    case "$MANUAL_OVERRIDES" in
      *" $space_idx "*) return 0 ;;
    esac

    current_type="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.index == $space_idx) | .type")"
    case "$SYNCED_SPACES" in
      *" $space_idx "*)
        if [ "$current_type" != "$target_layout" ]; then
          yabai -m space "$space_idx" --layout "$target_layout" 2>/dev/null || true
        fi
        ;;
      *)
        yabai -m space "$space_idx" --layout "$target_layout" 2>/dev/null || true
        printf '%s\n' "$space_idx" >> "$SYNCED_SPACES_FILE"
        SYNCED_SPACES="$SYNCED_SPACES $space_idx "
        ;;
    esac
  }

  # 1. Label spaces according to display geometry
  SPACE_LABELS=""
  if [ "$NUM_DISPLAYS" -le 1 ]; then
    pos=1
    for idx in $(printf '%s' "$SPACES_JSON" | jq -r '.[].index'); do
      label="main${pos}"
      yabai -m space "$idx" --label "$label" 2>/dev/null || true
      SPACE_LABELS="$SPACE_LABELS ${idx}=${label}"
      pos=$((pos + 1))
    done
  else
    MAIN_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r 'sort_by((.frame.w * .frame.h) * -1) | .[0].index')"
    MAIN_X="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index == $MAIN_DISPLAY) | .frame.x")"

    LEFT_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index != $MAIN_DISPLAY and .frame.x < $MAIN_X) | .index" | head -n 1)"
    RIGHT_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index != $MAIN_DISPLAY and .frame.x > $MAIN_X) | .index" | head -n 1)"

    pos=1
    for idx in $(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $MAIN_DISPLAY) | .index"); do
      label="main${pos}"
      yabai -m space "$idx" --label "$label" 2>/dev/null || true
      SPACE_LABELS="$SPACE_LABELS ${idx}=${label}"
      pos=$((pos + 1))
    done

    left_space=""
    if [ -n "$LEFT_DISPLAY" ]; then
      left_space="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $LEFT_DISPLAY) | .index" | head -n 1)"
      if [ -n "$left_space" ]; then
        yabai -m space "$left_space" --label "left" 2>/dev/null || true
        SPACE_LABELS="$SPACE_LABELS ${left_space}=left"
      fi
    fi

    right_space=""
    if [ -n "$RIGHT_DISPLAY" ]; then
      right_space="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $RIGHT_DISPLAY) | .index" | head -n 1)"
      if [ -n "$right_space" ]; then
        yabai -m space "$right_space" --label "right" 2>/dev/null || true
        SPACE_LABELS="$SPACE_LABELS ${right_space}=right"
      fi
    fi
  fi

  # 2. Load local overrides (per-space layout defaults and window placement rules)
  YABAI_SYNC_SOURCING=1
  SPACE_LAYOUT_OVERRIDES=""
  unset -f apply_local_rules 2>/dev/null || true
  if [ -f "$HOME/.config/yabai/local.sh" ]; then
    . "$HOME/.config/yabai/local.sh"
  fi
  if [ "$EVENT_TYPE" != "space_changed" ] || [ "$CURRENT_MODE" != "$PREV_MODE" ]; then
    if command -v apply_local_rules >/dev/null 2>&1; then
      apply_local_rules
    fi
    yabai -m rule --apply 2>/dev/null || true
    SPACES_JSON="$(yabai -m query --spaces 2>/dev/null)" || return 0
  fi

  # 3. Sync layouts on currently visible spaces
  if [ "$NUM_DISPLAYS" -le 1 ]; then
    for idx in $(printf '%s' "$SPACES_JSON" | jq -r '.[] | select(."is-visible" == true) | .index'); do
      sync_visible_space "$idx" "stack"
    done
  else
    for idx in $(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $MAIN_DISPLAY and .\"is-visible\" == true) | .index"); do
      sync_visible_space "$idx" "bsp"
    done
    if [ -n "$left_space" ]; then
      sync_visible_space "$left_space" "stack"
    fi
    if [ -n "$right_space" ]; then
      sync_visible_space "$right_space" "stack"
    fi
  fi
}

if [ "$EVENT_TYPE" = "display" ]; then
  # Debounce rapid display reconfiguration bursts and run multi-pass settle
  # (1s, 3s, 5s) because macOS WindowServer often finishes DisplayPort link
  # training and space migration 2-4s after the initial `display_added` signal.
  printf '%s\n' "$$" > "$DISPLAY_PID_FILE"
  sleep 1
  [ "$(cat "$DISPLAY_PID_FILE" 2>/dev/null)" = "$$" ] || exit 0
  sync_once 1
  sleep 2
  [ "$(cat "$DISPLAY_PID_FILE" 2>/dev/null)" = "$$" ] || exit 0
  sync_once 1
  sleep 2
  [ "$(cat "$DISPLAY_PID_FILE" 2>/dev/null)" = "$$" ] || exit 0
  sync_once 0
  exit 0
fi

if [ "$EVENT_TYPE" = "app_launched" ]; then
  sleep 1
fi

sync_once 0
