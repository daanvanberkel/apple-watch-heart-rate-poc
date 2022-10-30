//
//  RootViewModel.swift
//  watchHeartRatePoc Watch App
//
//  Created by Daan van Berkel on 30/10/2022.
//

import Foundation
import HealthKit
import WatchConnectivity

class RootViewModel: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, ObservableObject, WCSessionDelegate {
    public static let shared = RootViewModel()
    
    private var healthStore: HKHealthStore? = nil
    private let typesToShare = Set([HKQuantityType.workoutType()])
    private let typesToRead = Set([
        HKQuantityType.quantityType(forIdentifier: .heartRate)!
    ])
    private var session: HKWorkoutSession? = nil
    private var builder: HKLiveWorkoutBuilder? = nil
    private var wcSession: WCSession? = nil
    
    @Published var heartRate: Double? = nil
    @Published var workoutStarted = false
    
    private override init() {
        super.init()
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
        
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession!.delegate = self
            wcSession!.activate()
        }
    }
    
    func startWorkout(_ configuration: HKWorkoutConfiguration) {
        guard let healthStore = healthStore else {
            return
        }
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session!.associatedWorkoutBuilder()
            builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session!.delegate = self
            builder!.delegate = self
            
            session!.startActivity(with: Date())
            builder!.beginCollection(withStart: Date()) { (success, error) in
                guard success else {
                    if let wcSession = self.wcSession {
                        wcSession.transferUserInfo(["error": "Workout started failed", "details": error?.localizedDescription ?? ""])
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.workoutStarted = true
                }
                
                if let wcSession = self.wcSession {
                    wcSession.transferUserInfo(["action": "Workout started"])
                }
            }
        } catch {
            if let wcSession = self.wcSession {
                wcSession.transferUserInfo(["error": "Workout started failed", "details": error.localizedDescription])
            }
        }
    }
    
    func stopWorkout() {
        guard let session = session else {
            return
        }
        
        session.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            guard success else {
                if let wcSession = self.wcSession {
                    wcSession.transferUserInfo(["error": "Workout stopping failed", "details": error?.localizedDescription ?? ""])
                }
                return
            }
            
            // Save workout to healthkit
            self.builder?.finishWorkout { (workout, error) in
                guard workout != nil else {
                    if let wcSession = self.wcSession {
                        wcSession.transferUserInfo(["error": "Workout finishing failed", "details": error?.localizedDescription ?? ""])
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.workoutStarted = false
                }
                
                if let wcSession = self.wcSession {
                    wcSession.transferUserInfo(["action": "Workout stopped"])
                }
            }
            
            self.builder = nil
        }
        
        self.session = nil
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                continue
            }
            
            guard let statistics = workoutBuilder.statistics(for: quantityType) else {
                continue
            }
            
            if statistics.quantityType == HKQuantityType(.heartRate), let heartRate = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                let heartRatePerMinute = (heartRate * 60)
                if let wcSession = self.wcSession {
                    wcSession.transferUserInfo(["heartRate": heartRatePerMinute])
                }
                
                DispatchQueue.main.async {
                    self.heartRate = heartRatePerMinute
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WC Session active")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message: \(message)")
        
        if let action = message["action"] as? String {
            if action == "stopWorkout" {
                self.stopWorkout()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("Received userInfo: \(userInfo)")
        
        if let action = userInfo["action"] as? String {
            if action == "stopWorkout" {
                self.stopWorkout()
            }
        }
    }
}
