//
//  RepositoryService.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 14/01/26.
//

class RepositoryService<T> {
    
    func insert(element: T) async -> Bool {
        fatalError("Subclasses must implement the 'insert' method.")
    }
    func delete(element: T) async -> Bool {
        fatalError("Subclasses must implement the 'delete' method.")
    }
    func update(element: T) async -> Bool {
        fatalError("Subclasses must implement the 'update' method.")
    }
    func read(id: String) async -> Bool {
        fatalError("Subclasses must implement the 'update' method.")
    }

    func fromData() -> T {}
}
