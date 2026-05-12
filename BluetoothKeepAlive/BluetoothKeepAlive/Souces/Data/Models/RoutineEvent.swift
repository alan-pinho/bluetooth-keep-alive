// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  RoutineEvent.swift
//  BluetoothKeepAlive
//

import Foundation
import GRDB

enum RoutineEventType: String, Codable {
    case pingOk
    case pingFailed
    case connected
    case disconnected
    case dormantSkip
    case snoozeSkip
}

struct RoutineEvent: Codable, Identifiable, FetchableRecord, PersistableRecord, Equatable {
    var id: Int64?
    let routineId: String
    let type: String
    let timestamp: String
    let message: String?

    static let databaseTableName = "routine_events"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let routineId = Column(CodingKeys.routineId)
        static let type = Column(CodingKeys.type)
        static let timestamp = Column(CodingKeys.timestamp)
        static let message = Column(CodingKeys.message)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    var typed: RoutineEventType? {
        RoutineEventType(rawValue: type)
    }

    static func make(_ type: RoutineEventType, routineId: String, message: String? = nil) -> RoutineEvent {
        RoutineEvent(
            id: nil,
            routineId: routineId,
            type: type.rawValue,
            timestamp: Date().isoFormatter,
            message: message
        )
    }
}
