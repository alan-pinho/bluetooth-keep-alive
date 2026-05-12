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
    func ping(deviceId: String) -> PingOutcome
    func keepAliveMethodLabel(deviceId: String) -> String?

    func startObserving(_ handler: @escaping (String, ConnectionChange) -> Void)
    func updateRegisteredAddresses(_ addresses: Set<String>)
    func stopObserving()
}

extension BluetoothDevicePinger {
    func keepAliveMethodLabel(deviceId: String) -> String? { nil }
}
