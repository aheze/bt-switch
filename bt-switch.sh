#!/bin/bash
# bt-switch.sh — unified script for both Mac Mini and MacBook
# Watches display state. Monitor plugged in → connect devices. Monitor removed → disconnect.
# Usage: bt-switch.sh <default_width>
#   Mac Mini: bt-switch.sh 1920  (virtual display width when no monitor)
#   MacBook:  bt-switch.sh 1728  (built-in display width)

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

KEYBOARD="38-09-fb-12-33-82"
TRACKPAD="04-41-a5-8b-59-88"
MX_MASTER="db-2d-99-05-2b-82"

DEFAULT_WIDTH="${1:?Usage: bt-switch.sh <default_width>}"

# PID of in-flight connect/disconnect background job
action_pid=""

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

get_screen_width() {
    osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.objectAtIndex(0).frame.size.width' 2>/dev/null
}

has_external_monitor() {
    [ "$1" != "$DEFAULT_WIDTH" ]
}

all_connected() {
    [ "$(blueutil --is-connected "$KEYBOARD" 2>/dev/null)" = "1" ] &&
    [ "$(blueutil --is-connected "$TRACKPAD" 2>/dev/null)" = "1" ] &&
    [ "$(blueutil --is-connected "$MX_MASTER" 2>/dev/null)" = "1" ]
}

any_connected() {
    [ "$(blueutil --is-connected "$KEYBOARD" 2>/dev/null)" = "1" ] ||
    [ "$(blueutil --is-connected "$TRACKPAD" 2>/dev/null)" = "1" ] ||
    [ "$(blueutil --is-connected "$MX_MASTER" 2>/dev/null)" = "1" ]
}

cancel_inflight() {
    if [ -n "$action_pid" ] && kill -0 "$action_pid" 2>/dev/null; then
        kill "$action_pid" 2>/dev/null
        wait "$action_pid" 2>/dev/null
        log "Cancelled in-flight action"
    fi
    action_pid=""
}

do_connect() {
    if all_connected; then
        log "Monitor detected — all devices already connected"
        return
    fi
    log "Monitor detected — connecting devices"
    for attempt in 1 2 3 4 5; do
        [ "$(blueutil --is-connected "$KEYBOARD" 2>/dev/null)" = "1" ]  || blueutil --connect "$KEYBOARD"
        [ "$(blueutil --is-connected "$TRACKPAD" 2>/dev/null)" = "1" ]  || blueutil --connect "$TRACKPAD"
        [ "$(blueutil --is-connected "$MX_MASTER" 2>/dev/null)" = "1" ] || blueutil --connect "$MX_MASTER"
        sleep 2
        if all_connected; then
            log "All devices connected on attempt $attempt"
            return
        fi
        log "Attempt $attempt failed — retrying"
    done
    log "Could not connect all devices after 5 attempts"
}

do_disconnect() {
    if ! any_connected; then
        log "Monitor removed — devices already disconnected"
        return
    fi
    log "Monitor removed — disconnecting devices"
    [ "$(blueutil --is-connected "$KEYBOARD" 2>/dev/null)" = "1" ]  && blueutil --disconnect "$KEYBOARD"
    [ "$(blueutil --is-connected "$TRACKPAD" 2>/dev/null)" = "1" ]  && blueutil --disconnect "$TRACKPAD"
    [ "$(blueutil --is-connected "$MX_MASTER" 2>/dev/null)" = "1" ] && blueutil --disconnect "$MX_MASTER"
}

prev_state=""

log "Script started (default_width=$DEFAULT_WIDTH)"

while true; do
    info=$(get_screen_width)

    if has_external_monitor "$info"; then
        state="monitor"
    else
        state="no_monitor"
    fi

    log "poll: display_info=$info state=$state"

    if [ "$state" != "$prev_state" ]; then
        cancel_inflight

        if [ "$state" = "monitor" ]; then
            (sleep 3 && do_connect) &
            action_pid=$!
        else
            do_disconnect &
            action_pid=$!
        fi
        prev_state="$state"
    fi

    sleep 0.5
done
