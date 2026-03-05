//
//  RoutineModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 15/01/26.
//

import Foundation
import GRDB

struct Routines : Codable, Identifiable, FetchableRecord, PersistableRecord {
    let id : String
    let deviceId : String
    let name : String
    let isEnabled : Int
    let createdAt : String
    var intervalSeconds : Int
    var updateAt : String?
    
    static func toRoutineModel(_ device: BluetoothModel) -> Routines {
        return Routines(
            id: device.id,
            deviceId: device.id,
            name: device.name,
            isEnabled: 0,
            createdAt: Date().isoFormatter,
            intervalSeconds: 0,
            updateAt: nil
        )
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let device_id = Column(CodingKeys.deviceId)
        static let name = Column(CodingKeys.name)
        static let interval_seconds = Column(CodingKeys.intervalSeconds)
        static let is_enabled = Column(CodingKeys.isEnabled)
        static let created_at = Column(CodingKeys.createdAt)
        static let update_at = Column(CodingKeys.updateAt)
    }
    
    
}

