// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  PingerRegistry.swift
//  BluetoothKeepAlive
//

import Foundation

final class PingerRegistry {
    private var pingers: [RoutineTransport: BluetoothDevicePinger] = [:]

    func register(_ pinger: BluetoothDevicePinger) {
        pingers[pinger.transport] = pinger
    }

    func pinger(for transport: RoutineTransport) -> BluetoothDevicePinger? {
        pingers[transport]
    }

    var classic: BluetoothDevicePinger? {
        pingers[.classic]
    }

    var all: [BluetoothDevicePinger] {
        Array(pingers.values)
    }
}
