//
//  SettingRepository.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/03/26.
//

import GRDB
import Foundation

class SettingRepository : RepositoryService<Settings>{
    
    override func get(id: String) throws -> Settings? {
        do {
            return try dbQueue.read { db in
                try Settings.fetchOne(db, key: id)
            }
        } catch {
            return nil
        }
    }
    
    override func insert(element: Settings) throws {
        do {
            try dbQueue.write { db in
                try element.insert(db)
            }
            repositoryUpdated.send(element)
        } catch {
            throw ErrorHelpers.insetionFailed(reason: "Failed to insert settings \(error)")
        }
    }
    
    override func update(element: Settings) throws {
        do {
            _ = try dbQueue.write { db in
                try element.update(db)
            }
            repositoryUpdated.send(element)
        } catch {
            throw ErrorHelpers.updateFailed(reason: "Failed to update setting")
        }
    }
    
}
