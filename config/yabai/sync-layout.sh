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
RESTART_IDS_FILE="/tmp/yabai_last_restart_ids_${USER:-rkj}"
RESTART_LOCK_DIR="/tmp/yabai_restart_lock_${USER:-rkj}"
START_HISTORY_FILE="/tmp/yabai_start_history_${USER:-rkj}"
AUTO_RESTART_HISTORY_FILE="/tmp/yabai_auto_restart_history_${USER:-rkj}"
LOG_FILE="/tmp/yabai_sync_${USER:-rkj}.log"
DISPLAY_PID_FILE="/tmp/yabai_display_sync_pid_${USER:-rkj}"
SIGNALS_STAMP_FILE="/tmp/yabai_signals_v4_${USER:-rkj}"
EVENT_TYPE="${1:-init}"

RESTART_WINDOW_SEC=600
MAX_AUTO_RESTARTS=3
START_LOOP_ALERT_THRESHOLD=3

log_event() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$EVENT_TYPE" "$1" >> "$LOG_FILE" 2>/dev/null || true
}

notify_user() {
  command -v osascript >/dev/null 2>&1 || return 0
  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "yabai" subtitle (item 2 of argv)' \
    -e 'end run' \
    "$2" "$1" >/dev/null 2>&1 &
}

notify_throttled() {
  nt_tag="$1"
  nt_cooldown="$2"
  nt_sub="$3"
  nt_msg="$4"
  nt_file="/tmp/yabai_notify_${nt_tag}_${USER:-rkj}"
  nt_now="$(date +%s)"
  nt_last="$(cat "$nt_file" 2>/dev/null || echo 0)"
  case "$nt_last" in ''|*[!0-9]*) nt_last=0 ;; esac
  if [ $((nt_now - nt_last)) -ge "$nt_cooldown" ]; then
    printf '%s\n' "$nt_now" > "$nt_file"
    notify_user "$nt_sub" "$nt_msg"
    return 0
  fi
  return 1
}

# Filter a timestamp file to entries within the rolling window and echo the count
prune_timestamps() {
  pt_file="$1"
  pt_now="$2"
  pt_win="$3"
  pt_cutoff=$((pt_now - pt_win))
  pt_tmp="${pt_file}.tmp.$$"
  pt_count=0
  : > "$pt_tmp"
  if [ -f "$pt_file" ]; then
    while IFS= read -r pt_ts; do
      case "$pt_ts" in
        ''|*[!0-9]*) continue ;;
      esac
      if [ "$pt_ts" -ge "$pt_cutoff" ] && [ "$pt_ts" -le "$pt_now" ]; then
        printf '%s\n' "$pt_ts" >> "$pt_tmp"
        pt_count=$((pt_count + 1))
      fi
    done < "$pt_file"
  fi
  mv -f "$pt_tmp" "$pt_file" 2>/dev/null || rm -f "$pt_tmp"
  printf '%s' "$pt_count"
}

sync_once() {
  force_pass="${1:-0}"

  if [ "$EVENT_TYPE" = "init" ]; then
    rmdir "$RESTART_LOCK_DIR" 2>/dev/null || true
    INIT_NOW="$(date +%s)"
    printf '%s\n' "$INIT_NOW" >> "$START_HISTORY_FILE"
    RECENT_STARTS="$(prune_timestamps "$START_HISTORY_FILE" "$INIT_NOW" "$RESTART_WINDOW_SEC")"
    log_event "yabai started (starts in last 10m: ${RECENT_STARTS})"
    if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d ' ')" -gt 300 ]; then
      tail -n 200 "$LOG_FILE" > "${LOG_FILE}.tmp.$$" 2>/dev/null && mv -f "${LOG_FILE}.tmp.$$" "$LOG_FILE" 2>/dev/null || rm -f "${LOG_FILE}.tmp.$$"
    fi
    if [ "${RECENT_STARTS:-0}" -ge "$START_LOOP_ALERT_THRESHOLD" ]; then
      LAST_AUTO="$(cat "$RESTART_FILE" 2>/dev/null || echo 0)"
      case "$LAST_AUTO" in ''|*[!0-9]*) LAST_AUTO=0 ;; esac
      # Avoid duplicate banner right after an already-notified auto-restart unless
      # starts exceed the auto-restart budget (e.g. external crashes/respawns).
      if [ $((INIT_NOW - LAST_AUTO)) -gt 10 ] || [ "${RECENT_STARTS:-0}" -gt "$MAX_AUTO_RESTARTS" ]; then
        notify_throttled "start_loop" 300 \
          "Frequent restarts detected" \
          "yabai restarted ${RECENT_STARTS} times in the last 10m. See ${LOG_FILE}" || true
      fi
    fi
  fi

  if [ "$EVENT_TYPE" = "init" ] || [ ! -f "$SIGNALS_STAMP_FILE" ]; then
    SYNC_SCRIPT="$HOME/.config/yabai/sync-layout.sh"
    yabai -m signal --add event=display_added        label="sync_display_add"     action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_removed      label="sync_display_remove"  action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_moved        label="sync_display_moved"   action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_resized      label="sync_display_resized" action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m signal --add event=display_changed      label="sync_display_changed" action="$SYNC_SCRIPT space_changed" 2>/dev/null || true
    yabai -m signal --add event=system_woke          label="sync_system_woke"     action="$SYNC_SCRIPT display"       2>/dev/null || true
    yabai -m rule   --add label="rule_deskrest"      app="^[Dd]esk ?[Rr]est$"     manage=off                          2>/dev/null || true
    yabai -m rule   --add label="rule_workrave"      app="^[Ww]orkrave$"          manage=off                          2>/dev/null || true
    yabai -m rule   --apply                                                                                           2>/dev/null || true
    printf '1\n' > "$SIGNALS_STAMP_FILE"
  fi

  DISPLAYS_JSON="$(yabai -m query --displays 2>/dev/null)" || return 0
  SPACES_JSON="$(yabai -m query --spaces 2>/dev/null)" || return 0
  WINDOWS_JSON="$(yabai -m query --windows 2>/dev/null)" || return 0
  [ -n "$DISPLAYS_JSON" ] && [ -n "$SPACES_JSON" ] && [ -n "$WINDOWS_JSON" ] || return 0

  # If any currently visible Chrome / Chrome PWA window shows up as unresolved
  # `app_mode_loader` or loses its AX reference (`has-ax-reference: false`, e.g.
  # after Chrome crashes/restarts or wakes from sleep), restart yabai ONCE per
  # broken window ID, guarded by exponential backoff (30s / 2m / 5m) and a
  # circuit breaker (max 3 auto-restarts per 10m) with macOS UI notifications.
  # Ignore non-visible windows (inactive spaces routinely lack AX references with
  # SIP enabled) and skip while the lock screen / shield window is active.
  if [ "$EVENT_TYPE" != "init" ]; then
    SHIELD_SHOWING="$(notifyutil -g com.apple.sessionagent.shieldWindowIsShowing 2>/dev/null | awk '{print $NF}')"
    LOCK_SHOWING="$(notifyutil -g com.apple.sessionagent.screenLockUIIsShowing 2>/dev/null | awk '{print $NF}')"
    if [ "${SHIELD_SHOWING:-0}" = "0" ] && [ "${LOCK_SHOWING:-0}" = "0" ]; then
      # Prune previously attempted window IDs that are now healthy or closed
      if ALL_BROKEN_IDS="$(printf '%s' "$WINDOWS_JSON" | jq -r '[.[] | select(.app == "app_mode_loader" or (."has-ax-reference" == false and .app == "Google Chrome")) | .id] | map(tostring) | join(" ")' 2>/dev/null)"; then
        if [ -f "$RESTART_IDS_FILE" ]; then
          KEPT_IDS=""
          for prev_id in $(cat "$RESTART_IDS_FILE" 2>/dev/null); do
            case " $ALL_BROKEN_IDS " in
              *" $prev_id "*) KEPT_IDS="$KEPT_IDS $prev_id" ;;
            esac
          done
          if [ -n "$KEPT_IDS" ]; then
            printf '%s\n' "$KEPT_IDS" > "$RESTART_IDS_FILE"
          else
            rm -f "$RESTART_IDS_FILE"
          fi
        fi
      fi

      VISIBLE_BROKEN_IDS="$(printf '%s' "$WINDOWS_JSON" | jq -r '[.[] | select(."is-visible" == true and ."is-minimized" == false and ."is-hidden" == false and (.frame.w > 0 and .frame.h > 0) and (.app == "app_mode_loader" or (."has-ax-reference" == false and .app == "Google Chrome"))) | .id] | map(tostring) | join(" ")' 2>/dev/null || true)"
      if [ -n "$VISIBLE_BROKEN_IDS" ]; then
        PREV_ATTEMPTED=" $(cat "$RESTART_IDS_FILE" 2>/dev/null | tr '\n' ' ') "
        NEW_BROKEN_IDS=""
        for bid in $VISIBLE_BROKEN_IDS; do
          case "$PREV_ATTEMPTED" in
            *" $bid "*) ;;
            *) NEW_BROKEN_IDS="$NEW_BROKEN_IDS $bid" ;;
          esac
        done
        if [ -n "$NEW_BROKEN_IDS" ]; then
          find "$RESTART_LOCK_DIR" -maxdepth 0 -mmin +1 -exec rmdir {} + 2>/dev/null || true
          if mkdir "$RESTART_LOCK_DIR" 2>/dev/null; then
            NOW="$(date +%s)"
            LAST_RESTART="$(cat "$RESTART_FILE" 2>/dev/null || echo 0)"
            case "$LAST_RESTART" in ''|*[!0-9]*) LAST_RESTART=0 ;; esac
            PREV_ATTEMPTED=" $(cat "$RESTART_IDS_FILE" 2>/dev/null | tr '\n' ' ') "
            STILL_NEW=""
            for bid in $NEW_BROKEN_IDS; do
              case "$PREV_ATTEMPTED" in
                *" $bid "*) ;;
                *) STILL_NEW="$STILL_NEW $bid" ;;
              esac
            done
            if [ -n "$STILL_NEW" ]; then
              RECENT_AUTO="$(prune_timestamps "$AUTO_RESTART_HISTORY_FILE" "$NOW" "$RESTART_WINDOW_SEC")"
              BROKEN_DESC="$(printf '%s' "$WINDOWS_JSON" | jq -r '[.[] | select(."is-visible" == true and ."is-minimized" == false and ."is-hidden" == false and (.frame.w > 0 and .frame.h > 0) and (.app == "app_mode_loader" or (."has-ax-reference" == false and .app == "Google Chrome"))) | "\(.app) (id \(.id))"] | join(", ")' 2>/dev/null || printf '%s' "$STILL_NEW")"
              if [ "${RECENT_AUTO:-0}" -ge "$MAX_AUTO_RESTARTS" ]; then
                rmdir "$RESTART_LOCK_DIR" 2>/dev/null || true
                if notify_throttled "throttled" 300 \
                  "Auto-restart paused (throttled)" \
                  "Hit ${MAX_AUTO_RESTARTS} restarts in 10m (${BROKEN_DESC}). Use Hyper+Backspace to restart manually."; then
                  log_event "auto-restart throttled (${RECENT_AUTO}/${MAX_AUTO_RESTARTS} in 10m) for ${BROKEN_DESC}"
                fi
              else
                case "${RECENT_AUTO:-0}" in
                  0) COOLDOWN=30 ;;
                  1) COOLDOWN=120 ;;
                  *) COOLDOWN=300 ;;
                esac
                if [ $((NOW - LAST_RESTART)) -gt "$COOLDOWN" ]; then
                  NEW_COUNT=$((RECENT_AUTO + 1))
                  printf '%s\n' "$NOW" > "$RESTART_FILE"
                  printf '%s\n' "$NOW" >> "$AUTO_RESTART_HISTORY_FILE"
                  printf '%s\n' "$PREV_ATTEMPTED $STILL_NEW" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u | tr '\n' ' ' > "$RESTART_IDS_FILE"
                  printf '\n' >> "$RESTART_IDS_FILE"
                  rmdir "$RESTART_LOCK_DIR" 2>/dev/null || true
                  log_event "auto-restarting yabai (${NEW_COUNT}/${MAX_AUTO_RESTARTS} in 10m) for ${BROKEN_DESC}"
                  notify_user \
                    "Auto-restarted (${NEW_COUNT}/${MAX_AUTO_RESTARTS} in 10m)" \
                    "Recovering broken AX window: ${BROKEN_DESC}"
                  yabai --restart-service >/dev/null 2>&1 &
                  exit 0
                fi
                rmdir "$RESTART_LOCK_DIR" 2>/dev/null || true
              fi
            else
              rmdir "$RESTART_LOCK_DIR" 2>/dev/null || true
            fi
          fi
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

  # On `window_created`, yabai already evaluates all registered rules automatically.
  # Skip re-labeling spaces and global `yabai -m rule --apply` when topology is unchanged.
  if [ "$EVENT_TYPE" = "window_created" ] && [ "$CURRENT_MODE" = "$PREV_MODE" ]; then
    return 0
  fi

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
