# shellcheck shell=bash

# Reuse the upstream default theme styling and only trim the visible segments.
# The goal is:
# - left: keep only session/window/pane info
# - center: keep the tmux window list
# - right: show nothing

# shellcheck disable=SC1090
source "${TMUX_POWERLINE_DIR_THEMES}/default.sh"

TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
	"tmux_session_info 148 234"
)

TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=()
