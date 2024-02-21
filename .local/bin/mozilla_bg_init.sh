#!/bin/bash
firefox "about:blank" &
WAITFOR="Mozilla Firefox"

get_windows() { wmctrl -l | grep "$WAITFOR" | awk '{print $1}'; }

wait_for_window() {
    while [ -z "$(get_windows)" ]; do
        sleep 1
    done
}

wait_for_window
APP=$(get_windows)

for win in ${APP[@]}; do
    xdotool windowunmap "$win"
done

HIDDEN_APPS=$APP
while [ -n "$(get_windows)" ]; do
    sleep 1
done
wait_for_window

for win in ${HIDDEN_APPS[@]}; do
    xdotool windowmap "$win"
done
