// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

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
