# Bluetooth Keep Alive (macOS)

[![Version](https://img.shields.io/badge/version-0.9.1-blue?style=flat-square&logo=apple&logoColor=white)](https://github.com/alan-pinho/bluetooth-keep-alive/releases/tag/v0.9.1)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=flat-square&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/alan.pinho)

A menu-bar app that keeps paired Bluetooth devices awake by pinging them on a
schedule. Lives in the menu bar, has no Dock icon, and is meant to run in the
background — including at login.

It targets the case where macOS aggressively idles Bluetooth links (audio
headsets dropping out, paired peripherals going to sleep faster than you want)
and works around it by poking the device on a per-routine interval.

---

## Features

- **Per-device routines** — set an interval (seconds) and toggle on/off for any
  paired Bluetooth device.
- **Connection-aware state machine** — every routine sits in one of three
  states: *disabled* (off), *dormant* (device currently disconnected, no
  pings sent), *active* (connected, being pinged on schedule). Status badges
  in the Home list reflect this live.
- **Two keep-alive strategies** with auto-detection and per-device override:
  - **SDP query** — issues `IOBluetoothDevice.performSDPQuery` (works for most
    classic peripherals).
  - **Audio blip** — for audio devices that ignore SDP (most headsets and
    speakers do): keeps an `AVAudioEngine` warm and schedules a 200ms
    zero-PCM buffer per tick, which is enough to keep the A2DP/HFP session
    alive *as long as the device is the system's default output*.
- **Snooze** — pause all routines from the menu (15 min / 30 min / 1 h), with
  automatic resume.
- **Event log** — every ping result, connect/disconnect, dormant-skip and
  snooze-skip is recorded per routine in SQLite. Surfaced today as "last
  successful ping" and "disconnects this session" in the device view.
- **Start at login** — optional, via `SMAppService.mainApp` so the routine
  engine boots without opening any window.
- **Sandboxed** — only the Bluetooth device entitlement is granted; no
  network access, no file access beyond the app container.

---

## Architecture (short version)

- **SwiftUI + AppKit hybrid.** `@main` is an empty SwiftUI `Settings` scene
  (so SwiftUI doesn't auto-open a window); the `AppDelegate` builds the
  `NSStatusItem` and drives all windows via `NSHostingView`.
- **GRDB / SQLite** for persistence, with versioned migrations (`v1_baseline`,
  `v2_routine_events`, `v3_routine_keep_alive_strategy`).
- **CoreBluetooth** for BLE scan/discovery; **IOBluetooth** for classic paired
  devices and connect/disconnect notifications.

See [`CLAUDE.md`](CLAUDE.md) for the deeper architecture notes (DI graph,
state store, pinger abstraction).

### Current limitations

- BLE devices are **listed** in the Home screen but BLE keep-alive is not
  implemented yet — the pinger registry only ships a classic-Bluetooth
  implementation today.
- The audio-blip strategy needs the device to be the active audio output for
  the silence to reach it.

---

## Requirements

- macOS 15.5 or newer (deployment target)
- Xcode 17 or newer
- Apple Developer account (for code signing — even for local builds)

---

## Build & Run

The project keeps `DEVELOPMENT_TEAM` blank so the repo isn't tied to any one
account. Two ways to build:

**Xcode:** open `BluetoothKeepAlive/BluetoothKeepAlive.xcodeproj`, set your
team under *Target → Signing & Capabilities*, then ⌘R.

**CLI:**

```sh
xcodebuild \
    -project BluetoothKeepAlive/BluetoothKeepAlive.xcodeproj \
    -scheme BluetoothKeepAlive \
    -configuration Debug \
    DEVELOPMENT_TEAM=<your-team-id> \
    build
```

> There is no test target — `xcodebuild test` will fail.

---

## Packaging a release `.dmg`

```sh
DEVELOPMENT_TEAM=<your-team-id> ./scripts/make-dmg.sh
```

What the script does:

1. Builds a universal Release binary (`arm64` + `x86_64`).
2. Re-signs the bundle with **only** the entitlements declared in
   `BluetoothKeepAliveRelease.entitlements` (strips the
   `get-task-allow` / `network.client` entitlements the Apple Development
   profile injects automatically).
3. Wraps the `.app` + a drag-to-`/Applications` shortcut into a
   compressed `.dmg` under `dist/`, versioned from
   `CFBundleShortVersionString`.

The output is signed with Apple Development, not Developer ID, and is **not
notarized**. Recipients on another Mac will need to right-click → *Open* once,
or run:

```sh
xattr -d com.apple.quarantine /Applications/BluetoothKeepAlive.app
```

For a clean Gatekeeper experience, switch the signing identity to a
Developer ID Application certificate and add a `notarytool submit` +
`stapler staple` step.

---

## Use cases

- Keep Bluetooth headphones / speakers from idling out mid-listen.
- Keep paired controllers and peripherals responsive on long sessions.
- Stabilise classic-Bluetooth automation flows where macOS idles links faster
  than your peripheral can re-establish them.

---

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE) for the full text.

Copyright © 2026 Alan Pinho. This program is free software: you can
redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version. This
program is distributed WITHOUT ANY WARRANTY; see the LICENSE file for
details.
