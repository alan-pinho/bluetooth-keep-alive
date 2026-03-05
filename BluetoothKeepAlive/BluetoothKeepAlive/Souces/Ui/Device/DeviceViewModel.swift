//
//  DeviceViewModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 10/02/26.
//

import Foundation


final class DeviceViewModel :  ObservableObject {
    let routineRepository : RoutineRepository = .init();
    let bluetoothModel : BluetoothModel
    @Published var routine : Routines?

    @Published var timeInterval : Double = 0
    
    init(bluetoothModel: BluetoothModel) {
        self.bluetoothModel = bluetoothModel
        load()
    }
    
    func load() -> Void {
        do {
            routine = try routineRepository.get(id: bluetoothModel.id)
        } catch {
            routine = nil
        }
    }
    
    func saveRoutine() async throws -> Void{
        if timeInterval == 0 {
            throw ErrorHelpers.invalidValue(reason: "Invalid time interval (0)")
        }
        do {
            var element = Routines.toRoutineModel(bluetoothModel)
            element.intervalSeconds = Int(timeInterval)
            element.updateAt = Date().isoFormatter
            try routineRepository.insert(element: element)
        } catch {
            var element = try routineRepository.get(id: bluetoothModel.id)
            if element == nil {
                return
            }
            element!.intervalSeconds = Int(timeInterval)
            try routineRepository.update(element: element!)
        }
        print(timeInterval)
    }
}
