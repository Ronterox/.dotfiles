#!/usr/bin/env bash

TARGET_COLOR="#FD0436"

echo "Searching for $TARGET_COLOR..."

# 'txt:-' outputs every pixel as: (x,y): (r,g,b) #HEXCOLOR
# Use 'head -n 2000000' to avoid crashing on massive 4K screens
MATCH=$(import -window root txt:- | rg -i -m 1 "$TARGET_COLOR")

# Check if we found a match
if [ -n "$MATCH" ]; then
    # The line looks like: 542,321: (255,0,0) #FF0000 red
    COORDS=$(echo $MATCH | grep -oP '^\d+,\d+')
    X=$(echo $COORDS | cut -d',' -f1)
    Y=$(echo $COORDS | cut -d',' -f2)

    echo "Found red at $X, $Y. Clicking!"
    xdotool mousemove $X $Y click 1
else
    echo "No red pixels found on screen."
fi
