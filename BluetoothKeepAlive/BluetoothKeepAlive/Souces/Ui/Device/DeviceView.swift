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
        _deviceViewModel = StateObject(wrappedValue: DeviceViewModel(deviceId: device.id))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(device.name)
                .font(.title2)

            Text("ID: \(device.id)")
                .foregroundColor(.secondary)
            Stepper(
                "Intervalo de tempo (minutos)",
                value: $deviceViewModel.timeInterval,
                in: 0...3600,
                format: .number,
            )
            Button("Salvar"){
                Task{
                    do{
                       try await deviceViewModel.salvar()
                    } catch {
                        showError(error as! ErrorHelpers)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
