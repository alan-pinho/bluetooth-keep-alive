// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  SettingsViewModel.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/03/26.
//

import Foundation
import AppKit
import ServiceManagement

final class SettingsViewModel: ObservableObject {
    let settingRepository: SettingRepository
    let routineRepository: RoutineRepository
    
    private let startWithSystemSettingId = "start-with-system"
    private let startWithSystemSettingName = "Start with system"
    private var previousStartWithSystemValue: Bool = false
    
    init(settingsRepository: SettingRepository) {
        self.settingRepository = settingsRepository
        self.routineRepository = DIService.shared.routineRepository
        load()
    }
    
    @Published var startWithSystemEnabled: Bool = false
    
    func load() {
        do {
            let setting = try settingRepository.get(id: startWithSystemSettingId)
            startWithSystemEnabled = setting?.isEnabled.boolean ?? false
            previousStartWithSystemValue = startWithSystemEnabled
        } catch {
            startWithSystemEnabled = false
            previousStartWithSystemValue = false
        }
    }
    
    func updateStartWithSystem(_ isEnabled: Bool) throws {
        previousStartWithSystemValue = startWithSystemEnabled
        try configureSystemStartup(isEnabled)
        
        do {
            let setting = try settingRepository.get(id: startWithSystemSettingId)
            
            if setting == nil {
                try settingRepository.insert(
                    element: Settings(
                        id: startWithSystemSettingId,
                        name: startWithSystemSettingName,
                        isEnabled: isEnabled.integer
                    )
                )
                return
            }
            
            var updatedSetting = setting!
            updatedSetting = Settings(
                id: updatedSetting.id,
                name: updatedSetting.name,
                isEnabled: isEnabled.integer
            )
            try settingRepository.update(element: updatedSetting)
            startWithSystemEnabled = isEnabled
        } catch {
            try? configureSystemStartup(previousStartWithSystemValue)
            startWithSystemEnabled = previousStartWithSystemValue
            throw ErrorHelpers.updateFailed(reason: "Failed to save app startup setting")
        }
    }

    private func configureSystemStartup(_ isEnabled: Bool) throws {
        do {
            let startupService = SMAppService.mainApp
            
            if isEnabled {
                if startupService.status != .enabled && startupService.status != .requiresApproval {
                    try startupService.register()
                }
                return
            }

            if startupService.status == .enabled || startupService.status == .requiresApproval {
                try startupService.unregister()
            }
        } catch {
            throw ErrorHelpers.updateFailed(reason: "Failed to update macOS startup configuration")
        }
    }
    
    func deleteAllRoutines() throws {
        do {
            let routines = try routineRepository.list() ?? []
            for routine in routines {
                try routineRepository.delete(element: routine)
            }
        } catch {
            throw ErrorHelpers.deletionFailed(reason: "Failed to delete all routines")
        }
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
}
