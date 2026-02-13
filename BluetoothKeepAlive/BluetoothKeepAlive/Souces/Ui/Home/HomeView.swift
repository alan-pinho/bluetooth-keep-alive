//
//  HomeView.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 31/12/25.
//

import SwiftUI



struct HomeView: View {
    
    @StateObject var homeViewModel = HomeViewModel()
    
    var body: some View {
        NavigationView{
            List(homeViewModel.devices) { device in
                Button {
                    homeViewModel.selectedDevice = device
                } label: {
                    HStack {
                        Text(device.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)

            Group{
                if let device = homeViewModel.selectedDevice {
                    DeviceView(device: device)
                } else {
                    Text("Selecione um dispositivo")
                        .foregroundColor(.secondary)
                }
            }
            .frame(alignment: .topLeading)
        }
        .navigationTitle("Despositivos")
    }
}

#Preview {
    HomeView()
}
