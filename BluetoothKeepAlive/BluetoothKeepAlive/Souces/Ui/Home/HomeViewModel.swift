//
//  HomeViewModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 31/12/25.
//

import Foundation
import CoreBluetooth
import IOBluetooth

final class HomeViewModel: NSObject, ObservableObject {
    
    @Published var devices: [BluetoothModel] = []
    @Published var selectedDevice: BluetoothModel?
    private let localName = IOBluetoothHostController.default()?.addressAsString() ?? ""
    
    
    override init() {
        super.init()
        loadPaired()
    }
    
    func loadPaired() {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        
        for device in paired {
            print("Local MAC: \(localName) | Device - Name: \(device.name ?? "Unknown") MAC: \(device.addressString ?? "")")
            
            if device.isLocalMacHostUniversal { continue }
            
            addOrUpdate(
                BluetoothModel(
                    id: device.addressString ?? UUID().uuidString,
                    name: device.name ?? "Classic Device",
                    type: .classic(device),
                    rssi: nil,
                )
            )
        }
    }
    
    private func addOrUpdate(_ newDevice: BluetoothModel) {
        if let index = devices.firstIndex(where: { $0.id == newDevice.id }) {
            devices[index] = newDevice
        } else {
            devices.append(newDevice)
        }
    }
    
}

extension HomeViewModel: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let id = peripheral.identifier.uuidString
        let name = peripheral.name
        let rssi = RSSI.intValue
        
        if devices.contains(where: { $0.id == id }) { return }
        if name == nil { return }
        
        devices.append(BluetoothModel(id: id, name: name ?? "Unknow", type: .ble(peripheral), rssi: rssi))
    }
}

extension IOBluetoothDevice {
    var isLocalMacHostUniversal: Bool {

        return
            (addressString?.hasPrefix("d") == true)
            && deviceClassMajor == 0
            && deviceClassMinor == 0
            && classOfDevice == 0
            && serviceClassMajor == 0
            && rawRSSI() == 0
            && (services?.isEmpty ?? true)
            && isPaired()
    }
}
