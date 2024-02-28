#!/bin/bash
firefox "about:blank" 2>/dev/null &
WAITFOR="Mozilla Firefox"

get_windows() {
    WINS=$(wmctrl -l | grep "$WAITFOR" | awk '{print $1}');
    for win in ${WINS[@]}; do
        [ "$#" -eq 0 ] && continue
        eval $@ "$win"
    done
    echo "${WINS[@]}"
}

wait_for_windows() {
    while [ -z "$(get_windows)" ]; do
        # echo "Waiting for windows to open"
        sleep 1
    done
}

wait_for_windows

get_windows 'sleep 1 ; echo'
HIDDEN_APPS=$(get_windows 'xdotool windowunmap')
while [ -n "$(get_windows)" ]; do
    # echo "Waiting for windows to close"
    sleep 1
done

wait_for_windows

for win in ${HIDDEN_APPS[@]}; do
    # echo "Restoring window $win"
    xdotool windowmap "$win"
done
