//
//  RoutineStatusBadge.swift
//  BluetoothKeepAlive
//

import SwiftUI

struct RoutineStatusBadge: View {

    /// `nil` means the device has no routine configured.
    let state: RoutineRuntimeState?
    var showLabel: Bool = false

    private var color: Color {
        switch state {
        case .active: return .green
        case .dormant: return .gray
        case .disabled: return .secondary.opacity(0.4)
        case .none: return .clear
        }
    }

    private var label: String {
        switch state {
        case .active: return "Active"
        case .dormant: return "Dormant"
        case .disabled: return "Disabled"
        case .none: return ""
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(state == nil ? 0 : 0.2), lineWidth: 0.5)
                )
            if showLabel, state != nil {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityLabel(state == nil ? "No routine" : label)
    }
}
