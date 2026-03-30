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
    /usr/local/bin/display-count 2>/dev/null
}

connect_devices() {
    log "Monitor detected — connecting keyboard, trackpad, and MX Master to MacBook"
    blueutil --connect "$KEYBOARD"
    blueutil --connect "$TRACKPAD"
    blueutil --connect "$MX_MASTER"
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

    sleep 4
done
