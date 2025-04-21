import Foundation

// Represents a single event fetched from Google Calendar
struct CalendarEvent: Identifiable, Decodable, Hashable {
    let id: String
    let summary: String? // Event title
    let description: String? // Event description
    let start: EventDateTime? // Keep original string data if needed
    let end: EventDateTime?   // Keep original string data if needed
    let htmlLink: String? // Link to the event in Google Calendar web UI

    // --- ADDED: Parsed Date properties ---
    let startDate: Date?
    let endDate: Date?
    // ------------------------------------

    // Computed property to get a displayable start time string
    var startTimeString: String {
        // Use the stored Date if available, otherwise return N/A
        guard let date = startDate else { return "N/A" }
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    // Computed property to get a displayable end time string
    var endTimeString: String {
        // Use the stored Date if available, otherwise return N/A
        guard let date = endDate else { return "N/A" }
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    // Helper to parse date string into Date object
    private static func parseDateTimeString(_ dateTimeString: String?) -> Date? {
        guard let dateTimeString = dateTimeString else { return nil }
        
        // --- Added Logging ---
        let loggerEnabled = UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey)
        if loggerEnabled { print("DEBUG [DateParse]: Attempting to parse: '\(dateTimeString)'") }
        // -------------------
        
        // Prioritize parsing the full date-time string first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Support with/without fractional seconds
        if let date = isoFormatter.date(from: dateTimeString) {
            if loggerEnabled { print("    -> Success with .withInternetDateTime, .withFractionalSeconds") }
            return date // Successfully parsed full date-time
        }
        
        // Fallback 1: Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateTimeString) {
            if loggerEnabled { print("    -> Success with .withInternetDateTime (no fractional seconds)") }
             return date
        }
        
        // Fallback 2: Try parsing just the date (for all-day events)
        isoFormatter.formatOptions = [.withFullDate]
        if let date = isoFormatter.date(from: dateTimeString) {
            if loggerEnabled { print("    -> Success with .withFullDate (all-day event?)") }
            return date 
        }

        // Fallback 3: Sometimes Google might omit fractional seconds AND timezone offset like '2023-10-27T10:00:00'
        // This is less common but can happen. Add a specific check for it.
        // No standard format option for this, might need manual parsing or different formatter

        print("Warning: Failed to parse date/time string with multiple formats: \(dateTimeString)")
        return nil // Parsing failed
    }
    
    // Custom Decodable initializer to parse dates
    enum CodingKeys: String, CodingKey {
        case id, summary, description, start, end, htmlLink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        start = try container.decodeIfPresent(EventDateTime.self, forKey: .start)
        end = try container.decodeIfPresent(EventDateTime.self, forKey: .end)
        htmlLink = try container.decodeIfPresent(String.self, forKey: .htmlLink)

        // Parse the dates after decoding the strings
        startDate = CalendarEvent.parseDateTimeString(start?.dateTime ?? start?.date) // Prefer dateTime, fallback to date
        endDate = CalendarEvent.parseDateTimeString(end?.dateTime ?? end?.date)
    }

    // Make Hashable for potential use in ForEach without explicit ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    // --- REMOVED old formatDate helper --- 
    // private func formatDate(from eventDateTime: EventDateTime?) -> String { ... } 
    // --- (logic moved/adapted into parseDateTimeString and computed vars) --- 
}

// Represents the start/end time structure from Google Calendar API
struct EventDateTime: Decodable, Hashable {
    let dateTime: String? // Full RFC3339 timestamp (e.g., "2025-04-20T10:00:00-07:00")
    let date: String?     // Just the date (e.g., "2025-04-20") for all-day events
    let timeZone: String? // Optional: Timezone (e.g., "America/Los_Angeles")
}
 