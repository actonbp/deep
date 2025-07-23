/*
Bryan's Brain - Calendar Event Deletion Tool

Abstract:
Tool for deleting calendar events using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct DeleteCalendarEventTool: Tool {
    let name = "deleteCalendarEvent"
    let description = "Deletes a specific event from the user's primary Google Calendar for today, identified by its summary and start time"
    
    @Generable
    struct Arguments {
        @Guide(description: "The title or summary of the event to delete")
        let summary: String
        
        @Guide(description: "The original start time of the event to delete (e.g., '9:00 AM', '14:30')")
        let startTimeToday: String
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 DeleteCalendarEventTool: Deleting event: \(arguments.summary)")
        
        return await withCheckedContinuation { continuation in
            // Convert time string to Date - simplified for now
            let today = Date()
            
            CalendarService.shared.deleteCalendarEvent(
                summary: arguments.summary,
                startTime: today
            ) { success, error in
                if success {
                    Logging.general.log("DeleteCalendarEventTool: Event deleted successfully")
                    continuation.resume(returning: "Deleted calendar event: '\(arguments.summary)' at \(arguments.startTimeToday)")
                } else {
                    Logging.general.log("DeleteCalendarEventTool: Error deleting event: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: "Sorry, I couldn't delete the calendar event. It may not exist or there was a connection issue.")
                }
            }
        }
    }
}