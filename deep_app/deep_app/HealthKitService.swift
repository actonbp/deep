//
//  HealthKitService.swift
//  deep_app
//
//  Basic HealthKit integration for ADHD-focused health insights
//

import Foundation
import HealthKit

@available(iOS 13.0, *)
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    // Health data types we want to read
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
    ]
    
    private init() {}
    
    // Check if HealthKit is available on this device
    var isHealthDataAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Request authorization to read health data
    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else {
            print("HealthKit not available on this device")
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            print("HealthKit authorization completed")
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }
    
    // Get a basic health summary for AI context
    func getHealthSummary() async -> String {
        guard isHealthDataAvailable else {
            return "Health data not available on this device."
        }
        
        // Check authorization status
        let sleepStatus = healthStore.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        guard sleepStatus == .sharingAuthorized else {
            return "Health data access not authorized. Enable in Settings to get ADHD-specific insights."
        }
        
        do {
            let sleepSummary = await getSleepSummary()
            let activitySummary = await getActivitySummary()
            
            return """
            📊 Health Summary (Last 24 Hours):
            
            💤 Sleep: \(sleepSummary)
            🚶‍♂️ Activity: \(activitySummary)
            
            💡 This data can help tailor ADHD task recommendations based on your current physical state.
            """
        } catch {
            return "Unable to retrieve health data: \(error.localizedDescription)"
        }
    }
    
    // Get sleep summary for the last night
    private func getSleepSummary() async -> String {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Query for sleep data from yesterday
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(returning: "Error reading sleep data")
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: "No sleep data available")
                    return
                }
                
                let totalSleepTime = sleepSamples.reduce(0) { total, sample in
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        return total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    return total
                }
                
                let hours = Int(totalSleepTime / 3600)
                let minutes = Int((totalSleepTime.truncatingRemainder(dividingBy: 3600)) / 60)
                
                if hours > 0 || minutes > 0 {
                    continuation.resume(returning: "\(hours)h \(minutes)m")
                } else {
                    continuation.resume(returning: "No sleep data for last 24h")
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // Get activity summary for today
    private func getActivitySummary() async -> String {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        // Query for today's steps
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(returning: "Error reading activity data")
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: "No activity data available")
                    return
                }
                
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: "\(steps) steps today")
            }
            
            self.healthStore.execute(query)
        }
    }
}