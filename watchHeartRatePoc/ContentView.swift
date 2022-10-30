//
//  ContentView.swift
//  watchHeartRatePoc
//
//  Created by Daan van Berkel on 30/10/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = RootViewModel()
    
    var body: some View {
        if let error = viewModel.error {
            Text("Error: \(error)")
        }
        
        if !viewModel.counterpartAppInstalled {
            Text("Install watch app first")
        } else {
            if !viewModel.permissionsGranted {
                Button("Request permission") {
                    viewModel.requestPermission()
                }
                .padding(.bottom, 20)
            }
            
            if viewModel.workoutStarted {
                Button("Stop workout") {
                    viewModel.stopWatchingHeartRate()
                }
                .padding(.bottom, 20)
            } else {
                Button("Start workout") {
                    viewModel.watchHeartRate()
                }
                .padding(.bottom, 20)
            }
            
            if let heartRate = viewModel.heartRate {
                Text("Heart rate: \(String(format: "%.1f", heartRate)) bpm")
            }
        }
        
        Spacer()
    }
}
