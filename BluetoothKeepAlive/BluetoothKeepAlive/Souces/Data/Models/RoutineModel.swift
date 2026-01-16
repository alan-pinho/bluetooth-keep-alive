//
//  RoutineModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 15/01/26.
//

import Foundation

struct RoutineModel {
    let id : String
    let deviceId : String
    let name : String
    let intervalSeconds : Int
    let isEnabled : Bool
    let createdAt : Date
    let updateAt : Date?
}
