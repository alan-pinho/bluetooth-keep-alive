//
//  TimerRoutineService.swift
//  BluetoothKeepAlive
//

import Foundation
import Combine

class TimerRoutineService {
    private var timers: [TimerModel] = []
    private var cancellables: Set<AnyCancellable> = []
    private let routineRepository: RoutineRepository
    private let pingerRegistry: PingerRegistry
    private let stateStore: RoutineStateStore
    private let eventRepository: RoutineEventRepository
    private let snoozeService: SnoozeService

    /// Tracks which routines have already logged a dormantSkip since they last became dormant.
    private var dormantSkipLogged: Set<String> = []

    /// Tracks routines for which we already logged a snoozeSkip during the current snooze window.
    private var snoozeSkipLogged: Set<String> = []

    /// Per-routine keep-alive strategy override. Refreshed on every repositoryUpdated event
    /// so each tick can resolve the override without hitting the DB.
    private var strategyOverrides: [String: KeepAliveStrategyKind] = [:]

    init(routineRepository: RoutineRepository,
         pingerRegistry: PingerRegistry,
         stateStore: RoutineStateStore,
         eventRepository: RoutineEventRepository,
         snoozeService: SnoozeService) {
        self.routineRepository = routineRepository
        self.pingerRegistry = pingerRegistry
        self.stateStore = stateStore
        self.eventRepository = eventRepository
        self.snoozeService = snoozeService
        do {
            self.timerSink()
            self.transitionSink()
            self.snoozeSink()
            try self.startTimers()
        } catch {
            showError(ErrorHelpers.recordNotFound("Failed to start timers"))
        }
    }

    /// Adds a repeating timer that fires every `seconds` seconds and calls `closure`.
    func addTimerFromMinutes(_ seconds: Int, _ id: String, closure: @escaping () -> Void) {
        let clampedSeconds = max(1, seconds)
        let interval = TimeInterval(clampedSeconds)

        if let existingIndex = timers.firstIndex(where: { $0.id == id }) {
            timers[existingIndex].timer.invalidate()
            timers.remove(at: existingIndex)
        }

        let createTimer: () -> Void = { [weak self] in
            guard let self = self else { return }
            let timer = Timer(timeInterval: interval, repeats: true) { _ in
                if Thread.isMainThread {
                    closure()
                } else {
                    DispatchQueue.main.async { closure() }
                }
            }
            RunLoop.main.add(timer, forMode: .common)

            let newTimer = TimerModel(id: id, timer: timer)
            self.timers.append(newTimer)
        }

        if Thread.isMainThread {
            createTimer()
        } else {
            DispatchQueue.main.async { createTimer() }
        }
    }

    func invalidateTimer(_ id: String) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].timer.invalidate()
        timers.remove(at: index)
    }

    func invalidateAll() {
        for i in timers.indices {
            timers[i].timer.invalidate()
        }
        timers.removeAll()
    }

    private func startTimers() throws {
        _ = try routineRepository.list()
    }

    private func timerSink() {
        routineRepository.repositoryUpdated.sink { [weak self] update in
            guard let self = self else { return }
            self.strategyOverrides[update.id] = update.keepAliveStrategy

            let timer = self.timers.first(where: { $0.id == update.id })
            if timer == nil {
                if !update.isEnabled.boolean { return }
                self.startTimer(update.id, update.intervalSeconds)
                return
            }
            if update.isEnabled.boolean {
                self.startTimer(update.id, update.intervalSeconds)
                return
            }
            self.invalidateTimer(update.id)
        }.store(in: &cancellables)
    }

    /// Fires an immediate ping when a routine transitions dormant → active,
    /// to recover the connection faster than waiting for the next tick.
    private func transitionSink() {
        stateStore.transitions
            .sink { [weak self] id, newState in
                guard let self = self else { return }
                switch newState {
                case .active:
                    self.dormantSkipLogged.remove(id)
                    self.fireTick(for: id)
                case .dormant, .disabled:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func startTimer(_ id: String, _ interval: Int) {
        self.addTimerFromMinutes(interval, id) { [weak self] in
            self?.fireTick(for: id)
        }
    }

    private func fireTick(for id: String) {
        guard let pinger = pingerRegistry.classic else { return }

        if snoozeService.isPaused() {
            if !snoozeSkipLogged.contains(id) {
                eventRepository.log(.snoozeSkip, routineId: id)
                snoozeSkipLogged.insert(id)
            }
            return
        }
        snoozeSkipLogged.remove(id)

        switch stateStore.state(for: id) {
        case .disabled:
            return
        case .dormant:
            if !dormantSkipLogged.contains(id) {
                eventRepository.log(.dormantSkip, routineId: id)
                dormantSkipLogged.insert(id)
            }
            return
        case .active:
            dormantSkipLogged.remove(id)
            let override = strategyOverrides[id]
            let method = pinger.keepAliveMethodLabel(deviceId: id, strategyOverride: override)
            switch pinger.ping(deviceId: id, strategyOverride: override) {
            case .ok:
                eventRepository.log(.pingOk, routineId: id, message: method)
            case .failed(let reason):
                eventRepository.log(.pingFailed, routineId: id, message: reason)
            case .skippedDormant, .skippedSnooze:
                break
            }
        }
    }

    /// When snooze ends, reset the snooze rate-limit set so the next tick can log again
    /// if the user re-snoozes later.
    private func snoozeSink() {
        snoozeService.$snoozedUntil
            .receive(on: DispatchQueue.main)
            .sink { [weak self] until in
                if until == nil { self?.snoozeSkipLogged.removeAll() }
            }
            .store(in: &cancellables)
    }
}
