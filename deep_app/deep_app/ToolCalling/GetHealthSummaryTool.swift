/*
Bryan's Brain - Health Summary Tool

Abstract:
Simple tool for retrieving basic health data to provide ADHD-specific context to the AI assistant
*/

import Foundation
import HealthKit

// OpenAI tool for getting health summary
struct GetHealthSummaryTool {
    let name = "getHealthSummary"
    let description = "Gets a basic health summary including sleep and activity data to provide ADHD-specific task recommendations"
    
    struct Arguments: Codable {
        // No arguments needed - always returns current health summary
    }
    
    func call() async -> String {
        // Check if HealthKit is enabled in settings
        let healthKitEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
        
        guard healthKitEnabled else {
            return "Health integration is disabled. Enable 'HealthKit' in Settings to get ADHD-specific insights based on your sleep and activity patterns."
        }
        
        // Check if HealthKit is available
        if #available(iOS 13.0, *) {
            let healthService = HealthKitService.shared
            guard healthService.isHealthDataAvailable else {
                return "HealthKit is not available on this device."
            }
            
            // Get health summary
            let summary = await healthService.getHealthSummary()
            return summary
        } else {
            return "HealthKit requires iOS 13 or later."
        }
    }
}

// Foundation Models tool for getting health summary
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
struct GetHealthSummaryFoundationTool: Tool {
    let name = "getHealthSummary"
    let description = "Gets basic health data (sleep, activity) to provide ADHD-specific recommendations"
    
    @Generable
    struct Arguments {
        // No arguments needed
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Check if HealthKit is enabled in settings
        let healthKitEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
        
        guard healthKitEnabled else {
            let message = "Health insights are disabled. Enable 'HealthKit' in Settings to get personalized ADHD recommendations based on your sleep and activity."
            return ToolOutput(message)
        }
        
        // Check if HealthKit is available
        let healthService = HealthKitService.shared
        guard healthService.isHealthDataAvailable else {
            return ToolOutput("HealthKit is not available on this device.")
        }
        
        // Get health summary
        let summary = await healthService.getHealthSummary()
        return ToolOutput(summary)
    }
}
#endif