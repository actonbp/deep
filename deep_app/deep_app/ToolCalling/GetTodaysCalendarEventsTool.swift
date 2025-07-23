/*
Bryan's Brain - Today's Calendar Events Tool

Abstract:
Tool for retrieving today's calendar events using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct GetTodaysCalendarEventsTool: Tool {
    let name = "getTodaysCalendarEvents"
    let description = "Gets the list of events scheduled on the user's primary Google Calendar for today"
    
    @Generable
    struct Arguments {
        let retrieve: Bool
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 GetTodaysCalendarEventsTool: Getting today's calendar events")
        
        return await withCheckedContinuation { continuation in
            CalendarService.shared.fetchTodaysEvents { events, error in
                if let error = error {
                    Logging.general.log("GetTodaysCalendarEventsTool: Error fetching events: \(error.localizedDescription)")
                    continuation.resume(returning: "Sorry, I couldn't fetch your calendar events. Please check your Google Calendar connection.")
                    return
                }
                
                guard let events = events else {
                    Logging.general.log("GetTodaysCalendarEventsTool: No events returned")
                    continuation.resume(returning: "You have no calendar events scheduled for today.")
                    return
                }
                
                if events.isEmpty {
                    Logging.general.log("GetTodaysCalendarEventsTool: No events found for today")
                    continuation.resume(returning: "You have no calendar events scheduled for today.")
                } else {
                    let eventList = events.map { event in
                        let timeStr = event.startTimeString.isEmpty ? "All day" : "\(event.startTimeString) - \(event.endTimeString)"
                        return "• \(event.summary ?? "Untitled") (\(timeStr))"
                    }.joined(separator: "\n")
                    
                    Logging.general.log("GetTodaysCalendarEventsTool: Found \(events.count) events")
                    continuation.resume(returning: "Today's calendar events (\(events.count) total):\n\(eventList)")
                }
            }
        }
    }
}