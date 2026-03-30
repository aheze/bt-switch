#!/bin/bash
# bt-switch.sh — unified script for both Mac Mini and MacBook
# Watches display count. Monitor plugged in → connect devices. Monitor removed → disconnect.
# Usage: bt-switch.sh <builtin_display_count>
#   Mac Mini (no built-in display): bt-switch.sh 0
#   MacBook (has built-in display):  bt-switch.sh 1

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

KEYBOARD="38-09-fb-12-33-82"
TRACKPAD="04-41-a5-8b-59-88"
MX_MASTER="db-2d-99-05-2b-82"

BUILTIN_DISPLAY_COUNT="${1:?Usage: bt-switch.sh <builtin_display_count>}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

display_count() {
    osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.count' 2>/dev/null
}

all_connected() {
    [ "$(blueutil --is-connected "$KEYBOARD" 2>/dev/null)" = "1" ] &&
    [ "$(blueutil --is-connected "$TRACKPAD" 2>/dev/null)" = "1" ] &&
    [ "$(blueutil --is-connected "$MX_MASTER" 2>/dev/null)" = "1" ]
}

connect_devices() {
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

disconnect_devices() {
    log "Monitor removed — disconnecting devices"
    blueutil --disconnect "$KEYBOARD"
    blueutil --disconnect "$TRACKPAD"
    blueutil --disconnect "$MX_MASTER"
}

prev_state=""

log "Script started (builtin_display_count=$BUILTIN_DISPLAY_COUNT)"

while true; do
    count=$(display_count)

    if [ "$count" -gt "$BUILTIN_DISPLAY_COUNT" ]; then
        state="monitor"
    else
        state="no_monitor"
    fi

    if [ "$state" != "$prev_state" ]; then
        if [ "$state" = "monitor" ]; then
            sleep 3
            # Re-check after delay to avoid false triggers
            count=$(display_count)
            if [ "$count" -gt "$BUILTIN_DISPLAY_COUNT" ]; then
                connect_devices
            fi
        else
            disconnect_devices
        fi
        prev_state="$state"
    fi

    sleep 2
done
