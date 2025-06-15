/*
Bryan's Brain - Current Date/Time Tool

Abstract:
Tool for getting current date and time using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct GetCurrentDateTimeTool: Tool {
    let name = "getCurrentDateTime"
    let description = "Gets the current date and time"
    
    @Generable
    struct Arguments {
        let getCurrentTime: Bool
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 GetCurrentDateTimeTool: Getting current date and time")
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        let dateTimeString = formatter.string(from: now)
        
        Logging.general.log("GetCurrentDateTimeTool: Current time retrieved successfully")
        return ToolOutput("Current date and time: \(dateTimeString)")
    }
}