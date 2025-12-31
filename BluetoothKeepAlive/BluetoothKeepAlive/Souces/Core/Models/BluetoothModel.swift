//
//  BluetoothModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 31/12/25.
//
import Foundation
import CoreBluetooth
import IOBluetooth


enum BTType {
    case ble(CBPeripheral)
    case classic(IOBluetoothDevice)
    
    func toString() -> String {
        switch self {
        case .ble(let peripheral):
            return "\(peripheral.name ?? "Unknow")"
        case .classic(let device):
            return "\(device.name ?? "Unknow")"
        }
    }
}


struct BluetoothModel: Identifiable {
    let id: String
    let name: String
    let type: BTType
    let rssi: Int?
}
