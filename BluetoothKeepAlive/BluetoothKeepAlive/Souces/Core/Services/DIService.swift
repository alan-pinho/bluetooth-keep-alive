// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  DIService.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 06/03/26.
//

class DIService {
    static let shared = DIService()

    lazy var routineRepository = RoutineRepository()
    lazy var settingRepository = SettingRepository()
    lazy var routineEventRepository = RoutineEventRepository()

    lazy var pingerRegistry: PingerRegistry = {
        let registry = PingerRegistry()
        registry.register(ClassicBluetoothPinger())
        return registry
    }()

    lazy var routineStateStore = RoutineStateStore(
        routineRepository: DIService.shared.routineRepository,
        pingerRegistry: DIService.shared.pingerRegistry,
        eventRepository: DIService.shared.routineEventRepository
    )

    lazy var snoozeService = SnoozeService(
        settingRepository: DIService.shared.settingRepository
    )

    lazy var timerRoutineService = TimerRoutineService(
        routineRepository: DIService.shared.routineRepository,
        pingerRegistry: DIService.shared.pingerRegistry,
        stateStore: DIService.shared.routineStateStore,
        eventRepository: DIService.shared.routineEventRepository,
        snoozeService: DIService.shared.snoozeService
    )
}
