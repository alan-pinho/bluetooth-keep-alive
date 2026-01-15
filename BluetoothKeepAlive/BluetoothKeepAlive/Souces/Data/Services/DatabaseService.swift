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

    func withDatabase<T>(_ block: (OpaquePointer?) -> T) -> T {
        return queue.sync {
            block(db)
        }
    }
}
