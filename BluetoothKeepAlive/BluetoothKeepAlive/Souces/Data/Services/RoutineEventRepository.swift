// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  RoutineEventRepository.swift
//  BluetoothKeepAlive
//

import Foundation
import GRDB

final class RoutineEventRepository: RepositoryService<RoutineEvent> {

    override func insert(element: RoutineEvent) throws {
        do {
            try dbQueue.write { db in
                try element.insert(db)
            }
            repositoryUpdated.send(element)
        } catch {
            throw ErrorHelpers.insetionFailed(reason: "Failed to insert routine event \(error)")
        }
    }

    func log(_ type: RoutineEventType, routineId: String, message: String? = nil) {
        let event = RoutineEvent.make(type, routineId: routineId, message: message)
        do {
            try insert(element: event)
        } catch {
            print("Failed to log routine event: \(error.localizedDescription)")
        }
    }

    func recent(routineId: String, limit: Int = 50) -> [RoutineEvent] {
        do {
            return try dbQueue.read { db in
                try RoutineEvent
                    .filter(RoutineEvent.Columns.routineId == routineId)
                    .order(RoutineEvent.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            return []
        }
    }

    func lastSuccess(routineId: String) -> RoutineEvent? {
        do {
            return try dbQueue.read { db in
                try RoutineEvent
                    .filter(RoutineEvent.Columns.routineId == routineId)
                    .filter(RoutineEvent.Columns.type == RoutineEventType.pingOk.rawValue)
                    .order(RoutineEvent.Columns.timestamp.desc)
                    .fetchOne(db)
            }
        } catch {
            return nil
        }
    }

    func disconnectsSince(routineId: String, since: Date) -> Int {
        let sinceIso = since.isoFormatter
        do {
            return try dbQueue.read { db in
                try RoutineEvent
                    .filter(RoutineEvent.Columns.routineId == routineId)
                    .filter(RoutineEvent.Columns.type == RoutineEventType.disconnected.rawValue)
                    .filter(RoutineEvent.Columns.timestamp >= sinceIso)
                    .fetchCount(db)
            }
        } catch {
            return 0
        }
    }

    /// Keep the last `retainPerRoutine` events per routine. Cheap to run on launch.
    func prune(retainPerRoutine: Int = 200) {
        do {
            try dbQueue.write { db in
                try db.execute(sql: """
                    DELETE FROM routine_events
                    WHERE id IN (
                        SELECT id FROM (
                            SELECT id,
                                   ROW_NUMBER() OVER (PARTITION BY routineId ORDER BY timestamp DESC) AS rn
                            FROM routine_events
                        ) WHERE rn > ?
                    )
                    """, arguments: [retainPerRoutine])
            }
        } catch {
            print("Failed to prune routine events: \(error.localizedDescription)")
        }
    }
}
