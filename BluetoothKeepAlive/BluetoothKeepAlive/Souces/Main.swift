//
//  Main.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 31/12/25.
//

import SwiftUI
import AppKit

@main
struct BluetoothKeepAliveApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {

        NSApp.setActivationPolicy(.accessory)

        createStatusItem()
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

        statusItem.menu = createMenu()
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

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )

        menu.addItem(configureItem)
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        return menu
    }

    @objc func toggleMenu() {
        statusItem.button?.performClick(nil)
    }

    @objc func openWindow() {

        if window == nil {

            let view = HomeView()
            let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)

            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: screenSize.width/2, height: screenSize.height/2),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            window?.center()
            window?.title = "Bluetooth Keep Alive"
            window?.contentView = NSHostingView(rootView: view)
            window?.delegate = self
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openSettings() {
        print("settings")
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

}
