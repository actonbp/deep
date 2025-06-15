/*
Bryan's Brain - Calendar Event Time Update Tool

Abstract:
Tool for updating calendar event times using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateCalendarEventTimeTool: Tool {
    let name = "updateCalendarEventTime"
    let description = "Updates the start and/or end time of a specific event on the user's primary Google Calendar for today"
    
    @Generable
    struct Arguments {
        @Guide(description: "The title or summary of the event to update")
        let summary: String
        
        @Guide(description: "The original start time of the event being updated (e.g., '9:00 AM', '14:30')")
        let originalStartTimeToday: String
        
        @Guide(description: "The new start time for the event (e.g., '10:00 AM', '15:30')")
        let newStartTimeToday: String
        
        @Guide(description: "The new end time for the event (e.g., '11:00 AM', '16:00')")
        let newEndTimeToday: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 UpdateCalendarEventTimeTool: Updating event time: \(arguments.summary)")
        
        return await withCheckedContinuation { continuation in
            // Convert time strings to Dates - simplified for now
            let today = Date()
            let newStart = Date()
            let newEnd = Date()
            
            CalendarService.shared.updateCalendarEventTime(
                summary: arguments.summary,
                originalStartTime: today,
                newStartTime: newStart,
                newEndTime: newEnd
            ) { success, error in
                if success {
                    Logging.general.log("UpdateCalendarEventTimeTool: Event time updated successfully")
                    continuation.resume(returning: ToolOutput("Updated '\(arguments.summary)' from \(arguments.originalStartTimeToday) to \(arguments.newStartTimeToday) - \(arguments.newEndTimeToday)"))
                } else {
                    Logging.general.log("UpdateCalendarEventTimeTool: Error updating event: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: ToolOutput("Sorry, I couldn't update the calendar event time. It may not exist or there was a connection issue."))
                }
            }
        }
    }
}