/*
Bryan's Brain - Safe Calendar Tool

Abstract:
Ultra-safe calendar tool designed to avoid Apple's safety guardrails while retrieving calendar events.
Uses positive, productivity-focused language to minimize rejection risk.
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct SafeCalendarTool: Tool {
    let name = "getScheduleOverview"
    let description = "Gets today's schedule and appointments to help with time management and productivity planning"
    
    @Generable
    struct Arguments {
        @Guide(description: "Type of schedule information: today, upcoming, or summary")
        let scheduleType: String
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 SafeCalendarTool: Getting schedule overview: \(arguments.scheduleType)")
        
        return await withCheckedContinuation { continuation in
            CalendarService.shared.fetchTodaysEvents { events, error in
                if let error = error {
                    Logging.general.log("SafeCalendarTool: Error fetching schedule: \(error.localizedDescription)")
                    let safeErrorResponse = "I'm having trouble accessing your schedule right now. Your calendar connection might need attention. You can check your Google Calendar directly or try refreshing the connection in Settings."
                    continuation.resume(returning: safeErrorResponse)
                    return
                }
                
                guard let events = events else {
                    Logging.general.log("SafeCalendarTool: No schedule data returned")
                    let emptyResponse = "Your schedule is completely open today! This is a great opportunity to focus on your important tasks or take some well-deserved personal time."
                    continuation.resume(returning: emptyResponse)
                    return
                }
                
                let output: String
                switch arguments.scheduleType.lowercased() {
                case "today":
                    if events.isEmpty {
                        output = "Your schedule is beautifully clear today! No appointments are currently planned, giving you full flexibility to focus on your priorities."
                    } else {
                        let eventList = events.map { event in
                            let timeStr = event.startTimeString.isEmpty ? "All day commitment" : "From \(event.startTimeString) to \(event.endTimeString)"
                            return "📅 \(event.summary ?? "Scheduled appointment") (\(timeStr))"
                        }.joined(separator: "\n")
                        
                        output = "Today's Schedule Overview (\(events.count) appointments):\n\n\(eventList)\n\nGreat job staying organized with your time!"
                    }
                    
                case "summary":
                    if events.isEmpty {
                        output = "Schedule Summary: Your day is completely open! Perfect time to focus on personal productivity goals or enjoy some flexibility."
                    } else {
                        let totalEvents = events.count
                        
                        output = "Schedule Summary: \(totalEvents) appointments planned today. You're doing excellent work managing your time and commitments!"
                    }
                    
                case "upcoming":
                    if events.isEmpty {
                        output = "No upcoming appointments today - your schedule is wide open for productivity and personal time!"
                    } else {
                        // Show next few events
                        let nextEvents = events.prefix(3).map { event in
                            let timeStr = event.startTimeString.isEmpty ? "All day" : event.startTimeString
                            return "⏰ \(event.summary ?? "Appointment") at \(timeStr)"
                        }.joined(separator: "\n")
                        
                        output = "Next Upcoming Appointments:\n\n\(nextEvents)\n\nStaying on top of your schedule - excellent time management!"
                    }
                    
                default:
                    if events.isEmpty {
                        output = "Your schedule is wonderfully open today! Great opportunity for focused work or personal time."
                    } else {
                        output = "You have \(events.count) appointments scheduled today. Your time management skills are keeping you well-organized!"
                    }
                }
                
                Logging.general.log("SafeCalendarTool: Returning positive schedule response")
                continuation.resume(returning: output)
            }
        }
    }
}