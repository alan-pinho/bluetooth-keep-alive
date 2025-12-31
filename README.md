# Bluetooth Keep Alive (macOS)

**Bluetooth Keep Alive** is a macOS application designed to keep Bluetooth devices continuously connected and responsive by automatically maintaining and restoring their connections.

It supports both **Bluetooth Low Energy (BLE)** devices and **classic Bluetooth (paired devices)**, providing a unified interface to monitor, reconnect, and manage Bluetooth connections in real time.

---

## Features

* Scan and list **Bluetooth Low Energy (BLE)** devices
* Load and manage **classic Bluetooth paired devices**
* Unified device list (BLE + Classic)
* Automatic reconnection / keep-alive routines
* Real-time RSSI monitoring
* Menu bar support (background operation)
* macOS-native SwiftUI interface
* Safe, sandboxed and code-signed execution

---

## How It Works

Bluetooth Keep Alive uses:

* **CoreBluetooth** to scan and manage BLE devices
* **IOBluetooth** to load and reconnect classic paired devices
* A unified device model to present both device types in one list
* Periodic timers to automatically restore dropped connections

This ensures Bluetooth devices remain active, responsive and stable.

---

## Screens

* Home screen shows all available Bluetooth devices
* Devices are marked as:

  * **BLE**
  * **Classic (Paired)**
* Context actions allow manual reconnection and keep-alive triggering

---

## Permissions

The app requires Bluetooth access:

`Info.plist`

```xml
NSBluetoothAlwaysUsageDescription
```

Capabilities:

```
App Sandbox
  ✔ Bluetooth
  ✔ Outgoing Connections (Client)
```

---

## Build & Run

### Requirements

* macOS 13+ (Ventura or newer recommended)
* Xcode 15+
* Apple Developer account (for signing)

### Run

1. Open the project in Xcode
2. Select your signing team
3. Press **⌘ R**

---

## Use Cases

* Prevent Bluetooth devices from sleeping
* Maintain serial BT connections (Arduino, ESP32, etc)
* Keep headsets and audio devices responsive
* Stabilize Bluetooth automation workflows

---

## Architecture

```
BluetoothKeepAliveApp/
 ├── UI/
 ├── Bluetooth/
 ├── Services/
 ├── MenuBar/
 └── Resources/
```

---

## 📄 License

MIT License
