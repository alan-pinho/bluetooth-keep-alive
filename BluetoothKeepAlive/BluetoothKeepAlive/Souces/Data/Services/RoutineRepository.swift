//
//  RoutineRepository.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 03/03/26.
//

import GRDB
import Foundation

class RoutineRepository : RepositoryService<Routines>{
    override func insert(element: Routines) throws {
        do {
            try dbQueue.write { db in
                try element.insert(db)
            }
        } catch {
            throw ErrorHelpers.insetionFailed(reason: "Failed to insert routine \(error)")
        }
    }
    
    override func get(id: String) throws -> Routines? {
        do {
            return try dbQueue.read { db in
                try Routines.fetchOne(db, key: id)
            }
        } catch {
            return nil
        }
    }
    
    override func update(element: Routines) throws {
        do {
            _ = try dbQueue.write { db in
                try element.update(db)
            }
        } catch {
            throw ErrorHelpers.updateFailed(reason: "Failed to update routine")
        }
    }
    
    override func list() throws -> Array<Routines>? {
        try dbQueue.read { db in
            try Routines.fetchAll(db)
        }
    }
    
    override func delete(id: String) throws -> Bool {
        do {
            _ = try dbQueue.write { db in
                try Routines.deleteAll(db, keys: [id])
            }
            return true
        } catch {
            return false
        }
    }
}

