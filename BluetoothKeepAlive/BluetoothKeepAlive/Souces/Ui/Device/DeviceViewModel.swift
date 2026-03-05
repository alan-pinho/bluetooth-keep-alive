//
//  DeviceViewModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 10/02/26.
//

import Foundation


final class DeviceViewModel :  ObservableObject {
    let routineRepository : RoutineRepository = .init();
    private var bluetoothModel : BluetoothModel
    
    @Published var selectedRoutine : Routines?
    @Published var timeInterval : Double = 0
    
    init(bluetoothModel: BluetoothModel) {
        self.bluetoothModel = bluetoothModel
        load()
    }

    func updateDevice(_ bluetoothModel: BluetoothModel) {
        self.bluetoothModel = bluetoothModel
        load()
    }
    
    func load() -> Void {
        clearViewModel()
        do {
            selectedRoutine = try routineRepository.get(id: bluetoothModel.id)
            if (selectedRoutine == nil) {
                return;
            }
            timeInterval = Double(selectedRoutine!.intervalSeconds)
        } catch {
            selectedRoutine = nil
        }
    }
    
    private func clearViewModel() -> Void {
        selectedRoutine = nil
        timeInterval = 0
    }
    
    func saveRoutine() async throws -> Void{
        if timeInterval == 0 {
            throw ErrorHelpers.invalidValue(reason: "Invalid time interval (0)")
        }
        
        let routine = try routineRepository.get(id: bluetoothModel.id)
        
        if routine == nil {
            try createRoutine()
            return
        }
        try updateRoutine()
        print(timeInterval)
    }
    
    private func createRoutine() throws -> Void {
        var element = Routines.toRoutineModel(bluetoothModel)
        element.intervalSeconds = Int(timeInterval)
        element.updateAt = Date().isoFormatter
        try routineRepository.insert(element: element)
    }
    
    private func updateRoutine() throws -> Void {
        var routine = try routineRepository.get(id: bluetoothModel.id)
        routine!.intervalSeconds = Int(timeInterval)
        routine!.updateAt = Date().isoFormatter
        try routineRepository.update(element: routine!)
    }
}
