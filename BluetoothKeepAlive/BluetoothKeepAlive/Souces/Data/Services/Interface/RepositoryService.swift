//
//  RepositoryService.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 14/01/26.
//

class RepositoryService<T> {
    
    func insert(element: T) -> Bool {
        fatalError("Subclasses must implement the 'insert' method.")
    }
    func delete(id: String) -> Bool {
        fatalError("Subclasses must implement the 'delete' method.")
    }
    func update(element: T) -> Bool {
        fatalError("Subclasses must implement the 'update' method.")
    }
    func get(id: String) -> Bool {
        fatalError("Subclasses must implement the 'get' method.")
    }
    func list() -> Array<T>? {
        fatalError("Subclasses must implement the 'list' method.")
    }
}
