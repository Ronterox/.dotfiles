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

yad --width=$WIDTH --height=$HEIGHT \
    --geometry=${WIDTH}x${HEIGHT}+${X}+${Y} \
    --title="Popup" \
    --class "yad-popup" \
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
