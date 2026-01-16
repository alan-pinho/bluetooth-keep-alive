//
//  Routines.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 14/01/26.
//

import SQLite3
import Foundation


class RoutineRepositoryService: RepositoryService<RoutineModel> {
    
    override func insert(element: RoutineModel) -> Bool {
        let query = """
            INSERT INTO routines
            (id, device_id, name, interval_seconds, is_enabled, created_at, update_at)
            VALUES(?, ?, ?, ?, ?, ?, ?);
            """
        let date = Date.now
        
        DatabaseService.shared.databaseAction(query: query){ (stmt) in
            sqlite3_bind_text(stmt, 1, "\(UUID().uuid.4)", -1, nil)
            sqlite3_bind_text(stmt, 2, element.deviceId, -1, nil)
            sqlite3_bind_text(stmt, 3, element.name, -1, nil)
            sqlite3_bind_int(stmt, 4, Int32(element.intervalSeconds))
            sqlite3_bind_int(stmt, 4, Int32(0))
            sqlite3_bind_text(stmt, 6, date.ISO8601Format(), -1, nil)
            sqlite3_bind_text(stmt, 7, date.ISO8601Format(), -1, nil)
        }
        
        return true
    }
    
    override func delete(id: String) -> Bool {
        let query = """
            DELETE FROM routines
            WHERE id=?;
            """

        let response = DatabaseService.shared.databaseAction(query: query){ (stmt) in
            sqlite3_bind_text(stmt, 1, id, -1, nil)
        }
        return response != nil
    }
    
    override func get(id: String) -> Bool {
        let query = """
            SELECT *
            FROM routines
            WHERE id=?;
            """
        let response =  DatabaseService.shared.databaseAction(query: query){ (stmt) in
            sqlite3_bind_text(stmt, 1, id, -1, nil)
        }
        return response != nil
    }
    override func list() -> Array<RoutineModel>? {
        let query = """
            SELECT *
            FROM routines;
            """
        let response = DatabaseService.shared.databaseAction(query: query){ (stmt) in
            sqlite3_bind_text(stmt, 1, nil, -1, nil)
            var list : [RoutineModel] = []
             while sqlite3_step(stmt) == SQLITE_ROW {
                list.append(RoutineModel(
                    id: String(cString: sqlite3_column_text(stmt, 0)),
                    deviceId: String(cString: sqlite3_column_text(stmt, 1)),
                    name: String(cString: sqlite3_column_text(stmt, 2)),
                    intervalSeconds: Int(sqlite3_column_int(stmt, 3)),
                    isEnabled: sqlite3_column_int(stmt, 3) == 1,
                    createdAt: ISO8601DateFormatter().date(from: String(cString: sqlite3_column_text(stmt, 4)))!,
                    updateAt: ISO8601DateFormatter().date(from: String(cString: sqlite3_column_text(stmt, 5))))
                )
            }
            return list
        }
        
        return response
    }
}
