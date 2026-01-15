//
//  Routines.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 14/01/26.
//

import SQLite3
import Foundation

class RoutineRepositoryService: RepositoryService<RoutineModel> {

    override func insert(element: RoutineModel) async -> Bool {
       return DatabaseService.shared.withDatabase { db in
            var stmt: OpaquePointer?
            let date = Date.now
            
            let sql = """
            INSERT INTO routines
            (id, device_id, name, interval_seconds, is_enabled, created_at, update_at)
            VALUES(?, ?, ?, ?, ?, ?, ?);
            """

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

                sqlite3_bind_text(stmt, 1, "\(UUID().uuid.4)", -1, nil)
                sqlite3_bind_text(stmt, 2, element.deviceId, -1, nil)
                sqlite3_bind_text(stmt, 3, element.name, -1, nil)
                sqlite3_bind_int(stmt, 4, Int32(element.intervalSeconds))
                sqlite3_bind_int(stmt, 4, Int32(0))
                sqlite3_bind_text(stmt, 6, date.ISO8601Format(), -1, nil)
                sqlite3_bind_text(stmt, 7, date.ISO8601Format(), -1, nil)

                sqlite3_step(stmt)
            }

            let rc = sqlite3_finalize(stmt)
            
            if rc == SQLITE_DONE {
                return true
            } else {
                let err = String(cString: sqlite3_errmsg(db))
                print("SQLite error:", err)
                
                return false
            }
        }
    }
    
}
