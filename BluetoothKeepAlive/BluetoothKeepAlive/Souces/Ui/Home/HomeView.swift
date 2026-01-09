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
                HStack{
                    Text(device.name)
                }
            }
        } .navigationTitle("Despositivos")
    }
}

#Preview {
    HomeView()
}
