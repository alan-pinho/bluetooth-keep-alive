// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  Main.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 31/12/25.
//

import SwiftUI
import AppKit
import ServiceManagement

@main
struct BluetoothKeepAliveApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // SwiftUI.Settings (not WindowGroup) so SwiftUI does not auto-open a window at launch.
    // The menu-bar app drives its own NSWindows via AppDelegate. Qualified to disambiguate
    // from the local `Settings` GRDB record.
    var body: some Scene {
        SwiftUI.Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var homeWindow: NSWindow?
    var settingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {

        NSApp.setActivationPolicy(.accessory)

        createStatusItem()
        applyStartupSetting()
        bootRoutineEngine()
    }

    /// Ensure the timer + connection observers come up at launch, even when no window is opened
    /// (e.g. when launched headless by SMAppService at login).
    private func bootRoutineEngine() {
        _ = DIService.shared.timerRoutineService
        DispatchQueue.global(qos: .utility).async {
            DIService.shared.routineEventRepository.prune()
        }
    }

    func createStatusItem() {

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {

            let image = NSImage(named: "bluetooth.icon")
            image?.isTemplate = true

            button.image = image
            button.action = #selector(toggleMenu)
            button.target = self
        }

        let menu = createMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func createMenu() -> NSMenu {

        let menu = NSMenu()

        let configureItem = NSMenuItem(
            title: "Configure paired devices",
            action: #selector(openWindow),
            keyEquivalent: ""
        )
        configureItem.image = NSImage(systemSymbolName: "square.and.pencil", accessibilityDescription: nil)

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)

        let pauseItem = NSMenuItem(
            title: "Pause routines",
            action: nil,
            keyEquivalent: ""
        )
        pauseItem.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: nil)
        pauseItem.submenu = createPauseSubmenu()

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )

        menu.addItem(configureItem)
        menu.addItem(settingsItem)
        menu.addItem(pauseItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        return menu
    }

    private func createPauseSubmenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        let options: [(String, Int)] = [
            ("15 minutes", 15),
            ("30 minutes", 30),
            ("1 hour", 60),
        ]
        for (label, minutes) in options {
            let item = NSMenuItem(
                title: label,
                action: #selector(snoozeAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = minutes
            submenu.addItem(item)
        }

        submenu.addItem(NSMenuItem.separator())

        let resumeItem = NSMenuItem(
            title: "Resume",
            action: #selector(resumeAction),
            keyEquivalent: ""
        )
        resumeItem.target = self
        resumeItem.identifier = NSUserInterfaceItemIdentifier("resume")
        submenu.addItem(resumeItem)

        return submenu
    }

    @objc private func snoozeAction(_ sender: NSMenuItem) {
        DIService.shared.snoozeService.snooze(minutes: sender.tag)
    }

    @objc private func resumeAction() {
        DIService.shared.snoozeService.resume()
    }

    private func updatePauseSubmenu(_ submenu: NSMenu) {
        let isPaused = DIService.shared.snoozeService.isPaused()
        for item in submenu.items {
            if item.identifier?.rawValue == "resume" {
                if let until = DIService.shared.snoozeService.snoozedUntil {
                    item.title = "Resume (paused until \(Self.timeFormatter.string(from: until)))"
                    item.isEnabled = true
                } else {
                    item.title = "Resume"
                    item.isEnabled = false
                }
            } else if item.tag > 0 {
                item.state = isPaused ? .off : .off
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    @objc func toggleMenu() {
        statusItem.button?.performClick(nil)
    }

    @objc func openWindow() {

        if homeWindow == nil {

            let view = HomeView()
            let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)

            homeWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: screenSize.width/2, height: screenSize.height/2),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            homeWindow?.center()
            homeWindow?.title = "Bluetooth Keep Alive"
            homeWindow?.contentView = NSHostingView(rootView: view)
            homeWindow?.delegate = self
        }
        
        homeWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openSettings() {
        if settingWindow == nil {

            let view = SettingsView()
            let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)

            settingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: screenSize.width/2, height: screenSize.height/2),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            settingWindow?.center()
            settingWindow?.title = "Settings"
            settingWindow?.contentView = NSHostingView(rootView: view)
            settingWindow?.delegate = self
        }
        
        settingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    private func applyStartupSetting() {
        do {
            let setting = try DIService.shared.settingRepository.get(id: "start-with-system")
            let shouldStartWithSystem = setting?.isEnabled.boolean ?? false
            let startupService = SMAppService.mainApp

            if shouldStartWithSystem {
                if startupService.status != .enabled && startupService.status != .requiresApproval {
                    try startupService.register()
                }
                return
            }

            if startupService.status == .enabled || startupService.status == .requiresApproval {
                try startupService.unregister()
            }
        } catch {
            print("Failed to apply startup setting: \(error.localizedDescription)")
        }
    }
}

extension AppDelegate: NSWindowDelegate {

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

}

extension AppDelegate: NSMenuDelegate {

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let pauseItem = menu.items.first(where: { $0.title == "Pause routines" || $0.title.hasPrefix("Pause routines") }),
              let submenu = pauseItem.submenu else { return }

        if DIService.shared.snoozeService.isPaused(),
           let until = DIService.shared.snoozeService.snoozedUntil {
            pauseItem.title = "Pause routines (until \(Self.timeFormatter.string(from: until)))"
        } else {
            pauseItem.title = "Pause routines"
        }
        updatePauseSubmenu(submenu)
    }
}
