//
//  TimerRoutineService.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 05/03/26.
//

import Foundation
import Combine

class TimerRoutineService {
    private var timers: [TimerModel] = []
    private var cancellables: Set<AnyCancellable> = []
    private let routineRepository: RoutineRepository

    init(routineRepository: RoutineRepository) {
        self.routineRepository = routineRepository
        do {
            self.timerSink()
            try self.startTimers()
        } catch {
            showError(ErrorHelpers.recordNotFound("Failed to start timers"))
        }
    }

    /// Adds a repeating timer that fires every `seconds` seconds and calls `closure`.
    /// - Parameters:
    ///   - seconds: The interval in seconds between firings. Values <= 0 will be treated as 1 second.
    ///   - closure: The closure to invoke when the timer fires.
    func addTimerFromMinutes(_ seconds: Int, _ id: String, closure: @escaping () -> Void) {
        let clampedSeconds = max(1, seconds)
        let interval = TimeInterval(clampedSeconds)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // Ensure callbacks happen on the main thread if UI work is expected
            closure()
        }
        let newTimer = TimerModel(id: id, timer: timer)
        timers.append(newTimer)
    }
    
    func invalidateTimer(_ id: String) {
        let timerElement = timers.first(where: { $0.id == id })
        if timerElement == nil {
            return
        }
        timerElement!.timer.invalidate()
        timers.removeAll(where: {$0.id == id})
    }

    /// Invalidates and clears all timers managed by this service.
    func invalidateAll() {
        for i in timers.indices {
            timers[i].timer.invalidate()
        }

        timers.removeAll()
    }
    
    private func startTimers() throws{
        _ = try routineRepository.list()
    }
    
    private func timerSink() {
        routineRepository.repositoryUpdated.sink{ update in
            let timer = self.timers.first(where: { $0.id == update.id})
            if timer == nil {
                if !update.isEnabled.boolean {
                    return
                }
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
    
    private func startTimer(_ id: String, _ interval: Int){
        self.addTimerFromMinutes(interval, id){
            print("Timer fired \(id)")
        }
    }
}

