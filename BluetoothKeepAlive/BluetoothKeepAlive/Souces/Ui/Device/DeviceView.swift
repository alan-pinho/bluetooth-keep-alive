// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  DeviceView.swift
//  BluetoothKeepAlive
//

import Foundation
import SwiftUI

struct DeviceView: View {
    let device: BluetoothModel
    @StateObject private var deviceViewModel: DeviceViewModel

    init(device: BluetoothModel) {
        self.device = device
        _deviceViewModel = StateObject(wrappedValue: DeviceViewModel(bluetoothModel: device))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(device.name)
                .font(.title2)

            Text("ID: \(device.id)")
                .foregroundColor(.secondary)

            statusSection

            Stepper(
                "Time Interval (s):",
                value: $deviceViewModel.timeInterval,
                in: 0...3600,
                format: .number,
            )
            Toggle("Enabled", isOn: $deviceViewModel.isEnabled)
            strategyPicker
            Button("Save") {
                Task {
                    do {
                        try await deviceViewModel.saveRoutine()
                    } catch {
                        showError(error)
                    }
                }
            }
        }
        .padding()
        .task {
            deviceViewModel.updateDevice(device)
        }
        .onChange(of: device.id) { _, _ in
            deviceViewModel.updateDevice(device)
        }
    }

    @ViewBuilder
    private var strategyPicker: some View {
        Picker("Keep-alive method", selection: $deviceViewModel.strategyOverride) {
            Text("Auto\(deviceViewModel.detectedMethod.map { " (detected: \($0))" } ?? "")")
                .tag(KeepAliveStrategyKind?.none)
            ForEach(KeepAliveStrategyKind.allCases, id: \.self) { kind in
                Text(kind.label).tag(KeepAliveStrategyKind?.some(kind))
            }
        }
        .pickerStyle(.radioGroup)
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                RoutineStatusBadge(state: deviceViewModel.runtimeState, showLabel: true)
            }
            if let method = deviceViewModel.keepAliveMethod {
                Text("Keep-alive method: \(method)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if method == "Audio blip" {
                    Text("Tip: make sure this device is the active audio output.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            if let lastPing = deviceViewModel.lastPingAt {
                Text("Last successful ping: \(lastPing, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if deviceViewModel.sessionDisconnects > 0 {
                Text("Disconnects this session: \(deviceViewModel.sessionDisconnects)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}
