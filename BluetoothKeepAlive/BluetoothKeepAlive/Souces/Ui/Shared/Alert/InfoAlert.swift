// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  InfoAlert.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/02/26.
//

import AppKit

func showError(_ error: ErrorHelpers) {
    let alert = NSAlert()
    alert.messageText = "Warning"
    alert.informativeText = error.reason()
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Ok")
    alert.icon = NSImage(
        systemSymbolName: "exclamationmark.circle",
        accessibilityDescription: nil
    )
    if let window = NSApp.keyWindow {
        alert.beginSheetModal(for: window)
    } else {
        alert.runModal()
    }
}

/// Catch-all overload for `catch { showError(error) }`. Unwraps ErrorHelpers
/// when possible; otherwise surfaces `localizedDescription` under a generic
/// updateFailed category so the user still gets the reason string.
func showError(_ error: Error) {
    if let helper = error as? ErrorHelpers {
        showError(helper)
        return
    }
    showError(.updateFailed(reason: error.localizedDescription))
}
