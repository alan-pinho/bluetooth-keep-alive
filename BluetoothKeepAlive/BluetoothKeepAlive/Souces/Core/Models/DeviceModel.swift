//
//  DeviceModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 20/01/26.
//

import Foundation

struct DeviceModel {
    let id : String
    let deviceId : String
    let name : String
    let intervalSeconds : Int
    let isEnabled : Bool
    let createdAt : Date
    let updateAt : Date?
    
    func fromBluetoothModel(bluetooth: BluetoothModel) -> DeviceModel{
        return DeviceModel(
            id: UUID().uuid.4.description,
            deviceId: bluetooth.id,
            name: bluetooth.name,
            intervalSeconds: 0,
            isEnabled: false,
            createdAt: Date.now,
            updateAt: Date.now
        )
    }
}
