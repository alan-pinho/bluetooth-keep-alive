//
//  DeviceView.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 20/01/26.
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
            Stepper(
                "Time Interval (s):",
                value: $deviceViewModel.timeInterval,
                in: 0...3600,
                format: .number,
            )
            Button("Save"){
                Task{
                    do{
                        try await deviceViewModel.saveRoutine()
                    } catch {
                        showError(error as! ErrorHelpers)
                    }
                }
            }
        }
        .padding()
        .task(id: device) {
            deviceViewModel.load()
        }
    }
}

#Preview {
    HomeView()
}
