#!/usr/bin/env sh
# Dynamically labels spaces by display geometry and switches between:
# - Single-monitor mode (laptop only): all spaces use `stack` layout
# - Multi-monitor mode: center/main display spaces use `bsp`, side displays use `stack`

DISPLAYS_JSON="$(yabai -m query --displays 2>/dev/null)" || exit 0
SPACES_JSON="$(yabai -m query --spaces 2>/dev/null)" || exit 0

NUM_DISPLAYS="$(printf '%s' "$DISPLAYS_JSON" | jq 'length')"

if [ "$NUM_DISPLAYS" -le 1 ]; then
  # Single monitor (undocked): switch default and all existing spaces to stack view
  yabai -m config layout stack
  pos=1
  for idx in $(printf '%s' "$SPACES_JSON" | jq -r '.[].index'); do
    yabai -m space "$idx" --label "main${pos}" 2>/dev/null || true
    yabai -m space "$idx" --layout stack 2>/dev/null || true
    pos=$((pos + 1))
  done
else
  # Multi-monitor (docked):
  # Identify main display (largest resolution area), left display (x < main.x), right display (x > main.x)
  MAIN_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r 'sort_by((.frame.w * .frame.h) * -1) | .[0].index')"
  MAIN_X="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index == $MAIN_DISPLAY) | .frame.x")"

  LEFT_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index != $MAIN_DISPLAY and .frame.x < $MAIN_X) | .index" | head -n 1)"
  RIGHT_DISPLAY="$(printf '%s' "$DISPLAYS_JSON" | jq -r ".[] | select(.index != $MAIN_DISPLAY and .frame.x > $MAIN_X) | .index" | head -n 1)"

  yabai -m config layout bsp

  # Label and set `bsp` on main display spaces (main1, main2, main3, ...)
  pos=1
  for idx in $(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $MAIN_DISPLAY) | .index"); do
    yabai -m space "$idx" --label "main${pos}" 2>/dev/null || true
    yabai -m space "$idx" --layout bsp 2>/dev/null || true
    pos=$((pos + 1))
  done

  # Label and set `stack` on left monitor space (`left`)
  if [ -n "$LEFT_DISPLAY" ]; then
    left_space="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $LEFT_DISPLAY) | .index" | head -n 1)"
    if [ -n "$left_space" ]; then
      yabai -m space "$left_space" --label "left" 2>/dev/null || true
      yabai -m space "$left_space" --layout stack 2>/dev/null || true
    fi
  fi

  # Label and set `stack` on right monitor space (`right`)
  if [ -n "$RIGHT_DISPLAY" ]; then
    right_space="$(printf '%s' "$SPACES_JSON" | jq -r ".[] | select(.display == $RIGHT_DISPLAY) | .index" | head -n 1)"
    if [ -n "$right_space" ]; then
      yabai -m space "$right_space" --label "right" 2>/dev/null || true
      yabai -m space "$right_space" --layout stack 2>/dev/null || true
    fi
  fi

  # Refresh machine-local / work-specific window rules against updated space labels and apply
  if [ -f "$HOME/.config/yabai/local.sh" ]; then
    . "$HOME/.config/yabai/local.sh"
  fi
  yabai -m rule --apply 2>/dev/null || true
fi
