//
//  DIService.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 06/03/26.
//

class DIService {
    static let shared = DIService()

    lazy var routineRepository = RoutineRepository()
    lazy var timerRoutineService = TimerRoutineService(routineRepository: DIService.shared.routineRepository)
}
