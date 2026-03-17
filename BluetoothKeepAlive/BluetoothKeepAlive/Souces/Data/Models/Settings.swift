//
//  Settings.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/03/26.
//

import Foundation
import GRDB

struct Settings : Codable, Identifiable, Equatable, FetchableRecord, PersistableRecord {
    
    let id : String
    let name: String
    let isEnabled: Int
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let isEnabled = Column(CodingKeys.isEnabled)
    }
}
