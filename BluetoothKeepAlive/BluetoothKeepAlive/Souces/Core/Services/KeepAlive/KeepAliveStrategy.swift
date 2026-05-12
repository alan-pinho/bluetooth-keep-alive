//
//  KeepAliveStrategy.swift
//  BluetoothKeepAlive
//

import Foundation
import IOBluetooth

protocol KeepAliveStrategy: AnyObject {
    var label: String { get }
    func perform(on device: IOBluetoothDevice) -> PingOutcome
}
