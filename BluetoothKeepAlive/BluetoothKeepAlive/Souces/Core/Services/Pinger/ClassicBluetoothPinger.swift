// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  ClassicBluetoothPinger.swift
//  BluetoothKeepAlive
//

import Foundation
import IOBluetooth

final class ClassicBluetoothPinger: NSObject, BluetoothDevicePinger {

    let transport: RoutineTransport = .classic

    private var registeredAddresses: Set<String> = []
    private var connectionHandler: ((String, ConnectionChange) -> Void)?

    // Must be retained — IOBluetooth releases observers when these refs are dropped.
    private var classConnectNotification: IOBluetoothUserNotification?
    private var perDeviceDisconnect: [String: IOBluetoothUserNotification] = [:]

    private let stateQueue = DispatchQueue(label: "com.bluetooth-keep-alive.classic-pinger.state")

    private let sdpStrategy = SDPQueryStrategy()
    private let audioStrategy = AudioBlipStrategy()

    deinit {
        stopObserving()
    }

    func isConnected(deviceId: String) -> Bool {
        IOBluetoothDevice(addressString: deviceId)?.isConnected() ?? false
    }

    func ping(deviceId: String, strategyOverride: KeepAliveStrategyKind?) -> PingOutcome {
        guard let device = IOBluetoothDevice(addressString: deviceId) else {
            return .failed("Could not resolve IOBluetoothDevice for \(deviceId)")
        }
        return strategy(for: device, override: strategyOverride).perform(on: device)
    }

    func keepAliveMethodLabel(deviceId: String, strategyOverride: KeepAliveStrategyKind?) -> String? {
        guard let device = IOBluetoothDevice(addressString: deviceId) else { return nil }
        return strategy(for: device, override: strategyOverride).label
    }

    /// Override (if present) wins. Otherwise we auto-detect: audio devices
    /// (`deviceClassMajor == kBluetoothDeviceClassMajorAudio`) don't reliably respond to SDP
    /// queries — many headsets ignore them outright. For those, sending a short silent PCM
    /// buffer to the default audio output keeps the A2DP session alive (provided the device
    /// is currently the active output).
    private func strategy(for device: IOBluetoothDevice, override: KeepAliveStrategyKind?) -> KeepAliveStrategy {
        switch override {
        case .sdp: return sdpStrategy
        case .audio: return audioStrategy
        case .none:
            if device.deviceClassMajor == UInt32(kBluetoothDeviceClassMajorAudio) {
                return audioStrategy
            }
            return sdpStrategy
        }
    }

    func startObserving(_ handler: @escaping (String, ConnectionChange) -> Void) {
        connectionHandler = handler

        if classConnectNotification == nil {
            classConnectNotification = IOBluetoothDevice.register(
                forConnectNotifications: self,
                selector: #selector(handleConnect(_:device:))
            )
        }

        // Attach disconnect observers to already-connected paired devices in our set.
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        for device in paired {
            guard let address = device.addressString else { continue }
            let normalized = Self.normalize(address)
            if registeredAddresses.contains(normalized), device.isConnected() {
                attachDisconnectObserver(to: device, address: normalized)
                handler(normalized, .connected)
            }
        }
    }

    func updateRegisteredAddresses(_ addresses: Set<String>) {
        stateQueue.sync {
            registeredAddresses = Set(addresses.map { Self.normalize($0) })
        }
    }

    func stopObserving() {
        classConnectNotification?.unregister()
        classConnectNotification = nil
        for (_, notif) in perDeviceDisconnect {
            notif.unregister()
        }
        perDeviceDisconnect.removeAll()
        connectionHandler = nil
    }

    // MARK: - IOBluetooth callbacks

    @objc private func handleConnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard let raw = device.addressString else { return }
        let address = Self.normalize(raw)

        let isRegistered = stateQueue.sync { registeredAddresses.contains(address) }
        guard isRegistered else { return }

        attachDisconnectObserver(to: device, address: address)
        connectionHandler?(address, .connected)
    }

    @objc private func handleDisconnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard let raw = device.addressString else { return }
        let address = Self.normalize(raw)

        if let notif = perDeviceDisconnect.removeValue(forKey: address) {
            notif.unregister()
        }
        connectionHandler?(address, .disconnected)
    }

    // MARK: - Helpers

    private func attachDisconnectObserver(to device: IOBluetoothDevice, address: String) {
        guard perDeviceDisconnect[address] == nil else { return }
        if let notif = device.register(
            forDisconnectNotification: self,
            selector: #selector(handleDisconnect(_:device:))
        ) {
            perDeviceDisconnect[address] = notif
        }
    }

    /// IOBluetooth addresses come back uppercase hex with hyphens; normalize for set membership.
    static func normalize(_ address: String) -> String {
        address.uppercased()
    }
}
