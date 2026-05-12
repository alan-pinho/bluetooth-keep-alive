// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  SnoozeService.swift
//  BluetoothKeepAlive
//

import Foundation
import Combine

final class SnoozeService: ObservableObject {

    static let settingId = "snooze-until"
    static let settingName = "Snooze until"

    @Published private(set) var snoozedUntil: Date?

    private let settingRepository: SettingRepository
    private var expiryTimer: DispatchSourceTimer?

    init(settingRepository: SettingRepository) {
        self.settingRepository = settingRepository
        hydrate()
    }

    func isPaused(now: Date = Date()) -> Bool {
        guard let until = snoozedUntil else { return false }
        return until > now
    }

    func snooze(minutes: Int) {
        let until = Date().addingTimeInterval(TimeInterval(minutes * 60))
        persist(until: until)
        snoozedUntil = until
        scheduleExpiry(at: until)
    }

    func resume() {
        persist(until: nil)
        snoozedUntil = nil
        expiryTimer?.cancel()
        expiryTimer = nil
    }

    // MARK: - Persistence

    private func hydrate() {
        guard let setting = (try? settingRepository.get(id: Self.settingId)) ?? nil,
              setting.isEnabled.boolean else { return }

        if let date = ISO8601DateFormatter.parse(setting.name), date > Date() {
            snoozedUntil = date
            scheduleExpiry(at: date)
        } else if ISO8601DateFormatter.parse(setting.name) != nil {
            persist(until: nil)
        }
    }

    private func persist(until: Date?) {
        do {
            let existing = try settingRepository.get(id: Self.settingId)
            if let until = until {
                let setting = Settings(
                    id: Self.settingId,
                    name: until.isoFormatter,
                    isEnabled: 1
                )
                if existing == nil {
                    try settingRepository.insert(element: setting)
                } else {
                    try settingRepository.update(element: setting)
                }
                return
            }

            if existing != nil {
                let cleared = Settings(
                    id: Self.settingId,
                    name: "",
                    isEnabled: 0
                )
                try settingRepository.update(element: cleared)
            }
        } catch {
            print("SnoozeService persistence failed: \(error.localizedDescription)")
        }
    }

    private func scheduleExpiry(at date: Date) {
        expiryTimer?.cancel()
        let interval = max(0, date.timeIntervalSinceNow)
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + interval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.snoozedUntil = nil
            self.persist(until: nil)
            self.expiryTimer = nil
        }
        timer.resume()
        expiryTimer = timer
    }
}

private extension ISO8601DateFormatter {
    static func parse(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: string)
    }
}
