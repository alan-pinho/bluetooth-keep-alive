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
    private var central: CBCentralManager!
    private let localName = IOBluetoothHostController.default()?.addressAsString() ?? ""
    
    
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
            print("Local MAC: \(localName) | Dispositivo - Nome: \(device.name ?? "Sem nome") MAC: \(device.addressString ?? "")")
            
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

extension IOBluetoothDevice {
    var isLocalMacHostUniversal: Bool {

        return
            // 1. Endereço virtual interno do macOS (sempre começa com 'd')
            (addressString?.hasPrefix("d") == true)

            // 2. Não anuncia nenhuma classe Bluetooth válida
            && deviceClassMajor == 0
            && deviceClassMinor == 0
            && classOfDevice == 0
            && serviceClassMajor == 0

            // 3. Nunca reporta RSSI real
            && rawRSSI() == 0

            // 4. Nunca anuncia serviços
            && (services?.isEmpty ?? true)

            // 5. Sempre aparece como pareado
            && isPaired()
    }
}
