//
//  LoadData.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 14/01/26.
//

import Foundation
import SQLite3

final class DatabaseService {
    
    static let shared = DatabaseService()

    private(set) var db: OpaquePointer?

    private let queue = DispatchQueue(label: "bt.database.queue")

    private init() {
        openDatabase()
    }

    // MARK: - Open

    private func openDatabase() {
        let url = AppSupportHelper.appSupportURL().appendingPathComponent("seed.sqlite3")
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            fatalError("Failed to open database")
        }
    }

    // MARK: - Thread-safe access

    private func withDatabase<T>(_ block: (OpaquePointer?) -> T) -> T {
        return queue.sync {
            block(db)
        }
    }
    
    func databaseAction<T>(query: String, actions: (OpaquePointer?) -> T) -> T?{
        var stmt: OpaquePointer?
        var result: T?
        return DatabaseService.shared.withDatabase{ db in
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                result = actions(stmt)
                sqlite3_step(stmt)
            }

            let rc = sqlite3_finalize(stmt)
            
            if rc != SQLITE_DONE {
                fatalError("Failed to finalize query")
            }
            
            return result
        }
    }
}
