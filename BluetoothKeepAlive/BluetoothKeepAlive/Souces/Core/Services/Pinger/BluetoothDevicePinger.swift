// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  BluetoothDevicePinger.swift
//  BluetoothKeepAlive
//

import Foundation

enum RoutineTransport: String, Codable {
    case classic
    case ble
}

enum ConnectionChange {
    case connected
    case disconnected
}

enum PingOutcome {
    case ok
    case failed(String)
    case skippedDormant
    case skippedSnooze
}

protocol BluetoothDevicePinger: AnyObject {
    var transport: RoutineTransport { get }

    func isConnected(deviceId: String) -> Bool
    func ping(deviceId: String, strategyOverride: KeepAliveStrategyKind?) -> PingOutcome
    func keepAliveMethodLabel(deviceId: String, strategyOverride: KeepAliveStrategyKind?) -> String?

    func startObserving(_ handler: @escaping (String, ConnectionChange) -> Void)
    func updateRegisteredAddresses(_ addresses: Set<String>)
    func stopObserving()
}

extension BluetoothDevicePinger {
    func keepAliveMethodLabel(deviceId: String, strategyOverride: KeepAliveStrategyKind?) -> String? { nil }
}
