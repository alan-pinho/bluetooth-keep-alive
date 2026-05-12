// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  SDPQueryStrategy.swift
//  BluetoothKeepAlive
//

import Foundation
import IOBluetooth

final class SDPQueryStrategy: KeepAliveStrategy {
    let label = "SDP query"

    func perform(on device: IOBluetoothDevice) -> PingOutcome {
        device.performSDPQuery(nil)
        return .ok
    }
}
