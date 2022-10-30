//
//  watchHeartRatePocApp.swift
//  watchHeartRatePoc Watch App
//
//  Created by Daan van Berkel on 30/10/2022.
//

import SwiftUI
import WatchKit

@main
struct watchHeartRatePoc_Watch_AppApp: App {
    let rootViewModel = RootViewModel.shared
    
    @WKApplicationDelegateAdaptor(WkDelegate.self) var applicationDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: rootViewModel)
        }
    }
}
