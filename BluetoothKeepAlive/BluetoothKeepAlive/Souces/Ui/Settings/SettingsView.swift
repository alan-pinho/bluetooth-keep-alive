//
//  SettingsView.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/03/26.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject var viewModel = SettingsViewModel(settingsRepository: DIService.shared.settingRepository)
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section("General") {
                Toggle(
                    "Start with system",
                    isOn: Binding(
                        get: { viewModel.startWithSystemEnabled },
                        set: { isEnabled in
                            do {
                                try viewModel.updateStartWithSystem(isEnabled)
                            } catch {
                                showError(error as? ErrorHelpers ?? .updateFailed(reason: "Failed to update startup setting"))
                            }
                        }
                    )
                )
            }
            
            Section("Routines") {
                Button("Delete all routines", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
            
            Section {
                Button("Quit app", role: .destructive) {
                    viewModel.quitApp()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .confirmationDialog(
            "Do you want to delete all routines?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete all", role: .destructive) {
                do {
                    try viewModel.deleteAllRoutines()
                } catch {
                    showError(error as? ErrorHelpers ?? .deletionFailed(reason: "Failed to delete all routines"))
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
}
