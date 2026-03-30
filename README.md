# bt-switch

Automatically switches Magic Keyboard and Magic Trackpad between Mac Mini and MacBook based on whether the MacBook's external monitor is plugged in.

## How it works

- **Mac Mini** is the default host. It claims both devices on boot and reclaims them whenever they go missing.
- **MacBook** watches the display count every 4 seconds. When an external monitor is connected it grabs the keyboard + trackpad; when the monitor is removed it drops them and the Mac Mini reclaims.
- No SSH, no coordination — each machine acts independently.
- MX Master stays on Mac Mini via USB dongle permanently (not involved in switching).

## Device addresses

| Device | Address |
|---|---|
| Magic Keyboard | `38-09-fb-12-33-82` |
| Magic Trackpad | `04-41-a5-8b-59-88` |

## Install on MacBook

```bash
# Copy script to a stable location
sudo cp macbook-monitor-watch.sh /usr/local/bin/bt-switch-macbook.sh
sudo chmod +x /usr/local/bin/bt-switch-macbook.sh

# Install LaunchAgent (runs at login, auto-restarts on crash)
cp com.aheze.bt-switch-macbook.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.aheze.bt-switch-macbook.plist
```

## Install on Mac Mini

```bash
# Copy script to a stable location
sudo cp macmini-reconnect-watch.sh /usr/local/bin/bt-switch-macmini.sh
sudo chmod +x /usr/local/bin/bt-switch-macmini.sh

# Install LaunchAgent (runs at login, auto-restarts on crash)
cp com.aheze.bt-switch-macmini.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.aheze.bt-switch-macmini.plist
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
# MacBook
launchctl unload ~/Library/LaunchAgents/com.aheze.bt-switch-macbook.plist
rm ~/Library/LaunchAgents/com.aheze.bt-switch-macbook.plist
sudo rm /usr/local/bin/bt-switch-macbook.sh

# Mac Mini
launchctl unload ~/Library/LaunchAgents/com.aheze.bt-switch-macmini.plist
rm ~/Library/LaunchAgents/com.aheze.bt-switch-macmini.plist
sudo rm /usr/local/bin/bt-switch-macmini.sh
```
