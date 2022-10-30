//
//  RootViewModel.swift
//  watchHeartRatePoc
//
//  Created by Daan van Berkel on 30/10/2022.
//

import Foundation
import HealthKit
import WatchConnectivity

class RootViewModel: NSObject, ObservableObject, WCSessionDelegate {
    private var healthStore: HKHealthStore? = nil
    private let typesToShare = Set([
        HKQuantityType.workoutType()
    ])
    private let typesToRead = Set([
        HKQuantityType.quantityType(forIdentifier: .heartRate)!
    ])
    private var wcSession: WCSession? = nil
    
    @Published var heartRate: Double? = nil
    @Published var workoutStarted = false
    @Published var permissionsGranted = false
    @Published var counterpartAppInstalled = false
    @Published var error: String? = nil
    
    override init() {
        super.init()
        
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            checkPermissionStatus()
        }
        
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession!.delegate = self
            wcSession!.activate()
        }
    }
    
    func requestPermission() {
        guard let healthStore = healthStore else {
            return
        }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                print("No permissions: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self.permissionsGranted = true
            }
        }
    }
    
    private func checkPermissionStatus() {
        guard let healthStore = healthStore else {
            return
        }
        
        healthStore.getRequestStatusForAuthorization(toShare: typesToShare, read: typesToRead) { (status, error) in
            if status == .unnecessary {
                DispatchQueue.main.async {
                    self.permissionsGranted = true
                }
            }
        }
    }
    
    func watchHeartRate() {
        guard let healthStore = healthStore else {
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .indoor
        
        healthStore.startWatchApp(with: configuration) { (success, error) in
            guard success else {
                print("Error starting watch app: \(error)")
                return
            }
            
            print("Start workout on watch")
        }
    }
    
    func stopWatchingHeartRate() {
        guard let session = wcSession else {
            return
        }
        
        session.transferUserInfo(["action": "stopWorkout"])
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activated")
        
        DispatchQueue.main.async {
            self.counterpartAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("Did receive user info: \(userInfo)")
        
        if let heartRate = userInfo["heartRate"] as? Double {
            DispatchQueue.main.async {
                self.heartRate = heartRate
            }
        }
        
        if let action = userInfo["action"] as? String {
            if action == "Workout started" {
                DispatchQueue.main.async {
                    self.workoutStarted = true
                }
            }
            
            if action == "Workout stopped" {
                DispatchQueue.main.async {
                    self.workoutStarted = false
                }
            }
        }
        
        if let error = userInfo["error"] as? String {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
}
