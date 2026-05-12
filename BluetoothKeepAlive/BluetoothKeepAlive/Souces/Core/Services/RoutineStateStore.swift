//
//  RoutineStateStore.swift
//  BluetoothKeepAlive
//

import Foundation
import Combine

enum RoutineRuntimeState: Equatable {
    case disabled
    case dormant
    case active
}

final class RoutineStateStore: ObservableObject {

    /// Keyed by routine id exactly as stored in the database.
    @Published private(set) var states: [String: RoutineRuntimeState] = [:]

    /// Fires `(routineId, newState)` whenever a routine's state changes.
    let transitions = PassthroughSubject<(String, RoutineRuntimeState), Never>()

    private let routineRepository: RoutineRepository
    private let pingerRegistry: PingerRegistry
    private let eventRepository: RoutineEventRepository
    private var cancellables: Set<AnyCancellable> = []

    /// Maps normalized (uppercase) MAC → routine id as stored in DB.
    /// Lets us translate observer callbacks back to canonical routine ids.
    private var normalizedToRoutineId: [String: String] = [:]

    init(routineRepository: RoutineRepository,
         pingerRegistry: PingerRegistry,
         eventRepository: RoutineEventRepository) {
        self.routineRepository = routineRepository
        self.pingerRegistry = pingerRegistry
        self.eventRepository = eventRepository

        bindRepository()
        startObservers()
        bootstrap()
    }

    // MARK: - Bootstrap & subscriptions

    private func bootstrap() {
        do {
            let routines = try routineRepository.list() ?? []
            rebuildAddressSet(from: routines)
            for routine in routines {
                refreshState(for: routine, emitTransition: false)
            }
        } catch {
            print("RoutineStateStore bootstrap failed: \(error.localizedDescription)")
        }
    }

    private func bindRepository() {
        routineRepository.repositoryUpdated
            .sink { [weak self] routine in
                guard let self = self else { return }
                self.handleRoutineUpdate(routine)
            }
            .store(in: &cancellables)
    }

    private func startObservers() {
        for pinger in pingerRegistry.all {
            pinger.startObserving { [weak self] address, change in
                self?.handleConnectionChange(address: address, change: change)
            }
        }
    }

    // MARK: - Repository updates

    private func handleRoutineUpdate(_ routine: Routines) {
        do {
            let all = try routineRepository.list() ?? []
            rebuildAddressSet(from: all)

            let ids = Set(all.map { $0.id })
            let stale = states.keys.filter { !ids.contains($0) }
            if !stale.isEmpty {
                DispatchQueue.main.async {
                    for id in stale { self.states.removeValue(forKey: id) }
                }
            }
        } catch {
            print("RoutineStateStore: failed to relist routines: \(error.localizedDescription)")
        }

        refreshState(for: routine, emitTransition: true)
    }

    private func refreshState(for routine: Routines, emitTransition: Bool) {
        let next: RoutineRuntimeState
        if !routine.isEnabled.boolean {
            next = .disabled
        } else {
            let connected = pingerRegistry.classic?.isConnected(deviceId: routine.id) ?? false
            next = connected ? .active : .dormant
        }
        applyState(next, for: routine.id, emitTransition: emitTransition)
    }

    private func rebuildAddressSet(from routines: [Routines]) {
        let enabled = routines.filter { $0.isEnabled.boolean }
        var lookup: [String: String] = [:]
        var set: Set<String> = []
        for routine in enabled {
            let normalized = routine.id.uppercased()
            lookup[normalized] = routine.id
            set.insert(normalized)
        }
        normalizedToRoutineId = lookup
        for pinger in pingerRegistry.all {
            pinger.updateRegisteredAddresses(set)
        }
    }

    // MARK: - Connection callbacks (from pinger)

    private func handleConnectionChange(address: String, change: ConnectionChange) {
        let normalized = address.uppercased()
        guard let routineId = normalizedToRoutineId[normalized] else { return }

        let new: RoutineRuntimeState
        switch change {
        case .connected:
            new = .active
            eventRepository.log(.connected, routineId: routineId)
        case .disconnected:
            new = .dormant
            eventRepository.log(.disconnected, routineId: routineId)
        }
        applyState(new, for: routineId, emitTransition: true)
    }

    // MARK: - State mutation

    private func applyState(_ state: RoutineRuntimeState, for id: String, emitTransition: Bool) {
        DispatchQueue.main.async {
            let previous = self.states[id]
            guard previous != state else { return }
            self.states[id] = state
            if emitTransition {
                self.transitions.send((id, state))
            }
        }
    }

    // MARK: - Read

    func state(for id: String) -> RoutineRuntimeState {
        states[id] ?? .disabled
    }
}
