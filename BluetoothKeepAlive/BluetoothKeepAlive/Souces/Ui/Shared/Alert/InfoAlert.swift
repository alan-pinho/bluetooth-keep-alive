//
//  InfoAlert.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/02/26.
//

import AppKit

func showError (_ error: ErrorHelpers){
    let alert = NSAlert()
    alert.messageText = NSTextField(labelWithString: "Atenção").stringValue
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
