//
//  RoutineModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 15/01/26.
//

import Foundation

class RoutineModel {
    let id : String
    let deviceId : String
    let name : String
    let intervalSeconds : Int
    let isEnabled : Bool
    let createdAt : Date
    let updateAt : Date
    
    init(id: String, deviceId: String, name: String, intervalSeconds: Int, isEnabled: Bool, createdAt: Date, updateAt: Date) {
        self.id = id
        self.deviceId = deviceId
        self.name = name
        self.intervalSeconds = intervalSeconds
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updateAt = updateAt
    }
}
