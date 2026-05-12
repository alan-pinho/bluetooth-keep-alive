//
//  HomeView.swift
//  BluetoothKeepAlive
//

import SwiftUI

struct HomeView: View {

    @StateObject var homeViewModel = HomeViewModel(
        timerRoutineService: DIService.shared.timerRoutineService,
        stateStore: DIService.shared.routineStateStore
    )

    var body: some View {
        NavigationView {
            List(homeViewModel.devices) { device in
                Button {
                    homeViewModel.selectedDevice = device
                } label: {
                    HStack {
                        Text(device.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        RoutineStatusBadge(state: homeViewModel.routineState(for: device.id))
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            Group {
                if let device = homeViewModel.selectedDevice {
                    DeviceView(device: device)
                } else {
                    Text("Select a device")
                        .foregroundColor(.secondary)
                }
            }
            .frame(alignment: .topLeading)
        }
        .navigationTitle("Devices")
    }
}

#Preview {
    HomeView()
}
