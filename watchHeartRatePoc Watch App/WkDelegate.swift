//
//  WkDelegate.swift
//  watchHeartRatePoc Watch App
//
//  Created by Daan van Berkel on 30/10/2022.
//

import Foundation
import WatchKit
import HealthKit

class WkDelegate: NSObject, WKApplicationDelegate {    
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        RootViewModel.shared.startWorkout(workoutConfiguration)
    }
}
