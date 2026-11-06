# USB-Ampel for macOS

A small native macOS app (SwiftUI) to control a **Cleware USB-Ampel** (traffic light, USB ID `0d50:0008`) plugged directly into your Mac.

- Click a lamp to toggle it
- *All on* / *All off*
- Blink one colour
- Keyboard shortcuts: ⌘1 red, ⌘2 yellow, ⌘3 green, ⌘0 all off
- Detects plugging/unplugging and restores the shown state on reconnect

Requires macOS 13 (Ventura) or later. Universal binary (Apple Silicon + Intel).

## Install

1. Download `USB-Ampel-x.y.z.zip` from the latest [release](../../releases) and unzip it.
2. Move `USB-Ampel.app` to `/Applications`.
3. The app is ad-hoc signed, not notarized. On first launch, either right-click → **Open**, or run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/USB-Ampel.app
   ```

## How it works

The Ampel only has an interrupt-IN endpoint, so commands are sent as HID output reports
(`IOHIDDeviceSetReport`) with the payload `00 <switch> <state>`:

| Switch | Lamp   |
|--------|--------|
| `0x10` | red    |
| `0x11` | yellow |
| `0x12` | green  |

State `0x01` = on, `0x00` = off.

## Build locally

```bash
scripts/build-app.sh 1.0.0
open build/USB-Ampel.app
```

## Release

Bump the version in `VERSION` and push to `main` (or push a tag like `v1.0.1`). GitHub Actions builds the app on a macOS runner and attaches the zip to the release `v<VERSION>`.
