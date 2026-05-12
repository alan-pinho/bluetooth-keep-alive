//
//  HomeViewModel.swift
//  BluetoothKeepAlive
//

import Foundation
import CoreBluetooth
import IOBluetooth
import Combine

final class HomeViewModel: NSObject, ObservableObject {

    @Published var devices: [BluetoothModel] = []
    @Published var selectedDevice: BluetoothModel?
    @Published var routines: [Routines] = []
    @Published var routineStates: [String: RoutineRuntimeState] = [:]

    private let localName = IOBluetoothHostController.default()?.addressAsString() ?? ""
    private let timerRoutineService: TimerRoutineService
    private let stateStore: RoutineStateStore
    private var cancellables: Set<AnyCancellable> = []

    init(timerRoutineService: TimerRoutineService,
         stateStore: RoutineStateStore) {
        self.timerRoutineService = timerRoutineService
        self.stateStore = stateStore
        super.init()
        loadPaired()
        bindStateStore()
    }

    func loadPaired() {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []

        for device in paired {
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

    private func bindStateStore() {
        stateStore.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.routineStates = $0 }
            .store(in: &cancellables)
    }

    func routineState(for deviceId: String) -> RoutineRuntimeState? {
        routineStates[deviceId]
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
