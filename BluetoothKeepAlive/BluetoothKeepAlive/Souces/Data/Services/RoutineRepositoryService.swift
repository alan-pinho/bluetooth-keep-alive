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
        
        let response = DatabaseService.shared.databaseAction(query: query){ (stmt) in
            sqlite3_bind_text(stmt, 1, "\(UUID().uuid.4)", -1, nil)
            sqlite3_bind_text(stmt, 2, element.deviceId, -1, nil)
            sqlite3_bind_text(stmt, 3, element.name, -1, nil)
            sqlite3_bind_int(stmt, 4, Int32(element.intervalSeconds))
            sqlite3_bind_int(stmt, 4, Int32(0))
            sqlite3_bind_text(stmt, 6, date.ISO8601Format(), -1, nil)
            sqlite3_bind_text(stmt, 7, date.ISO8601Format(), -1, nil)
            return true
        }
        
        return  response != nil
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
                    isEnabled: sqlite3_column_int(stmt, 4) == 1,
                    createdAt: ISO8601DateFormatter().date(from: String(cString: sqlite3_column_text(stmt, 5)))!,
                    updateAt: ISO8601DateFormatter().date(from: String(cString: sqlite3_column_text(stmt, 6))))
                )
            }
            return list
        }
        
        return response
    }
    
    override func update(element: RoutineModel) -> Bool {
        let query = """
        UPDATE routines
        SET device_id=\(element.deviceId),
        name=\(element.name),
        interval_seconds=\(element.intervalSeconds),
        is_enabled=\(element.isEnabled),
        created_at=\(element.createdAt.isoFormatter),
        update_at=\(Date.now.isoFormatter)
        WHERE id=\(element.id);
        """
        
        let response = DatabaseService.shared.databaseAction(query: query){ (stmt) in
            sqlite3_bind_text(stmt, 1, (element.deviceId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (element.name as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 3, Int32(element.intervalSeconds))
            sqlite3_bind_int(stmt, 4, element.isEnabled ? 1 : 0)
            sqlite3_bind_text(stmt, 5, (element.createdAt.isoFormatter as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (element.id as NSString).utf8String, -1, nil)
            return true
        }
        
        return response != nil
    }
}
