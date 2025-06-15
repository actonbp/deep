/*
Bryan's Brain - Calendar Event Creation Tool

Abstract:
Tool for creating calendar events using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct CreateCalendarEventTool: Tool {
    let name = "createCalendarEvent"
    let description = "Creates a new event on the user's primary Google Calendar for today"
    
    @Generable
    struct Arguments {
        @Guide(description: "The title or summary of the event")
        let summary: String
        
        @Guide(description: "An optional longer description for the event")
        let description: String?
        
        @Guide(description: "The start time for today's event (e.g., '9:00 AM', '14:30')")
        let startTimeToday: String
        
        @Guide(description: "The end time for today's event (e.g., '10:30 AM', '15:00')")
        let endTimeToday: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 CreateCalendarEventTool: Creating event: \(arguments.summary)")
        
        return await withCheckedContinuation { continuation in
            // For now, use a placeholder implementation since calendar integration needs proper time parsing
            Logging.general.log("CreateCalendarEventTool: Calendar creation not fully implemented - returning success message")
            continuation.resume(returning: ToolOutput("Calendar event creation is not yet fully implemented with the local model. Event: '\(arguments.summary)' from \(arguments.startTimeToday) to \(arguments.endTimeToday)"))
        }
    }
}