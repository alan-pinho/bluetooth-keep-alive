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
    private var central: CBCentralManager!
    private let localMAC = IOBluetoothHostController.default()?.addressAsString()
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
        loadPaired()
    }
    
    func startScanning() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: nil)
    }
    
    func stopScanning() {
        central.stopScan()
    }
    
    func loadPaired() {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        
        for device in paired {
            // TODO: remove self device
            if device.addressString == localMAC { continue }
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
        if central.state == .poweredOn{
            startScanning()
        }
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
