//
//  DatabaseMigrations.swift
//  BluetoothKeepAlive
//

import Foundation
import GRDB

enum DatabaseMigrations {

    static func register(in migrator: inout DatabaseMigrator) {

        migrator.registerMigration("v1_baseline") { db in
            if try !db.tableExists("routines") {
                try db.create(table: "routines") { t in
                    t.column("id", .text).primaryKey()
                    t.column("deviceId", .text).notNull()
                    t.column("name", .text).notNull()
                    t.column("createdAt", .text).notNull()
                    t.column("intervalSeconds", .integer).notNull().defaults(to: 0)
                    t.column("isEnabled", .integer).notNull().defaults(to: 0)
                    t.column("updateAt", .text)
                }
            }
            if try !db.tableExists("settings") {
                try db.create(table: "settings") { t in
                    t.column("id", .text).primaryKey()
                    t.column("name", .text).notNull()
                    t.column("isEnabled", .integer).notNull().defaults(to: 0)
                }
            }
        }

        migrator.registerMigration("v2_routine_events") { db in
            try db.create(table: "routine_events") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("routineId", .text).notNull().indexed()
                t.column("type", .text).notNull()
                t.column("timestamp", .text).notNull()
                t.column("message", .text)
            }
            try db.create(
                index: "idx_routine_events_routine_ts",
                on: "routine_events",
                columns: ["routineId", "timestamp"]
            )
        }

        migrator.registerMigration("v3_routine_keep_alive_strategy") { db in
            try db.alter(table: "routines") { t in
                t.add(column: "keepAliveStrategy", .text)
            }
        }
    }
}
