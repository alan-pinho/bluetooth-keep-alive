//
//  DeviceViewModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 10/02/26.
//

import Foundation


final class DeviceViewModel :  ObservableObject {
    let routineRepository : RoutineRepositoryService = RoutineRepositoryService();
    let deviceId : String
    var routine : RoutineModel?

    @Published var timeInterval : Double = 0
    
    init(deviceId: String) {
        self.deviceId = deviceId
        load()
    }
    
    func load() -> Void{
        routine = routineRepository.getByDeviceId(id: deviceId);
    }
    
    func salvar() async throws -> Void{
        if timeInterval == 0 {
            throw ErrorHelpers.invalidValue(reason: "Valor de intervalo inválido! (0)")
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        print(timeInterval)
    }
}
