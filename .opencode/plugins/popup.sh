#!/bin/bash

export GTK_THEME=Adwaita:dark

WIDTH=220
HEIGHT=50
MARGIN=35
GAP=10

SCREEN_WIDTH=$(xrandr --current 2>/dev/null | grep -oP '^\s+\K\d+' | head -1 || echo "1920")

X=$((SCREEN_WIDTH - WIDTH - MARGIN))
BASE_Y=$MARGIN

POPUP_COUNT=$(xdotool search --any "yad" 2>/dev/null | wc -l)

Y=$((BASE_Y + (POPUP_COUNT * (HEIGHT + GAP))))

# Feed the pulsating bar from a background helper and exit as soon as yad does.
# A pipeline (`... | yad`) would keep this script alive forever: after yad dies
# the feeder never writes again, so it never gets SIGPIPE and bash keeps waiting.
(
    while true; do
        echo 1
        sleep 0.3
    done
) &
FEEDER=$!
trap 'kill "$FEEDER" 2>/dev/null' EXIT

yad --width=$WIDTH --height=$HEIGHT \
    --geometry=${WIDTH}x${HEIGHT}+${X}+${Y} \
    --title="Loading" \
    --class "yad-popup" \
    --progress \
    --pulsate \
    --text="$*" \
    --text-align=center \
    --fontname="Sans 11" \
    --borders=12 \
    --button="🗙:0" \
    --buttons-layout=center \
    --fixed \
    --on-top \
    --undecorated \
    --no-focus \
    2>/dev/null
