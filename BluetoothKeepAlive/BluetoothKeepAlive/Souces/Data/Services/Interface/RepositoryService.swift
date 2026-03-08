//
//  RepositoryService.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 14/01/26.
//

import Foundation
import GRDB
import Combine

class RepositoryService<T> {
    let repositoryUpdated = PassthroughSubject<T, Never>()
    let dbQueue: DatabaseQueue

    init() {
        dbQueue = Self.openDatabase()
    }

    // MARK: - Paths
    private static func databaseDirectoryURL() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundleID = Bundle.main.bundleIdentifier ?? "BluetoothKeepAlive"
        let dir = appSupport.appendingPathComponent(bundleID, isDirectory: true)

        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: dir.path, isDirectory: &isDir)

        if exists {
            if !isDir.boolValue {
                // A file exists where our directory should be; remove it first
                try fm.removeItem(at: dir)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            // If it's already a directory, nothing to do
        } else {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }

    private static func databaseFileURL() throws -> URL {
        try databaseDirectoryURL().appendingPathComponent("RoutinesDatabase.sqlite3", isDirectory: false)
    }

    // MARK: - Seeding
    private static func ensureSeedCopied() throws {
        let fm = FileManager.default
        let targetURL = try databaseFileURL()

        if !fm.fileExists(atPath: targetURL.path) {
            guard let seedURL = Bundle.main.url(forResource: "RoutinesDatabase", withExtension: "sqlite3") else {
                throw NSError(domain: "RoutineRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "RoutinesDatabase.sqlite3 does not exist in the app bundle."])
            }
            try fm.copyItem(at: seedURL, to: targetURL)
        }
    }

    // MARK: - Open DB
    private static func openDatabase() -> DatabaseQueue {
        do {
            try ensureSeedCopied()
            let dbURL = try databaseFileURL()
            print("DB path: \(dbURL.path)")
            return try DatabaseQueue(path: dbURL.path)
        } catch {
            fatalError("Error opening database: \(error.localizedDescription)")
        }
    }
    
    func insert(element: T) throws {
        fatalError("Subclasses must implement the 'insert' method.")
    }
    func delete(element: T) throws {
        fatalError("Subclasses must implement the 'delete' method.")
    }
    func update(element: T) throws {
        fatalError("Subclasses must implement the 'update' method.")
    }
    func get(id: String) throws -> T? {
        fatalError("Subclasses must implement the 'get' method.")
    }
    func list() throws -> Array<T>? {
        fatalError("Subclasses must implement the 'list' method.")
    }
}
