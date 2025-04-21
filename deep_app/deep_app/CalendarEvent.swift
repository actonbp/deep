import Foundation

// Represents a single event fetched from Google Calendar
struct CalendarEvent: Identifiable, Decodable, Hashable {
    let id: String
    let summary: String? // Event title
    let description: String? // Event description
    let start: EventDateTime?
    let end: EventDateTime?
    let htmlLink: String? // Link to the event in Google Calendar web UI

    // Computed property to get a displayable start time string
    var startTimeString: String {
        formatDate(from: start)
    }
    
    // Computed property to get a displayable end time string
    var endTimeString: String {
        formatDate(from: end)
    }
    
    // Helper function to format date/time
    private func formatDate(from eventDateTime: EventDateTime?) -> String {
        guard let eventDateTime = eventDateTime else { return "N/A" }
        
        // Prefer dateTime (specific time) over date (all-day)
        if let dateTimeString = eventDateTime.dateTime {
            // Use ISO8601DateFormatter which understands RFC3339 with timezone
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Handle optional fractional seconds
            
            // Try parsing with and without fractional seconds
            if let date = isoFormatter.date(from: dateTimeString) ?? ISO8601DateFormatter().date(from: dateTimeString) {
                let displayFormatter = DateFormatter()
                displayFormatter.timeStyle = .short
                // Optional: Set timezone if needed, otherwise uses device default
                // displayFormatter.timeZone = TimeZone(identifier: eventDateTime.timeZone ?? TimeZone.current.identifier)
                return displayFormatter.string(from: date)
            } else {
                // Fallback if parsing fails
                return "Invalid Time" 
            }
        } else if let dateString = eventDateTime.date {
             // Handle all-day event - parse YYYY-MM-DD
             let dateFormatter = DateFormatter()
             dateFormatter.dateFormat = "yyyy-MM-dd"
             if let date = dateFormatter.date(from: dateString) {
                 // Optionally format the date differently, e.g., DateFormatter.localizedString
                 // For simplicity, confirm it's all-day
                  return "All-day" // Simplified output
             } else {
                  return "Invalid Date" // Date string format mismatch
             }
        }
        
        return "Invalid Date/Time" // Neither dateTime nor date available
    }

    // Make Hashable for potential use in ForEach without explicit ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// Represents the start/end time structure from Google Calendar API
struct EventDateTime: Decodable, Hashable {
    let dateTime: String? // Full RFC3339 timestamp (e.g., "2025-04-20T10:00:00-07:00")
    let date: String?     // Just the date (e.g., "2025-04-20") for all-day events
    let timeZone: String? // Optional: Timezone (e.g., "America/Los_Angeles")
}
 