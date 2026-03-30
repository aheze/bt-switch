#!/bin/bash
# macmini-reconnect-watch.sh
# Install on Mac Mini. Mac Mini is the default/home host for keyboard + trackpad.
# On launch: immediately connects both devices.
# While running: if both disconnect, waits 3s then reclaims if still gone.

KEYBOARD="38-09-fb-12-33-82"
TRACKPAD="04-41-a5-8b-59-88"
MX_MASTER="db-2d-99-05-2b-82"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

is_connected() {
    blueutil --is-connected "$1" 2>/dev/null | grep -q "^1$"
}

connect_devices() {
    log "Connecting keyboard, trackpad, and MX Master to Mac Mini"
    blueutil --connect "$KEYBOARD"
    blueutil --connect "$TRACKPAD"
    blueutil --connect "$MX_MASTER"
}

# Mac Mini is the default host — claim devices immediately on launch
log "Script started — claiming devices as default host"
connect_devices

while true; do
    kb_connected=false
    tp_connected=false
    mx_connected=false

    is_connected "$KEYBOARD" && kb_connected=true
    is_connected "$TRACKPAD" && tp_connected=true
    is_connected "$MX_MASTER" && mx_connected=true

    if ! $kb_connected && ! $tp_connected && ! $mx_connected; then
        log "All devices disconnected — waiting 3s before reclaiming"
        sleep 3

        # Re-check: MacBook may have grabbed them intentionally
        is_connected "$KEYBOARD" && kb_connected=true
        is_connected "$TRACKPAD" && tp_connected=true
        is_connected "$MX_MASTER" && mx_connected=true

        if ! $kb_connected && ! $tp_connected && ! $mx_connected; then
            connect_devices
        else
            log "At least one device reconnected elsewhere — leaving alone"
        fi
    fi

    sleep 4
done
