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
            repositoryUpdated.send(element)
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
            repositoryUpdated.send(element)
        } catch {
            throw ErrorHelpers.updateFailed(reason: "Failed to update routine")
        }
    }
    
    override func list() throws -> Array<Routines>? {
        return try dbQueue.read { db in
            let routines = try Routines.fetchAll(db)

            for routine in routines {
                repositoryUpdated.send(routine)
            }
            return routines
        }
    }
    
    override func delete(element: Routines) throws {
        do {
            _ = try dbQueue.write { db in
                try element.delete(db)
            }
            repositoryUpdated.send(element)
        } catch {
            throw ErrorHelpers.deletionFailed(reason: "Faield to delete routine")
        }
    }
}

