// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  RoutineModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 15/01/26.
//

import Foundation
import GRDB

struct Routines : Codable, Identifiable, Equatable, FetchableRecord, PersistableRecord {
    let id : String
    let deviceId : String
    let name : String
    let createdAt : String
    var intervalSeconds : Int
    var isEnabled : Int
    var updateAt : String?
    var keepAliveStrategy : KeepAliveStrategyKind?

    static func toRoutineModel(_ device: BluetoothModel) -> Routines {
        return Routines(
            id: device.id,
            deviceId: device.id,
            name: device.name,
            createdAt: Date().isoFormatter,
            intervalSeconds: 0,
            isEnabled: 0,
            updateAt: nil,
            keepAliveStrategy: nil
        )
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let device_id = Column(CodingKeys.deviceId)
        static let name = Column(CodingKeys.name)
        static let interval_seconds = Column(CodingKeys.intervalSeconds)
        static let is_enabled = Column(CodingKeys.isEnabled)
        static let created_at = Column(CodingKeys.createdAt)
        static let update_at = Column(CodingKeys.updateAt)
        static let keep_alive_strategy = Column(CodingKeys.keepAliveStrategy)
    }
}
