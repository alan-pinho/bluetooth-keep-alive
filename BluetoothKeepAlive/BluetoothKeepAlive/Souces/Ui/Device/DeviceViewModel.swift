//
//  DeviceViewModel.swift
//  BluetoothKeepAlive
//

import Foundation
import Combine

final class DeviceViewModel: ObservableObject {

    let routineRepository: RoutineRepository = DIService.shared.routineRepository
    private let stateStore: RoutineStateStore = DIService.shared.routineStateStore
    private let eventRepository: RoutineEventRepository = DIService.shared.routineEventRepository

    private var bluetoothModel: BluetoothModel
    private var cancellables: Set<AnyCancellable> = []
    private let sessionStart: Date = Date()

    @Published var selectedRoutine: Routines?
    @Published var timeInterval: Double = 0
    @Published var isEnabled: Bool = false
    @Published var runtimeState: RoutineRuntimeState = .disabled
    @Published var lastPingAt: Date?
    @Published var sessionDisconnects: Int = 0
    @Published var keepAliveMethod: String?
    @Published var detectedMethod: String?
    @Published var strategyOverride: KeepAliveStrategyKind?

    init(bluetoothModel: BluetoothModel) {
        self.bluetoothModel = bluetoothModel
        load()
        bindStateStore()
    }

    func updateDevice(_ bluetoothModel: BluetoothModel) {
        self.bluetoothModel = bluetoothModel
        load()
    }

    func load() {
        clearViewModel()
        let pinger = DIService.shared.pingerRegistry.classic
        detectedMethod = pinger?.keepAliveMethodLabel(deviceId: bluetoothModel.id, strategyOverride: nil)
        do {
            selectedRoutine = try routineRepository.get(id: bluetoothModel.id)
            if selectedRoutine == nil {
                runtimeState = .disabled
                keepAliveMethod = detectedMethod
                return
            }
            timeInterval = Double(selectedRoutine!.intervalSeconds)
            isEnabled = selectedRoutine!.isEnabled.boolean
            strategyOverride = selectedRoutine!.keepAliveStrategy
            keepAliveMethod = pinger?.keepAliveMethodLabel(deviceId: bluetoothModel.id, strategyOverride: strategyOverride)
            runtimeState = stateStore.state(for: bluetoothModel.id)
            refreshStats()
        } catch {
            selectedRoutine = nil
        }
    }

    private func bindStateStore() {
        stateStore.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                guard let self = self else { return }
                self.runtimeState = states[self.bluetoothModel.id] ?? .disabled
            }
            .store(in: &cancellables)

        stateStore.transitions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id, state in
                guard let self = self, id == self.bluetoothModel.id else { return }
                if state == .dormant {
                    self.sessionDisconnects += 1
                }
                if state == .active {
                    self.refreshStats()
                }
            }
            .store(in: &cancellables)

        $strategyOverride
            .dropFirst()
            .sink { [weak self] override in
                guard let self = self else { return }
                self.keepAliveMethod = DIService.shared.pingerRegistry.classic?
                    .keepAliveMethodLabel(deviceId: self.bluetoothModel.id, strategyOverride: override)
            }
            .store(in: &cancellables)
    }

    private func refreshStats() {
        if let event = eventRepository.lastSuccess(routineId: bluetoothModel.id) {
            lastPingAt = ISO8601DateFormatter.parse(event.timestamp)
        } else {
            lastPingAt = nil
        }
        sessionDisconnects = eventRepository.disconnectsSince(
            routineId: bluetoothModel.id,
            since: sessionStart
        )
    }

    private func clearViewModel() {
        selectedRoutine = nil
        timeInterval = 0
        isEnabled = false
        runtimeState = .disabled
        lastPingAt = nil
        sessionDisconnects = 0
        keepAliveMethod = nil
        detectedMethod = nil
        strategyOverride = nil
    }

    func saveRoutine() async throws {
        if timeInterval == 0 {
            throw ErrorHelpers.invalidValue(reason: "Invalid time interval (0)")
        }

        let routine = try routineRepository.get(id: bluetoothModel.id)

        if routine == nil {
            try createRoutine()
            return
        }
        try updateRoutine(routine!)
    }

    private func createRoutine() throws {
        var element = Routines.toRoutineModel(bluetoothModel)
        element.intervalSeconds = Int(timeInterval)
        element.updateAt = Date().isoFormatter
        element.isEnabled = isEnabled.integer
        element.keepAliveStrategy = strategyOverride
        try routineRepository.insert(element: element)
    }

    private func updateRoutine(_ routine: Routines) throws {
        var updatedRoutine = routine
        updatedRoutine.intervalSeconds = Int(timeInterval)
        updatedRoutine.updateAt = Date().isoFormatter
        updatedRoutine.isEnabled = isEnabled.integer
        updatedRoutine.keepAliveStrategy = strategyOverride
        try routineRepository.update(element: updatedRoutine)
    }
}

private extension ISO8601DateFormatter {
    static func parse(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: string)
    }
}
