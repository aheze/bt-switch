#!/bin/bash
# macbook-monitor-watch.sh
# Install on MacBook. Watches display count every 4 seconds.
# Monitor plugged in  → connect keyboard + trackpad to MacBook
# Monitor unplugged   → disconnect them (Mac Mini will reclaim)

# Ensure Homebrew binaries are available (launchd has a minimal PATH)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

KEYBOARD="38-09-fb-12-33-82"
TRACKPAD="04-41-a5-8b-59-88"
MX_MASTER="db-2d-99-05-2b-82"

# Number of displays when only the built-in screen is active
BUILTIN_DISPLAY_COUNT=1

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

display_count() {
    osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.count' 2>/dev/null
}

connect_devices() {
    log "Monitor detected — connecting keyboard, trackpad, and MX Master to MacBook"
    for attempt in 1 2 3 4 5; do
        blueutil --connect "$KEYBOARD"
        blueutil --connect "$TRACKPAD"
        blueutil --connect "$MX_MASTER"
        sleep 2
        kb=$(blueutil --is-connected "$KEYBOARD" 2>/dev/null)
        tp=$(blueutil --is-connected "$TRACKPAD" 2>/dev/null)
        mx=$(blueutil --is-connected "$MX_MASTER" 2>/dev/null)
        if [ "$kb" = "1" ] && [ "$tp" = "1" ] && [ "$mx" = "1" ]; then
            log "All devices connected on attempt $attempt"
            return
        fi
        log "Attempt $attempt failed (kb=$kb tp=$tp mx=$mx) — retrying"
    done
    log "Could not connect all devices after 5 attempts"
}

disconnect_devices() {
    log "Monitor removed — disconnecting keyboard, trackpad, and MX Master"
    blueutil --disconnect "$KEYBOARD"
    blueutil --disconnect "$TRACKPAD"
    blueutil --disconnect "$MX_MASTER"
}

# Track previous state to avoid redundant calls
prev_state=""

while true; do
    count=$(display_count)

    if [ "$count" -gt "$BUILTIN_DISPLAY_COUNT" ]; then
        state="external"
    else
        state="builtin"
    fi

    if [ "$state" != "$prev_state" ]; then
        if [ "$state" = "external" ]; then
            connect_devices
        else
            disconnect_devices
        fi
        prev_state="$state"
    fi

    sleep 2
done
