//
//  ContentView.swift
//  watchHeartRatePoc Watch App
//
//  Created by Daan van Berkel on 30/10/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: RootViewModel
    
    var body: some View {
        VStack {
            if viewModel.workoutStarted {
                Text("Workout started")
            } else {
                Text("Start workout in the iPhone app")
            }
            
            if let heartRate = viewModel.heartRate {
                Text("Heart rate: \(String(format: "%.1f", heartRate)) bpm")
            }
        }
        .padding()
    }
}
