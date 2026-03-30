# bt-switch

Automatically switches Magic Keyboard, Magic Trackpad, and MX Master between Mac Mini and MacBook when a monitor cable is swapped between them.

## How it works

Both machines run the same `bt-switch.sh` script. It polls screen width every 0.5s via JXA (`NSScreen`):

- **Monitor plugged in** (screen width changes from default) -> wait 3s, then connect all BT devices
- **Monitor unplugged** (screen width returns to default) -> immediately disconnect all BT devices

The 3s delay on connect gives the other machine time to detect the unplug and release devices first.

Each machine has a config file with its "default" screen width (the width when no external monitor is connected):
- **Mac Mini**: `1920` (virtual display)
- **MacBook**: `1728` (built-in Retina)

The MX Master uses different BT addresses per pairing profile, so device addresses are in per-machine config files.

## Device addresses

| Device | Mac Mini | MacBook |
|---|---|---|
| Magic Keyboard | `38-09-fb-12-33-82` | `38-09-fb-12-33-82` |
| Magic Trackpad | `04-41-a5-8b-59-88` | `04-41-a5-8b-59-88` |
| MX Master 4 | `db-2d-99-05-2b-82` | `db-2d-99-05-2b-81` |

## Prerequisites

```bash
brew install blueutil
```

## Config files

Each machine needs a config at the path referenced by its plist (currently `/usr/local/etc/bt-switch.conf`):

**Mac Mini** (`config-macmini.sh`):
```bash
DEFAULT_WIDTH=1920
KEYBOARD="38-09-fb-12-33-82"
TRACKPAD="04-41-a5-8b-59-88"
MX_MASTER="db-2d-99-05-2b-82"
```

**MacBook** (`config-macbook.sh`):
```bash
DEFAULT_WIDTH=1728
KEYBOARD="38-09-fb-12-33-82"
TRACKPAD="04-41-a5-8b-59-88"
MX_MASTER="db-2d-99-05-2b-81"
```

## Install

Same steps on both machines (use the appropriate config file):

```bash
# Copy script
sudo mkdir -p /usr/local/bin /usr/local/etc
sudo cp bt-switch.sh /usr/local/bin/bt-switch.sh
sudo chmod +x /usr/local/bin/bt-switch.sh

# Copy config (use config-macmini.sh or config-macbook.sh)
sudo cp config-<machine>.sh /usr/local/etc/bt-switch.conf
sudo chmod 644 /usr/local/etc/bt-switch.conf

# Install LaunchAgent
cp com.aheze.bt-switch-<machine>.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.aheze.bt-switch-<machine>.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.aheze.bt-switch-<machine>.plist
```

## Logs

```bash
# MacBook
tail -f /tmp/bt-switch-macbook.log

# Mac Mini
tail -f /tmp/bt-switch-macmini.log
```

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.aheze.bt-switch-<machine>.plist
rm ~/Library/LaunchAgents/com.aheze.bt-switch-<machine>.plist
sudo rm /usr/local/bin/bt-switch.sh /usr/local/etc/bt-switch.conf
```

## Known issues / TODO

- **Config file permissions**: `/usr/local/etc/bt-switch.conf` gets created as root-only readable by `sudo cp`. Must `sudo chmod 644` after copying, or the script silently fails to load config. Should move config to a user-readable location (e.g. `~/.config/bt-switch.conf`) to avoid this.
- **MacBook connect failures**: When cable is swapped from Mac Mini to MacBook, `blueutil --connect` sometimes fails repeatedly (~20s per device before timeout). Mac Mini disconnect works fine, but MacBook can't grab the devices. Needs investigation — may be a blueutil timeout issue or devices going to sleep.
- **Verbose polling logs**: Currently logs every 0.5s poll for debugging. Should be removed or reduced once stable.
- **Old scripts still in repo**: `macbook-monitor-watch.sh`, `macmini-reconnect-watch.sh`, and `display-count.swift` are superseded by `bt-switch.sh` and can be deleted.
